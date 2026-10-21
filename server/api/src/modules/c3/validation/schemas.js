const { z } = require('zod');
const { childId, objectId } = require('../../c1/validation/schemas');

const wholeNumber = (name) => z.preprocess(
  (v) => (v === undefined || (typeof v === 'string' && v.trim() === '') ? undefined : Number(v)),
  z.number({ required_error: `${name} is required`, invalid_type_error: `${name} must be a number` }).int(`${name} must be a whole number`),
);
const share = z.number().min(0).max(1);
const nonNegative = z.number().min(0);

const ageQuery = z.object({ age: wholeNumber('age') });
const itemsQuery = z.object({ armId: z.string().trim().min(1).max(100) });
const questionnaireQuery = z.object({ language: z.enum(['si', 'en']).optional() });

const createSession = z.object({
  childId,
  age: z.number({ required_error: 'age is required' }).int('age must be a whole number'),
  language: z.enum(['si', 'en']).default('si'),
  cameraOn: z.boolean().default(false),
  plannedMinutes: z.number().int().min(5).max(60).optional(),
  maxActivities: z.number().int().min(1).max(20).optional(),
  c2Flag: z.enum(['yes', 'no', 'missing']).optional(),
}).strict();

const nextActivity = z.object({
  excludeArmIds: z.array(z.string().max(100)).max(50).default([]),
  force: z.boolean().default(false), // pick even when the planned time is used up
}).strict();

// Face numbers only, computed on the phone (vision-service/app/engagement/features.py defines them); no images.
// Window fields other than facePresentRatio are null when no face was seen in that window.
const angle = nonNegative.max(180).nullable().optional();
const cameraWindow = z.object({
  durationSec: z.number().min(0).max(60).optional(),
  facePresentRatio: share,
  yawStdDeg: angle,
  pitchStdDeg: angle,
  yawAbsMeanDeg: angle,
  pitchAbsMeanDeg: angle,
  lookAwayRatio: share.nullable().optional(),
  eyeOpenMean: share.nullable().optional(),
  eyesClosedRatio: share.nullable().optional(),
  smileMean: share.nullable().optional(),
}).strict();

const camera = z.object({
  // The 10-second windows the camera model scores; the aggregate fields below are kept for older clients.
  windows: z.array(cameraWindow).max(60).optional(),
  facePresentRatio: share.optional(),
  yawStdDeg: nonNegative.max(90).optional(),
  pitchStdDeg: nonNegative.max(90).optional(),
  eyeOpenMean: share.optional(),
  smileMean: share.optional(),
}).strict().refine((c) => c.windows?.length || c.facePresentRatio !== undefined, {
  message: 'camera needs windows or facePresentRatio', path: ['windows'],
});

const activityResult = z.object({
  skipped: z.boolean().default(false),
  targets: z.number().int().min(1).max(100).optional(),
  successes: z.number().int().min(0).max(100).optional(),
  completedShare: share.optional(),
  attempts: z.number().int().min(0).max(500).optional(),
  responseLatencyMs: nonNegative.max(600000).optional(),
  taps: z.number().int().min(0).max(10000).optional(),
  durationSec: z.number({ required_error: 'durationSec is required' }).min(0).max(3600),
  earlyExit: z.boolean().default(false),
  parentHelp: z.number().int().min(0).max(3).optional(),
  parentFeedback: z.enum(['too_hard', 'just_right', 'too_easy']).optional(),
  camera: camera.optional(),
  engagementEstimate: z.object({
    score: share,
    mode: z.enum(['logs', 'camera_logs']).optional(),
    modelVersion: z.string().max(100).optional(),
  }).strict().optional(),
}).strict().superRefine((r, ctx) => {
  if (r.skipped) return;
  if (r.targets === undefined) ctx.addIssue({ code: 'custom', path: ['targets'], message: 'targets is required unless the activity was skipped' });
  if (r.successes === undefined) ctx.addIssue({ code: 'custom', path: ['successes'], message: 'successes is required unless the activity was skipped' });
  if (r.targets !== undefined && r.successes !== undefined && r.successes > r.targets) {
    ctx.addIssue({ code: 'custom', path: ['successes'], message: 'successes cannot exceed targets' });
  }
});

const wordCheck = z.object({
  wordIndex: z.coerce.number({ invalid_type_error: 'wordIndex is required: the 0-based position of the word in item.targetWords' })
    .int().min(0).max(50),
}).strict();

const wordCheckReview = z.object({
  decision: z.enum(['match', 'mismatch']),
  by: z.enum(['parent', 'slp']),
  notes: z.string().trim().max(500).optional(),
}).strict();

const breakBody = z.object({
  durationSec: z.number().int().min(10).max(1800).optional(),
  reason: z.enum(['low_engagement', 'requested', 'other']).default('requested'),
}).strict();

const questionnaire = z.object({
  answers: z.record(z.number().int().min(1).max(5)),
  language: z.enum(['si', 'en']).optional(),
}).strict();

const historyQuery = z.object({
  status: z.enum(['active', 'completed', 'abandoned']).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

const banditQuery = z.object({ matrices: z.enum(['0', '1']).default('0') });

const calibrate = z.object({
  minSessions: z.number().int().min(4).max(10000).default(10),
  activate: z.boolean().default(false),
  epochs: z.number().int().min(100).max(50000).default(4000),
  lr: z.number().positive().max(5).default(0.1),
  l2: z.number().min(0).max(10).default(0.01),
}).strict();

const activateModel = z.object({ version: z.string().trim().min(1).max(100) }).strict();

const overTimeQuery = z.object({
  ageBand: z.enum(['5-10', '11-14']).optional(),
  bucketMinutes: z.coerce.number().int().min(1).max(30).default(5),
});

const pilotCheckQuery = z.object({ ageBand: z.enum(['5-10', '11-14']).optional() });

const replayQuery = z.object({
  childId: childId.optional(),
  limit: z.coerce.number().int().min(1).max(500).default(100),
  offset: z.coerce.number().int().min(0).default(0),
});

module.exports = {
  childId, objectId, ageQuery, itemsQuery, questionnaireQuery, createSession, nextActivity, activityResult, wordCheck, wordCheckReview, breakBody,
  questionnaire, historyQuery, banditQuery, calibrate, activateModel, overTimeQuery, pilotCheckQuery, replayQuery,
};
