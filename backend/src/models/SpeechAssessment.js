const mongoose = require('mongoose');

const speechAssessmentSchema = new mongoose.Schema({
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child', required: true },
  childCode: { type: String }, // e.g. 'CH-001'
  recordedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  
  // Section 2: Task metadata
  taskType: { 
    type: String, 
    enum: ['picture-description', 'passage-reading', 'Reading Practice', 'Picture Description', 'unknown'],
    default: 'picture-description'
  },
  childAge: { type: Number },
  
  // Core Stuttering Classification (C1/C2/C3 compatibility)
  stutterDetected: { type: Boolean, required: true },
  stutterType: { 
    type: String, 
    enum: ['Repetition', 'Prolongation', 'Block', 'Mixed', 'None', 'Sound Repetition', 'Word Repetition', 'Interjection'],
    default: 'None'
  },
  severity: { 
    type: String, 
    enum: ['Mild', 'Moderate', 'Severe', 'None', 'Unavailable'],
    default: 'None'
  },
  confidence: { type: Number, default: 0 },
  
  // Granular Event Timeline (for Flutter fl_chart and C2 fusion)
  detectedEvents: [{
    startTime: { type: Number, required: true },
    endTime: { type: Number, required: true },
    eventType: { type: String, required: true },
    confidence: { type: Number, default: 0 },
    duration: { type: Number, default: 0 },
  }],

  // Event category counts
  eventCounts: {
    blocks: { type: Number, default: 0 },
    prolongations: { type: Number, default: 0 },
    soundRepetitions: { type: Number, default: 0 },
    wordRepetitions: { type: Number, default: 0 },
    interjections: { type: Number, default: 0 },
    total: { type: Number, default: 0 },
  },

  // Section 5: Syllable Metrics & %SS
  syllableMetrics: {
    totalSyllables: { type: Number, default: 0 },
    stutteredSyllables: { type: Number, default: 0 },
    percentSyllablesStuttered: { type: Number, default: 0 }, // %SS
    syllableCountMethod: { type: String, default: 'Acoustic Intensity Nucleus Peak Detection' },
    isReliable: { type: Boolean, default: true },
  },

  // Duration Metrics
  durationMetrics: {
    totalDuration: { type: Number, default: 0 },
    speechDuration: { type: Number, default: 0 },
    longestEventDuration: { type: Number, default: 0 },
    averageEventDuration: { type: Number, default: 0 },
  },

  // Legacy & C2/C3 compatible acoustic features
  features: {
    duration: { type: Number, default: 0 },
    pauseCount: { type: Number, default: 0 },
    averagePauseDuration: { type: Number, default: 0 },
    speechRate: { type: Number, default: 0 },
    estimatedWordCount: { type: Number, default: 0 },
  },

  // Pipeline execution & reproducibility
  analysisId: { type: String },
  analysisStatus: { 
    type: String, 
    enum: ['completed', 'failed', 'weights_unavailable', 'partial'],
    default: 'completed'
  },
  modelInfo: {
    modelName: { type: String },
    featureExtractor: { type: String },
    classifierType: { type: String },
    weightsLoaded: { type: Boolean, default: false },
    isTrained: { type: Boolean, default: false },
    version: { type: String },
  },
  warnings: [{ type: String }],
  clinicalDisclaimer: { type: String },
  audioUrl: { type: String },
  isPrototype: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('SpeechAssessment', speechAssessmentSchema);
