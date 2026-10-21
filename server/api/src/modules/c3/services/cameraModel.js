// The camera part of the engagement model: P(engaged) for one 10-second window of face numbers from the phone.
// The file is written by vision-service/training/train_engagement.py (logistic regression or gradient-boosted
// trees, trained on DAiSEE); until then a provisional hand-set logistic file is used. The window features are
// defined in vision-service/app/engagement/features.py and computed the same way on the phone.
const path = require('path');
const fs = require('fs');
const { round } = require('./scoring');

const FILE = path.join(__dirname, '../data/engagementCameraModel.json');
const WINDOW_FEATURES = ['facePresentRatio', 'yawStdDeg', 'pitchStdDeg', 'yawAbsMeanDeg', 'pitchAbsMeanDeg',
  'lookAwayRatio', 'eyeOpenMean', 'eyesClosedRatio', 'smileMean'];
const WINDOW_SEC = 10;
const LOGIT_CLIP = 4;

const sigmoid = (t) => 1 / (1 + Math.exp(-t));

/** Raw score (log-odds of engaged) for one feature vector; null entries take the training means. */
function rawScore(model, x) {
  const v = x.map((value, i) => (value === null || value === undefined ? model.impute[i] : value));
  if (model.type === 'logistic') {
    const { mean, scale, intercept, weights } = model.logistic;
    return v.reduce((s, value, i) => s + weights[i] * ((value - mean[i]) / scale[i]), intercept);
  }
  const { init, learningRate, trees } = model.gbdt;
  let s = 0;
  for (const t of trees) {
    let node = 0;
    while (t.left[node] !== -1) node = v[t.feature[node]] <= t.threshold[node] ? t.left[node] : t.right[node];
    s += t.value[node];
  }
  return init + learningRate * s;
}

/** Loads the model file and checks it: the feature list must match, and the evaluator must reproduce the
 *  trainer's own predictions, so a mis-exported file fails at start-up instead of scoring children wrongly. */
function load(file = FILE) {
  const model = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (!['logistic', 'gbdt'].includes(model.type)) throw new Error(`${file}: unknown camera model type ${model.type}`);
  if (JSON.stringify(model.features) !== JSON.stringify(WINDOW_FEATURES)) {
    throw new Error(`${file}: feature list differs from the camera window features; retrain or update both sides`);
  }
  for (const c of model.selfCheck || []) {
    // Compared as log-odds: probabilities near 0 or 1 would hide a wrong tree.
    const r = rawScore(model, c.x);
    if (Math.abs(r - c.raw) > 1e-4) throw new Error(`${file}: self-check failed (${r.toFixed(6)} vs ${c.raw}); the export and evaluator disagree`);
  }
  return model;
}

const model = load();

const windowVector = (w) => WINDOW_FEATURES.map((f) => (Number.isFinite(w[f]) ? w[f] : null));

/** Windows from the request: the 10-second windows when sent, else one window from the older aggregate fields. */
function windowsOf(camera) {
  if (camera.windows?.length) return camera.windows;
  return [{ ...camera, durationSec: WINDOW_SEC }];
}

/**
 * Camera engagement for one activity: the duration-weighted mean P(engaged) over the windows in which a face was
 * visible often enough. Windows without a face are missing data, not disengagement; with none usable it is null.
 */
function scoreWindows(camera, faceAbsentBelow) {
  const windows = windowsOf(camera);
  const usable = windows.filter((w) => w.facePresentRatio >= faceAbsentBelow);
  if (!usable.length) return { score: null, logit: null, windowsUsed: 0, windowsTotal: windows.length, modelVersion: model.version };
  let sum = 0;
  let weight = 0;
  for (const w of usable) {
    const d = w.durationSec > 0 ? w.durationSec : WINDOW_SEC;
    sum += d * sigmoid(rawScore(model, windowVector(w)));
    weight += d;
  }
  const p = Math.min(1 - 1e-6, Math.max(1e-6, sum / weight));
  const logit = Math.max(-LOGIT_CLIP, Math.min(LOGIT_CLIP, Math.log(p / (1 - p))));
  return { score: round(p), logit: round(logit), windowsUsed: usable.length, windowsTotal: windows.length, modelVersion: model.version };
}

const info = () => ({
  version: model.version, provisional: Boolean(model.provisional), type: model.type, features: model.features,
  threshold: model.threshold, training: model.training || null,
});

module.exports = { WINDOW_FEATURES, WINDOW_SEC, load, rawScore, scoreWindows, info, sigmoid };
