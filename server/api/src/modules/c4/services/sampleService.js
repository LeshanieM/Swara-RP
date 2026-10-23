/**
 * Language samples: the background job and transcript corrections.
 *
 * Job, per recording:
 *   1. ASR (language service /transcribe): the raw transcript, which keeps repetitions,
 *      plus word timings. Skipped if a transcript was typed at upload.
 *   2. C1 (speech service /analyze-speech) with that transcript: events, stutter
 *      moments and spontaneous %SS. If C1 is down, stored as "not_assessed".
 *   3. Measures (language service /measures) with the C1 events: mazes,
 *      utterances, MLU / NDW / MATTR and the per-utterance H4d rows.
 *   4. New words and bands are recomputed for the whole child; the audio is deleted.
 */
const fs = require('fs/promises');
const env = require('../../../config/env');
const ApiError = require('../../../lib/ApiError');
const JobQueue = require('../../../lib/jobQueue');
const LanguageSample = require('../models/LanguageSample');
const LanguageSession = require('../models/LanguageSession');
const languageClient = require('./languageClient');
const c1Link = require('./c1Link');
const vocabularyService = require('./vocabularyService');
const bandService = require('./bandService');
const { transcription: transcriptionSchema, analysis: analysisSchema } = require('../validation/schemas');

const TRANSIENT = new Set(['language_service_unavailable', 'language_service_timeout', 'busy']);
const MAX_TRIES = 3;
const RETRY_BASE_MS = 2000;
const sleep = (ms) => new Promise((resolve) => { setTimeout(resolve, ms); });

async function withRetry(fn, id, what) {
  for (let attempt = 1; ; attempt += 1) {
    try {
      return await fn();
    } catch (err) {
      if (!TRANSIENT.has(err.code) || attempt >= MAX_TRIES) throw err;
      const wait = RETRY_BASE_MS * attempt;
      console.warn(`[c4-job] ${id} ${what}: ${err.code}; retry ${attempt}/${MAX_TRIES - 1} in ${wait} ms`);
      await sleep(wait);
    }
  }
}

function checked(schema, data, what) {
  const parsed = schema.safeParse(data);
  if (!parsed.success) {
    const where = parsed.error.issues.slice(0, 3).map((i) => i.path.join('.')).join(', ');
    throw Object.assign(new Error(`Language service ${what} response broke the contract at: ${where}`), { code: 'invalid_language_response' });
  }
  return parsed.data;
}

const c1Inputs = (stuttering) => (stuttering?.status === 'assessed'
  ? {
    c1Events: stuttering.events.map(({ type, start, end }) => ({ type, start, end })),
    c1Moments: stuttering.stutterMoments.map(({ start, end }) => ({ start, end })),
  }
  : {});

const versionMeasures = (version, kind, analysis, stuttering) => ({
  version,
  kind,
  measures: analysis.measures,
  syllables: analysis.syllables,
  mazes: analysis.mazes,
  flags: analysis.flags,
  percentSS: stuttering?.status === 'assessed' ? stuttering.percentSSCurrent : null,
});

/** Recompute new words and bands for the child; `includeId` is a sample about to be marked completed. */
async function recomputeChild(childId, includeId) {
  await vocabularyService.recomputeForChild(childId, includeId);
  await bandService.recomputeForChild(childId, includeId);
}

async function deleteAudio(id) {
  const stored = await LanguageSample.findById(id).select('+audio.storedPath');
  if (!stored?.audio?.storedPath || stored.audio.deleted) return;
  await fs.rm(stored.audio.storedPath, { force: true });
  await LanguageSample.updateOne({ _id: id }, {
    $set: { 'audio.deleted': true, 'audio.deletedAt': new Date() }, $unset: { 'audio.storedPath': 1 },
  });
}

async function processSample(id) {
  // Claim the job atomically so it can never run twice.
  const doc = await LanguageSample.findOneAndUpdate(
    { _id: id, status: 'queued' },
    { $set: { status: 'processing', startedAt: new Date() }, $inc: { attempts: 1 } },
    { new: true },
  ).select('+audio.storedPath +uploadTranscript');
  if (!doc) return;

  try {
    const file = { filePath: doc.audio.storedPath, originalName: doc.audio.originalName };
    const typed = doc.uploadTranscript;

    let asr = null;
    if (!typed) {
      asr = checked(transcriptionSchema, await withRetry(() => languageClient.transcribe(file), id, 'transcribe'), 'transcribe');
    }
    const firstText = typed || asr.text;
    const kind = typed ? 'manual' : 'asr';

    const stuttering = await c1Link.analyse({ ...file, transcript: firstText, language: doc.language });

    const analysis = checked(analysisSchema, await withRetry(() => languageClient.measures({
      ...(asr ? { words: asr.words } : {}),
      ...(typed ? { text: typed } : {}),
      source: kind,
      durationSec: asr?.audio?.durationSec ?? stuttering.audioDurationSec ?? null,
      ...c1Inputs(stuttering),
    }), id, 'measures'), 'measures');

    const finalStuttering = c1Link.recompute(stuttering, analysis.syllables.total);
    await LanguageSample.updateOne({ _id: doc._id }, {
      $set: {
        asr,
        transcripts: [{ version: 1, kind, text: firstText, editedBy: typed ? 'parent' : 'system' }],
        currentVersion: 1,
        analysis,
        measuresByVersion: [versionMeasures(1, kind, analysis, finalStuttering)],
        stuttering: finalStuttering,
      },
      $unset: { error: 1 },
    });
    // New words and bands first, so a client never sees a completed sample without them.
    await recomputeChild(doc.childId, doc._id);
    await LanguageSample.updateOne({ _id: doc._id }, { $set: { status: 'completed', completedAt: new Date() } });
  } catch (err) {
    console.error(`[c4-job] ${id} failed: ${err.code || 'error'} ${err.message}`);
    await LanguageSample.updateOne({ _id: doc._id }, {
      $set: { status: 'failed', error: { code: err.code || 'analysis_failed', message: err.message }, completedAt: new Date() },
    });
  } finally {
    if (!env.c4KeepUploads) await deleteAudio(doc._id).catch((e) => console.error(`[c4-job] ${id} audio cleanup failed:`, e));
  }
}

const queue = new JobQueue(processSample, env.c4JobConcurrency);

async function create(session, input, file) {
  if (!file) throw ApiError.unprocessable('audio_required', 'Attach the recording as multipart field "audio".');
  // One sample per session, so progress and H4c count each session once. A failed one may be retried.
  const existing = await LanguageSample.findOne({ sessionId: session._id, status: { $ne: 'failed' } }).select('_id status');
  if (existing) {
    throw ApiError.unprocessable('session_already_recorded', `This session already has sample ${existing.id} (${existing.status}); start a new session.`);
  }
  const doc = await LanguageSample.create({
    childId: session.childId,
    sessionId: session._id,
    age: session.age,
    ageBand: session.ageBand,
    language: session.language,
    mode: session.mode,
    topicId: session.topic.id,
    categoryId: session.topic.categoryId,
    topicLevel: session.topic.level,
    uploadTranscript: input.transcript,
    audio: { originalName: file.originalname, mimeType: file.mimetype, sizeBytes: file.size, storedPath: file.path },
  });
  await LanguageSession.updateOne({ _id: session._id }, { $set: { status: 'recorded' }, $push: { sampleIds: doc._id } });
  queue.push(doc.id);
  return doc;
}

async function get(id) {
  const doc = await LanguageSample.findById(id);
  if (!doc) throw ApiError.notFound('sample_not_found', `No language sample with id ${id}.`);
  return doc;
}

/** Human correction or a fully manual transcript: a new version, re-measured with the original timings. */
async function editTranscript(id, { text, kind, editedBy }) {
  const doc = await get(id);
  if (doc.status !== 'completed') {
    throw ApiError.unprocessable('sample_not_completed', `Only completed samples can be corrected (status: ${doc.status}).`);
  }
  const analysis = checked(analysisSchema, await languageClient.measures({
    text,
    source: kind,
    ...(doc.asr?.words?.length ? { words: doc.asr.words } : {}),
    durationSec: doc.asr?.audio?.durationSec ?? doc.stuttering?.audioDurationSec ?? null,
    ...c1Inputs(doc.stuttering),
  }).catch((err) => { throw languageClient.toApiError(err); }), 'measures');
  const version = (doc.currentVersion || 0) + 1;
  const stuttering = c1Link.recompute(doc.stuttering, analysis.syllables.total);

  doc.transcripts.push({ version, kind, text, editedBy });
  doc.measuresByVersion.push(versionMeasures(version, kind, analysis, stuttering));
  doc.currentVersion = version;
  doc.analysis = analysis;
  doc.stuttering = stuttering;
  doc.markModified('analysis');
  doc.markModified('stuttering');
  await doc.save();
  await recomputeChild(doc.childId);
  return get(id);
}

async function listForChild(childId, { status, limit, offset }) {
  const filter = { childId, ...(status && { status }) };
  const [items, total] = await Promise.all([
    LanguageSample.find(filter).sort({ createdAt: -1, _id: -1 }).skip(offset).limit(limit)
      .select('-asr.words -analysis.tokens -analysis.lexicon -analysis.utterances -stuttering.events -stuttering.stutterMoments -measuresByVersion'),
    LanguageSample.countDocuments(filter),
  ]);
  return { items, total, limit, offset };
}

async function remove(id) {
  const doc = await LanguageSample.findById(id).select('+audio.storedPath');
  if (!doc) throw ApiError.notFound('sample_not_found', `No language sample with id ${id}.`);
  if (doc.status === 'processing') {
    throw ApiError.unprocessable('sample_in_progress', 'This sample is being analysed; delete it once it has finished.');
  }
  if (doc.audio?.storedPath) await fs.rm(doc.audio.storedPath, { force: true });
  await doc.deleteOne();
  await LanguageSession.updateOne({ _id: doc.sessionId }, { $pull: { sampleIds: doc._id } });
  await recomputeChild(doc.childId);
  return { deleted: true, id };
}

/**
 * Re-queue work interrupted by a restart; fail jobs whose audio is gone. Also delete audio that a finished
 * job still holds because the server stopped between saving the result and deleting the file.
 */
async function recover() {
  const cleaned = env.c4KeepUploads ? 0 : await cleanFinished();
  const pending = await LanguageSample.find({ status: { $in: ['queued', 'processing'] } }).select('+audio.storedPath');
  let requeued = 0;
  let failed = 0;
  for (const doc of pending) {
    const exists = doc.audio?.storedPath && await fs.access(doc.audio.storedPath).then(() => true, () => false);
    if (exists) {
      await LanguageSample.updateOne({ _id: doc._id }, { $set: { status: 'queued' } });
      queue.push(doc.id);
      requeued += 1;
    } else {
      await LanguageSample.updateOne({ _id: doc._id }, {
        $set: { status: 'failed', error: { code: 'audio_missing_after_restart', message: 'The server restarted and the audio file was gone.' } },
      });
      failed += 1;
    }
  }
  return { requeued, failed, cleaned };
}

async function cleanFinished() {
  const stale = await LanguageSample.find({
    status: { $in: ['completed', 'failed'] }, 'audio.deleted': { $ne: true }, 'audio.storedPath': { $exists: true },
  }).select('_id');
  for (const doc of stale) await deleteAudio(doc._id);
  return stale.length;
}

module.exports = {
  create, get, editTranscript, listForChild, remove, recover, recomputeChild, queueStats: () => queue.stats(),
};
