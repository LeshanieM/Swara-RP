// Builds the bandit's named context from the profile, C1, C2 and the child's C3 history.
const config = require('../config');
const ActivityAttempt = require('../models/ActivityAttempt');
const TherapySession = require('../models/TherapySession');
const { round, mean } = require('./scoring');

const DONE = ['completed', 'skipped'];

/** Latest C1 result for the child, read in-process through C1's own summary (read-only). */
async function c1Context(childId) {
  let summary;
  try {
    // Required lazily so C3 still runs (with C1 "unavailable") if the C1 module is removed.
    // eslint-disable-next-line global-require
    summary = await require('../../c1/services/assessmentService').summaryForChild(childId);
  } catch (err) {
    return { status: 'unavailable', error: err.message };
  }
  if (!summary.latest) return { status: 'missing' };
  const { latest } = summary;
  const task = summary.byTask[latest.taskType] || {};
  return {
    status: 'available',
    assessmentId: latest.assessmentId,
    date: latest.date,
    taskType: latest.taskType,
    severity: latest.severity,
    severityOrdinal: latest.severityOrdinal,
    percentSS: latest.percentSS,
    stutterType: latest.stutterType ?? null, // Block / Prolongation / Repetition / Mixed / None
    previousPercentSS: task.previousPercentSS ?? null,
    trend: task.trend ?? 'insufficient_data',
  };
}

/** Latest C2 flag for the child, read in-process through C2's own summary (read-only). */
async function c2Context(childId) {
  let summary;
  try {
    // Required lazily so C3 still runs (with C2 "unavailable") if the C2 module is removed.
    // eslint-disable-next-line global-require
    summary = await require('../../c2/services/analysisService').summaryForChild(childId);
  } catch (err) {
    return { status: 'unavailable', flag: 'missing', error: err.message };
  }
  if (!summary.latest) return { status: 'missing', flag: 'missing' };
  return {
    status: 'available',
    flag: summary.c2Flag,
    behaviourTypes: summary.latest.behaviourTypes ?? [], // e.g. ['FG'], ['HM'], ['FG', 'HM']
    analysisId: summary.latest.analysisId,
    date: summary.latest.date,
    hasVideo: summary.hasVideo,
    notAssessedReason: summary.latest.notAssessedReason ?? null,
  };
}

/**
 * The flag a new session starts with. C2's own yes / no wins; the client's value is used only when C2
 * has no yes / no for the child (no analysis yet, the camera was declined, or nothing could be assessed).
 */
async function resolveC2Flag(childId, clientFlag) {
  const c2 = await c2Context(childId);
  if (c2.flag === 'yes' || c2.flag === 'no') {
    return { flag: c2.flag, source: 'c2', analysisId: c2.analysisId, behaviourTypes: c2.behaviourTypes };
  }
  if (clientFlag) return { flag: clientFlag, source: 'client', analysisId: null };
  return { flag: 'missing', source: c2.status === 'available' ? 'c2' : 'none', analysisId: c2.analysisId ?? null };
}

/** Activity time used so far: reported durations of finished activities plus breaks. */
function elapsedMinutes(session, attempts) {
  const activitySec = attempts.filter((a) => DONE.includes(a.status)).reduce((s, a) => s + (a.result?.durationSec || 0), 0);
  const breakSec = (session?.breaks || []).reduce((s, b) => s + (b.durationSec || 0), 0);
  return (activitySec + breakSec) / 60;
}

/** Mean reward of the child's last few finished activities of each type (arm-specific feature). */
async function typeScores(childId) {
  const recent = await ActivityAttempt.find({ childId, status: { $in: DONE }, reward: { $ne: null } })
    .sort({ completedAt: -1 }).limit(200).select('type reward');
  const byType = {};
  for (const a of recent) {
    byType[a.type] = byType[a.type] || [];
    if (byType[a.type].length < config.history.typeAttempts) byType[a.type].push(a.reward);
  }
  return Object.fromEntries(Object.entries(byType).map(([t, v]) => [t, { score: round(mean(v)), n: v.length }]));
}

/**
 * Context shared by every arm for this child right now. `session` may be null (child-level preview),
 * in which case the camera is off, C2's latest flag is read live and no session time has been used.
 * A session keeps the C2 flag it started with.
 */
async function baseContext({ childId, ageBand, session = null, sessionAttempts = [] }) {
  const h = config.history;
  const [c1, c2Live, helpAttempts, pastSessions, completedCount] = await Promise.all([
    c1Context(childId),
    session ? null : resolveC2Flag(childId),
    ActivityAttempt.find({ childId, status: { $in: DONE }, 'result.parentHelp': { $ne: null } })
      .sort({ completedAt: -1 }).limit(h.parentHelpAttempts).select('result.parentHelp'),
    TherapySession.find({
      childId, status: 'completed', 'outcome.meanEngagement': { $ne: null }, ...(session ? { _id: { $ne: session._id } } : {}),
    })
      .sort({ completedAt: -1 }).limit(h.engagementSessions).select('outcome.meanEngagement'),
    TherapySession.countDocuments({ childId, status: 'completed' }),
  ]);

  const c2 = session
    ? {
      flag: session.c2Flag || 'missing',
      source: session.c2FlagSource || 'none',
      analysisId: session.c2AnalysisId ?? null,
      behaviourTypes: session.c2BehaviourTypes || [],
    }
    : c2Live;
  const c2Types = c2.flag === 'yes' ? (c2.behaviourTypes || []) : [];
  const c1Type = c1.status === 'available' ? c1.stutterType : null;
  const c2Flag = c2.flag;
  const parentHelp = helpAttempts.length ? mean(helpAttempts.map((a) => a.result.parentHelp / 3)) : 0;
  const engagementTrend = pastSessions.length ? mean(pastSessions.map((s) => s.outcome.meanEngagement)) : config.neutralPrior;
  const plannedMinutes = session?.plannedMinutes || config.defaultPlannedMinutes;
  const elapsed = elapsedMinutes(session, sessionAttempts);

  const values = {
    bias: 1,
    band11to14: ageBand === '11-14' ? 1 : 0,
    c1Severity: c1.status === 'available' ? round(c1.severityOrdinal / 3) : 0,
    c1Missing: c1.status === 'available' ? 0 : 1,
    c1PercentSS: c1.status === 'available' ? round(Math.min(1, (c1.percentSS ?? 0) / 20)) : 0,
    c1Repetition: c1Type === 'Repetition' ? 1 : 0,
    c1BlockProlong: c1Type === 'Block' || c1Type === 'Prolongation' ? 1 : 0,
    c2Yes: c2Flag === 'yes' ? 1 : 0,
    c2Missing: c2Flag === 'missing' ? 1 : 0,
    c2FG: c2Types.includes('FG') ? 1 : 0,
    c2HM: c2Types.includes('HM') ? 1 : 0,
    cameraOn: session?.cameraOn ? 1 : 0,
    parentHelp: round(parentHelp),
    engagementTrend: round(engagementTrend),
    sessionsCompleted: round(Math.min(1, completedCount / h.sessionsForFullExperience)),
    sessionElapsed: round(Math.min(1, elapsed / plannedMinutes)),
  };
  const sources = {
    c1,
    c2,
    parentHelp: { activities: helpAttempts.length },
    engagementTrend: { sessions: pastSessions.length, prior: pastSessions.length === 0 },
    sessionsCompleted: completedCount,
    elapsedMinutes: round(elapsed, 2),
    plannedMinutes,
  };
  return { values, sources };
}

/** Full named context for one arm: the base plus the arm's type score. */
function forArm(base, scores, arm) {
  return { ...base.values, typeRecentScore: scores[arm.type]?.score ?? config.neutralPrior };
}

module.exports = { c1Context, c2Context, resolveC2Flag, elapsedMinutes, typeScores, baseContext, forArm, DONE };
