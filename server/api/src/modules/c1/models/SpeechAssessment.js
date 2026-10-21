const mongoose = require('mongoose');

const { Schema } = mongoose;
const EVENT_TYPES = ['block', 'prolongation', 'sound_repetition', 'word_repetition', 'interjection'];
const SEVERITY_LABELS = ['none_very_mild', 'mild', 'moderate', 'severe'];
const TASK_TYPES = ['reading', 'picture_description'];
const STATUSES = ['queued', 'processing', 'completed', 'failed'];

const eventSchema = new Schema({
  type: { type: String, enum: EVENT_TYPES, required: true },
  start: Number,
  end: Number,
  duration: Number,
  confidence: Number,
}, { _id: false });

const momentSchema = new Schema({
  start: Number,
  end: Number,
  duration: Number,
  types: [{ type: String, enum: EVENT_TYPES }],
}, { _id: false });

const resultSchema = new Schema({
  events: [eventSchema],
  stutterMoments: [momentSchema],
  counts: {
    block: Number, prolongation: Number, soundRepetition: Number, wordRepetition: Number, interjection: Number,
  },
  primaryType: { type: String, enum: [...EVENT_TYPES, null] },
  syllables: {
    total: Number, source: { type: String, enum: ['passage', 'transcript', 'estimated'] }, estimatedFromAudio: Number, fromText: Number,
  },
  stutteredSyllables: Number,
  percentSS: Number,
  durationTerm: { meanLongest3Sec: Number, longestSec: Number, eventsUsed: Number },
  severity: {
    label: { type: String, enum: SEVERITY_LABELS },
    displayLabel: String,
    score: Number,
    maxScore: Number,
    components: { frequencyPoints: Number, durationPoints: Number, physicalPoints: Number },
    belowFrequencyFloor: Boolean,
    physicalTermUsed: Boolean,
    taskType: { type: String, enum: TASK_TYPES },
    method: String,
    version: String,
    provisional: Boolean,
  },
  baselines: { type: Schema.Types.Mixed },
  features: {
    duration: Number,
    speechDuration: Number,
    pauseCount: Number,
    averagePauseDuration: Number,
    longestPause: Number,
    speechRate: Number,
    articulationRate: Number,
    estimatedSyllables: Number,
  },
  summary: {
    stutterDetected: Boolean,
    stutterType: { type: String, enum: ['Repetition', 'Prolongation', 'Block', 'Mixed', 'None'] },
    severity: { type: String, enum: ['None', 'Mild', 'Moderate', 'Severe'] },
    confidence: Number,
  },
  audio: { type: Schema.Types.Mixed },
  detector: { type: Schema.Types.Mixed },
  windows: { type: Schema.Types.Mixed },
  warnings: [{ _id: false, code: String, message: String }],
  processingMs: Number,
  serviceVersion: String,
}, { _id: false });

const reviewSchema = new Schema({
  reviewerRole: { type: String, enum: ['slp', 'parent'], required: true },
  referencePercentSS: { type: Number, min: 0, max: 100 },
  slpSeverity: { type: String, enum: SEVERITY_LABELS },
  notes: { type: String, maxlength: 2000 },
  reviewedAt: { type: Date, default: Date.now },
}, { _id: false });

const speechAssessmentSchema = new Schema({
  childId: { type: String, required: true, trim: true },
  ageAtAssessment: { type: Number, required: true, min: 5, max: 14 },
  ageBand: { type: String, enum: ['5-10', '11-14'], required: true },
  taskType: { type: String, enum: TASK_TYPES, required: true },
  language: { type: String, enum: ['si', 'en'], default: 'si' },
  passageId: String,
  passageText: String,
  pictureId: String,
  transcript: String,
  concomitantScore: { type: Number, min: 0, max: 1 },

  status: { type: String, enum: STATUSES, default: 'queued', index: true },
  attempts: { type: Number, default: 0 },
  error: { _id: false, code: String, message: String },
  startedAt: Date,
  completedAt: Date,

  audio: {
    originalName: String,
    mimeType: String,
    sizeBytes: Number,
    storedPath: { type: String, select: false },
    deleted: { type: Boolean, default: false },
    deletedAt: Date,
  },

  result: resultSchema,

  // Reference values entered by SLPs or parents, kept as an append-only list so
  // a later note never overwrites an SLP's hand-counted %SS (calibration data).
  reviews: [reviewSchema],
}, {
  timestamps: true,
  collection: 'c1_speech_assessments',
  toJSON: {
    virtuals: true,
    transform(_doc, ret) {
      delete ret._id;
      delete ret.__v;
      if (ret.audio) delete ret.audio.storedPath;
      return ret;
    },
  },
});

speechAssessmentSchema.index({ childId: 1, createdAt: -1 });

module.exports = mongoose.model('SpeechAssessment', speechAssessmentSchema);
module.exports.SEVERITY_LABELS = SEVERITY_LABELS;
module.exports.TASK_TYPES = TASK_TYPES;
