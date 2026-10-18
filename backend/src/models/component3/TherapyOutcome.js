const mongoose = require('mongoose');

/**
 * Stores the final session-level TSS outcome after a session is completed.
 * planId is optional — sessions can be completed without a formal plan.
 */
const therapyOutcomeSchema = new mongoose.Schema({
  sessionId:       { type: mongoose.Schema.Types.ObjectId, ref: 'C3TherapySession', required: true },
  childId:         { type: mongoose.Schema.Types.ObjectId, ref: 'Child' }, // optional if session has no childId
  planId:          { type: mongoose.Schema.Types.ObjectId, ref: 'TherapyPlan' }, // optional
  TSS:             { type: Number, required: true }, // 0–100 composite research measure
  normalizedReward:{ type: Number, required: true }, // TSS / 100, used as LinUCB reward signal
  // Per-component breakdown for research transparency.
  meanPerformance: { type: Number, default: null },
  meanEngagement:  { type: Number, default: null },
  questionnaireQ:  { type: Number, default: null },
}, { timestamps: true });

module.exports = mongoose.models.TherapyOutcome
  || mongoose.model('TherapyOutcome', therapyOutcomeSchema);
