const mongoose = require('mongoose');

const therapyOutcomeSchema = new mongoose.Schema({
  sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'TherapySession', required: true },
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child', required: true },
  planId: { type: mongoose.Schema.Types.ObjectId, ref: 'TherapyPlan', required: true },
  TSS: { type: Number, required: true }, // Therapy Success Score (0-100)
  normalizedReward: { type: Number, required: true }, // Reward for LinUCB (0-1)
}, { timestamps: true });

module.exports = mongoose.model('TherapyOutcome', therapyOutcomeSchema);
