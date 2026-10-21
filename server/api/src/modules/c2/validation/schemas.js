const { z } = require('zod');
const c1 = require('../../c1/validation/schemas');

const { optional, wholeNumber, childId, objectId } = c1;
const CATEGORY = ['FG', 'HM'];
const SIGNAL = ['eye', 'lip', 'jaw', 'cheek', 'head'];
const INPUT_PATHS = ['in_task_camera', 'parent_upload'];
const STUTTER_SOURCES = ['c1_audio_track', 'c1_assessment', 'manual'];
const NOT_ASSESSED_REASONS = ['no_video_consent', 'camera_declined', 'camera_unavailable', 'video_unusable', 'other'];
const STATUSES = ['queued', 'awaiting_stutter_events', 'processing', 'completed', 'failed', 'not_assessed'];

const span = z.object({
  start: z.number().min(0),
  end: z.number().positive(),
  types: z.array(z.string().max(40)).max(10).optional(),
}).refine((s) => s.end > s.start, { message: 'end must be after start' });

// Multipart sends stutterSpans as a JSON string.
const jsonSpans = z.preprocess((v) => {
  if (typeof v !== 'string' || v.trim() === '') return v === '' ? undefined : v;
  try { return JSON.parse(v); } catch { return v; }
}, z.array(span, { invalid_type_error: 'stutterSpans must be a JSON list of {start, end} in seconds' }).min(1).max(200).optional());

const bool = (name) => z.preprocess(
  (v) => (v === 'true' || v === true ? true : v === 'false' || v === false ? false : v),
  z.boolean({ required_error: `${name} is required`, invalid_type_error: `${name} must be true or false` }),
);

const createAnalysis = z.object({
  childId,
  age: wholeNumber('age'),
  inputPath: z.enum(INPUT_PATHS, { required_error: 'inputPath is required (in_task_camera or parent_upload)' }),
  videoConsent: bool('videoConsent').refine((v) => v === true, 'videoConsent must be true: video is analysed only with parental consent'),
  stutterSource: optional(z.enum(STUTTER_SOURCES)),
  c1AssessmentId: optional(objectId),
  stutterSpans: jsonSpans,
  // Used only when the stutter moments come from the video's own audio (a new C1 assessment).
  taskType: optional(z.enum(c1.TASK)),
  language: optional(z.enum(['si', 'en'])).default('si'),
  passageId: optional(z.string().trim().max(100)),
  passageText: optional(z.string().trim().max(5000)),
  pictureId: optional(z.string().trim().max(100)),
  transcript: optional(z.string().trim().max(10000)),
  targetFps: optional(z.coerce.number().min(5).max(30)),
}).superRefine((v, ctx) => {
  if (v.c1AssessmentId && v.stutterSpans) {
    ctx.addIssue({ code: 'custom', path: ['stutterSpans'], message: 'Send c1AssessmentId or stutterSpans, not both' });
  }
  const implied = v.c1AssessmentId ? 'c1_assessment' : v.stutterSpans ? 'manual' : 'c1_audio_track';
  if (v.stutterSource && v.stutterSource !== implied) {
    const need = { c1_assessment: 'c1AssessmentId', manual: 'stutterSpans', c1_audio_track: 'neither c1AssessmentId nor stutterSpans' };
    ctx.addIssue({ code: 'custom', path: ['stutterSource'], message: `stutterSource ${v.stutterSource} needs ${need[v.stutterSource]}` });
  }
}).transform((v) => ({
  ...v,
  stutterSource: v.c1AssessmentId ? 'c1_assessment' : v.stutterSpans ? 'manual' : 'c1_audio_track',
}));

// Path C: no video. Recorded so C2 shows "not assessed", never "0 behaviours".
const notAssessed = z.object({
  childId,
  age: z.number({ required_error: 'age is required' }).int('age must be a whole number'),
  reason: z.enum(NOT_ASSESSED_REASONS),
  notes: z.string().trim().max(2000).optional(),
  c1AssessmentId: objectId.optional(),
}).strict();

const review = z.object({
  reviewerRole: z.enum(['slp', 'parent']),
  // Reference labels per stutter moment (the child test set's FG/HM labels).
  momentLabels: z.array(z.object({
    momentIndex: z.number().int().min(0),
    FG: z.boolean(),
    HM: z.boolean(),
  }).strict()).max(200).optional(),
  hasSecondaryBehaviors: z.boolean().optional(),
  notes: z.string().trim().max(2000).optional(),
}).strict().refine(
  (r) => r.momentLabels !== undefined || r.hasSecondaryBehaviors !== undefined || r.notes !== undefined,
  { message: 'Provide at least one of momentLabels, hasSecondaryBehaviors or notes' },
);

const historyQuery = z.object({
  status: z.enum(STATUSES).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

// Mirror of the vision service contract (contracts/c2/analyze-video.response.example.json).
// Unknown extra fields are allowed so the service can add fields without breaking the API.
const categoryOut = z.object({ present: z.boolean(), score: z.number(), scoreType: z.string() });
const signalOut = z.object({
  deviation: z.number(), direction: z.enum(['above', 'below']), topFeature: z.string(),
  threshold: z.number(), pValue: z.number().nullable(), exceeds: z.boolean(),
}).passthrough();

const visionResult = z.object({
  video: z.object({ durationSec: z.number(), analysedFps: z.number(), framesAnalysed: z.number(), faceDetectedRatio: z.number() }).passthrough(),
  detector: z.object({ name: z.string(), version: z.string(), fallback: z.boolean() }).passthrough(),
  baseline: z.object({ source: z.enum(['fluent_spans', 'whole_recording']), durationSec: z.number() }).passthrough(),
  stutterMoments: z.array(z.object({
    index: z.number(),
    start: z.number(),
    end: z.number(),
    assessed: z.boolean(),
    behaviourPresent: z.boolean().nullable(),
    categories: z.record(z.enum(CATEGORY), categoryOut).nullable(),
    signals: z.record(z.enum(SIGNAL), signalOut).nullable(),
    explanation: z.array(z.string()),
  }).passthrough()),
  behaviourEvents: z.array(z.object({
    category: z.enum(CATEGORY), signal: z.enum(SIGNAL), start: z.number(), end: z.number(), peakDeviation: z.number(), momentIndex: z.number(),
  }).passthrough()),
  counts: z.object({
    momentsTotal: z.number(), momentsAssessed: z.number(), momentsWithBehaviour: z.number(), FG: z.number(), HM: z.number(),
  }).passthrough(),
  behavioursPerStutter: z.object({ FG: z.number().nullable(), HM: z.number().nullable(), any: z.number().nullable() }),
  hasSecondaryBehaviors: z.boolean().nullable(),
  concomitantScore: z.number().min(0).max(1).nullable(),
  baselines: z.object({ rules: z.object({ momentsWithBehaviour: z.number() }).passthrough() }).passthrough(),
  summary: z.object({ assessed: z.boolean(), hasSecondaryBehaviors: z.boolean().nullable() }).passthrough(),
  warnings: z.array(z.object({ code: z.string(), message: z.string() })),
  processingMs: z.number(),
  serviceVersion: z.string(),
}).passthrough();

module.exports = {
  createAnalysis, notAssessed, review, historyQuery, visionResult, childId, objectId,
  INPUT_PATHS, STUTTER_SOURCES, NOT_ASSESSED_REASONS, STATUSES,
};
