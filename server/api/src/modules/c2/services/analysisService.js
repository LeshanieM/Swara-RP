const fs = require('fs/promises');
const env = require('../../../config/env');
const VideoAnalysis = require('../models/VideoAnalysis');
const ApiError = require('../../../lib/ApiError');
const JobQueue = require('../../../lib/jobQueue');
const visionClient = require('./visionClient');
const c1Bridge = require('./c1Bridge');
const { visionResult } = require('../validation/schemas');

const MIN_AGE = 5;
const MAX_AGE = 14;
const UNFINISHED = ['queued', 'awaiting_stutter_events', 'processing'];
// A change in the share of stutters with a behaviour of at least this much counts as a real change.
const TREND_MIN_CHANGE = 0.15;
// Vision-service failures worth retrying inside one job (outage, timeout, busy).
const TRANSIENT = new Set(['vision_service_unavailable', 'vision_service_timeout', 'busy']);
const MAX_TRIES = 3;
const RETRY_BASE_MS = 2000;
const sleep = (ms) => new Promise((resolve) => { setTimeout(resolve, ms); });

const ageBand = (age) => {
  if (!Number.isInteger(age) || age < MIN_AGE || age > MAX_AGE) {
    throw ApiError.unprocessable('age_out_of_range', `Swara supports ages ${MIN_AGE}-${MAX_AGE}; got ${age}.`);
  }
  return age <= 10 ? '5-10' : '11-14';
};

async function withRetry(fn, id) {
  for (let attempt = 1; ; attempt += 1) {
    try {
      return await fn();
    } catch (err) {
      if (!TRANSIENT.has(err.code) || attempt >= MAX_TRIES) throw err;
      const wait = RETRY_BASE_MS * attempt;
      console.warn(`[c2-job] ${id} ${err.code}; retry ${attempt}/${MAX_TRIES - 1} in ${wait} ms`);
      await sleep(wait);
    }
  }
}

async function deleteVideo(id) {
  const stored = await VideoAnalysis.findById(id).select('+video.storedPath');
  if (!stored?.video?.storedPath || stored.video.deleted) return;
  await fs.rm(stored.video.storedPath, { force: true });
  await VideoAnalysis.updateOne({ _id: id }, {
    $set: { 'video.deleted': true, 'video.deletedAt': new Date() }, $unset: { 'video.storedPath': 1 },
  });
}

/** Stage 1 (audio-track source): extract the audio and start a linked C1 assessment. */
async function startC1(doc) {
  const { wav } = await withRetry(() => visionClient.extractAudio({
    filePath: doc.video.storedPath, originalName: doc.video.originalName,
  }), doc.id);
  const c1Id = await c1Bridge.createFromAudio(wav, {
    childId: doc.childId, age: doc.ageAtAssessment, c1Task: doc.stutterSource.c1Task,
  });
  await VideoAnalysis.updateOne({ _id: doc._id }, { $set: { 'stutterSource.c1AssessmentId': c1Id, status: 'awaiting_stutter_events' } });
  console.log(`[c2-job] ${doc.id} created C1 assessment ${c1Id} from the audio track`);
  return c1Id;
}

/** Stage 2: the stutter moments, from C1 (waiting for it if needed) or from the stored spans. */
async function stutterMoments(doc) {
  const src = doc.stutterSource;
  if (src.type === 'manual') return src.spans.map((s) => ({ start: s.start, end: s.end, types: s.types }));
  let c1Id = src.c1AssessmentId;
  if (!c1Id) c1Id = await startC1(doc);
  await VideoAnalysis.updateOne({ _id: doc._id }, { $set: { status: 'awaiting_stutter_events' } });
  const moments = await c1Bridge.waitForMoments(String(c1Id), env.c2C1WaitMs);
  // Keep a copy, so the analysis can be re-run or audited without C1.
  await VideoAnalysis.updateOne({ _id: doc._id }, { $set: { 'stutterSource.spans': moments } });
  return moments;
}

async function processAnalysis(id) {
  // Claim the job atomically so it can never run twice.
  const doc = await VideoAnalysis.findOneAndUpdate(
    { _id: id, status: { $in: UNFINISHED }, runningSince: null },
    { $set: { runningSince: new Date(), startedAt: new Date() }, $inc: { attempts: 1 } },
    { new: true },
  ).select('+video.storedPath');
  if (!doc) return;

  let finished = false;
  try {
    const moments = await stutterMoments(doc);
    await VideoAnalysis.updateOne({ _id: doc._id }, { $set: { status: 'processing' } });
    const raw = await withRetry(() => visionClient.analyze({
      filePath: doc.video.storedPath, originalName: doc.video.originalName, moments, targetFps: doc.targetFps,
    }), id);
    const parsed = visionResult.safeParse(raw);
    if (!parsed.success) {
      const where = parsed.error.issues.slice(0, 3).map((i) => i.path.join('.')).join(', ');
      throw Object.assign(new Error(`Vision service response broke the contract at: ${where}`), { code: 'invalid_vision_response' });
    }
    await VideoAnalysis.updateOne({ _id: doc._id }, {
      $set: { status: 'completed', result: parsed.data, completedAt: new Date() }, $unset: { error: 1 },
    });
    finished = true;
  } catch (err) {
    console.error(`[c2-job] ${id} failed: ${err.code || 'error'} ${err.message}`);
    await VideoAnalysis.updateOne({ _id: doc._id }, {
      $set: {
        status: 'failed',
        error: { code: err.code || 'analysis_failed', message: err.message, details: err.details ?? null },
        completedAt: new Date(),
      },
    });
    finished = true;
  } finally {
    await VideoAnalysis.updateOne({ _id: doc._id }, { $set: { runningSince: null } });
    if (finished && !env.c2KeepUploads) await deleteVideo(doc._id).catch((e) => console.error(`[c2-job] ${id} video cleanup failed:`, e));
  }
}

const queue = new JobQueue(processAnalysis, env.c2JobConcurrency);

async function create(input, file) {
  if (!file) throw ApiError.unprocessable('video_required', 'Attach the video as multipart field "video".');
  const band = ageBand(input.age);
  const stutterSource = { type: input.stutterSource };

  if (input.stutterSource === 'c1_audio_track') {
    // Reject a bad C1 task now, not minutes later inside the job.
    c1Bridge.checkTask(input);
    stutterSource.c1Task = Object.fromEntries(Object.entries({
      taskType: input.taskType,
      language: input.language,
      passageId: input.passageId,
      passageText: input.passageText,
      pictureId: input.pictureId,
      transcript: input.transcript,
    }).filter(([, v]) => v !== undefined));
  } else if (input.stutterSource === 'c1_assessment') {
    await c1Bridge.findLinked(input.c1AssessmentId, input.childId);
    stutterSource.c1AssessmentId = input.c1AssessmentId;
  } else {
    stutterSource.spans = input.stutterSpans;
  }

  const doc = await VideoAnalysis.create({
    childId: input.childId,
    ageAtAssessment: input.age,
    ageBand: band,
    inputPath: input.inputPath,
    videoConsent: input.videoConsent,
    stutterSource,
    targetFps: input.targetFps,
    video: {
      originalName: file.originalname, mimeType: file.mimetype, sizeBytes: file.size, storedPath: file.path,
    },
  });
  queue.push(doc.id);
  return doc;
}

/** Path C: no video. Stored so the child's record says "not assessed", never "no behaviours". */
async function recordNotAssessed(input) {
  const band = ageBand(input.age);
  if (input.c1AssessmentId) await c1Bridge.findLinked(input.c1AssessmentId, input.childId);
  return VideoAnalysis.create({
    childId: input.childId,
    ageAtAssessment: input.age,
    ageBand: band,
    inputPath: 'audio_only',
    status: 'not_assessed',
    notAssessedReason: input.reason,
    notes: input.notes,
    stutterSource: input.c1AssessmentId ? { type: 'c1_assessment', c1AssessmentId: input.c1AssessmentId } : undefined,
    completedAt: new Date(),
  });
}

async function get(id) {
  const doc = await VideoAnalysis.findById(id);
  if (!doc) throw ApiError.notFound('analysis_not_found', `No video analysis with id ${id}.`);
  return doc;
}

async function listForChild(childId, { status, limit, offset }) {
  const filter = { childId, ...(status && { status }) };
  const [items, total] = await Promise.all([
    VideoAnalysis.find(filter)
      .sort({ createdAt: -1, _id: -1 }).skip(offset).limit(limit)
      .select('-result.stutterMoments -result.behaviourEvents -result.baselines -stutterSource.spans -stutterSource.c1Task -reviews'),
    VideoAnalysis.countDocuments(filter),
  ]);
  return { items, total, limit, offset };
}

function trend(latest, previous) {
  const a = latest?.result?.concomitantScore;
  const b = previous?.result?.concomitantScore;
  if (a === null || a === undefined || b === null || b === undefined) return 'insufficient_data';
  if (a - b <= -TREND_MIN_CHANGE) return 'improving';
  if (a - b >= TREND_MIN_CHANGE) return 'needs_attention';
  return 'stable';
}

const flagOf = (doc) => {
  if (!doc || doc.status !== 'completed') return 'missing';
  const has = doc.result?.hasSecondaryBehaviors;
  if (has === true) return 'yes';
  if (has === false) return 'no';
  return 'missing'; // video present but no stutter moment could be assessed
};

const brief = (doc) => ({
  analysisId: doc.id,
  date: doc.completedAt || doc.createdAt,
  status: doc.status,
  inputPath: doc.inputPath,
  notAssessedReason: doc.notAssessedReason,
  hasSecondaryBehaviors: doc.result?.hasSecondaryBehaviors ?? null,
  concomitantScore: doc.result?.concomitantScore ?? null,
  behavioursPerStutter: doc.result?.behavioursPerStutter ?? null,
  behaviourTypes: doc.result?.summary?.behaviourTypes ?? [],
  momentsAssessed: doc.result?.counts?.momentsAssessed ?? null,
  c1AssessmentId: doc.stutterSource?.c1AssessmentId ?? null,
});

/**
 * C2's context for C3 and the progress report: the behaviour flag (yes / no / missing),
 * whether the child gave video, the latest concomitant score and its trend.
 */
async function summaryForChild(childId) {
  const docs = await VideoAnalysis.find({ childId, status: { $in: ['completed', 'not_assessed'] } })
    .sort({ completedAt: -1, _id: -1 })
    .select('childId status inputPath notAssessedReason completedAt createdAt stutterSource.c1AssessmentId result.hasSecondaryBehaviors result.concomitantScore result.behavioursPerStutter result.summary result.counts');
  const latest = docs[0];
  const completed = docs.filter((d) => d.status === 'completed');
  return {
    childId,
    c2Flag: flagOf(latest),
    hasVideo: latest?.status === 'completed',
    completedAnalyses: completed.length,
    notAssessedCount: docs.length - completed.length,
    latest: latest ? brief(latest) : null,
    latestWithVideo: completed[0] ? brief(completed[0]) : null,
    trend: trend(completed[0], completed[1]),
  };
}

async function review(id, body) {
  const doc = await get(id);
  if (doc.status !== 'completed') {
    throw ApiError.unprocessable('analysis_not_completed', `Only completed analyses can be reviewed (status: ${doc.status}).`);
  }
  const n = doc.result.stutterMoments.length;
  const bad = (body.momentLabels || []).filter((l) => l.momentIndex >= n).map((l) => l.momentIndex);
  if (bad.length) throw ApiError.unprocessable('unknown_moment', `momentIndex ${bad.join(', ')} out of range (this analysis has ${n} moments).`);
  doc.reviews.push(body);
  await doc.save();
  return doc;
}

async function remove(id) {
  const doc = await VideoAnalysis.findById(id).select('+video.storedPath +runningSince');
  if (!doc) throw ApiError.notFound('analysis_not_found', `No video analysis with id ${id}.`);
  if (doc.runningSince || doc.status === 'processing' || doc.status === 'awaiting_stutter_events') {
    throw ApiError.unprocessable('analysis_in_progress', 'This video is being analysed; delete it once it has finished.');
  }
  if (doc.video?.storedPath) await fs.rm(doc.video.storedPath, { force: true });
  await doc.deleteOne();
  return { deleted: true, id };
}

/**
 * Resume work interrupted by a restart at the stage it reached; fail jobs whose video is gone. Also delete
 * video that a finished job still holds because the server stopped between saving the result and deleting the file.
 */
async function recover() {
  const cleaned = env.c2KeepUploads ? 0 : await cleanFinished();
  const pending = await VideoAnalysis.find({ status: { $in: UNFINISHED } }).select('+video.storedPath');
  let requeued = 0;
  let failed = 0;
  for (const doc of pending) {
    const exists = doc.video?.storedPath && await fs.access(doc.video.storedPath).then(() => true, () => false);
    if (exists) {
      await VideoAnalysis.updateOne({ _id: doc._id }, { $set: { runningSince: null } });
      queue.push(doc.id);
      requeued += 1;
    } else {
      await VideoAnalysis.updateOne({ _id: doc._id }, {
        $set: {
          status: 'failed', runningSince: null, error: { code: 'video_missing_after_restart', message: 'The server restarted and the video file was gone.' },
        },
      });
      failed += 1;
    }
  }
  return { requeued, failed, cleaned };
}

async function cleanFinished() {
  const stale = await VideoAnalysis.find({
    status: { $in: ['completed', 'failed'] }, 'video.deleted': { $ne: true }, 'video.storedPath': { $exists: true },
  }).select('_id');
  for (const doc of stale) await deleteVideo(doc._id);
  return stale.length;
}

module.exports = {
  create, recordNotAssessed, get, listForChild, summaryForChild, review, remove, recover, queueStats: () => queue.stats(),
};
