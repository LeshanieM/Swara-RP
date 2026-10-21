// Component 2: video-based secondary behaviours (SRCD). Mounted at /api/c2.
const express = require('express');
const mongo = require('../../db/mongo');
const visionClient = require('./services/visionClient');
const analysisService = require('./services/analysisService');
const speechClient = require('../c1/services/speechClient');

async function health() {
  let vision;
  try {
    const h = await visionClient.health();
    vision = {
      status: h.faceModel?.status === 'available' ? 'ok' : 'degraded',
      faceModel: h.faceModel?.status,
      activeDetector: h.activeDetector,
      detectors: h.detectors,
    };
  } catch (err) {
    vision = { status: 'unreachable', error: err.code || err.message };
  }
  // The audio-track path sends the video's audio through C1, so C1's speech service matters too.
  let speech;
  try {
    await speechClient.health();
    speech = { status: 'ok' };
  } catch (err) {
    speech = { status: 'unreachable', error: err.code || err.message, affects: 'stutterSource c1_audio_track' };
  }
  return {
    ok: vision.status === 'ok' && speech.status === 'ok',
    visionService: vision,
    speechService: speech,
    queue: analysisService.queueStats(),
  };
}

const router = express.Router();
router.get('/health', async (_req, res) => {
  const { ok, ...details } = await health();
  const dbOk = mongo.state() === 'connected';
  res.status(ok && dbOk ? 200 : 503).json({ status: ok && dbOk ? 'ok' : 'degraded', mongo: { status: mongo.state() }, ...details });
});
router.use('/analyses', require('./routes/analyses'));
router.use('/children', require('./routes/children'));

module.exports = {
  name: 'c2',
  title: 'Video-based secondary behaviours (SRCD)',
  router,
  health,
  recover: analysisService.recover,
};
