const express = require('express');
const { z } = require('zod');
const validate = require('../../../middleware/validate');
const { requireParentMode } = require('../../../auth/middleware');
const { videoUpload } = require('../upload');
const schemas = require('../validation/schemas');
const service = require('../services/analysisService');

const router = express.Router();
const idParam = validate(z.object({ id: schemas.objectId }), 'params');

const links = (req, doc) => ({
  self: `${req.baseUrl}/${doc.id}`,
  ...(doc.stutterSource?.c1AssessmentId && { c1Assessment: `/api/c1/assessments/${doc.stutterSource.c1AssessmentId}` }),
});

// Upload a face video (paths A and B); analysis runs in the background. Poll GET /:id until completed or failed.
router.post('/', videoUpload, requireParentMode((req) => req.body?.inputPath === 'parent_upload'), validate(schemas.createAnalysis), async (req, res, next) => {
  try {
    const doc = await service.create(req.valid.body, req.file);
    res.status(202).location(`${req.baseUrl}/${doc.id}`).json({
      analysisId: doc.id,
      status: doc.status,
      inputPath: doc.inputPath,
      stutterSource: doc.stutterSource.type,
      ageBand: doc.ageBand,
      links: links(req, doc),
    });
  } catch (err) {
    next(err);
  }
});

// Path C: the child gave no video. Records "not assessed" so C2 is never reported as "0 behaviours".
router.post('/not-assessed', validate(schemas.notAssessed), async (req, res, next) => {
  try {
    const doc = await service.recordNotAssessed(req.valid.body);
    res.status(201).location(`${req.baseUrl}/${doc.id}`).json({ ...doc.toJSON(), links: links(req, doc) });
  } catch (err) {
    next(err);
  }
});

router.get('/:id', idParam, async (req, res, next) => {
  try {
    const doc = await service.get(req.valid.params.id);
    res.json({ ...doc.toJSON(), links: links(req, doc) });
  } catch (err) {
    next(err);
  }
});

// Add SLP or parent reference labels (per-moment FG/HM, overall, notes). Entries are appended.
router.post('/:id/reviews', idParam, validate(schemas.review), async (req, res, next) => {
  try {
    const doc = await service.review(req.valid.params.id, req.valid.body);
    res.status(201).json({ analysisId: doc.id, reviews: doc.reviews });
  } catch (err) {
    next(err);
  }
});

router.delete('/:id', idParam, async (req, res, next) => {
  try {
    res.json(await service.remove(req.valid.params.id));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
