// Component 1: stutter-event detection and severity. Mounted at /api/c1.
const express = require('express');
const mongo = require('../../db/mongo');
const speechClient = require('./services/speechClient');
const assessmentService = require('./services/assessmentService');

async function health() {
  let speech;
  try {
    const h = await speechClient.health();
    speech = { status: 'ok', activeDetector: h.activeDetector, severityVersion: h.severityVersion, detectors: h.detectors };
  } catch (err) {
    speech = { status: 'unreachable', error: err.code || err.message };
  }
  return {
    ok: speech.status === 'ok',
    speechService: speech,
    queue: assessmentService.queueStats(),
  };
}

const router = express.Router();
router.get('/health', async (_req, res) => {
  const { ok, ...details } = await health();
  const dbOk = mongo.state() === 'connected';
  res.status(ok && dbOk ? 200 : 503).json({ status: ok && dbOk ? 'ok' : 'degraded', mongo: { status: mongo.state() }, ...details });
});
router.use('/tasks', require('./routes/tasks'));
router.use('/assessments', require('./routes/assessments'));
router.use('/children', require('./routes/children'));

module.exports = {
  name: 'c1',
  title: 'Stutter-event detection and severity',
  router,
  health,
  recover: assessmentService.recover,
};
