const mongoose = require('mongoose');

const { Schema } = mongoose;

// Engagement-model versions fitted by calibration against the parent questionnaire. The provisional model in
// data/engagementModel.json is used until one of these is activated.
const engagementModelSchema = new Schema({
  version: { type: String, required: true, unique: true },
  basedOn: String,
  active: { type: Boolean, default: false, index: true },
  modes: Schema.Types.Mixed, // same shape as data/engagementModel.json "modes"
  training: Schema.Types.Mixed, // n, label rule, class balance, metrics, hyper-parameters
  activatedAt: Date,
}, {
  timestamps: true,
  collection: 'c3_engagement_models',
  toJSON: {
    virtuals: true,
    transform: (_doc, ret) => { delete ret._id; delete ret.__v; return ret; },
  },
});

module.exports = mongoose.model('C3EngagementModel', engagementModelSchema);
