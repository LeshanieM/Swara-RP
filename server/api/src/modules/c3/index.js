// Component 3: engagement-aware therapy recommender (Hybrid LinUCB). Mounted at /api/c3.
const express = require('express');
const mongo = require('../../db/mongo');
const config = require('./config');
const catalogService = require('./services/catalogService');
const engagementService = require('./services/engagementService');
const wordCheckService = require('./services/wordCheckService');
const sessionService = require('./services/sessionService');
const wordCheckClient = require('./services/wordCheckClient');

async function health() {
  let engagement;
  try {
    const m = await engagementService.activeModel();
    engagement = { status: 'ok', version: m.version, source: m.source };
  } catch (err) {
    engagement = { status: 'unavailable', error: err.message };
  }
  const catalog = catalogService.health();
  // Optional: without the language service only the word check is unavailable.
  const wordCheck = await wordCheckClient.health();
  const catalogOk = Object.values(catalog.eligibleArmsByBand).every((n) => n > 0);
  return {
    ok: catalogOk && engagement.status === 'ok',
    recommender: {
      policy: config.policy, alpha: config.alpha, childPrior: config.childPrior, exploreEpsilon: config.exploreEpsilon, rewardMode: config.rewardMode,
      ...(config.policy === 'discounted' ? { discountGamma: config.discountGamma } : {}),
    },
    catalog: { status: catalogOk ? 'ok' : 'empty_band', ...catalog },
    engagementModel: engagement,
    wordCheck: { languageService: wordCheck },
  };
}

const router = express.Router();
router.get('/health', async (_req, res) => {
  const { ok, ...details } = await health();
  const dbOk = mongo.state() === 'connected';
  res.status(ok && dbOk ? 200 : 503).json({ status: ok && dbOk ? 'ok' : 'degraded', mongo: { status: mongo.state() }, ...details });
});
router.use('/', require('./routes/catalog'));
router.use('/sessions', require('./routes/sessions'));
router.use('/children', require('./routes/children'));
router.use('/', require('./routes/evaluation'));

module.exports = {
  name: 'c3',
  title: 'Engagement-aware therapy recommender',
  router,
  health,
  // No background jobs: every C3 request finishes inside the request. A word clip left on disk is from a crash;
  // sessions left unfinished past the resume window are closed as abandoned.
  recover: async () => ({
    requeued: 0, failed: 0, cleaned: await wordCheckService.cleanUploads(), abandoned: await sessionService.expireStale(),
  }),
};
