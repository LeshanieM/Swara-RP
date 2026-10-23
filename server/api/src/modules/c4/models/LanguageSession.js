const mongoose = require('mongoose');

const { Schema } = mongoose;
const bilingual = { _id: false, en: String, si: String };

const topicSchema = new Schema({
  id: String,
  categoryId: String,
  level: { type: String, enum: ['concrete', 'open'] },
  title: bilingual,
  mainPrompt: bilingual,
  followUps: [bilingual],
}, { _id: false });

// One session = one topic (plus any topics offered before a main-prompt skip).
const languageSessionSchema = new Schema({
  childId: { type: String, required: true, trim: true, index: true },
  age: { type: Number, required: true },
  ageBand: { type: String, enum: ['5-10', '11-14'], required: true },
  language: { type: String, enum: ['si', 'en'], default: 'si' },
  mode: { type: String, enum: ['personalised', 'fixed'], required: true },
  status: { type: String, enum: ['open', 'recorded'], default: 'open' },

  topic: topicSchema,
  // The draw that chose the current topic: policy, every candidate's weights and the seed.
  selection: { type: Schema.Types.Mixed },
  progressSignal: { type: Schema.Types.Mixed },
  // The prompt on screen: -1 is the main prompt, 0.. a follow-up. Skips move it forward.
  currentPrompt: { type: Number, default: -1 },
  offeredTopicIds: [String],
  skips: [{
    _id: false,
    kind: { type: String, enum: ['follow_up', 'main_prompt'] },
    topicId: String,
    followUpIndex: Number,
    reason: String,
    replacedByTopicId: String,
    at: { type: Date, default: Date.now },
  }],
  sampleIds: [{ type: Schema.Types.ObjectId }],
}, {
  timestamps: true,
  collection: 'c4_sessions',
  toJSON: {
    virtuals: true,
    transform(_doc, ret) {
      delete ret._id;
      delete ret.__v;
      return ret;
    },
  },
});

languageSessionSchema.index({ childId: 1, createdAt: -1 });

module.exports = mongoose.model('LanguageSession', languageSessionSchema);
