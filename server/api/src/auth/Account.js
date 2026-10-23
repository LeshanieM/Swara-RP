const mongoose = require('mongoose');

const { Schema } = mongoose;

const toJSON = {
  virtuals: true,
  transform(_doc, ret) {
    delete ret._id;
    delete ret.__v;
    delete ret.passwordHash;
    delete ret.parentPinHash;
    return ret;
  },
};

// One login per child (set up by a parent, who also sets the parent-mode PIN), or a therapist login.
const accountSchema = new Schema({
  email: { type: String, required: true, unique: true, trim: true, lowercase: true },
  passwordHash: { type: String, required: true },
  role: { type: String, enum: ['child', 'therapist'], required: true },
  name: { type: String, required: true, trim: true },
  child: {
    _id: false,
    childId: { type: String, trim: true },
    firstName: { type: String, trim: true },
    age: { type: Number, min: 5, max: 14 },
  },
  parentPinHash: String,
}, { timestamps: true, collection: 'accounts', toJSON });

accountSchema.index({ 'child.childId': 1 }, { unique: true, partialFilterExpression: { 'child.childId': { $type: 'string' } } });

module.exports = mongoose.model('Account', accountSchema);
