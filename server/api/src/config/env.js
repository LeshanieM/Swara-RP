const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const int = (value, fallback) => {
  const n = Number.parseInt(value, 10);
  return Number.isFinite(n) ? n : fallback;
};

const num = (value, fallback) => {
  const n = Number.parseFloat(value);
  return Number.isFinite(n) ? n : fallback;
};

const production = process.env.NODE_ENV === 'production';
if (!process.env.JWT_SECRET) {
  if (production) throw new Error('JWT_SECRET must be set in production.');
  console.warn('[api] JWT_SECRET is not set; using a development secret. Set it in server/api/.env.');
}

const env = Object.freeze({
  port: int(process.env.PORT, 5001),
  mongoUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/swara',
  speechServiceUrl: (process.env.SPEECH_SERVICE_URL || 'http://localhost:8010').replace(/\/$/, ''),
  speechTimeoutMs: int(process.env.SPEECH_TIMEOUT_MS, 120000),
  uploadDir: path.resolve(__dirname, '../..', process.env.UPLOAD_DIR || 'uploads'),
  maxUploadMb: int(process.env.MAX_UPLOAD_MB, 50),
  jobConcurrency: Math.max(1, int(process.env.C1_JOB_CONCURRENCY, 2)),
  keepUploads: process.env.C1_KEEP_UPLOADS === '1',
  // Component 2 (video secondary behaviours)
  visionServiceUrl: (process.env.VISION_SERVICE_URL || 'http://localhost:8011').replace(/\/$/, ''),
  visionTimeoutMs: int(process.env.VISION_TIMEOUT_MS, 300000),
  maxVideoUploadMb: int(process.env.MAX_VIDEO_UPLOAD_MB, 200),
  c2JobConcurrency: Math.max(1, int(process.env.C2_JOB_CONCURRENCY, 1)),
  c2KeepUploads: process.env.C2_KEEP_UPLOADS === '1',
  // How long a C2 job waits for the linked C1 assessment to finish.
  c2C1WaitMs: int(process.env.C2_C1_WAIT_MS, 600000),
  // Component 3 (adaptive therapy recommender)
  c3Policy: process.env.C3_POLICY || 'hybrid',
  c3Alpha: num(process.env.C3_ALPHA, 0.6),
  c3DiscountGamma: num(process.env.C3_DISCOUNT_GAMMA, 0.95),
  c3ChildPrior: num(process.env.C3_CHILD_PRIOR, 5),
  c3ExploreEpsilon: num(process.env.C3_EXPLORE_EPSILON, 0),
  c3RewardMode: process.env.C3_REWARD_MODE || 'fused',
  c3MaxActivities: int(process.env.C3_MAX_ACTIVITIES, 5),
  // Word check (via the language service); the first call may wait for the ASR model to load.
  c3WordCheckTimeoutMs: int(process.env.C3_WORD_CHECK_TIMEOUT_MS, 60000),
  // Auth: one login per child plus a parent-mode PIN, and therapist logins
  jwtSecret: process.env.JWT_SECRET || 'swara-dev-only-secret',
  authRequired: process.env.AUTH_REQUIRED !== '0',
  tokenDays: Math.max(1, int(process.env.AUTH_TOKEN_DAYS, 7)),
  parentModeMinutes: Math.max(1, int(process.env.PARENT_MODE_MINUTES, 15)),
  therapistSignupCode: process.env.THERAPIST_SIGNUP_CODE || '',
  corsOrigins: (process.env.CORS_ORIGINS || '*').split(',').map((s) => s.trim()),
  // Component 4
  languageServiceUrl: (process.env.LANGUAGE_SERVICE_URL || 'http://localhost:8012').replace(/\/$/, ''),
  languageTimeoutMs: int(process.env.LANGUAGE_TIMEOUT_MS, 600000),
  c4JobConcurrency: Math.max(1, int(process.env.C4_JOB_CONCURRENCY, 1)),
  c4KeepUploads: process.env.C4_KEEP_UPLOADS === '1',
  c4BaselineSessions: Math.max(1, int(process.env.C4_BASELINE_SESSIONS, 3)),
  // Fixed-topic sessions (the personalised-vs-fixed research arm) are off: every session uses the child's interests.
  c4AllowFixed: process.env.C4_ALLOW_FIXED === '1',
});

module.exports = env;
