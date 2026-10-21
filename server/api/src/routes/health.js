const express = require('express');
const { version } = require('../../package.json');
const mongo = require('../db/mongo');
const modules = require('../modules');

const router = express.Router();

// Whole-server status: MongoDB plus each component's own dependencies.
router.get('/', async (_req, res) => {
  const db = mongo.state();
  const components = {};
  await Promise.all(modules.map(async (m) => {
    const { ok, ...details } = await m.health();
    components[m.name] = { status: ok ? 'ok' : 'degraded', ...details };
  }));
  const ok = db === 'connected' && Object.values(components).every((c) => c.status === 'ok');
  res.status(ok ? 200 : 503).json({
    status: ok ? 'ok' : 'degraded',
    api: { version, uptimeSec: Math.round(process.uptime()) },
    mongo: { status: db },
    components,
  });
});

module.exports = router;
