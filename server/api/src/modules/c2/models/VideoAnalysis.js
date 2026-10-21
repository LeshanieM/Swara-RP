const mongoose = require('mongoose');
const {
  INPUT_PATHS, STUTTER_SOURCES, NOT_ASSESSED_REASONS, STATUSES,
} = require('../validation/schemas');

const { Schema } = mongoose;
const CATEGORIES = ['FG', 'HM'];
const SIGNALS = ['eye', 'lip', 'jaw', 'cheek', 'head'];

// categories ({FG, HM: {present, score, scoreType}}) and signals ({eye, lip, jaw, cheek, head:
// {deviation, direction, topFeature, threshold, pValue, nullSpans, exceeds}}) are null for a
// moment that could not be assessed, so they are stored as Mixed; the contract check in
// validation/schemas.js (visionResult) guarantees their shape.
const momentSchema = new Schema({
  index: Number,
  start: Number,
  end: Number,
  duration: Number,
  types: [String],
  faceRatio: Number,
  assessed: Boolean,
  behaviourPresent: { type: Boolean, default: null },
  categories: { type: Schema.Types.Mixed, default: null },
  signals: { type: Schema.Types.Mixed, default: null },
  explanation: [String],
}, { _id: false });

const eventSchema = new Schema({
  category: { type: String, enum: CATEGORIES },
  signal: { type: String, enum: SIGNALS },
  feature: String,
  start: Number,
  end: Number,
  duration: Number,
  peakDeviation: Number,
  direction: String,
  momentIndex: Number,
}, { _id: false });

const resultSchema = new Schema({
  video: { type: Schema.Types.Mixed },
  detector: { type: Schema.Types.Mixed },
  baseline: { type: Schema.Types.Mixed },
  stutterMoments: [momentSchema],
  behaviourEvents: [eventSchema],
  counts: {
    momentsTotal: Number, momentsAssessed: Number, momentsWithBehaviour: Number, FG: Number, HM: Number, behaviourEvents: Number,
  },
  behavioursPerStutter: { FG: Number, HM: Number, any: Number },
  hasSecondaryBehaviors: { type: Boolean, default: null },
  concomitantScore: { type: Number, default: null },
  baselines: { type: Schema.Types.Mixed },
  summary: { type: Schema.Types.Mixed },
  warnings: [{ _id: false, code: String, message: String }],
  processingMs: Number,
  serviceVersion: String,
}, { _id: false });

const reviewSchema = new Schema({
  reviewerRole: { type: String, enum: ['slp', 'parent'], required: true },
  momentLabels: [{ _id: false, momentIndex: Number, FG: Boolean, HM: Boolean }],
  hasSecondaryBehaviors: Boolean,
  notes: { type: String, maxlength: 2000 },
  reviewedAt: { type: Date, default: Date.now },
}, { _id: false });

const videoAnalysisSchema = new Schema({
  childId: { type: String, required: true, trim: true },
  ageAtAssessment: { type: Number, required: true, min: 5, max: 14 },
  ageBand: { type: String, enum: ['5-10', '11-14'], required: true },
  inputPath: { type: String, enum: [...INPUT_PATHS, 'audio_only'], required: true },
  videoConsent: { type: Boolean, default: false },

  // Where the stutter moments come from: the video's own audio (a linked C1 assessment
  // created by C2), an existing C1 assessment, or spans entered by hand (research/SLP).
  stutterSource: {
    type: { type: String, enum: STUTTER_SOURCES },
    c1AssessmentId: { type: Schema.Types.ObjectId, ref: 'SpeechAssessment' },
    c1Task: { type: Schema.Types.Mixed }, // C1 task fields for the audio-track path
    spans: { type: [{ _id: false, start: Number, end: Number, types: [String] }], default: undefined },
  },
  targetFps: Number,

  status: { type: String, enum: STATUSES, default: 'queued', index: true },
  notAssessedReason: { type: String, enum: NOT_ASSESSED_REASONS },
  notes: String,
  attempts: { type: Number, default: 0 },
  runningSince: { type: Date, default: null },
  error: { _id: false, code: String, message: String, details: Schema.Types.Mixed },
  startedAt: Date,
  completedAt: Date,

  video: {
    originalName: String,
    mimeType: String,
    sizeBytes: Number,
    storedPath: { type: String, select: false },
    deleted: { type: Boolean, default: false },
    deletedAt: Date,
  },

  result: resultSchema,

  // SLP/parent reference labels, append-only (the child test set and calibration data).
  reviews: [reviewSchema],
}, {
  timestamps: true,
  collection: 'c2_video_analyses',
  toJSON: {
    virtuals: true,
    transform(_doc, ret) {
      delete ret._id;
      delete ret.__v;
      delete ret.runningSince;
      if (ret.video) delete ret.video.storedPath;
      if (ret.status === 'not_assessed') delete ret.video; // path C has no video at all
      return ret;
    },
  },
});

videoAnalysisSchema.index({ childId: 1, createdAt: -1 });

module.exports = mongoose.model('VideoAnalysis', videoAnalysisSchema);
