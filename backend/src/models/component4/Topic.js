const mongoose = require('mongoose');

const topicSchema = new mongoose.Schema({
  topicId: { type: String, required: true, unique: true },
  ageBand: { type: String, enum: ['5-10', '11-14'], required: true, index: true },
  category: { type: String, required: true, index: true },
  prompt_si: { type: String, required: true },
  prompt_en: { type: String, required: true },
  followUps_si: { type: [String], validate: v => v.length >= 2 && v.length <= 3 },
  level: { type: String, enum: ['concrete', 'open'], required: true },
  approvalStatus: { type: String, enum: ['unreviewed', 'approved', 'rejected'], default: 'unreviewed', index: true },
}, { timestamps: true });

module.exports = mongoose.model('C4Topic', topicSchema);
