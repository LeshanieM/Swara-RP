/**
 * Component 2 - video-based computer-vision analysis.
 * Mounted at /api/concomitant/video-analysis.
 *
 * Flutter -> (this router) -> FastAPI /analyze-video -> results -> Flutter.
 * Node only coordinates: it forwards the ONE uploaded video unchanged,
 * proxies status/results, and caches metadata/results in MongoDB.
 */
const express = require('express');
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const os = require('os');
const path = require('path');
const multer = require('multer');
const { auth } = require('../middleware/auth');
const VideoAnalysis = require('../models/VideoAnalysis');

const router = express.Router();

const AI_URL = () => process.env.AI_SERVICE_URL || 'http://localhost:8000';
// Forwarding a large local video can take several minutes on a slower disk or
// network. Keep this separate from the short status/results request timeouts.
const AI_UPLOAD_TIMEOUT_MS = Number(process.env.AI_UPLOAD_TIMEOUT_MS || 15 * 60 * 1000);
const VALID_TECH = ['mediapipe', 'openface', 'openseeface', '3ddfa_v2', 'mmpose'];

// Temp storage only (privacy): files live in the OS temp dir and are deleted after forwarding.
const upload = multer({
  dest: path.join(os.tmpdir(), 'swara-video-uploads'),
  limits: { fileSize: 500 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok = /\.(mp4|mov|webm|avi|mkv)$/i.test(file.originalname);
    cb(ok ? null : new Error('Unsupported video format'), ok);
  },
});

const safeUnlink = (p) => p && fs.unlink(p, () => {});

const aiError = (err) =>
  err.response
    ? { code: err.response.status, message: err.response.data?.detail || 'AI service error' }
    : { code: 502, message: 'AI service unreachable' };

const owned = async (id, userId) => {
  const doc = await VideoAnalysis.findOne({ analysisId: id });
  if (!doc) return { status: 404 };
  if (String(doc.createdBy) !== String(userId)) return { status: 403 };
  return { doc };
};

// POST /api/concomitant/video-analysis  (multipart: video, childId, technologies?, generateOverlay?, groundTruth?)
router.post('/', auth, upload.single('video'), async (req, res) => {
  const file = req.file;
  try {
    if (!file) return res.status(400).json({ message: 'A single video file is required (field "video")' });
    const { childId, technologies = 'all', generateOverlay = 'false', groundTruth } = req.body;
    if (!childId) return res.status(400).json({ message: 'childId is required' });

    if (technologies !== 'all') {
      const bad = technologies.split(',').map((t) => t.trim().toLowerCase()).filter((t) => !VALID_TECH.includes(t));
      if (bad.length) return res.status(400).json({ message: `Unknown technologies: ${bad.join(', ')}` });
    }

    const form = new FormData();
    form.append('video', fs.createReadStream(file.path), { filename: file.originalname });
    form.append('technologies', technologies);
    form.append('generate_overlay', String(generateOverlay === 'true' || generateOverlay === true));
    form.append('generate_timeline', 'true');
    if (groundTruth) form.append('ground_truth', typeof groundTruth === 'string' ? groundTruth : JSON.stringify(groundTruth));

    const aiRes = await axios.post(`${AI_URL()}/analyze-video`, form, {
      headers: form.getHeaders(),
      maxBodyLength: Infinity,
      maxContentLength: Infinity,
      timeout: AI_UPLOAD_TIMEOUT_MS,
    });

    const doc = await VideoAnalysis.create({
      analysisId: aiRes.data.analysis_id,
      childId,
      createdBy: req.user.id,
      video: { filename: file.originalname, sizeBytes: file.size, storedPermanently: false },
      technologiesRequested: aiRes.data.technologies,
      status: 'queued',
      progress: { completed: 0, total: aiRes.data.technologies.length },
      groundTruthProvided: !!groundTruth,
    });

    res.status(202).json({ analysisId: doc.analysisId, status: doc.status, technologies: doc.technologiesRequested });
  } catch (err) {
    const e = aiError(err);
    res.status(e.code >= 400 && e.code < 600 ? e.code : 500).json({ message: e.message || err.message });
  } finally {
    safeUnlink(file && file.path); // raw child video is never retained by Node
  }
});

// GET /api/concomitant/video-analysis/history/:childId
router.get('/history/:childId', auth, async (req, res) => {
  try {
    const docs = await VideoAnalysis.find({ childId: req.params.childId, createdBy: req.user.id })
      .select('-results')
      .sort({ createdAt: -1 });
    res.json(docs);
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

// GET /api/concomitant/video-analysis/:id  (live status)
router.get('/:id', auth, async (req, res) => {
  try {
    const { doc, status } = await owned(req.params.id, req.user.id);
    if (!doc) return res.status(status).json({ message: status === 404 ? 'Not found' : 'Forbidden' });

    if (doc.status === 'completed' || doc.status === 'failed') {
      return res.json({
        analysis_id: doc.analysisId, status: doc.status,
        completed: doc.progress.completed, total: doc.progress.total,
        current_technology: null, technologies_requested: doc.technologiesRequested,
      });
    }
    const aiRes = await axios.get(`${AI_URL()}/analyze-video/${doc.analysisId}/status`, { timeout: 15000 });
    const s = aiRes.data;
    doc.status = s.status;
    doc.progress = { completed: s.completed, total: s.total, currentTechnology: s.current_technology };
    await doc.save();
    res.json(s);
  } catch (err) {
    const e = aiError(err);
    res.status(e.code).json({ message: e.message });
  }
});

// GET /api/concomitant/video-analysis/:id/results
router.get('/:id/results', auth, async (req, res) => {
  try {
    const { doc, status } = await owned(req.params.id, req.user.id);
    if (!doc) return res.status(status).json({ message: status === 404 ? 'Not found' : 'Forbidden' });

    if (doc.results) return res.json(doc.results);

    const aiRes = await axios.get(`${AI_URL()}/analyze-video/${doc.analysisId}/results`, { timeout: 30000 });
    doc.results = aiRes.data;
    doc.status = aiRes.data.status;
    doc.completedAt = new Date();
    doc.progress.completed = doc.progress.total;
    doc.markModified('results');
    await doc.save();
    res.json(aiRes.data);
  } catch (err) {
    const e = aiError(err);
    res.status(e.code).json({ message: e.message });
  }
});

// GET /api/concomitant/video-analysis/:id/overlay/:tech  (annotated video, streamed from FastAPI)
// Browsers cannot attach an Authorization header to a <video> element, so this
// one route also accepts the JWT as ?access_token=... (header still preferred).
const overlayAuth = (req, res, next) => {
  if (!req.header('Authorization') && req.query.access_token) {
    req.headers.authorization = `Bearer ${req.query.access_token}`;
  }
  return auth(req, res, next);
};

router.get('/:id/overlay/:tech', overlayAuth, async (req, res) => {
  try {
    const tech = String(req.params.tech).toLowerCase();
    if (!VALID_TECH.includes(tech)) return res.status(400).json({ message: 'Unknown technology' });
    const { doc, status } = await owned(req.params.id, req.user.id);
    if (!doc) return res.status(status).json({ message: status === 404 ? 'Not found' : 'Forbidden' });

    const headers = {};
    if (req.headers.range) headers.Range = req.headers.range; // required for seeking / MP4 with trailing index
    const aiRes = await axios.get(`${AI_URL()}/analyze-video/${doc.analysisId}/overlay/${tech}`, {
      responseType: 'stream',
      headers,
      timeout: 30000,
      validateStatus: (s) => s === 200 || s === 206 || s === 404 || s === 416,
    });

    if (aiRes.status === 404) {
      aiRes.data.destroy();
      return res.status(404).json({ message: 'No annotated video for this technology' });
    }
    res.status(aiRes.status);
    ['content-type', 'content-length', 'content-range', 'accept-ranges'].forEach((h) => {
      if (aiRes.headers[h]) res.setHeader(h, aiRes.headers[h]);
    });
    req.on('close', () => aiRes.data.destroy());
    aiRes.data.pipe(res);
  } catch (err) {
    const e = aiError(err);
    if (!res.headersSent) res.status(e.code).json({ message: e.message });
  }
});

// Multer/validation errors -> clean 400s
router.use((err, _req, res, _next) => res.status(400).json({ message: err.message }));

module.exports = router;
