// Answer check for the reading and picture-description activities: the language service transcribes the child's
// recording (stutter repetitions removed) and compares it with the passage (reading) or with the words the picture
// description should mention (keywords). The latest check of the activity sets P's inputs; the clip is not kept.
const fs = require('fs/promises');
const ApiError = require('../../../lib/ApiError');
const ActivityAttempt = require('../models/ActivityAttempt');
const catalogService = require('./catalogService');
const wordCheckClient = require('./wordCheckClient');

/** What the attempt's item is checked against, or a 422 for activities that are not checked this way. */
function referenceOf(attempt) {
  const item = catalogService.findItem(attempt.itemId);
  if (item?.type === 'passage_reading' && item.text?.si) return { item, mode: 'reading', reference: item.text.si };
  if (item?.type === 'picture_description' && item.keywords?.si?.length) return { item, mode: 'keywords', keywords: item.keywords.si };
  throw ApiError.unprocessable(
    'not_a_speech_check_activity',
    `Activity ${attempt.armId} (${attempt.itemId}) has no passage or keywords to check; word activities use word-checks.`,
  );
}

async function create(session, attemptId, file) {
  try {
    if (!file) throw ApiError.unprocessable('audio_required', 'Send the recording as the "audio" file field.');
    const attempt = await ActivityAttempt.findOne({ _id: attemptId, sessionId: session._id });
    if (!attempt) throw ApiError.notFound('activity_not_found', `No activity ${attemptId} in session ${session.id}.`);
    if (session.status !== 'active') throw new ApiError(409, 'session_not_active', `Session is ${session.status}.`);
    if (attempt.status !== 'pending') {
      throw new ApiError(409, 'activity_not_pending', `A recording can be checked only before the result is posted; this activity is ${attempt.status}.`);
    }
    if (session.language === 'en') {
      throw ApiError.unprocessable('language_not_supported', 'The check uses a Sinhala ASR model; English sessions are not supported.');
    }
    const ref = referenceOf(attempt);
    const out = await wordCheckClient.checkSpeech({
      filePath: file.path, originalName: file.originalname, mode: ref.mode, reference: ref.reference, keywords: ref.keywords,
    });
    const check = {
      mode: out.mode,
      decision: out.decision,
      share: out.mode === 'reading' ? out.wordsReadShare : out.foundShare,
      wordsRead: out.wordsRead ?? null,
      referenceWords: out.referenceWords ?? null,
      missedWords: out.missedWords ?? null,
      wer: out.wer ?? null,
      keywords: out.keywords ?? null,
      found: out.found ?? null,
      heard: out.heard,
      heardRaw: out.heardRaw,
      engine: out.engine,
      methodVersion: out.methodVersion,
      audio: { originalName: file.originalname, durationSec: out.audio?.durationSec, deleted: true },
      at: new Date(),
    };
    const updated = await ActivityAttempt.findOneAndUpdate(
      { _id: attempt._id, status: 'pending' }, { $set: { speechCheck: check } }, { new: true, runValidators: true },
    );
    if (!updated) throw new ApiError(409, 'activity_not_pending', 'The result for this activity was posted while the recording was being checked.');
    return { attemptId: updated.id, ...check, verification: summarise(updated) };
  } finally {
    if (file?.path) await fs.rm(file.path, { force: true }).catch(() => {});
  }
}

/**
 * P's inputs from the check, or null when there is none (or it was unclear): reading counts the share of the passage
 * read, a description the share of keywords mentioned, both scaled to the item's targets.
 */
function summarise(attempt) {
  const c = attempt.speechCheck;
  if (!c || c.decision === 'unclear' || !Number.isFinite(c.share)) return null;
  const targets = catalogService.findItem(attempt.itemId)?.targets ?? 1;
  return {
    source: 'speech_check', mode: c.mode, share: c.share, decision: c.decision, targets, successes: Math.round(c.share * targets),
  };
}

module.exports = { create, summarise, referenceOf };
