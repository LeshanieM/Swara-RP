const fs = require('fs');
const express = require('express');
const { z } = require('zod');
const validate = require('../../../middleware/validate');
const { requireParentMode } = require('../../../auth/middleware');
const schemas = require('../validation/schemas');
const sessionService = require('../services/sessionService');
const recommendationService = require('../services/recommendationService');
const wordCheckService = require('../services/wordCheckService');
const speechCheckService = require('../services/speechCheckService');
const { wordClipUpload } = require('../upload');

const router = express.Router();
const idParam = validate(z.object({ id: schemas.objectId }), 'params');
const attemptParams = validate(z.object({ id: schemas.objectId, attemptId: schemas.objectId }), 'params');
const checkParams = validate(z.object({ id: schemas.objectId, attemptId: schemas.objectId, checkId: schemas.objectId }), 'params');

router.post('/', validate(schemas.createSession), async (req, res, next) => {
  try {
    const session = await sessionService.create(req.valid.body);
    res.status(201).location(`/api/c3/sessions/${session.id}`).json({
      ...session.toJSON(),
      links: { self: `/api/c3/sessions/${session.id}`, nextActivity: `/api/c3/sessions/${session.id}/next-activity` },
    });
  } catch (err) {
    next(err);
  }
});

router.get('/:id', idParam, async (req, res, next) => {
  try {
    res.json(await sessionService.get(req.valid.params.id));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/next-activity', idParam, validate(schemas.nextActivity), async (req, res, next) => {
  try {
    const session = await sessionService.find(req.valid.params.id);
    const pick = await recommendationService.recommend(session, req.valid.body);
    res.status(pick.attemptId ? 201 : 200).json(pick);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/activities/:attemptId/result', attemptParams, validate(schemas.activityResult), async (req, res, next) => {
  try {
    const session = await sessionService.find(req.valid.params.id);
    res.json(await recommendationService.recordResult(session, req.valid.params.attemptId, req.valid.body));
  } catch (err) {
    next(err);
  }
});

// Word activities: one recording of one target word, checked while the client waits (the clip is not kept).
router.post('/:id/activities/:attemptId/word-checks', attemptParams, wordClipUpload, async (req, res, next) => {
  try {
    // Parsed here, not by the validate middleware, so a rejected form still reaches the catch that deletes the clip.
    const { wordIndex } = schemas.wordCheck.parse(req.body);
    const session = await sessionService.find(req.valid.params.id);
    res.status(201).json(await wordCheckService.create(session, req.valid.params.attemptId, wordIndex, req.file));
  } catch (err) {
    if (req.file?.path) fs.rm(req.file.path, { force: true }, () => {});
    next(err);
  }
});

// Reading and picture description: the whole recording, compared with the passage or the picture's keywords.
router.post('/:id/activities/:attemptId/speech-check', attemptParams, wordClipUpload, async (req, res, next) => {
  try {
    const session = await sessionService.find(req.valid.params.id);
    res.status(201).json(await speechCheckService.create(session, req.valid.params.attemptId, req.file));
  } catch (err) {
    if (req.file?.path) fs.rm(req.file.path, { force: true }, () => {});
    next(err);
  }
});

router.put('/:id/activities/:attemptId/word-checks/:checkId/review', checkParams, validate(schemas.wordCheckReview), async (req, res, next) => {
  try {
    const session = await sessionService.find(req.valid.params.id);
    res.json(await wordCheckService.review(session, req.valid.params.attemptId, req.valid.params.checkId, req.valid.body));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/breaks', idParam, validate(schemas.breakBody), async (req, res, next) => {
  try {
    res.status(201).json(await sessionService.addBreak(req.valid.params.id, req.valid.body));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/complete', idParam, async (req, res, next) => {
  try {
    res.json(await sessionService.complete(req.valid.params.id));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/questionnaire', requireParentMode(), idParam, validate(schemas.questionnaire), async (req, res, next) => {
  try {
    res.status(201).json(await sessionService.submitQuestionnaire(req.valid.params.id, req.valid.body));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
