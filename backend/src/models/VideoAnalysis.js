const mongoose = require('mongoose');

/**
 * Metadata + cached results for a Component 2 computer-vision experiment run.
 * Raw child video is NEVER stored: the upload is a temp file deleted right
 * after being forwarded to the AI service.
 */
const videoAnalysisSchema = new mongoose.Schema(
  {
    analysisId: { type: String, required: true, unique: true, index: true }, // id issued by the FastAPI service
    childId: { type: String, required: true, index: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    video: {
      filename: String,
      sizeBytes: Number,
      storedPermanently: { type: Boolean, default: false },
    },
    technologiesRequested: [String],
    status: {
      type: String,
      enum: ['queued', 'processing', 'completed', 'failed'],
      default: 'queued',
    },
    progress: {
      completed: { type: Number, default: 0 },
      total: { type: Number, default: 0 },
      currentTechnology: String,
    },
    results: { type: mongoose.Schema.Types.Mixed }, // full standardized payload from the AI service
    groundTruthProvided: { type: Boolean, default: false },
    error: String,
    completedAt: Date,
  },
  { timestamps: true }
);

module.exports = mongoose.model('VideoAnalysis', videoAnalysisSchema);
