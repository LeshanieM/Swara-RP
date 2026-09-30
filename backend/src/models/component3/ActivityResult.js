const mongoose = require('mongoose');

const activityResultSchema = new mongoose.Schema({
  sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Component3TherapySession', required: true },
  activityId: { type: mongoose.Schema.Types.ObjectId, ref: 'Component3Activity', required: true },
  targetOpportunities: { type: Number, required: true },
  successfulOpportunities: { type: Number, required: true },
  performanceRate: { type: Number },
  attempted: { type: Boolean, default: true },
  completed: { type: Boolean, default: true },
  duration: { type: Number } // duration in seconds
}, { timestamps: true });

// Pre-save hook to calculate performanceRate
activityResultSchema.pre('save', function(next) {
  if (this.targetOpportunities && this.targetOpportunities > 0) {
    this.performanceRate = this.successfulOpportunities / this.targetOpportunities;
  }
  next();
});

module.exports = mongoose.model('Component3ActivityResult', activityResultSchema);
