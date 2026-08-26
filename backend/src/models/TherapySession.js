const mongoose = require('mongoose');

const therapySessionSchema = new mongoose.Schema({
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child', required: true },
  activities: [{ type: mongoose.Schema.Types.ObjectId, ref: 'TherapyActivity' }],
  completedActivities: [{ type: mongoose.Schema.Types.ObjectId, ref: 'TherapyActivity' }],
  engagementScore: { type: Number, default: 0 },
  status: { type: String, enum: ['Pending', 'In Progress', 'Completed'], default: 'Pending' },
  isPrototype: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('TherapySession', therapySessionSchema);
