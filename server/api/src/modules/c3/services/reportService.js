// Evaluation reports: engagement over session time by age band, the camera model's check on pilot sessions,
// and the logged decisions for replay evaluation.
const ActivityAttempt = require('../models/ActivityAttempt');
const TherapySession = require('../models/TherapySession');
const cameraModel = require('./cameraModel');
const { metrics } = require('./calibrationService');
const { round, mean } = require('./scoring');

async function engagementOverTime({ ageBand, bucketMinutes }) {
  const filter = { status: { $in: ['completed', 'skipped'] }, 'engagement.score': { $ne: null }, ...(ageBand ? { ageBand } : {}) };
  const attempts = await ActivityAttempt.find(filter).select('ageBand elapsedMinAtStart engagement.score sessionId');
  const groups = {};
  for (const a of attempts) {
    const bucket = Math.floor((a.elapsedMinAtStart || 0) / bucketMinutes);
    const key = `${a.ageBand}|${bucket}`;
    groups[key] = groups[key] || { ageBand: a.ageBand, bucket, scores: [], sessions: new Set() };
    groups[key].scores.push(a.engagement.score);
    groups[key].sessions.add(String(a.sessionId));
  }
  const bands = {};
  for (const g of Object.values(groups).sort((x, y) => x.bucket - y.bucket)) {
    bands[g.ageBand] = bands[g.ageBand] || [];
    bands[g.ageBand].push({
      fromMin: g.bucket * bucketMinutes,
      toMin: (g.bucket + 1) * bucketMinutes,
      meanEngagement: round(mean(g.scores), 3),
      activities: g.scores.length,
      sessions: g.sessions.size,
    });
  }
  return { bucketMinutes, ageBands: bands, activities: attempts.length };
}

/**
 * How the DAiSEE-trained camera model does on real sessions: per session, the mean camera score of its activities
 * against the parent questionnaire's engaged label, by age band. The fused estimate E is reported beside it.
 * This is the domain-gap figure (DAiSEE is older students watching lectures, not children in therapy games).
 */
async function engagementPilotCheck({ ageBand }) {
  const sessions = await TherapySession.find({
    status: 'completed', 'questionnaire.submittedAt': { $ne: null }, ...(ageBand ? { ageBand } : {}),
  }).select('childId ageBand questionnaire.engaged');
  const rows = [];
  for (const s of sessions) {
    const attempts = await ActivityAttempt.find({ sessionId: s._id, 'engagement.features.cameraScore': { $ne: null } })
      .select('engagement.score engagement.features.cameraScore engagement.features.cameraModelVersion');
    if (attempts.length) {
      rows.push({
        childId: s.childId, ageBand: s.ageBand, y: s.questionnaire.engaged ? 1 : 0,
        camera: mean(attempts.map((a) => a.engagement.features.cameraScore)),
        fused: mean(attempts.map((a) => a.engagement.score)),
        versions: attempts.map((a) => a.engagement.features.cameraModelVersion),
      });
    }
  }
  const threshold = cameraModel.info().threshold ?? 0.5;
  const summarise = (group) => {
    const y = group.map((r) => r.y);
    const both = new Set(y).size === 2;
    return {
      sessions: group.length,
      children: new Set(group.map((r) => r.childId)).size,
      engaged: y.filter((v) => v === 1).length,
      camera: metrics(y, group.map((r) => (r.camera >= threshold ? 1 : 0))),
      fused: metrics(y, group.map((r) => (r.fused >= threshold ? 1 : 0))),
      ...(both ? {} : { note: 'only one label in this group: balanced accuracy and macro-F1 are not meaningful yet' }),
    };
  };
  const bands = {};
  for (const r of rows) (bands[r.ageBand] = bands[r.ageBand] || []).push(r);
  return {
    label: 'parent questionnaire engaged (session level)',
    threshold,
    cameraModel: cameraModel.info().version,
    modelVersionsSeen: [...new Set(rows.flatMap((r) => r.versions))],
    overall: rows.length ? summarise(rows) : { sessions: 0, note: 'no completed sessions with both camera data and a questionnaire yet' },
    ageBands: Object.fromEntries(Object.entries(bands).map(([band, group]) => [band, summarise(group)])),
  };
}

/** One row per decided activity: context, chosen arm, logging propensity and every reward variant. */
async function replayLog({ childId, limit, offset }) {
  const filter = { status: { $in: ['completed', 'skipped'] }, ...(childId ? { childId } : {}) };
  const [rows, total] = await Promise.all([
    ActivityAttempt.find(filter).sort({ createdAt: 1, _id: 1 }).skip(offset).limit(limit)
      .select('sessionId childId ageBand sequence armId itemId policy alpha epsilon explored propensity candidates context.featureNames context.x context.candidates rewards reward rewardMode banditUpdated createdAt'),
    ActivityAttempt.countDocuments(filter),
  ]);
  const items = rows.map((a) => ({
    attemptId: a.id,
    sessionId: String(a.sessionId),
    childId: a.childId,
    ageBand: a.ageBand,
    sequence: a.sequence,
    decidedAt: a.createdAt,
    armId: a.armId,
    itemId: a.itemId,
    policy: a.policy,
    epsilon: a.epsilon,
    explored: a.explored,
    propensity: a.propensity,
    candidates: a.candidates,
    featureNames: a.context?.featureNames,
    x: a.context?.x,
    candidateArms: a.context?.candidates?.length ? a.context.candidates : null,
    rewards: a.rewards,
    reward: a.reward,
    rewardMode: a.rewardMode,
    banditUpdated: a.banditUpdated,
  }));
  return { items, total, limit, offset };
}

module.exports = { engagementOverTime, engagementPilotCheck, replayLog };
