/**
 * New words, judged against the child's whole history rather than one session.
 *
 * Samples are replayed oldest first:
 * - the first C4_BASELINE_SESSIONS completed samples only build the starting
 *   vocabulary (status "baseline_building");
 * - after that, a stem not yet known and not in the parent's known-word list is
 *   a candidate new word. It counts at once if the transcript was corrected or
 *   typed by a person, or once it has been heard twice (in this sample or in
 *   earlier ones). Otherwise it waits in "pending", so a single mis-heard ASR
 *   word never counts as a new word.
 * - A stem that is a near spelling of a known stem (similarity ≥ NEAR_MATCH,
 *   4+ letters, same first letter) is the known word spelled differently, not a
 *   new word ("respelled").
 * Stems come from the language service's suffix stripping (stated limitation).
 *
 * Everything is recomputed for the child after any sample is added, edited or
 * deleted, so an edit to an early transcript corrects all later counts.
 */
const env = require('../../../config/env');
const LanguageSample = require('../models/LanguageSample');
const ChildLanguageProfile = require('../models/ChildLanguageProfile');

const TRUSTED = new Set(['corrected', 'manual']);
// A stem this close to a known one is the same word spelled differently (ASR noise), not a new word.
const NEAR_MATCH = 0.8;
const NEAR_MATCH_MIN_LENGTH = 4;
const round = (x, nd = 2) => Math.round(x * 10 ** nd) / 10 ** nd;

/** 1 − normalised Levenshtein distance, on code points. */
function similarity(a, b) {
  const x = [...a];
  const y = [...b];
  if (!x.length || !y.length) return 0;
  let prev = Array.from({ length: y.length + 1 }, (_, j) => j);
  for (let i = 1; i <= x.length; i += 1) {
    const cur = [i];
    for (let j = 1; j <= y.length; j += 1) {
      cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (x[i - 1] === y[j - 1] ? 0 : 1));
    }
    prev = cur;
  }
  return 1 - prev[y.length] / Math.max(x.length, y.length);
}

function nearKnown(stem, known) {
  if ([...stem].length < NEAR_MATCH_MIN_LENGTH) return null;
  for (const k of known.keys()) {
    // Same first letter too: ගැනීම (taking) and මැනීම (measuring) differ only there.
    if (k[0] === stem[0] && Math.abs([...k].length - [...stem].length) <= 2 && similarity(stem, k) >= NEAR_MATCH) return k;
  }
  return null;
}

async function completedSamples(childId, includeId) {
  const status = includeId ? { $or: [{ status: 'completed' }, { _id: includeId }] } : { status: 'completed' };
  return LanguageSample.find({ childId, ...status })
    .sort({ createdAt: 1, _id: 1 })
    .select('createdAt sessionId currentVersion transcripts analysis.lexicon analysis.measures analysis.flags analysis.source band vocabulary');
}

/** Replays the child's samples; returns per-sample results and the final state. */
function replay(samples, knownStems) {
  const known = new Map(); // stem -> how it got in: baseline | new | parent
  for (const s of knownStems) known.set(s, 'parent');
  const pending = new Map(); // stem -> times heard while untrusted
  const perSample = [];

  samples.forEach((doc, i) => {
    const lexicon = doc.analysis?.lexicon || [];
    const totalWords = doc.analysis?.measures?.totalWords || 0;
    const source = doc.analysis?.source;
    if (i < env.c4BaselineSessions) {
      for (const { stem } of lexicon) {
        if (!known.has(stem)) known.set(stem, 'baseline');
        pending.delete(stem);
      }
      perSample.push({
        id: doc._id, status: 'baseline_building', sessionNumber: i + 1, newWords: null, newWordCount: null, newWordsPer100: null,
      });
      return;
    }
    const fresh = [];
    const waiting = [];
    const respelled = [];
    for (const { stem, count, forms } of lexicon) {
      if (known.has(stem)) continue;
      const near = nearKnown(stem, known);
      if (near) {
        respelled.push({ stem, knownAs: near });
        continue;
      }
      const heard = (pending.get(stem) || 0) + count;
      if (TRUSTED.has(source) || heard >= 2) {
        known.set(stem, 'new');
        pending.delete(stem);
        fresh.push({ stem, forms, count });
      } else {
        pending.set(stem, heard);
        waiting.push(stem);
      }
    }
    perSample.push({
      id: doc._id,
      status: 'counted',
      sessionNumber: i + 1,
      source,
      newWords: fresh,
      newWordCount: fresh.length,
      newWordsPer100: totalWords ? round((fresh.length / totalWords) * 100) : null,
      pendingStems: waiting,
      respelled,
    });
  });
  return { perSample, known, pending };
}

async function knownStemsOf(childId) {
  const profile = await ChildLanguageProfile.findOne({ childId }).select('knownWords');
  return (profile?.knownWords || []).map((w) => w.stem);
}

async function recomputeForChild(childId, includeId) {
  const samples = await completedSamples(childId, includeId);
  const { perSample } = replay(samples, await knownStemsOf(childId));
  if (perSample.length) {
    await LanguageSample.bulkWrite(perSample.map(({ id, ...vocabulary }) => ({
      updateOne: { filter: { _id: id }, update: { $set: { vocabulary } } },
    })));
  }
  return perSample.length;
}

async function vocabularyFor(childId) {
  const samples = await completedSamples(childId);
  const { perSample, known, pending } = replay(samples, await knownStemsOf(childId));
  const by = (how) => [...known].filter(([, h]) => h === how).map(([s]) => s);
  return {
    childId,
    baselineSessions: env.c4BaselineSessions,
    samples: perSample.length,
    knownStems: known.size,
    bySource: { baseline: by('baseline').length, new: by('new').length, parent: by('parent').length },
    newStems: by('new'),
    pending: [...pending].map(([stem, heard]) => ({ stem, heard })),
    perSample: perSample.map(({ id, ...rest }) => ({ sampleId: String(id), ...rest })),
  };
}

module.exports = { recomputeForChild, vocabularyFor };
