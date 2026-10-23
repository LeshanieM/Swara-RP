// Per-activity reward and per-session Therapy Success Score (TSS).
const config = require('../config');

const clip01 = (v) => Math.min(1, Math.max(0, v));
const round = (v, places = 4) => (v === null || v === undefined ? v : Number(v.toFixed(places)));
const mean = (values) => (values.length ? values.reduce((s, v) => s + v, 0) / values.length : null);

/** P = successes ÷ targets × share completed. A skip scores 0. Response time and attempts never enter P. */
function performance(result) {
  if (result.skipped) return 0;
  return clip01((result.successes / result.targets) * result.completedShare);
}

/** All reward variants, so the ablation (taps vs engagement vs fused) can be computed from the same log. */
function rewards(P, E, parentFeedback) {
  const w = config.rewardWeights;
  return {
    fused: round(clip01(w.performance * P + w.engagement * E)),
    performance: round(P),
    engagement: round(E),
    tap: parentFeedback ? config.tapRewards[parentFeedback] : config.tapRewardWithoutFeedback,
  };
}

/** Q: mean answer on the 1–5 scale, scaled to 0–1. */
function questionnaireScore(answers, scale) {
  const values = Object.values(answers);
  const m = mean(values);
  return { meanScore: round(m, 3), q: round((m - scale.min) / (scale.max - scale.min)) };
}

/** TSS = 100 (0.5 P̄ + 0.3 Ē + 0.2 Q), with the weights re-normalised over the parts that exist. */
function tss(meanP, meanE, q) {
  const w = config.tssWeights;
  const parts = [
    ['performance', meanP],
    ['engagement', meanE],
    ['questionnaire', q],
  ].filter(([, v]) => v !== null && v !== undefined);
  if (!parts.some(([k]) => k === 'performance')) return { tss: null, weights: null };
  const total = parts.reduce((s, [k]) => s + w[k], 0);
  const weights = { performance: 0, engagement: 0, questionnaire: 0 };
  for (const [k] of parts) weights[k] = round(w[k] / total);
  const score = 100 * parts.reduce((s, [k, v]) => s + (w[k] / total) * v, 0);
  return { tss: round(score, 1), weights };
}

module.exports = { clip01, round, mean, performance, rewards, questionnaireScore, tss };
