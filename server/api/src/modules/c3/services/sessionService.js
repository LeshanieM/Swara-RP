// Therapy sessions: start, breaks, completion with the TSS, the parent questionnaire, history and the child summary.
const config = require('../config');
const ApiError = require('../../../lib/ApiError');
const TherapySession = require('../models/TherapySession');
const ActivityAttempt = require('../models/ActivityAttempt');
const BanditState = require('../models/BanditState');
const catalogService = require('./catalogService');
const contextService = require('./contextService');
const adviceService = require('./adviceService');
const scoring = require('./scoring');

const { round, mean } = scoring;

async function find(id) {
  const session = await TherapySession.findById(id);
  if (!session) throw ApiError.notFound('session_not_found', `No therapy session with id ${id}.`);
  return session;
}

const requireActive = (session) => {
  if (session.status !== 'active') throw new ApiError(409, 'session_not_active', `Session is ${session.status}.`);
};

/**
 * Closes the child's unfinished sessions that started more than config.resumeHours ago: their open activity is
 * abandoned (no reward, no bandit update), the outcome is computed from what was done, and the session is marked
 * abandoned. Runs before a child's sessions are listed, resumed or started, and for everyone at startup.
 */
async function expireStale(childId = null) {
  const cutoff = new Date(Date.now() - config.resumeHours * 3600 * 1000);
  const stale = await TherapySession.find({ status: 'active', createdAt: { $lt: cutoff }, ...(childId ? { childId } : {}) });
  for (const session of stale) {
    await ActivityAttempt.updateMany({ sessionId: session._id, status: 'pending' }, { $set: { status: 'abandoned', completedAt: new Date() } });
    const attempts = await ActivityAttempt.find({ sessionId: session._id });
    session.outcome = await computeOutcome(session, attempts);
    session.status = 'abandoned';
    session.abandonedAt = new Date();
    await session.save();
  }
  return stale.length;
}

/** The child's session that can still be continued (started within config.resumeHours), with any open activity. */
async function activeForChild(childId) {
  await expireStale(childId);
  const session = await TherapySession.findOne({ childId, status: 'active' }).sort({ createdAt: -1 });
  if (!session) return { session: null, pending: null };
  const attempts = await ActivityAttempt.find({ sessionId: session._id }).sort({ sequence: 1 });
  const open = attempts.find((a) => a.status === 'pending');
  let pending = null;
  if (open) {
    // Same shape as next-activity, so the app can reopen the activity screen.
    // eslint-disable-next-line global-require
    const { describeArm } = require('./recommendationService');
    let arm = null;
    try {
      arm = catalogService.findArm(open.armId);
    } catch {
      arm = null; // an arm from an older catalog
    }
    pending = {
      attemptId: open.id, sessionId: session.id, sequence: open.sequence,
      activity: arm ? describeArm(arm, open.parentLed) : { armId: open.armId, type: open.type, difficulty: open.difficulty, parentLed: open.parentLed },
      item: catalogService.findItem(open.itemId) ?? null,
      links: { result: `/api/c3/sessions/${session.id}/activities/${open.id}/result` },
    };
  }
  return {
    session: { ...session.toJSON(), advice: adviceService.evaluate(session, attempts) },
    activitiesDone: attempts.filter((a) => contextService.DONE.includes(a.status)).length,
    pending,
  };
}

async function create(body) {
  await expireStale(body.childId);
  const ageBand = catalogService.bandForAge(body.age);
  const c2 = await contextService.resolveC2Flag(body.childId, body.c2Flag);
  const session = new TherapySession({
    childId: body.childId,
    ageAtSession: body.age,
    ageBand,
    language: body.language,
    cameraOn: body.cameraOn,
    plannedMinutes: body.plannedMinutes ?? config.defaultPlannedMinutes,
    maxActivities: body.maxActivities ?? config.maxActivitiesPerSession,
    c2Flag: c2.flag,
    c2FlagSource: c2.source,
    c2AnalysisId: c2.analysisId,
    c2BehaviourTypes: c2.behaviourTypes ?? [],
    c2FlagClient: body.c2Flag ?? null,
    policy: config.policy,
    rewardMode: config.rewardMode,
  });
  const base = await contextService.baseContext({ childId: session.childId, ageBand, session });
  session.contextAtStart = base;
  await session.save();
  return session;
}

async function get(id) {
  const session = await find(id);
  const attempts = await ActivityAttempt.find({ sessionId: session._id }).sort({ sequence: 1 }).select('-context.x -context.z -scores');
  return {
    ...session.toJSON(),
    advice: session.status === 'active' ? adviceService.evaluate(session, attempts) : null,
    activities: attempts.map((a) => a.toJSON()),
  };
}

async function addBreak(id, body) {
  const session = await find(id);
  requireActive(session);
  const attempts = await ActivityAttempt.find({ sessionId: session._id });
  if (attempts.some((a) => a.status === 'pending')) {
    throw new ApiError(409, 'activity_pending', 'Finish or skip the open activity before taking a break.');
  }
  const elapsed = contextService.elapsedMinutes(session, attempts);
  session.breaks.push({ durationSec: body.durationSec ?? config.defaultBreakSec, reason: body.reason, elapsedMinAtStart: round(elapsed, 2) });
  await session.save();
  return { sessionId: session.id, breaks: session.breaks, advice: adviceService.evaluate(session, attempts) };
}

/** C1 %SS change for the record next to the TSS (not weighted into it until the weight is agreed). */
async function fluency(childId) {
  const c1 = await contextService.c1Context(childId);
  if (c1.status !== 'available') return { available: false, status: c1.status, includedInTss: false };
  return {
    available: true,
    assessmentId: c1.assessmentId,
    taskType: c1.taskType,
    severity: c1.severity,
    percentSS: c1.percentSS,
    previousPercentSS: c1.previousPercentSS,
    changePP: c1.previousPercentSS === null ? null : round(c1.percentSS - c1.previousPercentSS, 2),
    trend: c1.trend,
    includedInTss: false,
  };
}

async function computeOutcome(session, attempts, fluencyInfo) {
  const finished = attempts.filter((a) => contextService.DONE.includes(a.status));
  const engagements = finished.map((a) => a.engagement?.score).filter(Number.isFinite);
  const meanP = finished.length ? mean(finished.map((a) => a.performance ?? 0)) : null;
  const meanE = engagements.length ? mean(engagements) : null;
  const q = session.questionnaire?.q ?? null;
  const { tss, weights } = scoring.tss(meanP, meanE, q);
  const modes = {};
  for (const a of finished) if (a.engagement?.mode) modes[a.engagement.mode] = (modes[a.engagement.mode] || 0) + 1;
  return {
    activitiesCompleted: attempts.filter((a) => a.status === 'completed').length,
    activitiesSkipped: attempts.filter((a) => a.status === 'skipped').length,
    activitiesAbandoned: attempts.filter((a) => a.status === 'abandoned').length,
    meanPerformance: round(meanP),
    meanEngagement: round(meanE),
    questionnaireScore: q,
    weights,
    tss,
    engagementModes: modes,
    fluency: fluencyInfo ?? (await fluency(session.childId)),
    computedAt: new Date(),
  };
}

async function complete(id) {
  const session = await find(id);
  if (session.status === 'completed') throw new ApiError(409, 'session_already_completed', 'This session is already completed.');
  if (session.status === 'abandoned') throw new ApiError(409, 'session_abandoned', 'This session was left unfinished and has been closed.');
  // An activity left open gets no reward and no bandit update.
  await ActivityAttempt.updateMany({ sessionId: session._id, status: 'pending' }, { $set: { status: 'abandoned', completedAt: new Date() } });
  const attempts = await ActivityAttempt.find({ sessionId: session._id });
  session.outcome = await computeOutcome(session, attempts);
  session.status = 'completed';
  session.completedAt = new Date();
  await session.save();
  return get(id);
}

async function submitQuestionnaire(id, body) {
  const session = await find(id);
  if (session.questionnaire?.submittedAt) {
    throw new ApiError(409, 'questionnaire_already_submitted', 'The questionnaire for this session was already submitted.');
  }
  const qn = catalogService.questionnaire;
  const expected = qn.items.map((i) => i.id);
  const missing = expected.filter((k) => body.answers[k] === undefined);
  const unknown = Object.keys(body.answers).filter((k) => !expected.includes(k));
  if (missing.length || unknown.length) {
    throw ApiError.unprocessable('invalid_questionnaire', 'Answer every questionnaire item, and only those.', { missing, unknown, expected });
  }
  const { meanScore, q } = scoring.questionnaireScore(body.answers, qn.scale);
  session.questionnaire = {
    version: qn.version, answers: body.answers, meanScore, q, engaged: meanScore >= qn.engagedThreshold,
    respondent: 'parent', language: body.language ?? session.language, submittedAt: new Date(),
  };
  // A late questionnaire updates the TSS of a completed session.
  if (session.status === 'completed') {
    const attempts = await ActivityAttempt.find({ sessionId: session._id });
    session.outcome = await computeOutcome(session, attempts, session.outcome?.fluency);
  }
  await session.save();
  return { sessionId: session.id, status: session.status, questionnaire: session.questionnaire, outcome: session.outcome ?? null };
}

async function listForChild(childId, { status, limit, offset }) {
  await expireStale(childId);
  const filter = { childId, ...(status ? { status } : {}) };
  const [items, total] = await Promise.all([
    TherapySession.find(filter).sort({ createdAt: -1, _id: -1 }).skip(offset).limit(limit).select('-contextAtStart'),
    TherapySession.countDocuments(filter),
  ]);
  return { items, total, limit, offset };
}

function tssTrend(latest, previous) {
  if (latest == null || previous == null) return 'insufficient_data';
  const change = latest - previous;
  if (change >= config.tssTrendMinChange) return 'improving';
  if (change <= -config.tssTrendMinChange) return 'needs_attention';
  return 'stable';
}

/** Local calendar day (server time) of a date, as YYYY-MM-DD. */
const dayOf = (d) => {
  const x = new Date(d);
  return `${x.getFullYear()}-${String(x.getMonth() + 1).padStart(2, '0')}-${String(x.getDate()).padStart(2, '0')}`;
};

/** Consecutive days, ending today or yesterday, with at least one completed session. */
function streakDays(completedDates, now = new Date()) {
  const days = new Set(completedDates.map(dayOf));
  const cursor = new Date(now);
  if (!days.has(dayOf(cursor))) cursor.setDate(cursor.getDate() - 1); // today not done yet: count up to yesterday
  let n = 0;
  while (days.has(dayOf(cursor))) {
    n += 1;
    cursor.setDate(cursor.getDate() - 1);
  }
  return n;
}

/** C3's part of the progress report: TSS and engagement trend, recent scores by type, the bandit's view. */
async function summaryForChild(childId) {
  await expireStale(childId);
  const [completed, activeCount, typeScores, c1, c2, banditDoc] = await Promise.all([
    TherapySession.find({ childId, status: 'completed' }).sort({ completedAt: -1 }).limit(10).select('outcome questionnaire completedAt ageBand'),
    TherapySession.countDocuments({ childId, status: 'active' }),
    contextService.typeScores(childId),
    contextService.c1Context(childId),
    contextService.c2Context(childId),
    BanditState.findOne({ scope: 'child', childId }).select('arms updates'),
  ]);
  const withTss = completed.filter((s) => s.outcome?.tss != null);
  const latest = withTss[0]?.outcome.tss ?? null;
  const previous = withTss[1]?.outcome.tss ?? null;
  const lastThreeE = completed.map((s) => s.outcome?.meanEngagement).filter(Number.isFinite).slice(0, 3);
  const arms = Object.entries(banditDoc?.arms || {})
    .filter(([, a]) => a.n > 0)
    .map(([armId, a]) => ({ armId, n: a.n, meanReward: round(a.rewardSum / a.n) }))
    .sort((a, b) => b.n - a.n);
  const [allCompleted, activityCounts] = await Promise.all([
    TherapySession.find({ childId, status: 'completed' }).select('completedAt'),
    ActivityAttempt.aggregate([{ $match: { childId, status: { $in: ['completed', 'skipped'] } } }, { $group: { _id: '$status', n: { $sum: 1 } } }]),
  ]);
  const countOf = (s) => activityCounts.find((c) => c._id === s)?.n ?? 0;
  return {
    childId,
    sessionsCompleted: allCompleted.length,
    sessionsActive: activeCount,
    sessionsAbandoned: await TherapySession.countDocuments({ childId, status: 'abandoned' }),
    // Rewards shown in the app: a day streak of completed sessions and one star per completed activity.
    streakDays: streakDays(allCompleted.map((s) => s.completedAt)),
    stars: countOf('completed'),
    activitiesSkipped: countOf('skipped'),
    tss: { latest, previous, trend: tssTrend(latest, previous), recent: withTss.map((s) => ({ sessionId: s.id, date: s.completedAt, tss: s.outcome.tss })) },
    engagement: { lastSessions: lastThreeE, mean: round(mean(lastThreeE)) },
    questionnaire: {
      lastScore: completed.find((s) => s.questionnaire?.meanScore != null)?.questionnaire.meanScore ?? null,
    },
    typeScores,
    c1,
    c2,
    bandit: { updates: banditDoc?.updates ?? 0, arms },
  };
}

module.exports = { find, requireActive, expireStale, activeForChild, streakDays, create, get, addBreak, complete, submitQuestionnaire, listForChild, summaryForChild };
