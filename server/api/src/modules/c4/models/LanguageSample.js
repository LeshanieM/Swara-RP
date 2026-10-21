const mongoose = require('mongoose');

const { Schema } = mongoose;
const STATUSES = ['queued', 'processing', 'completed', 'failed'];
const BAND_VALUES = ['below', 'stable', 'gaining', 'baseline_building', 'not_reliable'];

const transcriptVersionSchema = new Schema({
  version: Number,
  kind: { type: String, enum: ['asr', 'corrected', 'manual'] },
  text: String,
  editedBy: { type: String, enum: ['system', 'parent', 'slp'] },
  createdAt: { type: Date, default: Date.now },
}, { _id: false });

// Measures for every transcript version, kept for the raw vs corrected vs manual (ICC) comparison.
const measuresVersionSchema = new Schema({
  version: Number,
  kind: String,
  measures: { type: Schema.Types.Mixed },
  syllables: { type: Schema.Types.Mixed },
  mazes: { type: Schema.Types.Mixed },
  flags: [String],
  percentSS: Number,
  createdAt: { type: Date, default: Date.now },
}, { _id: false });

const confirmationSchema = new Schema({
  by: { type: String, enum: ['parent', 'slp'] },
  decision: { type: String, enum: ['confirm', 'override'] },
  band: { type: String, enum: ['below', 'stable', 'gaining'] },
  computedBand: String,
  notes: String,
  at: { type: Date, default: Date.now },
}, { _id: false });

// One recording from a C4 session and everything computed from it.
const languageSampleSchema = new Schema({
  childId: { type: String, required: true, trim: true },
  sessionId: { type: Schema.Types.ObjectId, required: true, index: true },
  age: Number,
  ageBand: { type: String, enum: ['5-10', '11-14'] },
  language: { type: String, enum: ['si', 'en'], default: 'si' },
  mode: { type: String, enum: ['personalised', 'fixed'] },
  topicId: String,
  categoryId: String,
  topicLevel: String,

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
  // A transcript typed at upload time: ASR is skipped and it becomes version 1 ("manual").
  uploadTranscript: { type: String, select: false },

  asr: { type: Schema.Types.Mixed },                // language-service /transcribe output (null when skipped)
  transcripts: [transcriptVersionSchema],
  currentVersion: Number,
  analysis: { type: Schema.Types.Mixed },           // language-service /measures output for the current version
  measuresByVersion: [measuresVersionSchema],

  // Spontaneous-speech stuttering from C1's detector (C1 owns the %SS method).
  stuttering: { type: Schema.Types.Mixed },

  // Recomputed for the whole child whenever a sample is added, edited or deleted.
  vocabulary: { type: Schema.Types.Mixed },
  band: {
    _id: false,
    computed: { type: String, enum: BAND_VALUES },
    effective: { type: String, enum: BAND_VALUES },
    change: { type: Schema.Types.Mixed },
    baseline: { type: Schema.Types.Mixed },
    confirmations: [confirmationSchema],
  },
}, {
  timestamps: true,
  collection: 'c4_language_samples',
  toJSON: {
    virtuals: true,
    transform(_doc, ret) {
      delete ret._id;
      delete ret.__v;
      if (ret.audio) delete ret.audio.storedPath;
      delete ret.uploadTranscript;
      return ret;
    },
  },
});

languageSampleSchema.index({ childId: 1, createdAt: 1 });

module.exports = mongoose.model('LanguageSample', languageSampleSchema);
module.exports.BAND_VALUES = BAND_VALUES;
