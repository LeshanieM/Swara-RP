const mongoose = require('mongoose');

/**
 * Parent Questionnaire record for a completed C3 therapy session.
 *
 * IMPORTANT RESEARCH NOTE:
 * The questionnaire used here is a short adaptation of PRIME-O principles
 * for the purposes of capturing parent-rated engagement and activity difficulty
 * as a supplementary session-level signal. It is NOT the validated PRIME-O
 * instrument, and must not be reported as such.
 *
 * The current version ('prime_o_adapt_v1') contains 5 items rated on a
 * 1–5 Likert scale. scaledScore = (sum − 5) / 20, mapping [5,25] → [0,1].
 *
 * Research data collection involving children requires ethics approval and
 * informed consent. This record must not be collected until those are in place.
 *
 * Items (version 'prime_o_adapt_v1'):
 *   Q1: My child seemed engaged during today's session (1–5)
 *   Q2: Today's activities were about the right difficulty (1–5)
 *   Q3: My child was willing to attempt the activities (1–5)
 *   Q4: I felt able to support my child during the session (1–5)
 *   Q5: Overall, I think today's session went well (1–5)
 */
const SUPPORTED_VERSIONS = ['prime_o_adapt_v1'];
const VERSION_ITEM_COUNT = { 'prime_o_adapt_v1': 5 };
const VERSION_SCORE_RANGE = { 'prime_o_adapt_v1': { min: 5, max: 25 } };

const parentQuestionnaireSchema = new mongoose.Schema({
  sessionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'C3TherapySession',
    required: true,
  },
  ownerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },

  // Questionnaire version — must be one of the supported versions above.
  version: {
    type: String,
    required: true,
    enum: SUPPORTED_VERSIONS,
  },

  // Per-item responses keyed by item ID (e.g. { Q1: 4, Q2: 3, ... }).
  responses: {
    type: Map,
    of: Number,
    required: true,
  },

  // Derived scores (computed on save).
  rawScore:    { type: Number }, // sum of item scores
  scaledScore: { type: Number }, // 0–1, used as Q in TSS formula
  completedAt: { type: Date, default: Date.now },
}, { timestamps: true });

// One questionnaire per session.
parentQuestionnaireSchema.index({ sessionId: 1 }, { unique: true });

parentQuestionnaireSchema.pre('save', function (next) {
  const version = this.version;
  const itemCount = VERSION_ITEM_COUNT[version];
  const range = VERSION_SCORE_RANGE[version];

  if (!itemCount || !range) {
    return next(new Error(`Unsupported questionnaire version: ${version}`));
  }

  // Validate item count.
  const responses = this.responses;
  if (!responses || responses.size !== itemCount) {
    return next(new Error(
      `Questionnaire version ${version} requires exactly ${itemCount} responses; ` +
      `received ${responses ? responses.size : 0}.`
    ));
  }

  // Validate individual item scores.
  let rawScore = 0;
  for (const [key, value] of responses.entries()) {
    if (typeof value !== 'number' || value < 1 || value > 5 || !Number.isInteger(value)) {
      return next(new Error(`Item ${key}: score must be an integer 1–5; received ${value}.`));
    }
    rawScore += value;
  }

  this.rawScore = rawScore;
  // scaledScore: maps [min, max] → [0, 1]
  this.scaledScore = (rawScore - range.min) / (range.max - range.min);
  this.scaledScore = Math.max(0, Math.min(1, this.scaledScore));

  next();
});

module.exports = mongoose.models.ParentQuestionnaire
  || mongoose.model('ParentQuestionnaire', parentQuestionnaireSchema);
