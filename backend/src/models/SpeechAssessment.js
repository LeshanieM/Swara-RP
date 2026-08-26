const mongoose = require('mongoose');

const speechAssessmentSchema = new mongoose.Schema({
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child', required: true },
  stutterDetected: { type: Boolean, required: true },
  stutterType: { type: String, enum: ['Repetition', 'Prolongation', 'Block', 'Mixed', 'None'] },
  severity: { type: String, enum: ['Mild', 'Moderate', 'Severe', 'None'] },
  confidence: { type: Number },
  features: {
    duration: Number,
    pauseCount: Number,
    averagePauseDuration: Number,
    speechRate: Number,
    estimatedWordCount: Number,
  },
  audioUrl: { type: String },
  isPrototype: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('SpeechAssessment', speechAssessmentSchema);
