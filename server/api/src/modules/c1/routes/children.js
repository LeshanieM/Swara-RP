const express = require('express');
const { z } = require('zod');
const validate = require('../../../middleware/validate');
const schemas = require('../validation/schemas');
const service = require('../services/assessmentService');

const router = express.Router();
const childParam = validate(z.object({ childId: schemas.childId }), 'params');

router.get('/:childId/assessments', childParam, validate(schemas.historyQuery, 'query'), async (req, res, next) => {
  try {
    res.json(await service.listForChild(req.valid.params.childId, req.valid.query));
  } catch (err) {
    next(err);
  }
});

router.get('/:childId/summary', childParam, async (req, res, next) => {
  try {
    res.json(await service.summaryForChild(req.valid.params.childId));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
