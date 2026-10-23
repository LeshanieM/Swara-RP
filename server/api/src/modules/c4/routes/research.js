const express = require('express');
const validate = require('../../../middleware/validate');
const schemas = require('../validation/schemas');
const research = require('../services/researchService');
const run = require('./run');

const router = express.Router();

// H4c: personalised vs fixed topics, paired over children.
router.get('/h4c', run(async (_req, res) => {
  res.json(await research.h4c());
}));

// H4d: one row per utterance (length, complexity, stutter) for the grouped logistic regression.
router.get('/h4d', validate(schemas.h4dQuery, 'query'), run(async (req, res) => {
  const { childId, format } = req.valid.query;
  if (format === 'csv') {
    res.type('text/csv').attachment('c4_h4d_utterances.csv').send(research.toCsv(await research.h4dRows(childId)));
    return;
  }
  res.json(await research.h4d(childId));
}));

module.exports = router;
