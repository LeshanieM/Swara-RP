const mongoose = require('mongoose');

const childSchema = new mongoose.Schema({
  childId: { type: String, unique: true, required: true },
  firstName: { type: String, required: true, trim: true },
  age: { type: Number, required: true },
  gender: { type: String },
  dateOfBirth: { type: Date },
  interests: [{ type: String }],
  severity: { type: String, enum: ['Mild', 'Moderate', 'Severe'] },
  stutterType: { type: String, enum: ['Repetition', 'Prolongation', 'Block', 'Mixed'] },
  parentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  therapistId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  supportIndicator: { type: Number },
  communicationScore: { type: Number },
  assignedTheme: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('Child', childSchema);
