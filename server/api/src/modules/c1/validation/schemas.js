const { z } = require('zod');

const SEVERITY = ['none_very_mild', 'mild', 'moderate', 'severe'];
const TASK = ['reading', 'picture_description'];
const EVENT = ['block', 'prolongation', 'sound_repetition', 'word_repetition', 'interjection'];

// Multipart fields arrive as strings; empty strings mean "not sent".
const blankToUndefined = (v) => (typeof v === 'string' && v.trim() === '' ? undefined : v);
const optional = (schema) => z.preprocess(blankToUndefined, schema.optional());

// Whole-number field that may arrive as a string (multipart, query).
const wholeNumber = (name) => z.preprocess(
  (v) => (v === undefined || (typeof v === 'string' && v.trim() === '') ? undefined : Number(v)),
  z.number({ required_error: `${name} is required`, invalid_type_error: `${name} must be a number` })
    .int(`${name} must be a whole number`),
);

const childId = z.string().trim().min(1).max(64)
  .regex(/^[A-Za-z0-9_-]+$/, 'childId may contain letters, digits, "_" and "-" only');

const objectId = z.string().regex(/^[a-f0-9]{24}$/i, 'must be a 24-character hex id');

const createAssessment = z.object({
  childId,
  age: wholeNumber('age'),
  taskType: optional(z.enum(TASK)),
  language: optional(z.enum(['si', 'en'])).default('si'),
  passageId: optional(z.string().trim().max(100)),
  passageText: optional(z.string().trim().max(5000)),
  pictureId: optional(z.string().trim().max(100)),
  transcript: optional(z.string().trim().max(10000)),
  concomitantScore: optional(z.coerce.number().min(0).max(1)),
});

const tasksQuery = z.object({
  age: wholeNumber('age'),
  language: z.enum(['si', 'en']).optional(),
});

const historyQuery = z.object({
  taskType: z.enum(TASK).optional(),
  status: z.enum(['queued', 'processing', 'completed', 'failed']).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

const review = z.object({
  referencePercentSS: z.number().min(0).max(100).optional(),
  slpSeverity: z.enum(SEVERITY).optional(),
  reviewerRole: z.enum(['slp', 'parent']),
  notes: z.string().trim().max(2000).optional(),
}).strict().refine(
  (r) => r.referencePercentSS !== undefined || r.slpSeverity !== undefined || r.notes !== undefined,
  { message: 'Provide at least one of referencePercentSS, slpSeverity or notes' },
);

// Mirror of the speech service contract (contracts/analyze-speech.response.example.json).
// Unknown extra fields are allowed so the service can add fields without breaking the API.
const speechResult = z.object({
  taskType: z.enum(TASK),
  language: z.enum(['si', 'en']),
  audio: z.object({ durationSec: z.number(), sampleRate: z.number(), channels: z.number() }).passthrough(),
  detector: z.object({ name: z.string(), version: z.string(), fallback: z.boolean() }).passthrough(),
  windows: z.object({ sizeSec: z.number(), hopSec: z.number(), count: z.number() }).passthrough(),
  events: z.array(z.object({
    type: z.enum(EVENT), start: z.number(), end: z.number(), duration: z.number(), confidence: z.number(),
  })),
  stutterMoments: z.array(z.object({
    start: z.number(), end: z.number(), duration: z.number(), types: z.array(z.enum(EVENT)),
  })),
  counts: z.object({
    block: z.number(), prolongation: z.number(), soundRepetition: z.number(), wordRepetition: z.number(), interjection: z.number(),
  }),
  primaryType: z.enum(EVENT).nullable(),
  syllables: z.object({ total: z.number(), source: z.enum(['passage', 'transcript', 'estimated']) }).passthrough(),
  stutteredSyllables: z.number(),
  percentSS: z.number(),
  durationTerm: z.object({ meanLongest3Sec: z.number(), longestSec: z.number(), eventsUsed: z.number() }),
  severity: z.object({
    label: z.enum(SEVERITY), score: z.number(), version: z.string(), method: z.string(),
  }).passthrough(),
  baselines: z.object({ mimiChunkRatio: z.object({ ratioPercent: z.number(), label: z.enum(SEVERITY) }).passthrough() }),
  features: z.record(z.number()),
  summary: z.object({
    stutterDetected: z.boolean(), stutterType: z.string(), severity: z.string(), confidence: z.number(),
  }),
  warnings: z.array(z.object({ code: z.string(), message: z.string() })),
  processingMs: z.number(),
  serviceVersion: z.string(),
}).passthrough();

module.exports = {
  createAssessment, tasksQuery, historyQuery, review, speechResult, childId, objectId, optional, wholeNumber, TASK,
};
