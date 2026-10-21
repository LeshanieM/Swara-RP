const fs = require('fs/promises');
const env = require('../../../config/env');
const SpeechAssessment = require('../models/SpeechAssessment');
const ApiError = require('../../../lib/ApiError');
const JobQueue = require('../../../lib/jobQueue');
const speechClient = require('./speechClient');
const taskService = require('./taskService');
const { speechResult } = require('../validation/schemas');

const SEVERITY_ORDINAL = { none_very_mild: 0, mild: 1, moderate: 2, severe: 3 };
const TREND_MIN_CHANGE_PP = 1.0; // %SS change (percentage points) that counts as a real change
// Speech-service failures worth retrying inside one job (outage, timeout, busy).
const TRANSIENT = new Set(['speech_service_unavailable', 'speech_service_timeout', 'busy']);
const MAX_TRIES = 3;
const RETRY_BASE_MS = 2000;
const sleep = (ms) => new Promise((resolve) => { setTimeout(resolve, ms); });

async function analyzeWithRetry(request, id) {
  for (let attempt = 1; ; attempt += 1) {
    try {
      return await speechClient.analyze(request);
    } catch (err) {
      if (!TRANSIENT.has(err.code) || attempt >= MAX_TRIES) throw err;
      const wait = RETRY_BASE_MS * attempt;
      console.warn(`[c1-job] ${id} ${err.code}; retry ${attempt}/${MAX_TRIES - 1} in ${wait} ms`);
      await sleep(wait);
    }
  }
}

async function deleteAudio(doc) {
  const stored = await SpeechAssessment.findById(doc._id).select('+audio.storedPath');
  if (!stored?.audio?.storedPath || stored.audio.deleted) return;
  await fs.rm(stored.audio.storedPath, { force: true });
  await SpeechAssessment.updateOne({ _id: doc._id }, {
    $set: { 'audio.deleted': true, 'audio.deletedAt': new Date() }, $unset: { 'audio.storedPath': 1 },
  });
}

async function processAssessment(id) {
  // Claim the job atomically so it can never run twice.
  const doc = await SpeechAssessment.findOneAndUpdate(
    { _id: id, status: 'queued' },
    { $set: { status: 'processing', startedAt: new Date() }, $inc: { attempts: 1 } },
    { new: true },
  ).select('+audio.storedPath');
  if (!doc) return;

  try {
    const raw = await analyzeWithRetry({
      filePath: doc.audio.storedPath,
      originalName: doc.audio.originalName,
      taskType: doc.taskType,
      language: doc.language,
      passageText: doc.passageText,
      transcript: doc.transcript,
      concomitantScore: doc.concomitantScore,
    }, id);
    const parsed = speechResult.safeParse(raw);
    if (!parsed.success) {
      const where = parsed.error.issues.slice(0, 3).map((i) => i.path.join('.')).join(', ');
      throw Object.assign(new Error(`Speech service response broke the contract at: ${where}`), { code: 'invalid_speech_response' });
    }
    await SpeechAssessment.updateOne({ _id: doc._id }, {
      $set: { status: 'completed', result: parsed.data, completedAt: new Date() }, $unset: { error: 1 },
    });
  } catch (err) {
    console.error(`[c1-job] ${id} failed: ${err.code || 'error'} ${err.message}`);
    await SpeechAssessment.updateOne({ _id: doc._id }, {
      $set: { status: 'failed', error: { code: err.code || 'analysis_failed', message: err.message }, completedAt: new Date() },
    });
  } finally {
    if (!env.keepUploads) await deleteAudio(doc).catch((e) => console.error(`[c1-job] ${id} audio cleanup failed:`, e));
  }
}

const queue = new JobQueue(processAssessment, env.jobConcurrency);

/** Validate the task against the child's age band and resolve the text the scorer needs. */
function resolveTask(input) {
  const band = taskService.bandForAge(input.age);
  const taskType = input.taskType || band.taskType;
  if (taskType !== band.taskType) {
    throw ApiError.unprocessable('task_age_mismatch', `Age ${input.age} (band ${band.id}) uses the ${band.taskType} task, not ${taskType}.`);
  }
  const resolved = { ageBand: band.id, taskType };

  if (taskType === 'reading') {
    if (input.passageId && input.passageText) {
      throw ApiError.unprocessable('ambiguous_passage', 'Send passageId or passageText, not both.');
    }
    if (input.passageId) {
      const passage = taskService.findPassage(input.passageId);
      if (!passage) throw ApiError.unprocessable('unknown_passage', `No passage with id "${input.passageId}".`);
      if (passage.ageBand !== band.id) {
        throw ApiError.unprocessable('passage_age_mismatch', `Passage "${passage.id}" is for band ${passage.ageBand}, not ${band.id}.`);
      }
      return { ...resolved, passageId: passage.id, passageText: passage.text, language: passage.language };
    }
    if (!input.passageText) {
      throw ApiError.unprocessable('passage_required', 'The reading task needs passageId or passageText (the exact syllable count comes from it).');
    }
    return { ...resolved, passageText: input.passageText };
  }

  if (input.passageId || input.passageText) {
    throw ApiError.unprocessable('passage_not_applicable', 'Picture description takes no passage; send a transcript instead if you have one.');
  }
  if (input.pictureId && !taskService.findPicture(input.pictureId)) {
    throw ApiError.unprocessable('unknown_picture', `No picture with id "${input.pictureId}".`);
  }
  return { ...resolved, pictureId: input.pictureId };
}

async function create(input, file) {
  if (!file) throw ApiError.unprocessable('audio_required', 'Attach the recording as multipart field "audio".');
  const task = resolveTask(input);
  const doc = await SpeechAssessment.create({
    childId: input.childId,
    ageAtAssessment: input.age,
    language: input.language,
    transcript: input.transcript,
    concomitantScore: input.concomitantScore,
    ...task,
    audio: {
      originalName: file.originalname, mimeType: file.mimetype, sizeBytes: file.size, storedPath: file.path,
    },
  });
  queue.push(doc.id);
  return doc;
}

async function get(id) {
  const doc = await SpeechAssessment.findById(id);
  if (!doc) throw ApiError.notFound('assessment_not_found', `No assessment with id ${id}.`);
  return doc;
}

async function listForChild(childId, { taskType, status, limit, offset }) {
  const filter = { childId, ...(taskType && { taskType }), ...(status && { status }) };
  const [items, total] = await Promise.all([
    SpeechAssessment.find(filter)
      .sort({ createdAt: -1, _id: -1 }).skip(offset).limit(limit)
      .select('-result.events -result.stutterMoments -result.windows -result.audio -passageText -transcript'),
    SpeechAssessment.countDocuments(filter),
  ]);
  return { items, total, limit, offset };
}

function trend(latest, previous) {
  if (!previous) return 'insufficient_data';
  const change = latest.result.percentSS - previous.result.percentSS;
  if (change <= -TREND_MIN_CHANGE_PP) return 'improving';
  if (change >= TREND_MIN_CHANGE_PP) return 'needs_attention';
  return 'stable';
}

const brief = (doc) => ({
  assessmentId: doc.id,
  date: doc.createdAt,
  taskType: doc.taskType,
  severity: doc.result.severity.label,
  severityOrdinal: SEVERITY_ORDINAL[doc.result.severity.label],
  severityScore: doc.result.severity.score,
  percentSS: doc.result.percentSS,
  stutterDetected: doc.result.summary.stutterDetected,
  primaryType: doc.result.primaryType,
});

/** Latest severity per task plus the overall latest; the context C3 reads. */
async function summaryForChild(childId) {
  const completed = await SpeechAssessment.find({ childId, status: 'completed' })
    .sort({ createdAt: -1, _id: -1 }).select('childId taskType createdAt result.severity result.percentSS result.summary result.primaryType');
  const byTask = {};
  for (const taskType of SpeechAssessment.TASK_TYPES) {
    const [latest, previous] = completed.filter((d) => d.taskType === taskType);
    if (latest) {
      byTask[taskType] = {
        ...brief(latest),
        previousPercentSS: previous ? previous.result.percentSS : null,
        trend: trend(latest, previous),
      };
    }
  }
  return {
    childId,
    completedAssessments: completed.length,
    latest: completed[0] ? brief(completed[0]) : null,
    byTask,
  };
}

async function review(id, body) {
  const doc = await get(id);
  if (doc.status !== 'completed') {
    throw ApiError.unprocessable('assessment_not_completed', `Only completed assessments can be reviewed (status: ${doc.status}).`);
  }
  doc.reviews.push(body);
  await doc.save();
  return doc;
}

async function remove(id) {
  const doc = await SpeechAssessment.findById(id).select('+audio.storedPath');
  if (!doc) throw ApiError.notFound('assessment_not_found', `No assessment with id ${id}.`);
  if (doc.status === 'processing') {
    throw ApiError.unprocessable('assessment_in_progress', 'This assessment is being analysed; delete it once it has finished.');
  }
  if (doc.audio?.storedPath) await fs.rm(doc.audio.storedPath, { force: true });
  await doc.deleteOne();
  return { deleted: true, id };
}

/**
 * Re-queue work interrupted by a restart; fail jobs whose audio is gone. Also delete audio that a finished
 * job still holds because the server stopped between saving the result and deleting the file.
 */
async function recover() {
  const cleaned = env.keepUploads ? 0 : await cleanFinished();
  const pending = await SpeechAssessment.find({ status: { $in: ['queued', 'processing'] } }).select('+audio.storedPath');
  let requeued = 0;
  let failed = 0;
  for (const doc of pending) {
    const exists = doc.audio?.storedPath && await fs.access(doc.audio.storedPath).then(() => true, () => false);
    if (exists) {
      await SpeechAssessment.updateOne({ _id: doc._id }, { $set: { status: 'queued' } });
      queue.push(doc.id);
      requeued += 1;
    } else {
      await SpeechAssessment.updateOne({ _id: doc._id }, {
        $set: { status: 'failed', error: { code: 'audio_missing_after_restart', message: 'The server restarted and the audio file was gone.' } },
      });
      failed += 1;
    }
  }
  return { requeued, failed, cleaned };
}

async function cleanFinished() {
  const stale = await SpeechAssessment.find({
    status: { $in: ['completed', 'failed'] }, 'audio.deleted': { $ne: true }, 'audio.storedPath': { $exists: true },
  }).select('_id');
  for (const doc of stale) await deleteAudio(doc);
  return stale.length;
}

module.exports = {
  // resolveTask is also used by C2 to reject a bad task before accepting a video.
  create, get, listForChild, summaryForChild, review, remove, recover, resolveTask, queueStats: () => queue.stats(),
};
