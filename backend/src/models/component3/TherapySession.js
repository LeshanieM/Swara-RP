const mongoose = require('mongoose');

const therapySessionSchema = new mongoose.Schema({
  sessionId: { type: String, unique: true, required: true },
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child' },
  planId: { type: mongoose.Schema.Types.ObjectId, ref: 'TherapyPlan' },
  startTime: { type: Date, default: Date.now },
  endTime: { type: Date },
  selectedActivities: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Activity' }],
  resultSummary: { type: mongoose.Schema.Types.Mixed },
  status: { type: String, enum: ['Pending', 'In Progress', 'Completed', 'Terminated'], default: 'Pending' }
}, { timestamps: true });

module.exports = mongoose.models.C3TherapySession ||
  mongoose.model('C3TherapySession', therapySessionSchema, 'therapysessions');
