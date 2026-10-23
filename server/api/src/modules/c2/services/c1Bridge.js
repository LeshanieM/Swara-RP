/**
 * The only place C2 touches C1. C2 gets its stutter moments from C1:
 * either it creates a C1 assessment from the video's audio track (paths A/B),
 * or it reads one the app already created for the same recording.
 */
const crypto = require('crypto');
const fs = require('fs/promises');
const path = require('path');
const env = require('../../../config/env');
const ApiError = require('../../../lib/ApiError');
const c1Assessments = require('../../c1/services/assessmentService');
const SpeechAssessment = require('../../c1/models/SpeechAssessment');

const C1_UPLOAD_DIR = path.join(env.uploadDir, 'c1');
const sleep = (ms) => new Promise((resolve) => { setTimeout(resolve, ms); });

/** Check C1 task fields before accepting a video; throws C1's own 422 errors. */
function checkTask(input) {
  return c1Assessments.resolveTask(input);
}

/** Load a C1 assessment the client linked, and check it belongs to the same child. */
async function findLinked(id, childId) {
  const doc = await SpeechAssessment.findById(id).select('childId status');
  if (!doc) throw ApiError.unprocessable('c1_assessment_not_found', `No C1 assessment with id ${id}.`);
  if (doc.childId !== childId) {
    throw ApiError.unprocessable('c1_assessment_child_mismatch', `C1 assessment ${id} belongs to a different child.`);
  }
  if (doc.status === 'failed') {
    throw ApiError.unprocessable('c1_assessment_failed', `C1 assessment ${id} failed, so it has no stutter moments.`);
  }
  return doc;
}

/** Hand the extracted audio to C1 exactly as an app upload would arrive. Returns the new assessment id. */
async function createFromAudio(wav, { childId, age, c1Task }) {
  await fs.mkdir(C1_UPLOAD_DIR, { recursive: true });
  const file = path.join(C1_UPLOAD_DIR, `${crypto.randomUUID()}.wav`);
  await fs.writeFile(file, wav);
  try {
    const doc = await c1Assessments.create({ childId, age, ...c1Task }, {
      originalname: 'video-audio-track.wav', mimetype: 'audio/wav', size: wav.length, path: file,
    });
    return doc.id;
  } catch (err) {
    await fs.rm(file, { force: true });
    throw err;
  }
}

/**
 * Wait until the C1 assessment finishes. Returns its stutter moments, or throws
 * { code: 'stutter_events_unavailable' | 'stutter_events_timeout' }.
 */
async function waitForMoments(id, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  let delay = 1000;
  for (;;) {
    const doc = await SpeechAssessment.findById(id).select('status error result.stutterMoments');
    if (!doc) throw Object.assign(new Error(`C1 assessment ${id} no longer exists.`), { code: 'stutter_events_unavailable' });
    if (doc.status === 'completed') {
      return doc.result.stutterMoments.map((m) => ({ start: m.start, end: m.end, types: m.types }));
    }
    if (doc.status === 'failed') {
      throw Object.assign(new Error(`C1 could not analyse the audio (${doc.error?.code}): ${doc.error?.message}`), {
        code: 'stutter_events_unavailable', details: { c1AssessmentId: id, c1Error: doc.error },
      });
    }
    if (Date.now() > deadline) {
      throw Object.assign(new Error(`C1 assessment ${id} did not finish within ${timeoutMs} ms.`), { code: 'stutter_events_timeout' });
    }
    await sleep(delay);
    delay = Math.min(delay * 1.5, 5000);
  }
}

module.exports = {
  checkTask, findLinked, createFromAudio, waitForMoments,
};
