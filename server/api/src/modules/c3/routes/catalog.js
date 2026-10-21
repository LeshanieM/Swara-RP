// Activity pool and questionnaire (static content).
const express = require('express');
const validate = require('../../../middleware/validate');
const schemas = require('../validation/schemas');
const catalogService = require('../services/catalogService');

const router = express.Router();

router.get('/activities', validate(schemas.ageQuery, 'query'), (req, res, next) => {
  try {
    res.json(catalogService.activitiesForAge(req.valid.query.age));
  } catch (err) {
    next(err);
  }
});

router.get('/activities/items', validate(schemas.itemsQuery, 'query'), (req, res, next) => {
  try {
    res.json(catalogService.items(req.valid.query));
  } catch (err) {
    next(err);
  }
});

router.get('/questionnaire', validate(schemas.questionnaireQuery, 'query'), (req, res) => {
  res.json(catalogService.questionnaireFor(req.valid.query.language));
});

module.exports = router;
