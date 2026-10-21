// Component 4: spontaneous speech and language-sample analysis. Mounted at /api/c4.
const express = require('express');
const mongo = require('../../db/mongo');
const languageClient = require('./services/languageClient');
const sampleService = require('./services/sampleService');
const c1Link = require('./services/c1Link');
const catalog = require('./services/catalogService');

async function health() {
  let language;
  try {
    const h = await languageClient.health();
    language = { status: 'ok', activeEngine: h.activeEngine, engines: h.engines, methodVersion: h.methodVersion };
  } catch (err) {
    language = { status: 'unreachable', error: err.code || err.message };
  }
  return {
    ok: language.status === 'ok',
    languageService: language,
    // Optional: without C1, samples complete with stuttering "not_assessed".
    c1SpeechService: await c1Link.health(),
    topicBank: catalog.meta(),
    queue: sampleService.queueStats(),
  };
}

const router = express.Router();
router.get('/health', async (_req, res) => {
  const { ok, ...details } = await health();
  const dbOk = mongo.state() === 'connected';
  res.status(ok && dbOk ? 200 : 503).json({ status: ok && dbOk ? 'ok' : 'degraded', mongo: { status: mongo.state() }, ...details });
});
router.use('/catalog', require('./routes/catalog'));
router.use('/children', require('./routes/children'));
router.use('/sessions', require('./routes/sessions'));
router.use('/samples', require('./routes/samples'));
router.use('/research', require('./routes/research'));

module.exports = {
  name: 'c4',
  title: 'Spontaneous speech and language-sample analysis',
  router,
  health,
  recover: sampleService.recover,
};
