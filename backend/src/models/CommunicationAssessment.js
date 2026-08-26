const mongoose = require('mongoose');

const communicationAssessmentSchema = new mongoose.Schema({
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child', required: true },
  taskId: { type: String, required: true },
  scores: {
    keywordRelevance: Number,
    responseLength: Number,
    speechFluency: Number,
    responseOrganization: Number,
  },
  overallScore: { type: Number, required: true },
  status: { type: String, enum: ['Improving', 'Stable', 'Needs Review'] },
  audioUrl: { type: String },
  isPrototype: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('CommunicationAssessment', communicationAssessmentSchema);
