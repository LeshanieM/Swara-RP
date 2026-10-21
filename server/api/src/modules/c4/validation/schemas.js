const { z } = require('zod');
const { childId, objectId } = require('../../c1/validation/schemas');

const BANDS = ['below', 'stable', 'gaining'];
const SOURCES = ['asr', 'corrected', 'manual'];

// Multipart fields arrive as strings; empty strings mean "not sent".
const blankToUndefined = (v) => (typeof v === 'string' && v.trim() === '' ? undefined : v);
const optional = (schema) => z.preprocess(blankToUndefined, schema.optional());

// Whole-number field that may arrive as a string (query, multipart).
const wholeNumber = (name) => z.preprocess(
  (v) => (v === undefined || (typeof v === 'string' && v.trim() === '') ? undefined : Number(v)),
  z.number({ required_error: `${name} is required`, invalid_type_error: `${name} must be a number` })
    .int(`${name} must be a whole number`),
);

const ageQuery = z.object({ age: wholeNumber('age') });
const topicsQuery = z.object({
  age: wholeNumber('age'),
  category: z.string().trim().max(60).optional(),
  level: z.enum(['concrete', 'open']).optional(),
});

const profile = z.object({
  age: wholeNumber('age'),
  language: z.enum(['si', 'en']).default('si'),
  rankedCategories: z.array(z.string().trim().min(1).max(60), { required_error: 'rankedCategories is required' })
    .length(5, 'rank exactly 5 favourite categories, most favourite first'),
}).strict();

const checklist = z.object({
  respondent: z.enum(['parent', 'slp']),
  answers: z.array(z.object({ itemId: z.string().trim().min(1).max(60), answer: z.boolean() }).strict())
    .min(1, 'answer every checklist item'),
}).strict();

const knownWords = z.object({
  respondent: z.enum(['parent', 'slp']),
  words: z.array(z.string().trim().min(1).max(60)).min(1).max(2000),
}).strict();

const createSession = z.object({
  childId,
  mode: z.enum(['personalised', 'fixed']).default('personalised'),
  // Optional C3 signal until C3 is in the same API: a falling Therapy Success Score asks for concrete topics.
  c3TssTrend: z.enum(['falling', 'stable', 'rising']).optional(),
  // Fixes the random draw, for reproducible demos and analysis.
  seed: z.number().int().min(0).max(2 ** 32 - 1).optional(),
}).strict();

const skip = z.object({
  kind: z.enum(['follow_up', 'main_prompt']),
  reason: z.string().trim().max(200).optional(),
}).strict();

const recording = z.object({
  transcript: optional(z.string().trim().max(50000)),
});

const transcriptEdit = z.object({
  text: z.string().trim().min(1, 'text must not be empty').max(50000),
  kind: z.enum(['corrected', 'manual']),
  editedBy: z.enum(['parent', 'slp']),
}).strict();

const bandConfirmation = z.object({
  by: z.enum(['parent', 'slp']),
  decision: z.enum(['confirm', 'override']),
  band: z.enum(BANDS).optional(),
  notes: z.string().trim().max(2000).optional(),
}).strict().refine((b) => b.decision === 'confirm' || b.band, { message: 'an override needs band', path: ['band'] });

const historyQuery = z.object({
  status: z.enum(['queued', 'processing', 'completed', 'failed']).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

const h4dQuery = z.object({
  childId: childId.optional(),
  format: z.enum(['json', 'csv']).default('json'),
});

// ---- Mirror of the language-service contract (contracts/c4/). Extra fields are allowed. ----
const timedWord = z.object({
  word: z.string(), start: z.number().nullable(), end: z.number().nullable(), confidence: z.number().nullable().optional(),
}).passthrough();

const transcription = z.object({
  engine: z.object({ name: z.string(), model: z.string(), repetitionPreserving: z.boolean() }).passthrough(),
  text: z.string(),
  words: z.array(timedWord),
  wordTimings: z.enum(['ctc', 'word', 'segment']),
  audio: z.object({ durationSec: z.number() }).passthrough(),
  processingSec: z.number(),
}).passthrough();

const analysis = z.object({
  methodVersion: z.string(),
  source: z.enum(SOURCES),
  normalisedText: z.string(),
  cleanText: z.string(),
  tokens: z.array(z.object({
    norm: z.string(), stem: z.string(), maze: z.boolean(), utterance: z.number().nullable(),
  }).passthrough()),
  utterances: z.array(z.object({
    index: z.number(), wordCount: z.number(), complexity: z.number(), mazeOnly: z.boolean(), stutter: z.boolean().nullable(),
  }).passthrough()),
  measures: z.object({
    mluWords: z.number().nullable(),
    ndw50: z.number().nullable(),
    ndwAll: z.number(),
    mattr25: z.number().nullable(),
    totalWords: z.number(),
    utteranceCount: z.number(),
    mluLabel: z.literal('words'),
  }).passthrough(),
  syllables: z.object({ total: z.number(), words: z.number() }),
  lexicon: z.array(z.object({ stem: z.string(), count: z.number(), forms: z.array(z.string()) })),
  mazes: z.object({ total: z.number(), byReason: z.record(z.number()) }),
  flags: z.array(z.string()),
}).passthrough();

module.exports = {
  BANDS,
  SOURCES,
  childId,
  objectId,
  ageQuery,
  topicsQuery,
  profile,
  checklist,
  knownWords,
  createSession,
  skip,
  recording,
  transcriptEdit,
  bandConfirmation,
  historyQuery,
  h4dQuery,
  transcription,
  analysis,
};
