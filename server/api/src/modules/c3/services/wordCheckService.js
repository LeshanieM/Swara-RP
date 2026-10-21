// Word check for word activities: did the child say the item's target word? The language service decides
// match / mismatch / unclear per recording; this module stores the checks and turns them into P's inputs.
const fs = require('fs/promises');
const path = require('path');
const ApiError = require('../../../lib/ApiError');
const ActivityAttempt = require('../models/ActivityAttempt');
const catalogService = require('./catalogService');
const wordCheckClient = require('./wordCheckClient');
const { UPLOAD_DIR } = require('../upload');

/** The words the attempt's item asks for, or a 422 for activities that have none. */
function targetsOf(attempt) {
  const item = catalogService.findItem(attempt.itemId);
  const words = item?.targetWords?.si;
  if (!words?.length) {
    throw ApiError.unprocessable('not_a_word_activity', `Activity ${attempt.armId} (${attempt.itemId}) has no target words to check.`);
  }
  return { item, words };
}

/** Alternatives scored against the expected word: the item's other words plus its listed confusables. */
function alternativesFor(item, words, index) {
  const own = item.confusables?.[words[index]] || [];
  return [...new Set([...words.filter((_, i) => i !== index), ...own])];
}

async function create(session, attemptId, wordIndex, file) {
  try {
    if (!file) throw ApiError.unprocessable('audio_required', 'Send the recording of the word as the "audio" file field.');
    const attempt = await ActivityAttempt.findOne({ _id: attemptId, sessionId: session._id });
    if (!attempt) throw ApiError.notFound('activity_not_found', `No activity ${attemptId} in session ${session.id}.`);
    if (session.status !== 'active') throw new ApiError(409, 'session_not_active', `Session is ${session.status}.`);
    if (attempt.status !== 'pending') {
      throw new ApiError(409, 'activity_not_pending', `Words can be checked only before the result is posted; this activity is ${attempt.status}.`);
    }
    if (session.language === 'en') {
      throw ApiError.unprocessable('language_not_supported', 'The word check uses a Sinhala ASR model; English sessions are not supported.');
    }
    const { item, words } = targetsOf(attempt);
    if (wordIndex >= words.length) {
      throw ApiError.unprocessable('unknown_word', `wordIndex ${wordIndex} is out of range; this item has ${words.length} target words.`, { targetWords: words });
    }

    const alternatives = alternativesFor(item, words, wordIndex);
    const out = await wordCheckClient.verify({
      filePath: file.path, originalName: file.originalname, expected: words[wordIndex], alternatives,
    });
    const check = {
      wordIndex,
      expected: out.expected,
      alternatives,
      decision: out.decision,
      heard: out.heard,
      heardRaw: out.heardRaw,
      similarity: out.similarity,
      confidence: out.confidence,
      scores: out.scores,
      reasons: out.reasons,
      engine: out.engine,
      methodVersion: out.methodVersion,
      audio: { originalName: file.originalname, durationSec: out.audio?.durationSec, deleted: true },
    };
    // Append only while the activity is still open, so a check can't land after the result was scored.
    const updated = await ActivityAttempt.findOneAndUpdate(
      { _id: attempt._id, status: 'pending' }, { $push: { wordChecks: check } }, { new: true, runValidators: true },
    );
    if (!updated) throw new ApiError(409, 'activity_not_pending', 'The result for this activity was posted while the word was being checked.');
    const saved = updated.wordChecks[updated.wordChecks.length - 1];
    return { ...saved.toJSON(), attemptId: updated.id, targetWords: words, verification: summarise(updated) };
  } finally {
    // One short clip, checked while the client waits: never kept.
    if (file?.path) await fs.rm(file.path, { force: true }).catch(() => {});
  }
}

async function review(session, attemptId, checkId, body) {
  const attempt = await ActivityAttempt.findOne({ _id: attemptId, sessionId: session._id });
  if (!attempt) throw ApiError.notFound('activity_not_found', `No activity ${attemptId} in session ${session.id}.`);
  const check = attempt.wordChecks.id(checkId);
  if (!check) throw ApiError.notFound('word_check_not_found', `No word check ${checkId} on activity ${attemptId}.`);
  check.review = { ...body, at: new Date() };
  await attempt.save();
  return {
    ...check.toJSON(),
    attemptId: attempt.id,
    // Once the result is posted, P and the bandit update are fixed; a later review is kept as ground truth only.
    affectsScore: attempt.status === 'pending',
    verification: summarise(attempt),
  };
}

/**
 * The latest check of each target word decides it (a parent / SLP review wins over the automatic decision).
 * Judged words are matched or mismatched; unclear ones are left out of P rather than counted as wrong.
 */
function summarise(attempt) {
  const words = catalogService.findItem(attempt.itemId)?.targetWords?.si?.length ?? 0;
  const latest = new Map();
  for (const c of attempt.wordChecks || []) latest.set(c.wordIndex, c);
  const decisions = [...latest.values()].map((c) => c.review?.decision || c.decision);
  const matched = decisions.filter((d) => d === 'match').length;
  const mismatched = decisions.filter((d) => d === 'mismatch').length;
  return {
    source: matched + mismatched > 0 ? 'word_check' : 'reported',
    words,
    checked: latest.size,
    matched,
    mismatched,
    unclear: decisions.filter((d) => d === 'unclear').length,
  };
}

/** Startup: checks run inside the request, so any clip still on disk was left by a crash. */
async function cleanUploads() {
  const names = await fs.readdir(UPLOAD_DIR).catch(() => []);
  await Promise.all(names.map((n) => fs.rm(path.join(UPLOAD_DIR, n), { force: true })));
  return names.length;
}

module.exports = { create, review, summarise, cleanUploads, targetsOf };
