const mongoose = require('mongoose');

const physicalConcomitantsSchema = new mongoose.Schema({
  score: { type: Number, default: 0 },
  candidateEvents: { type: Number, default: 0 },
  confidence: { type: Number, default: 0 },
}, { _id: false });

const concomitantAssessmentSchema = new mongoose.Schema({
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child', required: true },
  speechAssessmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'SpeechAssessment' }, // Comp 1 link
  taskType: { type: String, required: true },
  audioUrl: { type: String },
  videoUrl: { type: String },
  duration: { type: Number },
  analysisStatus: { type: String, enum: ['pending', 'processing', 'completed', 'failed'], default: 'completed' },
  
  physicalConcomitants: {
    facialTension: { type: physicalConcomitantsSchema, default: () => ({}) },
    eyeMovements: { type: physicalConcomitantsSchema, default: () => ({}) },
    headMovements: { type: physicalConcomitantsSchema, default: () => ({}) },
    extremityMovements: { type: physicalConcomitantsSchema, default: () => ({}) }
  },

  vocalAvoidanceIndicators: {
    responseLatency: { 
      baseline: Number,
      elevated: Boolean,
      timestamps: [Number]
    },
    wordSubstitution: [{
      originalWord: String,
      detectedAlternative: String,
      confidence: Number,
      timestamp: Number
    }],
    circumlocution: [{
      utterance: String,
      confidence: Number,
      timestamp: Number
    }],
    acousticTension: {
      summary: String,
      candidateTimestamps: [Number],
      confidence: Number
    }
  },

  eventTimeline: [{
    timestamp: Number,
    eventType: String,
    source: String, // 'Component 1' or 'Component 2'
    details: String,
    confidence: Number
  }],

  modelConfidence: { type: Number, default: 0 },
  
  clinicianVerification: {
    status: { type: String, enum: ['Pending', 'Confirmed', 'Needs Review', 'Rejected'], default: 'Pending' },
    notes: String,
    verifiedAt: Date,
    verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
  },

  isPrototype: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('ConcomitantAssessment', concomitantAssessmentSchema);
