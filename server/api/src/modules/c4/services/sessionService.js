/**
 * C4 sessions: one topic per session, chosen from the child's ranked interests, with a skip log. (The fixed
 * sequence, the H4c control, is available only with C4_ALLOW_FIXED=1.)
 *
 * Topic level follows progress: concrete topics are preferred when the child's latest C4 band is "below", when
 * C3's Therapy Success Score is falling, when the stuttering rate (%SS from C1 or from C4's own samples) is rising,
 * or before any sample exists when the parent checklist said "emerging". The server reads C3 and C1 itself.
 */
const crypto = require('crypto');
const env = require('../../../config/env');
const ApiError = require('../../../lib/ApiError');
const ChildLanguageProfile = require('../models/ChildLanguageProfile');
const LanguageSession = require('../models/LanguageSession');
const LanguageSample = require('../models/LanguageSample');
const catalog = require('./catalogService');
const topicSelector = require('./topicSelector');

const copyTopic = (t) => ({
  id: t.id, categoryId: t.categoryId, level: t.level, title: t.title, mainPrompt: t.mainPrompt, followUps: t.followUps,
});

async function requireProfile(childId) {
  const profile = await ChildLanguageProfile.findOne({ childId });
  if (!profile) {
    throw ApiError.unprocessable('onboarding_required', `Child ${childId} has no C4 profile; PUT /children/${childId}/profile first.`);
  }
  return profile;
}

// %SS points between the last two measurements that count as "stuttering is rising".
const STUTTERING_RISE_PP = 2;
const C3_TREND = { needs_attention: 'falling', improving: 'rising', stable: 'stable' };

/** C3's TSS trend for the child (falling / stable / rising), read in-process; null when there is none. */
async function c3Trend(childId) {
  try {
    // Required lazily so C4 still runs if the C3 module is removed.
    // eslint-disable-next-line global-require
    const summary = await require('../../c3/services/sessionService').summaryForChild(childId);
    return C3_TREND[summary.tss?.trend] ?? null;
  } catch {
    return null;
  }
}

/** The stuttering rate's direction: C1's last two assessments of the same task, and C4's last two assessed samples. */
async function stutteringTrend(childId) {
  let c1 = null;
  try {
    // eslint-disable-next-line global-require
    const s = await require('../../c1/services/assessmentService').summaryForChild(childId);
    const t = s.latest ? s.byTask[s.latest.taskType] : null;
    if (t && t.previousPercentSS != null) c1 = { latest: t.percentSS, previous: t.previousPercentSS, change: round2(t.percentSS - t.previousPercentSS) };
  } catch {
    c1 = null;
  }
  const samples = await LanguageSample.find({ childId, status: 'completed', 'stuttering.status': 'assessed' })
    .sort({ createdAt: -1, _id: -1 }).limit(2).select('stuttering.percentSSCurrent stuttering.percentSS');
  const pss = (s) => s.stuttering?.percentSSCurrent ?? s.stuttering?.percentSS;
  const c4 = samples.length === 2 ? { latest: pss(samples[0]), previous: pss(samples[1]), change: round2(pss(samples[0]) - pss(samples[1])) } : null;
  const rising = [c1, c4].some((x) => x && x.change >= STUTTERING_RISE_PP);
  return { c1, c4, rising, risePP: STUTTERING_RISE_PP };
}

const round2 = (x) => Math.round(x * 100) / 100;

async function levelPolicy(profile, c3TssTrendIn) {
  const [latest, c3TssTrend, stuttering] = await Promise.all([
    LanguageSample.findOne({ childId: profile.childId, status: 'completed' }).sort({ createdAt: -1, _id: -1 }).select('band'),
    c3TssTrendIn ? Promise.resolve(c3TssTrendIn) : c3Trend(profile.childId),
    stutteringTrend(profile.childId),
  ]);
  const reasons = [];
  if (latest?.band?.effective === 'below') reasons.push('c4_band_below');
  if (c3TssTrend === 'falling') reasons.push('c3_tss_falling');
  if (stuttering.rising) reasons.push('stuttering_rising');
  if (!latest && profile.checklist?.startingLevel === 'emerging') reasons.push('checklist_emerging');
  return {
    preferConcrete: reasons.length > 0,
    stutteringRising: stuttering.rising,
    reasons,
    inputs: {
      c4Band: latest?.band?.effective ?? null,
      c3TssTrend: c3TssTrend ?? null,
      c3TssTrendSource: c3TssTrendIn ? 'request' : 'c3',
      stuttering,
      checklistLevel: profile.checklist?.startingLevel ?? null,
    },
  };
}

async function history(childId) {
  const sessions = await LanguageSession.find({ childId }).sort({ createdAt: 1, _id: 1 }).select('topic mode');
  return sessions.map((s) => ({ sessionId: String(s._id), topicId: s.topic.id, categoryId: s.topic.categoryId, mode: s.mode }));
}

function choose({ profile, mode, hist, policy, exclude, seed }) {
  if (mode === 'fixed') {
    const sequence = catalog.fixedSequence(profile.ageBand);
    const used = hist.filter((h) => h.mode === 'fixed').length + exclude.length;
    const topic = sequence[used % sequence.length];
    return { topic, selection: { method: 'fixed-sequence', position: used % sequence.length, length: sequence.length } };
  }
  return topicSelector.select({
    rankedCategories: profile.rankedCategories,
    topicsOf: (categoryId) => catalog.topics(profile.ageBand, { category: categoryId }),
    history: hist,
    levelPolicy: policy,
    exclude,
    seed,
  });
}

/** What the app shows now: the main prompt or a follow-up, in both languages. */
function prompts(session) {
  const { topic, currentPrompt } = session;
  const exhausted = currentPrompt >= topic.followUps.length;
  return {
    current: currentPrompt < 0 ? { kind: 'main', text: topic.mainPrompt }
      : exhausted ? null : { kind: 'follow_up', index: currentPrompt, text: topic.followUps[currentPrompt] },
    followUpsRemaining: Math.max(0, topic.followUps.length - Math.max(currentPrompt + 1, 0)),
    exhausted,
  };
}

const view = (session) => ({ ...session.toJSON(), prompts: prompts(session) });

async function create({ childId, mode, c3TssTrend, seed }) {
  if (mode === 'fixed' && !env.c4AllowFixed) {
    throw ApiError.unprocessable('fixed_sessions_off', 'Every session is personalised; fixed-topic sessions need C4_ALLOW_FIXED=1 on the server.');
  }
  const profile = await requireProfile(childId);
  if (mode === 'personalised' && profile.rankedCategories.length !== catalog.RANKED) {
    throw ApiError.unprocessable('onboarding_required', 'Rank 5 favourite categories before a personalised session.');
  }
  const policy = await levelPolicy(profile, c3TssTrend);
  const drawSeed = seed ?? crypto.randomInt(0, 2 ** 32 - 1);
  const { topic, selection } = choose({
    profile, mode, hist: await history(childId), policy, exclude: [], seed: drawSeed,
  });
  const session = await LanguageSession.create({
    childId,
    age: profile.age,
    ageBand: profile.ageBand,
    language: profile.language,
    mode,
    topic: copyTopic(topic),
    selection,
    progressSignal: policy,
    offeredTopicIds: [topic.id],
  });
  return view(session);
}

async function find(id) {
  const session = await LanguageSession.findById(id);
  if (!session) throw ApiError.notFound('session_not_found', `No C4 session with id ${id}.`);
  return session;
}

const get = async (id) => view(await find(id));

/**
 * Skipping a follow-up moves to the next follow-up. Skipping the main prompt
 * moves to another topic (never one already offered in this session). Both are logged.
 */
async function skip(id, { kind, reason }) {
  const session = await find(id);
  if (session.status !== 'open') {
    throw ApiError.unprocessable('session_already_recorded', 'This session already has a recording; start a new session.');
  }
  if (kind === 'follow_up') {
    if (session.currentPrompt < 0) {
      throw ApiError.unprocessable('main_prompt_showing', 'The main prompt is showing; skip it with kind "main_prompt".');
    }
    if (session.currentPrompt >= session.topic.followUps.length) {
      throw ApiError.unprocessable('no_follow_up_left', 'Every follow-up has been used.');
    }
    session.skips.push({ kind, topicId: session.topic.id, followUpIndex: session.currentPrompt, reason });
    session.currentPrompt += 1;
  } else {
    const profile = await requireProfile(session.childId);
    const policy = await levelPolicy(profile, session.progressSignal?.inputs?.c3TssTrend ?? undefined);
    // This session's own topic isn't history: the previous session still decides the blocked category.
    const hist = (await history(session.childId)).filter((h) => h.sessionId !== String(session._id));
    const { topic, selection } = choose({
      profile, mode: session.mode, hist, policy, exclude: session.offeredTopicIds, seed: crypto.randomInt(0, 2 ** 32 - 1),
    });
    session.skips.push({ kind, topicId: session.topic.id, followUpIndex: null, reason, replacedByTopicId: topic.id });
    session.topic = copyTopic(topic);
    session.selection = selection;
    session.offeredTopicIds.push(topic.id);
    session.currentPrompt = -1;
  }
  await session.save();
  return view(session);
}

/** Move from the main prompt (or a follow-up) to the next follow-up after the child answered. */
async function advance(id) {
  const session = await find(id);
  if (session.status !== 'open') {
    throw ApiError.unprocessable('session_already_recorded', 'This session already has a recording; start a new session.');
  }
  if (session.currentPrompt >= session.topic.followUps.length) {
    throw ApiError.unprocessable('no_follow_up_left', 'Every follow-up has been used.');
  }
  session.currentPrompt += 1;
  await session.save();
  return view(session);
}

async function listForChild(childId, { limit, offset }) {
  const [items, total] = await Promise.all([
    LanguageSession.find({ childId }).sort({ createdAt: -1, _id: -1 }).skip(offset).limit(limit).select('-selection.candidates'),
    LanguageSession.countDocuments({ childId }),
  ]);
  return { items, total, limit, offset };
}

module.exports = {
  create, get, find, skip, advance, listForChild, requireProfile,
};
