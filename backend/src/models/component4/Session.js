const mongoose = require('mongoose');

const utteranceSchema = new mongoose.Schema({
  utteranceId: String, text: String, start: Number, end: Number, wordCount: Number,
  syllableCount: Number, complexityProxy: Number, c1EventOverlap: { type: Boolean, default: null },
  c1EventTypes: [String],
}, { _id: false });

const sessionSchema = new mongoose.Schema({
  sessionId: { type: String, required: true, unique: true },
  ownerId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child', required: true, index: true },
  topicId: String, topicCategory: String, topicHistory: [{ topicId: String, action: String, at: Date }],
  recording: { fileName: String, mimeType: String, durationSeconds: Number, storageReference: String },
  originalTranscript: String, correctedTranscript: String, asr: { status: String, model: String, version: String, error: String },
  utterances: [utteranceSchema], languageMeasures: mongoose.Schema.Types.Mixed,
  c1: { assessmentId: String, model: String, percentSS: Number, events: [mongoose.Schema.Types.Mixed], status: String },
  shortSample: { type: Boolean, default: true }, reliabilityFlags: [String],
  status: { type: String, enum: ['created', 'processing', 'completed', 'failed', 'skipped'], default: 'created', index: true },
  error: String,
}, { timestamps: true });

sessionSchema.index({ childId: 1, createdAt: -1 });
module.exports = mongoose.model('C4Session', sessionSchema);
