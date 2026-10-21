const mongoose = require('mongoose');

const { Schema } = mongoose;
// abandoned: an unfinished session past the resume window (config.resumeHours), closed by the server.
const STATUSES = ['active', 'completed', 'abandoned'];
const C2_FLAGS = ['yes', 'no', 'missing'];
const BREAK_REASONS = ['low_engagement', 'requested', 'other'];

const breakSchema = new Schema({
  at: { type: Date, default: Date.now },
  durationSec: Number,
  reason: { type: String, enum: BREAK_REASONS },
  elapsedMinAtStart: Number,
}, { _id: false });

const questionnaireSchema = new Schema({
  version: String,
  answers: { type: Map, of: Number },
  meanScore: Number,
  q: Number, // mean answer scaled to 0–1
  engaged: Boolean, // mean ≥ the questionnaire's engagedThreshold; the calibration label
  respondent: { type: String, enum: ['parent'] },
  language: { type: String, enum: ['si', 'en'] },
  submittedAt: Date,
}, { _id: false });

const outcomeSchema = new Schema({
  activitiesCompleted: Number,
  activitiesSkipped: Number,
  activitiesAbandoned: Number,
  meanPerformance: Number, // P̄ (skips count as 0)
  meanEngagement: Number, // Ē
  questionnaireScore: Number, // Q, or null
  weights: { performance: Number, engagement: Number, questionnaire: Number },
  tss: Number, // 0–100, or null when no activity was done
  engagementModes: { type: Map, of: Number },
  fluency: Schema.Types.Mixed, // C1 %SS change, reported next to the TSS (not weighted into it yet)
  computedAt: Date,
}, { _id: false });

const therapySessionSchema = new Schema({
  childId: { type: String, required: true, trim: true },
  ageAtSession: { type: Number, required: true, min: 5, max: 14 },
  ageBand: { type: String, enum: ['5-10', '11-14'], required: true },
  language: { type: String, enum: ['si', 'en'], default: 'si' },
  cameraOn: { type: Boolean, default: false },
  plannedMinutes: { type: Number, default: 25 },
  maxActivities: { type: Number, default: 5 }, // completed + skipped activities before the session ends
  c2Flag: { type: String, enum: C2_FLAGS, default: 'missing' },
  // 'c2': read from the C2 module's latest analysis; 'client': sent by the app because C2 had no yes / no.
  c2FlagSource: { type: String, enum: ['c2', 'client', 'none'], default: 'none' },
  c2AnalysisId: { type: String, default: null }, // the C2 analysis the flag came from
  c2BehaviourTypes: { type: [String], default: [] }, // FG / HM seen in that analysis
  c2FlagClient: { type: String, enum: [...C2_FLAGS, null], default: null }, // what the app sent, kept for the record
  status: { type: String, enum: STATUSES, default: 'active', index: true },
  policy: String,
  rewardMode: String,
  contextAtStart: Schema.Types.Mixed, // named base context and its sources, for the record
  breaks: [breakSchema],
  questionnaire: questionnaireSchema,
  outcome: outcomeSchema,
  completedAt: Date,
  abandonedAt: Date,
}, {
  timestamps: true,
  collection: 'c3_therapy_sessions',
  toJSON: {
    virtuals: true,
    transform: (_doc, ret) => { delete ret._id; delete ret.__v; return ret; },
  },
});

therapySessionSchema.index({ childId: 1, createdAt: -1 });

const TherapySession = mongoose.model('C3TherapySession', therapySessionSchema);
TherapySession.C2_FLAGS = C2_FLAGS;
TherapySession.STATUSES = STATUSES;
TherapySession.BREAK_REASONS = BREAK_REASONS;
module.exports = TherapySession;
