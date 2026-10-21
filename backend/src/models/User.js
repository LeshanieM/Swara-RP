const mongoose = require('mongoose');

const childProfileSchema = new mongoose.Schema({
  childId: { type: String, default: '' },
  firstName: { type: String, trim: true },
  age: { type: Number, min: 5, max: 14 },
}, { _id: false });

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true },
  photoUrl: { type: String, default: null },
  child: { type: childProfileSchema, default: undefined },
  role: { type: String, enum: ['parent', 'therapist', 'child'], required: true },
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
