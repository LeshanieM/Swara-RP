const express = require('express');
const { z } = require('zod');
const validate = require('../../../middleware/validate');
const { requireParentMode } = require('../../../auth/middleware');
const schemas = require('../validation/schemas');
const sampleService = require('../services/sampleService');
const bandService = require('../services/bandService');
const run = require('./run');

const router = express.Router();
const idParam = validate(z.object({ id: schemas.objectId }), 'params');

router.get('/:id', idParam, run(async (req, res) => {
  res.json(await sampleService.get(req.valid.params.id));
}));

// Parent mode / SLP: a corrected or fully manual transcript. Kept as a new version; measures are recomputed.
router.put('/:id/transcript', requireParentMode(), idParam, validate(schemas.transcriptEdit), run(async (req, res) => {
  res.json(await sampleService.editTranscript(req.valid.params.id, req.valid.body));
}));

// A parent or SLP confirms the computed band or overrides it.
router.post('/:id/band-confirmation', requireParentMode(), idParam, validate(schemas.bandConfirmation), run(async (req, res) => {
  const doc = await bandService.confirm(await sampleService.get(req.valid.params.id), req.valid.body);
  res.status(201).json({ sampleId: doc.id, band: doc.band });
}));

router.delete('/:id', idParam, run(async (req, res) => {
  res.json(await sampleService.remove(req.valid.params.id));
}));

module.exports = router;
