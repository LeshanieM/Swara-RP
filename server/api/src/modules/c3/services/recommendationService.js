// Picks the next activity with Hybrid LinUCB and learns from each activity's reward.
const config = require('../config');
const ApiError = require('../../../lib/ApiError');
const ActivityAttempt = require('../models/ActivityAttempt');
const features = require('../bandit/features');
const hybrid = require('../bandit/hybridLinUCB');
const catalogService = require('./catalogService');
const contextService = require('./contextService');
const adviceService = require('./adviceService');
const engagementService = require('./engagementService');
const banditStore = require('./banditStore');
const scoring = require('./scoring');
const wordCheckService = require('./wordCheckService');
const speechCheckService = require('./speechCheckService');

const { round } = scoring;
const TIE_TOLERANCE = 1e-9;

async function itemLastUsed(childId) {
  const used = await ActivityAttempt.find({ childId, itemId: { $ne: null } }).select('itemId createdAt');
  const map = new Map();
  for (const a of used) if ((map.get(a.itemId) ?? 0) < a.createdAt.getTime()) map.set(a.itemId, a.createdAt.getTime());
  return map;
}

const describeArm = (arm, parentLed) => ({
  armId: arm.id, type: arm.type, difficulty: arm.difficulty, ageBand: arm.ageBand, title: arm.title,
  targetSkill: arm.targetSkill, durationMin: arm.durationMin, appActivityId: arm.appActivityId, parentLed,
});

/** Candidate arms: the band's eligible arms, minus exclusions; easy arms only for a parent-led activity. */
function candidateArms(session, attempts, { excludeArmIds = [], parentLed }) {
  let arms = catalogService.eligibleArms(session.ageBand).filter((a) => !excludeArmIds.includes(a.id));
  if (parentLed) arms = arms.filter((a) => a.difficulty === 'easy');
  // Avoid repeating the activity just done, when there is a choice.
  const last = [...attempts].sort((a, b) => b.sequence - a.sequence)[0];
  if (last && arms.length > 1) arms = arms.filter((a) => a.id !== last.armId);
  // Each activity type once per session while other types remain (a session has 5 activities, a band 6 types).
  const usedTypes = new Set(attempts.filter((a) => contextService.DONE.includes(a.status)).map((a) => a.type));
  const fresh = arms.filter((a) => !usedTypes.has(a.type));
  if (fresh.length) arms = fresh;
  if (!arms.length) throw ApiError.unprocessable('no_eligible_activity', 'No eligible activity is left after the exclusions.');
  return arms;
}

async function recommend(session, body) {
  if (session.status !== 'active') throw new ApiError(409, 'session_not_active', `Session is ${session.status}.`);
  const attempts = await ActivityAttempt.find({ sessionId: session._id });
  const pending = attempts.find((a) => a.status === 'pending');
  if (pending) {
    throw new ApiError(409, 'activity_pending', 'Record the result of the open activity (or skip it) before asking for the next one.', { attemptId: pending.id, armId: pending.armId });
  }

  const advice = adviceService.evaluate(session, attempts);
  if (advice.advice === 'end_session' && !body.force) {
    return { sessionId: session.id, activity: null, item: null, advice };
  }
  const parentLed = advice.advice === 'parent_led';
  const arms = candidateArms(session, attempts, { excludeArmIds: body.excludeArmIds, parentLed });

  const [base, typeScores, lastUsed] = await Promise.all([
    contextService.baseContext({ childId: session.childId, ageBand: session.ageBand, session, sessionAttempts: attempts }),
    contextService.typeScores(session.childId),
    itemLastUsed(session.childId),
  ]);
  const candidates = arms.map((arm) => {
    const values = contextService.forArm(base, typeScores, arm);
    const x = features.contextVector(values, banditStore.FEATURES);
    const z = features.sharedVector(x, arm, banditStore.FEATURES, catalogService.DIFFICULTIES, catalogService.TYPES);
    return { arm, armId: arm.id, values, x, z };
  });

  const [population, child] = await Promise.all([
    banditStore.loadPopulation(),
    banditStore.loadChild(session.childId, arms.map((a) => a.id)),
  ]);
  const scores = hybrid.score(banditStore.populationView(population), child.arms, candidates, config.alpha);

  // Greedy pick, ties broken at random (otherwise every new child starts at the first arm in catalog order),
  // unless the ε-random branch fires. The propensity of the chosen arm is logged for replay evaluation.
  const best = Math.max(...scores.map((s) => s.ucb));
  const tied = scores.map((s, i) => (best - s.ucb <= TIE_TOLERANCE ? i : -1)).filter((i) => i >= 0);
  const eps = config.exploreEpsilon;
  const explored = eps > 0 && Math.random() < eps;
  const chosenIndex = explored ? Math.floor(Math.random() * candidates.length) : tied[Math.floor(Math.random() * tied.length)];
  const propensity = eps / candidates.length + (tied.includes(chosenIndex) ? (1 - eps) / tied.length : 0);
  const chosen = candidates[chosenIndex];
  const item = catalogService.drawItem(chosen.arm, lastUsed);

  let attempt;
  try {
    attempt = await ActivityAttempt.create({
      sessionId: session._id,
      childId: session.childId,
      ageBand: session.ageBand,
      sequence: attempts.length + 1,
      armId: chosen.arm.id,
      type: chosen.arm.type,
      difficulty: chosen.arm.difficulty,
      itemId: item.id,
      parentLed,
      elapsedMinAtStart: advice.elapsedMinutes,
      policy: config.policy,
      alpha: config.alpha,
      epsilon: eps,
      explored,
      propensity: round(propensity, 6),
      candidates: candidates.length,
      advice: advice.advice,
      context: {
        featureNames: banditStore.FEATURES, values: chosen.values, x: chosen.x, z: chosen.z,
        candidates: candidates.map((c) => ({ armId: c.armId, typeRecentScore: c.values.typeRecentScore })),
      },
      scores: scores.map((s) => ({ ...s, mean: round(s.mean), bonus: round(s.bonus), ucb: round(s.ucb) })),
    });
  } catch (err) {
    if (err.code === 11000) throw new ApiError(409, 'activity_pending', 'Another activity was opened for this session at the same time.');
    throw err;
  }

  return {
    attemptId: attempt.id,
    sessionId: session.id,
    sequence: attempt.sequence,
    activity: describeArm(chosen.arm, parentLed),
    item,
    advice,
    context: { featureNames: banditStore.FEATURES, values: chosen.values, sources: base.sources },
    selection: {
      policy: config.policy,
      alpha: config.alpha,
      epsilon: eps,
      explored,
      propensity: attempt.propensity,
      candidates: candidates.length,
      scores: [...attempt.scores].sort((a, b) => b.ucb - a.ucb),
    },
    links: { result: `/api/c3/sessions/${session.id}/activities/${attempt.id}/result` },
  };
}

/** Observe the reward on the chosen arm; for the discounted policy, older per-child results fade first. */
function learn(childId, attempt, reward) {
  return banditStore.withLock(async () => {
    const sameSchema = features.sameNames(attempt.context.featureNames, banditStore.FEATURES);
    if (!sameSchema) return { updated: false, reason: 'feature_schema_changed' };
    const [population, child] = await Promise.all([banditStore.loadPopulation(), banditStore.loadChild(childId, [attempt.armId])]);
    const pop = banditStore.populationView(population);
    if (config.policy === 'discounted') hybrid.discountChild(pop, child.arms, config.discountGamma, config.childPrior);
    const arm = child.arms[attempt.armId];
    hybrid.update(pop, arm, attempt.context.x, attempt.context.z, reward);
    arm.lastUpdated = new Date();
    banditStore.applyPopulation(population, pop);
    population.updates += 1;
    child.updates += 1;
    await banditStore.save(population, child);
    return { updated: true, armId: attempt.armId, n: arm.n, meanReward: round(arm.rewardSum / arm.n) };
  });
}

function normaliseResult(body) {
  if (body.skipped) {
    return { ...body, targets: body.targets ?? null, successes: body.successes ?? 0, completedShare: 0 };
  }
  return { ...body, completedShare: body.completedShare ?? 1 };
}

async function recordResult(session, attemptId, body) {
  const attempt = await ActivityAttempt.findOne({ _id: attemptId, sessionId: session._id });
  if (!attempt) throw ApiError.notFound('activity_not_found', `No activity ${attemptId} in session ${session.id}.`);
  if (attempt.status !== 'pending') {
    throw new ApiError(409, 'result_already_recorded', `This activity is already ${attempt.status}.`, { attemptId: attempt.id, status: attempt.status });
  }
  if (session.status !== 'active') throw new ApiError(409, 'session_not_active', `Session is ${session.status}.`);

  const result = normaliseResult(body);
  const engagement = await engagementService.estimate({
    childId: session.childId, attemptId: attempt._id, result, clientEstimate: body.engagementEstimate,
  });
  // Word activities: when words were checked, P counts the words the child actually said (unclear ones left out).
  // Reading / picture description: P is the share of the passage read / keywords mentioned (speech check).
  // The app's own successes stay in the result for comparison.
  const speech = speechCheckService.summarise(attempt);
  const verification = speech ?? wordCheckService.summarise(attempt);
  let scored = result;
  if (!result.skipped && verification.source === 'word_check') {
    scored = { ...result, targets: verification.matched + verification.mismatched, successes: verification.matched };
  } else if (!result.skipped && verification.source === 'speech_check') {
    scored = { ...result, targets: verification.targets, successes: verification.successes };
  }
  const P = scoring.performance(scored);
  const rewards = scoring.rewards(P, engagement.score, result.parentFeedback);
  const reward = rewards[config.rewardMode];

  const { engagementEstimate, ...stored } = result;
  const update = {
    result: stored,
    verification,
    engagement,
    performance: round(P),
    rewards,
    reward,
    rewardMode: config.rewardMode,
    status: result.skipped ? 'skipped' : 'completed',
    completedAt: new Date(),
  };
  // Claim the attempt atomically so a duplicate request can't update the bandit twice.
  const claimed = await ActivityAttempt.findOneAndUpdate({ _id: attempt._id, status: 'pending' }, { $set: update }, { new: true, runValidators: true });
  if (!claimed) throw new ApiError(409, 'result_already_recorded', 'This activity was recorded by another request.');

  const bandit = await learn(session.childId, claimed, reward);
  if (bandit.updated) await ActivityAttempt.updateOne({ _id: claimed._id }, { $set: { banditUpdated: true } });

  const attempts = await ActivityAttempt.find({ sessionId: session._id });
  return {
    attemptId: claimed.id,
    status: claimed.status,
    armId: claimed.armId,
    itemId: claimed.itemId,
    performance: claimed.performance,
    verification: claimed.verification,
    engagement: claimed.engagement,
    rewards,
    reward,
    rewardMode: config.rewardMode,
    bandit,
    advice: adviceService.evaluate(session, attempts),
  };
}

/** The context the bandit would see for this child now, outside a session (camera off, C2 missing). */
async function contextPreview(childId, age) {
  const ageBand = catalogService.bandForAge(age);
  const [base, typeScores] = await Promise.all([
    contextService.baseContext({ childId, ageBand }),
    contextService.typeScores(childId),
  ]);
  const perType = Object.fromEntries(catalogService.TYPES.map((t) => [t, typeScores[t]?.score ?? config.neutralPrior]));
  return {
    childId, age, ageBand, featureNames: banditStore.FEATURES, values: base.values, typeRecentScore: perType, sources: base.sources,
  };
}

/** Per-arm counts, mean reward and θ for the child, plus the shared β; raw matrices on request (for the Dart mirror). */
async function banditForChild(childId, { matrices }) {
  const [population, child] = await Promise.all([banditStore.loadPopulation(), banditStore.loadChild(childId)]);
  const pop = banditStore.populationView(population);
  const arms = Object.entries(child.arms).map(([armId, arm]) => {
    const { theta } = hybrid.parameters(pop, arm);
    return {
      armId,
      n: arm.n,
      meanReward: arm.n ? round(arm.rewardSum / arm.n) : null,
      lastUpdated: arm.lastUpdated ?? null,
      theta: theta.map((v) => round(v)),
      ...(matrices ? { A: arm.A, B: arm.B, b: arm.b } : {}),
    };
  }).sort((a, b) => b.n - a.n);
  const { beta } = hybrid.populationTerms(pop);
  return {
    childId,
    policy: config.policy,
    alpha: config.alpha,
    childPrior: config.childPrior,
    discountGamma: config.policy === 'discounted' ? config.discountGamma : null,
    featureVersion: child.featureVersion,
    featureNames: banditStore.FEATURES,
    sharedNames: banditStore.SHARED,
    updates: child.updates,
    stored: !child.isNew,
    arms,
    population: {
      updates: population.updates,
      beta: Object.fromEntries(banditStore.SHARED.map((n, i) => [n, round(beta[i])]).filter(([, v]) => v !== 0)),
      ...(matrices ? { A0: pop.A0, b0: pop.b0 } : {}),
    },
    migrations: child.migratedFrom,
  };
}

module.exports = { describeArm, recommend, recordResult, contextPreview, banditForChild };
