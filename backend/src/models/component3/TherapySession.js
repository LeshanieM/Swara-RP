const mongoose = require('mongoose');

/**
 * C3 Therapy Session.
 *
 * TSS formula (research measure — not a validated clinical score):
 *   TSS = 100 × (0.5 × P̄ + 0.3 × Ē + 0.2 × Q)
 *
 * Where:
 *   P̄  = mean available activity performanceScore (0–1)
 *   Ē  = mean available activity engagementScore (0–1)
 *   Q  = parentQuestionnaire.scaledScore (0–1)
 *
 * If questionnaire is missing, TSS is renormalised over P and E only:
 *   TSS = 100 × (0.625 × P̄ + 0.375 × Ē)   [weights 5:3 preserve their ratio]
 * Similar renormalisation applies if P or E is entirely missing.
 * If all three components are missing, TSS is null.
 *
 * tssComponents stores the individual mean values used, for transparency.
 */
const parentQuestionnaireSchema = new mongoose.Schema({
  // Questionnaire version string — must match the version served by the endpoint.
  version:     { type: String, required: true },
  // Raw per-item responses, keyed by item identifier.
  responses:   { type: mongoose.Schema.Types.Mixed },
  // Total questionnaire score (sum or weighted sum of item scores).
  rawScore:    { type: Number },
  // scaledScore: questionnaire score normalised to 0–1.
  scaledScore: { type: Number },
  completedAt: { type: Date },
}, { _id: false });

const tssComponentsSchema = new mongoose.Schema({
  meanPerformance: { type: Number }, // P̄ — null if no valid performance observations
  meanEngagement:  { type: Number }, // Ē — null if no valid engagement observations
  questionnaireQ:  { type: Number }, // Q — null if questionnaire not completed
  // Weights actually used (sum to 1.0); may differ from defaults if data is missing.
  weightPerformance: { type: Number },
  weightEngagement:  { type: Number },
  weightQuestionnaire: { type: Number },
}, { _id: false });

const therapySessionSchema = new mongoose.Schema({
  // --- identifiers ---
  sessionId: { type: String, unique: true, required: true },
  ownerId:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  childId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Child' },
  planId:    { type: mongoose.Schema.Types.ObjectId, ref: 'TherapyPlan' }, // optional

  // --- timing ---
  startTime: { type: Date, default: Date.now },
  endTime:   { type: Date },

  // --- activities ---
  selectedActivities: [{ type: String }], // linucbActionIds of activities in session plan

  // --- result summary (kept for backward compatibility with Flutter history screen) ---
  resultSummary: { type: mongoose.Schema.Types.Mixed },

  // --- TSS (research measure) ---
  tss:            { type: Number, default: null }, // 0–100; null until session completed
  tssComponents:  { type: tssComponentsSchema, default: null },

  // --- parent questionnaire ---
  parentQuestionnaire: { type: parentQuestionnaireSchema, default: null },

  // --- recommender metadata ---
  // Context vector used for the first recommendation in this session.
  contextSnapshot: { type: [Number], default: null },
  modelVersion:    { type: String, default: null }, // e.g. 'linucb_v3'

  // --- lifecycle ---
  status: {
    type: String,
    enum: ['Pending', 'In Progress', 'Completed', 'Terminated'],
    default: 'Pending',
  },
}, { timestamps: true });

module.exports = mongoose.models.C3TherapySession
  || mongoose.model('C3TherapySession', therapySessionSchema, 'therapysessions');
