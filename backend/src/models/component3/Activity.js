const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema({
  activityId: { type: String, unique: true, required: true },
  name: { type: String, required: true },
  description: { type: String },
  technique: { type: String, required: true }, // e.g., "Pausing/Phrasing"
  therapeuticPurpose: { type: String },
  activityType: { type: String, required: true }, // e.g., "picture_description"
  ageRange: [{ type: Number }], // [min, max]
  difficulty: { type: Number, required: true },
  prerequisites: [{ type: String }],
  instructions: { type: String },
  materials: { type: String },
  targetType: { type: String },
  targetDefinition: { type: String },
  active: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Activity', activitySchema);
