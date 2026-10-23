const express = require('express');
const { z } = require('zod');
const validate = require('../../../middleware/validate');
const { audioUpload } = require('../upload');
const schemas = require('../validation/schemas');
const sessionService = require('../services/sessionService');
const sampleService = require('../services/sampleService');
const run = require('./run');

const router = express.Router();
const idParam = validate(z.object({ id: schemas.objectId }), 'params');

// Start a session: the topic is chosen from the child's ranked interests (or the fixed sequence).
router.post('/', validate(schemas.createSession), run(async (req, res) => {
  const session = await sessionService.create(req.valid.body);
  res.status(201).location(`${req.baseUrl}/${session.id}`).json(session);
}));

router.get('/:id', idParam, run(async (req, res) => {
  res.json(await sessionService.get(req.valid.params.id));
}));

// The child answered: show the next follow-up.
router.post('/:id/next-prompt', idParam, run(async (req, res) => {
  res.json(await sessionService.advance(req.valid.params.id));
}));

// Skip a follow-up (next follow-up) or the main prompt (another topic). Logged on the session.
router.post('/:id/skips', idParam, validate(schemas.skip), run(async (req, res) => {
  res.status(201).json(await sessionService.skip(req.valid.params.id, req.valid.body));
}));

// Upload the recording; analysis runs in the background. Poll GET /samples/:id.
router.post('/:id/recordings', idParam, audioUpload, validate(schemas.recording), run(async (req, res) => {
  const session = await sessionService.find(req.valid.params.id);
  const doc = await sampleService.create(session, req.valid.body, req.file);
  const self = `${req.baseUrl.replace(/\/sessions$/, '')}/samples/${doc.id}`;
  res.status(202).location(self).json({
    sampleId: doc.id,
    sessionId: String(session._id),
    status: doc.status,
    transcriptSource: req.valid.body.transcript ? 'manual' : 'asr',
    links: { self },
  });
}));

module.exports = router;
