const mongoose = require('mongoose');

const progressRecordSchema = new mongoose.Schema({
  childId: { type: mongoose.Schema.Types.ObjectId, ref: 'Child', required: true },
  sessionNumber: { type: Number, required: true },
  date: { type: Date, required: true },
  speechScore: { type: Number },
  communicationScore: { type: Number },
  therapyScore: { type: Number },
  notes: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('ProgressRecord', progressRecordSchema);
