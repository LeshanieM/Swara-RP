const express = require('express');
const { z } = require('zod');
const validate = require('../../../middleware/validate');
const { audioUpload } = require('../upload');
const schemas = require('../validation/schemas');
const service = require('../services/assessmentService');

const router = express.Router();
const idParam = validate(z.object({ id: schemas.objectId }), 'params');

// Upload a recording; analysis runs in the background. Poll GET /:id until status is completed or failed.
router.post('/', audioUpload, validate(schemas.createAssessment), async (req, res, next) => {
  try {
    const doc = await service.create(req.valid.body, req.file);
    res.status(202).location(`${req.baseUrl}/${doc.id}`).json({
      assessmentId: doc.id,
      status: doc.status,
      taskType: doc.taskType,
      ageBand: doc.ageBand,
      links: { self: `${req.baseUrl}/${doc.id}` },
    });
  } catch (err) {
    next(err);
  }
});

router.get('/:id', idParam, async (req, res, next) => {
  try {
    res.json(await service.get(req.valid.params.id));
  } catch (err) {
    next(err);
  }
});

// Add an SLP or parent reference (hand-counted %SS, severity rating, notes). Entries are appended.
router.post('/:id/reviews', idParam, validate(schemas.review), async (req, res, next) => {
  try {
    const doc = await service.review(req.valid.params.id, req.valid.body);
    res.status(201).json({ assessmentId: doc.id, reviews: doc.reviews });
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
