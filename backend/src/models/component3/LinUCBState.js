const mongoose = require('mongoose');

const linUCBStateSchema = new mongoose.Schema({
  activityId: { type: mongoose.Schema.Types.ObjectId, ref: 'Activity', required: true },
  A: { type: [[Number]], required: true }, // Activity-specific matrix A
  b: { type: [Number], required: true },   // Activity-specific reward vector b
  alpha: { type: Number, default: 0.1 },
  lastUpdated: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('LinUCBState', linUCBStateSchema);
