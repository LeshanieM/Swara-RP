// Engagement estimator in two modes: logs only (fallback) and camera + logs (main mode when the camera is on).
// Log signals are compared with the child's own history, so a slow but steady child is not marked disengaged.
// A face that isn't visible is missing data: the estimate falls back to logs only rather than scoring it as disengaged.
// The camera part is its own model (cameraModel.js, trained on DAiSEE); its log-odds enter here as one feature.
const provisional = require('../data/engagementModel.json');
const cameraModel = require('./cameraModel');
const EngagementModel = require('../models/EngagementModel');
const ActivityAttempt = require('../models/ActivityAttempt');
const { clip01, round, mean } = require('./scoring');

let cached = null;

async function activeModel() {
  if (cached) return cached;
  const stored = await EngagementModel.findOne({ active: true }).sort({ activatedAt: -1 });
  // Versions calibrated before the camera model existed carry the old camera features; they keep their logs mode.
  const modes = stored && stored.modes.camera_logs?.features?.includes('cameraLogit')
    ? stored.modes : stored && { ...stored.modes, camera_logs: provisional.modes.camera_logs };
  cached = stored
    ? { ...provisional, version: stored.version, provisional: false, modes, source: 'calibrated' }
    : { ...provisional, source: 'provisional' };
  return cached;
}

const resetCache = () => { cached = null; };

const sd = (values, m) => Math.sqrt(values.reduce((s, v) => s + (v - m) ** 2, 0) / Math.max(1, values.length - 1));

const rawSignals = (r) => ({
  responseLatencyMs: Number.isFinite(r.responseLatencyMs) ? r.responseLatencyMs : null,
  attemptsPerTarget: Number.isFinite(r.attempts) && r.targets > 0 ? r.attempts / r.targets : null,
  tapsPerMin: Number.isFinite(r.taps) && r.durationSec > 0 ? r.taps / (r.durationSec / 60) : null,
});

/** Mean and spread of each log signal over the child's recent activities; population norms until enough history. */
async function childNorms(childId, model, excludeId) {
  const recent = await ActivityAttempt.find({ childId, status: 'completed', _id: { $ne: excludeId } })
    .sort({ completedAt: -1 }).limit(model.historyWindow).select('result');
  const norms = {};
  for (const [signal, population] of Object.entries(model.populationNorms)) {
    const values = recent.map((a) => rawSignals(a.result)[signal]).filter((v) => v !== null);
    if (values.length >= model.historyMin) {
      const m = mean(values);
      // Floor the spread so a very consistent child doesn't turn tiny differences into huge z-scores.
      norms[signal] = { mean: m, sd: Math.max(sd(values, m), 0.25 * population.sd), source: 'child', n: values.length };
    } else {
      norms[signal] = { ...population, source: 'population', n: values.length };
    }
  }
  return norms;
}

function logsFeatures(result, norms) {
  const raw = rawSignals(result);
  const z = (signal) => (raw[signal] === null ? 0 : (raw[signal] - norms[signal].mean) / norms[signal].sd);
  return {
    completion: result.skipped ? 0 : result.completedShare,
    skipped: result.skipped ? 1 : 0,
    earlyExit: result.earlyExit ? 1 : 0,
    zAttemptsPerTarget: round(Math.max(-3, Math.min(3, z('attemptsPerTarget')))),
    zResponseLatency: round(Math.max(-3, Math.min(3, z('responseLatencyMs')))),
    zTapsPerMin: round(Math.max(-3, Math.min(3, z('tapsPerMin')))),
  };
}

const sigmoid = (t) => 1 / (1 + Math.exp(-t));

function predict(modeSpec, features) {
  const t = modeSpec.features.reduce((s, name, i) => s + modeSpec.weights[i] * features[name], modeSpec.intercept);
  return clip01(sigmoid(t));
}

/**
 * Engagement E for one activity. A client-side estimate (the on-device model, once the app has one) is used as is,
 * labelled with its source; otherwise the server computes it from the logs and, if present, the camera features.
 */
async function estimate({ childId, attemptId, result, clientEstimate }) {
  const model = await activeModel();
  if (clientEstimate) {
    return {
      score: round(clientEstimate.score), mode: clientEstimate.mode || 'client', source: 'client',
      modelVersion: clientEstimate.modelVersion || 'client', faceMissing: false, features: null,
    };
  }
  const norms = await childNorms(childId, model, attemptId);
  const features = logsFeatures(result, norms);
  const camera = result.camera ? cameraModel.scoreWindows(result.camera, model.faceAbsentBelow) : null;
  const faceVisible = Boolean(camera && camera.score !== null);
  const mode = faceVisible ? 'camera_logs' : 'logs';
  if (camera) {
    Object.assign(features, {
      cameraScore: camera.score, windowsUsed: camera.windowsUsed, windowsTotal: camera.windowsTotal, cameraModelVersion: camera.modelVersion,
    });
  }
  if (faceVisible) features.cameraLogit = camera.logit;
  return {
    score: round(predict(model.modes[mode], features)),
    mode,
    source: 'server',
    modelVersion: model.version,
    faceMissing: Boolean(result.camera) && !faceVisible,
    features: { ...features, normsSource: Object.fromEntries(Object.entries(norms).map(([k, v]) => [k, v.source])) },
  };
}

module.exports = { activeModel, resetCache, estimate, predict, sigmoid, provisional };
