const express = require('express');
const validate = require('../../../middleware/validate');
const schemas = require('../validation/schemas');
const catalog = require('../services/catalogService');
const run = require('./run');

const router = express.Router();

router.get('/', (_req, res) => res.json(catalog.meta()));

// Categories the child can rank at onboarding.
router.get('/categories', validate(schemas.ageQuery, 'query'), run((req, res) => {
  const ageBand = catalog.bandForAge(req.valid.query.age);
  res.json({ ageBand, categories: catalog.categories(ageBand) });
}));

router.get('/topics', validate(schemas.topicsQuery, 'query'), run((req, res) => {
  const { age, category, level } = req.valid.query;
  const ageBand = catalog.bandForAge(age);
  const topics = catalog.topics(ageBand, { category, level });
  res.json({ ageBand, count: topics.length, topics });
}));

// The parent checklist for the child's band (answered in parent mode).
router.get('/checklist', validate(schemas.ageQuery, 'query'), run((req, res) => {
  res.json(catalog.checklistFor(catalog.bandForAge(req.valid.query.age)));
}));

module.exports = router;
