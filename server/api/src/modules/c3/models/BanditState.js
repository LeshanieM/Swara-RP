const mongoose = require('mongoose');

const { Schema } = mongoose;

// One "population" document (the shared Hybrid LinUCB part) and one "child" document per child (per-arm parts).
// Matrices are stored with the feature names they were built with, so a schema change can be migrated by name.
const banditStateSchema = new Schema({
  scope: { type: String, enum: ['population', 'child'], required: true },
  childId: { type: String, default: null },
  featureVersion: Number,
  featureNames: [String],
  sharedNames: [String],
  A0: [[Number]],
  b0: [Number],
  arms: { type: Schema.Types.Mixed, default: {} }, // armId → { A, B, b, n, rewardSum, lastUpdated }
  updates: { type: Number, default: 0 },
  migratedFrom: [{ _id: false, featureVersion: Number, at: Date, added: [String], removed: [String] }],
}, {
  timestamps: true,
  minimize: false,
  collection: 'c3_bandit_states',
});

banditStateSchema.index({ scope: 1, childId: 1 }, { unique: true });

module.exports = mongoose.model('C3BanditState', banditStateSchema);
