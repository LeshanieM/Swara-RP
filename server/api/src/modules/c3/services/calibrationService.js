// Fits the logs-only engagement weights by logistic regression, with the parent questionnaire as the real-child label.
// One row per completed session: the mean of its activities' log features; label = questionnaire mean ≥ threshold.
const crypto = require('crypto');
const ApiError = require('../../../lib/ApiError');
const TherapySession = require('../models/TherapySession');
const ActivityAttempt = require('../models/ActivityAttempt');
const EngagementModel = require('../models/EngagementModel');
const engagementService = require('./engagementService');
const cameraModel = require('./cameraModel');
const { questionnaire } = require('./catalogService');
const { round, mean } = require('./scoring');

const LOGS_FEATURES = engagementService.provisional.modes.logs.features;

async function dataset() {
  const sessions = await TherapySession.find({ status: 'completed', 'questionnaire.submittedAt': { $ne: null } }).select('childId questionnaire');
  const rows = [];
  for (const s of sessions) {
    const attempts = await ActivityAttempt.find({ sessionId: s._id, 'engagement.source': 'server', 'engagement.features': { $ne: null } }).select('engagement.features');
    if (attempts.length) {
      const x = LOGS_FEATURES.map((f) => mean(attempts.map((a) => a.engagement.features[f] ?? 0)));
      rows.push({ sessionId: s.id, childId: s.childId, x, y: s.questionnaire.engaged ? 1 : 0 });
    }
  }
  return rows;
}

const sigmoid = engagementService.sigmoid;

/** Class-weighted logistic regression by batch gradient descent, L2 on the weights (not the intercept). */
function fit(rows, { epochs = 4000, lr = 0.1, l2 = 0.01 } = {}) {
  const d = LOGS_FEATURES.length;
  const n = rows.length;
  const pos = rows.filter((r) => r.y === 1).length;
  const classWeight = { 1: n / (2 * Math.max(pos, 1)), 0: n / (2 * Math.max(n - pos, 1)) };
  let w = new Array(d).fill(0);
  let b = 0;
  for (let e = 0; e < epochs; e += 1) {
    const gw = new Array(d).fill(0);
    let gb = 0;
    for (const r of rows) {
      const err = (sigmoid(b + r.x.reduce((s, v, i) => s + v * w[i], 0)) - r.y) * classWeight[r.y];
      for (let i = 0; i < d; i += 1) gw[i] += err * r.x[i];
      gb += err;
    }
    w = w.map((wi, i) => wi - lr * (gw[i] / n + l2 * wi));
    b -= lr * (gb / n);
  }
  return { intercept: b, weights: w };
}

function metrics(y, yhat) {
  const cm = { tp: 0, tn: 0, fp: 0, fn: 0 };
  y.forEach((t, i) => {
    if (t === 1 && yhat[i] === 1) cm.tp += 1; else if (t === 0 && yhat[i] === 0) cm.tn += 1;
    else if (t === 0) cm.fp += 1; else cm.fn += 1;
  });
  const recall1 = cm.tp + cm.fn ? cm.tp / (cm.tp + cm.fn) : 0;
  const recall0 = cm.tn + cm.fp ? cm.tn / (cm.tn + cm.fp) : 0;
  const f1 = (tp, fp, fn) => (2 * tp + fp + fn ? (2 * tp) / (2 * tp + fp + fn) : 0);
  return {
    n: y.length,
    balancedAccuracy: round((recall0 + recall1) / 2, 3),
    macroF1: round((f1(cm.tp, cm.fp, cm.fn) + f1(cm.tn, cm.fn, cm.fp)) / 2, 3),
    confusion: cm,
  };
}

const predictRow = (model, x) => (sigmoid(model.intercept + x.reduce((s, v, i) => s + v * model.weights[i], 0)) >= 0.5 ? 1 : 0);

/** Leave-one-child-out: every child's sessions are predicted by a model that never saw that child. */
function leaveOneChildOut(rows, opts) {
  const children = [...new Set(rows.map((r) => r.childId))];
  if (children.length < 3) return { skipped: true, reason: 'needs sessions from at least 3 children', children: children.length };
  const y = [];
  const yhat = [];
  for (const c of children) {
    const train = rows.filter((r) => r.childId !== c);
    const test = rows.filter((r) => r.childId === c);
    const classes = new Set(train.map((r) => r.y));
    const model = classes.size === 2 ? fit(train, opts) : null;
    const majority = train.filter((r) => r.y === 1).length * 2 >= train.length ? 1 : 0;
    for (const r of test) {
      y.push(r.y);
      yhat.push(model ? predictRow(model, r.x) : majority);
    }
  }
  return { skipped: false, children: children.length, ...metrics(y, yhat) };
}

async function calibrate({ minSessions, activate, epochs, lr, l2 }) {
  const rows = await dataset();
  const positives = rows.filter((r) => r.y === 1).length;
  if (rows.length < minSessions || positives === 0 || positives === rows.length) {
    throw ApiError.unprocessable('insufficient_calibration_data',
      `Calibration needs at least ${minSessions} completed sessions with a questionnaire, with both engaged and not-engaged labels.`,
      { sessions: rows.length, engaged: positives, notEngaged: rows.length - positives, minSessions });
  }
  const opts = { epochs, lr, l2 };
  const fitted = fit(rows, opts);
  const current = await engagementService.activeModel();
  const before = rows.map((r) => predictRow(current.modes.logs, r.x));
  const after = rows.map((r) => predictRow(fitted, r.x));
  const ys = rows.map((r) => r.y);

  // Millisecond timestamp plus a random suffix: two calibrations in the same second must not collide.
  const stamp = new Date().toISOString().replace(/[-:.TZ]/g, '').slice(0, 17);
  const version = `c3-engagement-calibrated-${stamp}-${crypto.randomBytes(2).toString('hex')}`;
  const doc = await EngagementModel.create({
    version,
    basedOn: current.version,
    active: false,
    modes: {
      logs: { features: LOGS_FEATURES, intercept: round(fitted.intercept, 6), weights: fitted.weights.map((w) => round(w, 6)) },
      camera_logs: current.modes.camera_logs, // camera part unchanged until it is trained on DAiSEE features
    },
    training: {
      sessions: rows.length,
      children: new Set(rows.map((r) => r.childId)).size,
      label: `questionnaire mean ≥ ${questionnaire.engagedThreshold}`,
      classBalance: { engaged: positives, notEngaged: rows.length - positives },
      hyperparameters: opts,
      inSample: metrics(ys, after),
      leaveOneChildOut: leaveOneChildOut(rows, opts),
      previousModelInSample: { version: current.version, ...metrics(ys, before) },
    },
  });
  if (activate) await activateVersion(version);
  return EngagementModel.findById(doc._id);
}

async function activateVersion(version) {
  if (version === 'provisional') {
    await EngagementModel.updateMany({}, { $set: { active: false } });
  } else {
    const doc = await EngagementModel.findOne({ version });
    if (!doc) throw ApiError.notFound('engagement_model_not_found', `No engagement model ${version}.`);
    await EngagementModel.updateMany({ _id: { $ne: doc._id } }, { $set: { active: false } });
    await EngagementModel.updateOne({ _id: doc._id }, { $set: { active: true, activatedAt: new Date() } });
  }
  engagementService.resetCache();
  return currentModel();
}

async function currentModel() {
  const m = await engagementService.activeModel();
  const versions = await EngagementModel.find().sort({ createdAt: -1 }).select('version active createdAt training.sessions');
  return { active: { version: m.version, source: m.source, provisional: m.provisional, modes: m.modes }, camera: cameraModel.info(), versions };
}

module.exports = { calibrate, activateVersion, currentModel, metrics };
