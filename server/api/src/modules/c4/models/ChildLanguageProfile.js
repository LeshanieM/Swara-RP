const mongoose = require('mongoose');

const { Schema } = mongoose;

const toJSON = {
  virtuals: true,
  transform(_doc, ret) {
    delete ret._id;
    delete ret.__v;
    return ret;
  },
};

// One per child: onboarding interests, the parent checklist and parent-supplied known words.
const childLanguageProfileSchema = new Schema({
  childId: { type: String, required: true, unique: true, trim: true },
  age: { type: Number, required: true, min: 5, max: 14 },
  ageBand: { type: String, enum: ['5-10', '11-14'], required: true },
  language: { type: String, enum: ['si', 'en'], default: 'si' },
  // Exactly 5 category ids from the band, most favourite first (weights 5:4:3:2:1).
  rankedCategories: [{ type: String }],

  checklist: {
    _id: false,
    version: String,
    ageBand: String,
    respondent: { type: String, enum: ['parent', 'slp'] },
    // No default, so a profile without a checklist shows none instead of an empty one.
    answers: { type: [{ _id: false, itemId: String, answer: Boolean }], default: undefined },
    yesCount: Number,
    startingLevel: { type: String, enum: ['emerging', 'developing', 'established'] },
    completedAt: Date,
  },

  // Words the parent says the child already uses; they never count as "new".
  knownWords: [{ _id: false, word: String, stem: String }],
  knownWordsUpdatedAt: Date,
}, { timestamps: true, collection: 'c4_profiles', toJSON });

module.exports = mongoose.model('ChildLanguageProfile', childLanguageProfileSchema);
