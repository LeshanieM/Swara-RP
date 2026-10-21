/**
 * The only place C4 touches C1. C4 sends its own recording to C1's speech
 * service and keeps the result inside the C4 sample, so spontaneous speech
 * gets C1's events and %SS without creating C1 assessments (which would mix
 * into C1's per-task history and summary).
 *
 * C1 owns the %SS method. C4's job is to supply the exact syllable count:
 * the transcript goes with the audio, and after a human correction %SS is
 * recomputed as C1's stuttered syllables over the corrected syllable count.
 */
const speechClient = require('../../c1/services/speechClient');
const c1Assessments = require('../../c1/services/assessmentService');
const { speechResult } = require('../../c1/validation/schemas');

// Spontaneous speech has no passage, so it is scored like C1's non-reader task.
const C1_TASK = 'picture_description';
const TRANSIENT = new Set(['speech_service_unavailable', 'speech_service_timeout', 'busy']);
const MAX_TRIES = 2;
const sleep = (ms) => new Promise((resolve) => { setTimeout(resolve, ms); });
const round = (x, nd = 2) => Math.round(x * 10 ** nd) / 10 ** nd;

const notAssessed = (code, message) => ({ status: 'not_assessed', reason: { code, message } });

/** Returns the stuttering block stored on the sample; never throws. */
async function analyse({ filePath, originalName, transcript, language }) {
  let raw;
  for (let attempt = 1; ; attempt += 1) {
    try {
      raw = await speechClient.analyze({ filePath, originalName, taskType: C1_TASK, language, transcript: transcript || undefined });
      break;
    } catch (err) {
      if (TRANSIENT.has(err.code) && attempt < MAX_TRIES) {
        await sleep(2000);
        continue;
      }
      return notAssessed(err.code || 'c1_error', err.message);
    }
  }
  const parsed = speechResult.safeParse(raw);
  if (!parsed.success) {
    return notAssessed('invalid_speech_response', `C1 response broke its contract at ${parsed.error.issues[0].path.join('.')}`);
  }
  const r = parsed.data;
  return {
    status: 'assessed',
    taskTypeUsed: C1_TASK,
    audioDurationSec: r.audio.durationSec,
    detector: r.detector,
    events: r.events,
    stutterMoments: r.stutterMoments,
    counts: r.counts,
    stutteredSyllables: r.stutteredSyllables,
    syllables: r.syllables,
    percentSS: r.percentSS,               // as C1 computed it, with the transcript sent at analysis time
    percentSSCurrent: r.percentSS,        // recomputed after each transcript correction
    syllablesCurrent: r.syllables.total,
    severity: { label: r.severity.label, score: r.severity.score, version: r.severity.version, provisional: r.severity.provisional },
    warnings: r.warnings,
    serviceVersion: r.serviceVersion,
  };
}

/** %SS for a corrected transcript: C1's stuttered syllables over the new syllable count. */
function recompute(stuttering, syllablesTotal) {
  if (stuttering?.status !== 'assessed') return stuttering;
  return {
    ...stuttering,
    syllablesCurrent: syllablesTotal,
    percentSSCurrent: syllablesTotal > 0 ? round((stuttering.stutteredSyllables / syllablesTotal) * 100) : null,
  };
}

async function health() {
  try {
    const h = await speechClient.health();
    return { status: 'ok', activeDetector: h.activeDetector };
  } catch (err) {
    return { status: 'unreachable', error: err.code || err.message };
  }
}

/** C1's structured-task summary, shown next to C4's spontaneous %SS. */
const taskSummary = (childId) => c1Assessments.summaryForChild(childId);

module.exports = { analyse, recompute, health, taskSummary };
