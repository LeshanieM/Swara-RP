const mongoose = require('mongoose');

const therapySessionSchema = new mongoose.Schema({
  sessionId: { type: String, unique: true, required: true },
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child', required: true },
  planId: { type: mongoose.Schema.Types.ObjectId, ref: 'Component3TherapyPlan', required: true },
  startTime: { type: Date, default: Date.now },
  endTime: { type: Date },
  selectedActivities: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Component3Activity' }],
  status: { type: String, enum: ['Pending', 'In Progress', 'Completed', 'Terminated'], default: 'Pending' }
}, { timestamps: true });

module.exports = mongoose.model('Component3TherapySession', therapySessionSchema);
