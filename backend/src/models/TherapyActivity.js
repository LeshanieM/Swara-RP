const mongoose = require('mongoose');

const therapyActivitySchema = new mongoose.Schema({
  activityId: { type: String, unique: true, required: true },
  name: { type: String, required: true },
  description: { type: String, required: true },
  ageRange: [{ type: Number }], // [min, max]
  severity: [{ type: String, enum: ['Mild', 'Moderate', 'Severe'] }],
  stutterTypes: [{ type: String, enum: ['Repetition', 'Prolongation', 'Block', 'Mixed'] }],
  difficulty: { type: String, enum: ['Beginner', 'Intermediate', 'Advanced'] },
  duration: { type: Number }, // in minutes
  theme: { type: String },
  therapistNotes: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('TherapyActivity', therapyActivitySchema);
