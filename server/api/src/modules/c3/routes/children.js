const express = require('express');
const { z } = require('zod');
const validate = require('../../../middleware/validate');
const schemas = require('../validation/schemas');
const sessionService = require('../services/sessionService');
const recommendationService = require('../services/recommendationService');

const router = express.Router();
const childParam = validate(z.object({ childId: schemas.childId }), 'params');

router.get('/:childId/sessions', childParam, validate(schemas.historyQuery, 'query'), async (req, res, next) => {
  try {
    res.json(await sessionService.listForChild(req.valid.params.childId, req.valid.query));
  } catch (err) {
    next(err);
  }
});

// The session that can still be continued (started within the resume window), with its open activity if any.
router.get('/:childId/sessions/active', childParam, async (req, res, next) => {
  try {
    res.json(await sessionService.activeForChild(req.valid.params.childId));
  } catch (err) {
    next(err);
  }
});

router.get('/:childId/summary', childParam, async (req, res, next) => {
  try {
    res.json(await sessionService.summaryForChild(req.valid.params.childId));
  } catch (err) {
    next(err);
  }
});

router.get('/:childId/context', childParam, validate(schemas.ageQuery, 'query'), async (req, res, next) => {
  try {
    res.json(await recommendationService.contextPreview(req.valid.params.childId, req.valid.query.age));
  } catch (err) {
    next(err);
  }
});

router.get('/:childId/bandit', childParam, validate(schemas.banditQuery, 'query'), async (req, res, next) => {
  try {
    res.json(await recommendationService.banditForChild(req.valid.params.childId, { matrices: req.valid.query.matrices === '1' }));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
