const mongoose = require('mongoose');

/**
 * Server-side LinUCB state for research logging and cross-device continuity.
 *
 * The primary LinUCB model runs on-device in Dart (linucb_activity_selector.dart).
 * This collection mirrors the per-child arm state so that:
 *  - A new device can restore a child's personalisation.
 *  - Research logs can capture model state at each update.
 *  - A future server-side Hybrid LinUCB can accumulate shared parameters.
 *
 * Hybrid LinUCB structure:
 *  Shared component:  β (shared_b vector), A₀ (shared_A matrix), B₀ (shared_B matrix)
 *  Child-specific:    per arm — A (d×d), b (d×1)
 *
 * For the current implementation, shared parameters accumulate across all children.
 * Per-child arms are stored separately with scope = 'child'.
 * The shared aggregate is stored as a single document with scope = 'shared'.
 *
 * contextDim must match linucb_activity_selector.dart → _LinUcbModel.contextSize (currently 9).
 */
const linUCBStateSchema = new mongoose.Schema({
  // 'shared' for the global shared component; childId (string) for per-child state
  scope:      { type: String, required: true },
  // linucbActionId — the stable arm identifier matching Dart's _TherapyActivityDefinition.id
  actionId:   { type: String, required: true },
  contextDim: { type: Number, required: true, default: 9 },

  // Per-arm matrices (stored as row-major flat arrays for compactness, or nested arrays)
  A:      { type: [[Number]], required: true }, // d×d design matrix (identity initialised)
  b:      { type: [Number], required: true },   // d×1 reward vector (zeros initialised)

  // Shared component fields (only populated for scope = 'shared')
  // A₀: shared feature design matrix (d_shared × d_shared)
  // B:  cross-term matrix (d_arm × d_shared)
  A0:     { type: [[Number]] },
  B:      { type: [[Number]] },
  b0:     { type: [Number] },

  // Metadata
  totalUpdates: { type: Number, default: 0 },
  totalReward:  { type: Number, default: 0 },
  alpha:        { type: Number, default: 0.8 }, // matches Dart _exploration constant
  modelVersion: { type: String, default: 'linucb_v3' },
  lastUpdated:  { type: Date, default: Date.now },
}, { timestamps: true });

// Compound unique index: one state document per (scope, actionId)
linUCBStateSchema.index({ scope: 1, actionId: 1 }, { unique: true });

module.exports = mongoose.models.LinUCBState
  || mongoose.model('LinUCBState', linUCBStateSchema);
