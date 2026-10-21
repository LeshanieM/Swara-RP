const express = require('express');
const { z } = require('zod');
const validate = require('../../../middleware/validate');
const { requireParentMode } = require('../../../auth/middleware');
const schemas = require('../validation/schemas');
const childService = require('../services/childService');
const sampleService = require('../services/sampleService');
const sessionService = require('../services/sessionService');
const vocabularyService = require('../services/vocabularyService');
const run = require('./run');

const router = express.Router();
const childParam = validate(z.object({ childId: schemas.childId }), 'params');

// Onboarding: age band and 5 ranked favourite categories. Re-sending updates the profile.
router.put('/:childId/profile', childParam, validate(schemas.profile), run(async (req, res) => {
  const { profile, created } = await childService.upsertProfile(req.valid.params.childId, req.valid.body);
  res.status(created ? 201 : 200).json(profile);
}));

router.get('/:childId/profile', childParam, run(async (req, res) => {
  res.json(await childService.getProfile(req.valid.params.childId));
}));

// Parent mode: the age-band checklist sets the starting level.
router.post('/:childId/checklist', requireParentMode(), childParam, validate(schemas.checklist), run(async (req, res) => {
  const profile = await childService.submitChecklist(req.valid.params.childId, req.valid.body);
  res.status(201).json({ childId: profile.childId, checklist: profile.checklist });
}));

// Parent mode: words the child already uses; they never count as new words.
router.put('/:childId/known-words', requireParentMode(), childParam, validate(schemas.knownWords), run(async (req, res) => {
  res.json(await childService.setKnownWords(req.valid.params.childId, req.valid.body));
}));

router.get('/:childId/sessions', childParam, validate(schemas.historyQuery, 'query'), run(async (req, res) => {
  res.json(await sessionService.listForChild(req.valid.params.childId, req.valid.query));
}));

router.get('/:childId/samples', childParam, validate(schemas.historyQuery, 'query'), run(async (req, res) => {
  res.json(await sampleService.listForChild(req.valid.params.childId, req.valid.query));
}));

router.get('/:childId/progress', childParam, run(async (req, res) => {
  res.json(await childService.progress(req.valid.params.childId));
}));

router.get('/:childId/vocabulary', childParam, run(async (req, res) => {
  res.json(await vocabularyService.vocabularyFor(req.valid.params.childId));
}));

router.get('/:childId/summary', childParam, run(async (req, res) => {
  res.json(await childService.summary(req.valid.params.childId));
}));

module.exports = router;
