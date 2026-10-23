/**
 * Language level relative to the child's own baseline: below / stable / gaining.
 * There are no Sinhala age norms, so no "on-track" label is given.
 *
 * - Only reliable samples (≥ 50 words) count. Unreliable ones are "not_reliable".
 * - The first C4_BASELINE_SESSIONS reliable samples set the baseline (mean MLU
 *   in words and mean NDW-50) and are "baseline_building".
 * - Each later reliable sample gets the mean of its relative changes in MLU and
 *   NDW-50: above +CHANGE_THRESHOLD → gaining, below −CHANGE_THRESHOLD → below,
 *   otherwise stable. The ±10 % threshold is provisional.
 * - A parent or SLP can confirm the band or override it; the effective band is
 *   the latest override, else the computed band.
 */
const env = require('../../../config/env');
const ApiError = require('../../../lib/ApiError');
const LanguageSample = require('../models/LanguageSample');

const CHANGE_THRESHOLD = 0.10;
const round = (x, nd = 3) => Math.round(x * 10 ** nd) / 10 ** nd;
const mean = (xs) => xs.reduce((a, b) => a + b, 0) / xs.length;

const isReliable = (doc) => !(doc.analysis?.flags || []).includes('unreliable_sample')
  && doc.analysis?.measures?.mluWords != null && doc.analysis?.measures?.ndw50 != null;

const COMPARABLE = new Set(['below', 'stable', 'gaining']);

/**
 * The latest override wins, but only while the sample still has a comparable band:
 * if a recompute (e.g. a deleted earlier sample) turns it into a baseline sample,
 * the override no longer applies. Confirmations are kept either way.
 */
function effective(computed, confirmations) {
  if (!COMPARABLE.has(computed)) return computed;
  const override = [...(confirmations || [])].reverse().find((c) => c.decision === 'override');
  return override ? override.band : computed;
}

async function recomputeForChild(childId, includeId) {
  const status = includeId ? { $or: [{ status: 'completed' }, { _id: includeId }] } : { status: 'completed' };
  const samples = await LanguageSample.find({ childId, ...status })
    .sort({ createdAt: 1, _id: 1 }).select('analysis.measures analysis.flags band');
  const reliable = samples.filter(isReliable);
  const baseDocs = reliable.slice(0, env.c4BaselineSessions);
  const baseline = baseDocs.length === env.c4BaselineSessions ? {
    mluWords: round(mean(baseDocs.map((d) => d.analysis.measures.mluWords)), 2),
    ndw50: round(mean(baseDocs.map((d) => d.analysis.measures.ndw50)), 2),
    samples: baseDocs.length,
  } : null;
  const baseIds = new Set(baseDocs.map((d) => String(d._id)));

  const ops = samples.map((doc) => {
    let computed;
    let change = null;
    if (!isReliable(doc)) computed = 'not_reliable';
    else if (!baseline || baseIds.has(String(doc._id))) computed = 'baseline_building';
    else {
      const m = doc.analysis.measures;
      const mlu = (m.mluWords - baseline.mluWords) / baseline.mluWords;
      const ndw = (m.ndw50 - baseline.ndw50) / baseline.ndw50;
      const composite = (mlu + ndw) / 2;
      change = { mluWords: round(mlu), ndw50: round(ndw), composite: round(composite), threshold: CHANGE_THRESHOLD };
      if (composite > CHANGE_THRESHOLD) computed = 'gaining';
      else if (composite < -CHANGE_THRESHOLD) computed = 'below';
      else computed = 'stable';
    }
    const confirmations = doc.band?.confirmations || [];
    return {
      updateOne: {
        filter: { _id: doc._id },
        update: {
          $set: {
            'band.computed': computed,
            'band.effective': effective(computed, confirmations),
            'band.change': change,
            'band.baseline': baseline,
          },
        },
      },
    };
  });
  if (ops.length) await LanguageSample.bulkWrite(ops);
  return baseline;
}

async function confirm(sample, body) {
  if (!COMPARABLE.has(sample.band?.computed)) {
    throw ApiError.unprocessable('band_not_available', `This sample has no band to confirm yet (${sample.band?.computed || 'none'}).`);
  }
  const entry = { ...body, computedBand: sample.band.computed };
  if (body.decision === 'confirm') entry.band = sample.band.computed;
  sample.band.confirmations.push(entry);
  sample.band.effective = effective(sample.band.computed, sample.band.confirmations);
  await sample.save();
  return sample;
}

module.exports = { recomputeForChild, confirm, CHANGE_THRESHOLD };
