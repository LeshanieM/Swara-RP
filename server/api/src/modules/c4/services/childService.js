/**
 * Per-child C4 data: onboarding (ranked interests), the parent checklist,
 * parent known-word lists, and the progress / summary views built from samples.
 */
const ApiError = require('../../../lib/ApiError');
const ChildLanguageProfile = require('../models/ChildLanguageProfile');
const LanguageSample = require('../models/LanguageSample');
const catalog = require('./catalogService');
const languageClient = require('./languageClient');
const vocabularyService = require('./vocabularyService');
const sampleService = require('./sampleService');
const c1Link = require('./c1Link');

const TREND_MIN_CHANGE = 0.05; // relative change in MLU between the last two reliable samples

async function upsertProfile(childId, { age, language, rankedCategories }) {
  const ageBand = catalog.bandForAge(age);
  catalog.checkRanking(ageBand, rankedCategories);
  const existing = await ChildLanguageProfile.findOne({ childId });
  // A checklist answered for another band no longer applies once the child moves band.
  const unset = existing?.checklist?.ageBand && existing.checklist.ageBand !== ageBand ? { checklist: 1 } : undefined;
  const profile = await ChildLanguageProfile.findOneAndUpdate(
    { childId },
    { $set: { age, ageBand, language, rankedCategories }, ...(unset && { $unset: unset }) },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  );
  return { profile, created: !existing };
}

async function getProfile(childId) {
  const profile = await ChildLanguageProfile.findOne({ childId });
  if (!profile) throw ApiError.notFound('profile_not_found', `Child ${childId} has no C4 profile.`);
  return profile;
}

async function submitChecklist(childId, { respondent, answers }) {
  const profile = await getProfile(childId);
  const sheet = catalog.checklistFor(profile.ageBand);
  const expected = sheet.items.map((i) => i.id);
  const given = answers.map((a) => a.itemId);
  const unknown = given.filter((id) => !expected.includes(id));
  const missing = expected.filter((id) => !given.includes(id));
  if (unknown.length || missing.length || new Set(given).size !== given.length) {
    throw ApiError.unprocessable('checklist_mismatch', `Answer each item of the ${profile.ageBand} checklist exactly once.`, { expected, unknown, missing });
  }
  const yesCount = answers.filter((a) => a.answer).length;
  profile.checklist = {
    version: sheet.version, ageBand: profile.ageBand, respondent, answers, yesCount,
    startingLevel: catalog.levelForYes(yesCount), completedAt: new Date(),
  };
  await profile.save();
  return profile;
}

async function setKnownWords(childId, { words }) {
  const profile = await getProfile(childId);
  // The language service stems the words exactly as it stems transcripts.
  const analysis = await languageClient.measures({ text: words.join('\n'), source: 'manual' })
    .catch((err) => { throw languageClient.toApiError(err); });
  const known = analysis.tokens.filter((t) => !t.maze && !t.unintelligible).map((t) => ({ word: t.norm, stem: t.stem }));
  const unique = [...new Map(known.map((k) => [k.stem, k])).values()];
  profile.knownWords = unique;
  profile.knownWordsUpdatedAt = new Date();
  await profile.save();
  await sampleService.recomputeChild(childId);
  return { childId, knownWords: unique.length, stems: unique };
}

const point = (doc) => ({
  sampleId: doc.id,
  sessionId: String(doc.sessionId),
  date: doc.createdAt,
  topicId: doc.topicId,
  categoryId: doc.categoryId,
  topicLevel: doc.topicLevel,
  mode: doc.mode,
  transcriptVersion: doc.currentVersion,
  transcriptKind: doc.analysis?.source,
  mluWords: doc.analysis?.measures?.mluWords ?? null,
  ndw50: doc.analysis?.measures?.ndw50 ?? null,
  ndwAll: doc.analysis?.measures?.ndwAll ?? null,
  mattr25: doc.analysis?.measures?.mattr25 ?? null,
  totalWords: doc.analysis?.measures?.totalWords ?? 0,
  utterances: doc.analysis?.measures?.utteranceCount ?? 0,
  mazeRatio: doc.analysis?.measures?.mazeRatio ?? null,
  newWordsPer100: doc.vocabulary?.newWordsPer100 ?? null,
  newWordCount: doc.vocabulary?.newWordCount ?? null,
  vocabularyStatus: doc.vocabulary?.status ?? null,
  band: doc.band?.effective ?? null,
  bandComputed: doc.band?.computed ?? null,
  bandConfirmed: (doc.band?.confirmations || []).length > 0,
  spontaneousPercentSS: doc.stuttering?.status === 'assessed' ? doc.stuttering.percentSSCurrent : null,
  stutteringStatus: doc.stuttering?.status ?? null,
  flags: doc.analysis?.flags || [],
});

async function completedPoints(childId) {
  const docs = await LanguageSample.find({ childId, status: 'completed' }).sort({ createdAt: 1, _id: 1 })
    .select('sessionId createdAt topicId categoryId topicLevel mode currentVersion analysis.source analysis.measures analysis.flags vocabulary band stuttering.status stuttering.percentSSCurrent');
  return docs.map(point);
}

const delta = (a, b) => (a == null || b == null ? null : Math.round((a - b) * 1000) / 1000);

/** The series the comparison screens plot, plus latest-vs-previous deltas. */
async function progress(childId) {
  const series = await completedPoints(childId);
  const [prev, latest] = series.slice(-2).length === 2 ? series.slice(-2) : [null, series[series.length - 1] || null];
  return {
    childId,
    samples: series.length,
    series,
    comparison: latest && prev ? {
      latestSampleId: latest.sampleId,
      previousSampleId: prev.sampleId,
      mluWords: delta(latest.mluWords, prev.mluWords),
      ndw50: delta(latest.ndw50, prev.ndw50),
      mattr25: delta(latest.mattr25, prev.mattr25),
      totalWords: delta(latest.totalWords, prev.totalWords),
      spontaneousPercentSS: delta(latest.spontaneousPercentSS, prev.spontaneousPercentSS),
    } : null,
  };
}

function trend(series) {
  const reliable = series.filter((p) => !p.flags.includes('unreliable_sample') && p.mluWords != null);
  if (reliable.length < 2) return 'insufficient_data';
  const [a, b] = reliable.slice(-2);
  const change = (b.mluWords - a.mluWords) / a.mluWords;
  if (change >= TREND_MIN_CHANGE) return 'improving';
  if (change <= -TREND_MIN_CHANGE) return 'needs_attention';
  return 'stable';
}

/** Latest band and measures, spontaneous %SS next to C1's task %SS; the context C3 and the progress report read. */
async function summary(childId) {
  const [profile, series] = await Promise.all([ChildLanguageProfile.findOne({ childId }), completedPoints(childId)]);
  const latest = series[series.length - 1] || null;
  let c1 = null;
  try {
    const s = await c1Link.taskSummary(childId);
    c1 = Object.fromEntries(Object.entries(s.byTask).map(([task, v]) => [task, { percentSS: v.percentSS, severity: v.severity, date: v.date }]));
  } catch (err) {
    c1 = { error: err.message };
  }
  return {
    childId,
    onboarded: Boolean(profile),
    ageBand: profile?.ageBand ?? null,
    checklistLevel: profile?.checklist?.startingLevel ?? null,
    completedSamples: series.length,
    latest,
    band: latest?.band ?? null,
    trend: trend(series),
    stuttering: {
      spontaneousPercentSS: latest?.spontaneousPercentSS ?? null,
      structuredTasks: c1,
    },
    vocabulary: series.length ? await vocabularyService.vocabularyFor(childId).then((v) => ({
      knownStems: v.knownStems, newStems: v.bySource.new, pending: v.pending.length,
    })) : null,
  };
}

module.exports = {
  upsertProfile, getProfile, submitChecklist, setKnownWords, progress, summary,
};
