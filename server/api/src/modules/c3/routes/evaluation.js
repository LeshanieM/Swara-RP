// Engagement-model calibration and the evaluation reports.
const express = require('express');
const validate = require('../../../middleware/validate');
const schemas = require('../validation/schemas');
const calibrationService = require('../services/calibrationService');
const reportService = require('../services/reportService');

const router = express.Router();

router.get('/engagement/model', async (_req, res, next) => {
  try {
    res.json(await calibrationService.currentModel());
  } catch (err) {
    next(err);
  }
});

router.post('/engagement/calibrate', validate(schemas.calibrate), async (req, res, next) => {
  try {
    res.status(201).json(await calibrationService.calibrate(req.valid.body));
  } catch (err) {
    next(err);
  }
});

router.post('/engagement/model/activate', validate(schemas.activateModel), async (req, res, next) => {
  try {
    res.json(await calibrationService.activateVersion(req.valid.body.version));
  } catch (err) {
    next(err);
  }
});

router.get('/reports/engagement-over-time', validate(schemas.overTimeQuery, 'query'), async (req, res, next) => {
  try {
    res.json(await reportService.engagementOverTime(req.valid.query));
  } catch (err) {
    next(err);
  }
});

router.get('/reports/engagement-pilot-check', validate(schemas.pilotCheckQuery, 'query'), async (req, res, next) => {
  try {
    res.json(await reportService.engagementPilotCheck(req.valid.query));
  } catch (err) {
    next(err);
  }
});

router.get('/reports/replay-log', validate(schemas.replayQuery, 'query'), async (req, res, next) => {
  try {
    res.json(await reportService.replayLog(req.valid.query));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
