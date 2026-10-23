const mongoose = require('mongoose');

const { Schema } = mongoose;
const STATUSES = ['pending', 'completed', 'skipped', 'abandoned'];
const FEEDBACK = ['too_hard', 'just_right', 'too_easy'];
const WORD_DECISIONS = ['match', 'mismatch', 'unclear'];

const resultSchema = new Schema({
  skipped: Boolean,
  targets: Number,
  successes: Number,
  completedShare: Number,
  attempts: Number,
  responseLatencyMs: Number,
  taps: Number,
  durationSec: Number,
  earlyExit: Boolean,
  parentHelp: Number, // 0 none … 3 the parent did most of it; context only, never the reward
  parentFeedback: { type: String, enum: FEEDBACK },
  camera: {
    facePresentRatio: Number, yawStdDeg: Number, pitchStdDeg: Number, eyeOpenMean: Number, smileMean: Number,
    windows: Schema.Types.Mixed, // the 10-second window numbers the camera model scored
  },
}, { _id: false });

// One recording of one target word, checked by the language service (word activities only).
const wordCheckSchema = new Schema({
  wordIndex: { type: Number, required: true },
  expected: { type: String, required: true },
  alternatives: [String],
  decision: { type: String, enum: WORD_DECISIONS, required: true }, // the automatic decision
  heard: String,
  heardRaw: String,
  similarity: Number,
  confidence: Number,
  scores: Schema.Types.Mixed,
  reasons: [String],
  engine: Schema.Types.Mixed,
  methodVersion: String,
  audio: { originalName: String, durationSec: Number, deleted: { type: Boolean, default: true } },
  // A parent or SLP correction; it overrides the automatic decision and is the ground truth for calibration.
  review: {
    decision: { type: String, enum: ['match', 'mismatch'] },
    by: { type: String, enum: ['parent', 'slp'] },
    notes: String,
    at: Date,
  },
}, {
  timestamps: { createdAt: true, updatedAt: false },
  // checkId is what the review route takes.
  toJSON: { transform: (_doc, ret) => { ret.checkId = String(ret._id); delete ret._id; return ret; } },
});

const activityAttemptSchema = new Schema({
  sessionId: { type: Schema.Types.ObjectId, ref: 'C3TherapySession', required: true },
  childId: { type: String, required: true },
  ageBand: { type: String, required: true },
  sequence: { type: Number, required: true },
  status: { type: String, enum: STATUSES, default: 'pending' },

  // What was recommended
  armId: { type: String, required: true },
  type: String,
  difficulty: String,
  itemId: String,
  parentLed: { type: Boolean, default: false },
  elapsedMinAtStart: Number,

  // How it was chosen (kept for replay evaluation)
  policy: String,
  alpha: Number,
  epsilon: Number,
  explored: Boolean, // picked by the ε-random branch
  propensity: Number, // probability the logging policy picked this arm
  candidates: Number,
  advice: String,
  context: {
    featureNames: [String],
    values: Schema.Types.Mixed, // named values for the chosen arm
    x: [Number],
    z: [Number],
    // Every arm that could have been picked, with the one feature that differs between arms; with the propensity
    // this lets the replay test (evaluation/ope.js) rebuild each alternative's context.
    candidates: [{ _id: false, armId: String, typeRecentScore: Number }],
  },
  scores: [{ _id: false, armId: String, mean: Number, bonus: Number, ucb: Number, n: Number }],

  // What happened
  result: resultSchema,
  engagement: {
    score: Number,
    mode: { type: String, enum: ['logs', 'camera_logs', 'client'] },
    source: { type: String, enum: ['server', 'client'] },
    modelVersion: String,
    faceMissing: Boolean,
    features: Schema.Types.Mixed,
  },
  wordChecks: [wordCheckSchema],
  // Reading / picture description: the latest check of the whole recording (services/speechCheckService.js).
  speechCheck: Schema.Types.Mixed,
  // What P was computed from: the word checks (latest per word, reviews first, unclear left out) or the app's count.
  verification: {
    source: { type: String, enum: ['word_check', 'speech_check', 'reported'] },
    mode: String, // speech_check: reading | keywords
    share: Number, // speech_check: share of the passage read / keywords mentioned
    decision: String,
    words: Number,
    checked: Number,
    matched: Number,
    mismatched: Number,
    unclear: Number,
  },
  performance: Number, // P = successes ÷ targets × completedShare
  rewards: { fused: Number, performance: Number, engagement: Number, tap: Number },
  reward: Number, // the one that updated the bandit
  rewardMode: String,
  banditUpdated: { type: Boolean, default: false },
  completedAt: Date,
}, {
  timestamps: true,
  collection: 'c3_activity_attempts',
  toJSON: {
    virtuals: true,
    transform: (_doc, ret) => { delete ret._id; delete ret.__v; return ret; },
  },
});

activityAttemptSchema.index({ sessionId: 1, sequence: 1 }, { unique: true });
activityAttemptSchema.index({ childId: 1, createdAt: -1 });
// At most one open activity per session, enforced by the database.
activityAttemptSchema.index({ sessionId: 1 }, { unique: true, partialFilterExpression: { status: 'pending' }, name: 'one_pending_per_session' });

const ActivityAttempt = mongoose.model('C3ActivityAttempt', activityAttemptSchema);
ActivityAttempt.STATUSES = STATUSES;
ActivityAttempt.FEEDBACK = FEEDBACK;
module.exports = ActivityAttempt;
