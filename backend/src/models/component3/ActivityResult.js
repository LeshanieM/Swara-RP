const mongoose = require('mongoose');

/**
 * Per-activity result record for a C3 therapy session.
 *
 * Performance score:  P = (successfulOpportunities / targetOpportunities) × completionFraction
 * Activity reward:    r = 0.6 × performanceScore + 0.4 × engagementScore
 *
 * Both values are computed and stored by the backend on save (see pre-save hook).
 * Missing values are explicitly represented as null, not 0, to avoid confounding
 * the TSS and reward calculations.
 *
 * engagementMode: 'camera_logs' | 'logs_only' | 'unavailable'
 *   - camera_logs:  engagement derived from on-device face detection + app logs.
 *   - logs_only:    engagement derived from app-log signals only (completion, rate, timing).
 *   - unavailable:  engagement could not be estimated; engagementScore is null.
 */
const activityResultSchema = new mongoose.Schema({
  sessionId:  { type: mongoose.Schema.Types.ObjectId, ref: 'C3TherapySession', required: true, index: true },

  // --- activity identification ---
  // activityId links to the Activity collection (ObjectId or linucbActionId string).
  // linucbActionId is the stable Dart-side arm key stored alongside for cross-reference.
  activityId:       { type: String, required: true }, // linucbActionId or activity string key
  activityObjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Activity' }, // optional DB ref

  // --- performance inputs (P = (S/T) × C) ---
  targetOpportunities:      { type: Number, default: null }, // T — eligible targets presented
  successfulOpportunities:  { type: Number, default: null }, // S — targets meeting success criterion
  completionFraction:       { type: Number, default: null }, // C — 0.0–1.0; null if not measured

  // --- performance output ---
  // Null when targetOpportunities is 0 or not available for this activity type.
  performanceScore: { type: Number, default: null }, // 0.0–1.0

  // --- engagement inputs ---
  engagementScore: { type: Number, default: null }, // 0.0–1.0; null = unavailable
  engagementMode: {
    type: String,
    enum: ['camera_logs', 'logs_only', 'unavailable'],
    default: 'unavailable',
  },

  // --- derived reward (stored for LinUCB update replay) ---
  // r = 0.6 × performanceScore + 0.4 × engagementScore
  // Null when both components are null.
  reward: { type: Number, default: null }, // 0.0–1.0

  // --- parent feedback ---
  // 'too_hard' | 'just_right' | 'too_easy' | null
  parentDifficultyFeedback: { type: String, default: null },
  // 0 = none, 1 = minimal, 2 = moderate, 3 = significant
  parentHelpLevel: { type: Number, default: null },

  // --- activity lifecycle ---
  attempted:   { type: Boolean, default: true },
  completed:   { type: Boolean, default: false },
  skipped:     { type: Boolean, default: false },
  skipReason:  { type: String, default: null }, // 'too_hard' | 'not_interested' | 'time' | 'other'

  // --- timing ---
  durationSeconds:   { type: Number, default: null },
  responseTimeMs:    { type: Number, default: null }, // first response latency

  // Text-only verification metadata for defined-answer prompts; raw audio is never stored.
  speechVerification: {
    promptId: { type: String, default: null },
    expectedAnswers: { type: [String], default: [] },
    recognizedText: { type: String, default: null },
    confidence: { type: Number, default: null },
    status: { type: String, enum: ['match', 'mismatch', 'could_not_recognize', 'not_applicable'], default: 'not_applicable' },
    similarity: { type: Number, default: null },
  },

  // --- recommendation context snapshot ---
  // linucbActionId and contextVector at selection time, for replay evaluation.
  recommendationActionId: { type: String, default: null },
  contextSnapshot:        { type: [Number], default: null },
}, { timestamps: true });

/**
 * Compute performanceScore and reward before saving.
 * Missing values are left as null rather than defaulting to 0.
 */
activityResultSchema.pre('save', function (next) {
  // Performance score: P = (S / T) × C
  if (
    this.targetOpportunities != null &&
    this.targetOpportunities > 0 &&
    this.successfulOpportunities != null &&
    this.completionFraction != null
  ) {
    const raw = (this.successfulOpportunities / this.targetOpportunities) * this.completionFraction;
    this.performanceScore = Math.max(0, Math.min(1, raw));
  } else if (this.performanceScore == null) {
    this.performanceScore = null; // explicitly unavailable
  }

  // Activity reward: r = 0.6 × P + 0.4 × E
  const P = this.performanceScore;
  const E = this.engagementScore;
  if (P != null && E != null) {
    this.reward = Math.max(0, Math.min(1, 0.6 * P + 0.4 * E));
  } else if (P != null) {
    // Engagement unavailable: weight renormalised to performance only (documented rule)
    this.reward = Math.max(0, Math.min(1, P));
  } else if (E != null) {
    // Performance unavailable: weight renormalised to engagement only
    this.reward = Math.max(0, Math.min(1, E));
  } else {
    this.reward = null; // both missing — cannot compute reward
  }

  next();
});

module.exports = mongoose.models.ActivityResult
  || mongoose.model('ActivityResult', activityResultSchema);
