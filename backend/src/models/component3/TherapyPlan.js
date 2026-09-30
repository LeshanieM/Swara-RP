const mongoose = require('mongoose');

const therapyPlanSchema = new mongoose.Schema({
  planId: { type: String, unique: true, required: true },
  therapeuticGoal: { type: String, required: true },
  activities: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Component3Activity' }],
  sequence: [{ type: Number }], // Defines ordering if any
  active: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Component3TherapyPlan', therapyPlanSchema);
