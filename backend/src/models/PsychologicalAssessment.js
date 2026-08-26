const mongoose = require('mongoose');

const psychologicalAssessmentSchema = new mongoose.Schema({
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child', required: true },
  score: { type: Number, required: true },
  level: { type: String, enum: ['Low', 'Medium', 'High'] },
  supportAreas: [{
    area: String,
    score: Number,
    suggestions: [String]
  }],
  caregiverGuidance: { type: String },
  answers: { type: Map, of: Number },
  isPrototype: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('PsychologicalAssessment', psychologicalAssessmentSchema);
