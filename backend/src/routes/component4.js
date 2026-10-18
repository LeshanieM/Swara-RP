const express = require('express');
const crypto = require('crypto');
const axios = require('axios');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const { auth } = require('../middleware/auth');
const Child = require('../models/Child');
const Topic = require('../models/component4/Topic');
const Session = require('../models/component4/Session');
const TherapyOutcome = require('../models/component3/TherapyOutcome');
const { analyzeTranscript, words } = require('../services/component4/languageMeasures');

const router = express.Router();
// Express 4 does not forward rejected async handlers to error middleware by itself.
for (const method of ['get', 'post', 'put']) {
  const register = router[method].bind(router);
  router[method] = (routePath, ...handlers) => register(routePath, ...handlers.map(handler =>
    handler.constructor.name === 'AsyncFunction'
      ? (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next)
      : handler));
}
const uploadDir = path.resolve(process.env.C4_UPLOAD_DIR || path.join(__dirname, '../../uploads/c4'));
const upload = multer({ dest: uploadDir, limits: { fileSize: Number(process.env.C4_MAX_AUDIO_BYTES || 50 * 1024 * 1024) }, fileFilter: (_req, file, cb) => {
  if (['audio/wav', 'audio/x-wav', 'audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/webm', 'audio/ogg'].includes(file.mimetype)) return cb(null, true);
  const error = new Error('Unsupported audio format'); error.statusCode = 415; cb(error);
} });
router.use(auth);

async function accessibleChild(childId, user) {
  if (!childId) return null;
  const ownership = user.role === 'therapist' ? { therapistId: user.id } : { parentId: user.id };
  if (user.role === 'child') return null;
  const idQuery = /^[a-f\d]{24}$/i.test(String(childId)) ? { _id: childId } : { childId: String(childId) };
  return Child.findOne({ ...idQuery, ...ownership });
}
const ageBand = age => age >= 5 && age <= 10 ? '5-10' : age >= 11 && age <= 14 ? '11-14' : null;
const sessionAccess = async (sessionId, user) => {
  const session = await Session.findOne({ sessionId, ownerId: user.id });
  return session;
};

router.get('/:childId/preferences', async (req, res) => {
  const child = await accessibleChild(req.params.childId, req.user);
  if (!child) return res.status(404).json({ message: 'Child profile not found' });
  res.json({ ageBand: child.c4Preferences?.ageBand || ageBand(child.age), rankedInterests: child.c4Preferences?.rankedInterests || [] });
});
router.put('/:childId/preferences', async (req, res) => {
  const child = await accessibleChild(req.params.childId, req.user);
  if (!child) return res.status(404).json({ message: 'Child profile not found' });
  if (req.user.role === 'child') return res.status(403).json({ message: 'Parent or therapist access required to change preferences' });
  const band = ageBand(child.age); const { rankedInterests } = req.body;
  if (!band || !Array.isArray(rankedInterests) || rankedInterests.length !== 5 || new Set(rankedInterests).size !== 5 || rankedInterests.some(x => typeof x !== 'string' || !x.trim())) return res.status(400).json({ message: 'Provide five distinct ranked interests for the child age band' });
  const available = new Set(await Topic.distinct('category', { ageBand: band }));
  if (rankedInterests.some(category => !available.has(category))) return res.status(400).json({ message: 'One or more interest categories are not available for this child age band' });
  child.c4Preferences = { ageBand: band, rankedInterests }; await child.save();
  res.json({ ageBand: band, rankedInterests: child.c4Preferences.rankedInterests });
});
router.get('/topics', async (req, res) => {
  const band = req.query.ageBand;
  if (!['5-10', '11-14'].includes(band)) return res.status(400).json({ message: 'ageBand must be 5-10 or 11-14' });
  const filter = { ageBand: band }; if (req.query.approvedOnly === 'true') filter.approvalStatus = 'approved';
  res.json(await Topic.find(filter).sort({ category: 1, topicId: 1 }).lean());
});
router.post('/:childId/topics/next', async (req, res) => {
  try {
    const child = await accessibleChild(req.params.childId, req.user);
    if (!child) return res.status(404).json({ message: 'Child profile not found' });
    const band = ageBand(child.age); const prefs = child.c4Preferences?.rankedInterests || [];
    if (!band || prefs.length !== 5) return res.status(409).json({ message: 'Five ranked interests are required before topic selection' });
    const filter = { ageBand: band, category: { $in: prefs } }; if (req.query.approvedOnly === 'true') filter.approvalStatus = 'approved';
    let topics = await Topic.find(filter).lean();
    if (!topics.length) return res.status(409).json({ message: 'No eligible topics are seeded for these interests' });
    const sessions = await Session.find({ childId: child._id }).sort({ createdAt: -1 }).limit(20).lean();
    const used = new Map(); sessions.forEach(s => { if (s.topicId && !used.has(s.topicId)) used.set(s.topicId, s.createdAt); });
    const previousCategory = sessions[0]?.topicCategory;
    topics = topics.filter(t => t.category !== previousCategory).concat(topics.filter(t => t.category === previousCategory));
    topics.sort((a, b) => {
      const aUsed = used.has(a.topicId), bUsed = used.has(b.topicId);
      if (aUsed !== bUsed) return aUsed ? 1 : -1;
      if (aUsed && bUsed) return new Date(used.get(a.topicId)) - new Date(used.get(b.topicId));
      if ((a.category === previousCategory) !== (b.category === previousCategory)) return a.category === previousCategory ? 1 : -1;
      const rankA = prefs.indexOf(a.category), rankB = prefs.indexOf(b.category);
      return rankA - rankB || a.topicId.localeCompare(b.topicId);
    });
    const seed = req.body.seed;
    let selected = topics[0];
    const eligibleCategories = prefs.filter(category => topics.some(t => t.category === category));
    const categoryPool = eligibleCategories.filter(category => category !== previousCategory);
    const rankedPool = categoryPool.length ? categoryPool : eligibleCategories;
    const weighted = rankedPool.flatMap(category => Array(5 - prefs.indexOf(category)).fill(category));
    const draw = Number.isInteger(seed) ? ((seed % Math.max(1, weighted.length)) + Math.max(1, weighted.length)) % Math.max(1, weighted.length) : crypto.randomInt(Math.max(1, weighted.length));
    const category = weighted[draw];
    const categoryTopics = topics.filter(t => t.category === category);
    if (categoryTopics.length) selected = Number.isInteger(seed) ? categoryTopics[Math.abs(seed) % categoryTopics.length] : categoryTopics[0];
    const outcomes = await TherapyOutcome.find({ childId: child._id }).sort({ createdAt: -1 }).limit(3).select('TSS').lean();
    let tssTrend = 'unavailable';
    if (outcomes.length >= 2) tssTrend = outcomes[0].TSS < outcomes[1].TSS ? 'declining' : outcomes[0].TSS > outcomes[1].TSS ? 'gaining' : 'stable';
    let languageProgress = 'unavailable';
    const measured = sessions.filter(s => s.languageMeasures?.MLU_words != null).map(s => s.languageMeasures.MLU_words);
    if (measured.length >= 2) languageProgress = measured[0] < measured.slice(1).reduce((a, b) => a + b, 0) / (measured.length - 1) ? 'below_baseline' : 'stable_or_gaining';
    if (process.env.NODE_ENV === 'test') {
      if (['below_baseline', 'stable_or_gaining'].includes(req.body.languageProgress)) languageProgress = req.body.languageProgress;
      if (['declining', 'gaining', 'stable'].includes(req.body.tssTrend)) tssTrend = req.body.tssTrend;
    }
    const preferConcrete = languageProgress === 'below_baseline' || tssTrend === 'declining';
    const levelMatch = categoryTopics.filter(t => t.level === (preferConcrete ? 'concrete' : 'open'));
    if (levelMatch.length) selected = Number.isInteger(seed) ? levelMatch[Math.abs(seed) % levelMatch.length] : levelMatch[0];
    res.json({ topic: selected, selection: { ageBand: band, weightedInterestSampling: true, seeded: Number.isInteger(seed), levelPreference: preferConcrete ? 'concrete' : 'open', languageProgress, tssTrend } });
  } catch (error) { res.status(503).json({ message: 'Topic selection unavailable' }); }
});

router.post('/sessions', async (req, res) => {
  const child = await accessibleChild(req.body.childId, req.user);
  if (!child) return res.status(404).json({ message: 'Child profile not found' });
  if (!req.body.topicId) return res.status(400).json({ message: 'topicId is required' });
  const topic = await Topic.findOne({ topicId: req.body.topicId, ageBand: ageBand(child.age) });
  if (!topic) return res.status(400).json({ message: 'Topic is not eligible for this child age band' });
  const session = await Session.create({ sessionId: `c4_${crypto.randomUUID()}`, ownerId: req.user.id, childId: child._id, topicId: topic.topicId, topicCategory: topic.category, topicHistory: [{ topicId: topic.topicId, action: 'shown', at: new Date() }] });
  res.status(201).json({ sessionId: session.sessionId, status: session.status, topic });
});
router.post('/sessions/:sessionId/skip', async (req, res) => {
  const session = await sessionAccess(req.params.sessionId, req.user); if (!session) return res.status(404).json({ message: 'Session not found' });
  session.topicHistory.push({ topicId: req.body.topicId || session.topicId, action: req.body.followUpIndex == null ? 'skipped' : `followup_skipped_${req.body.followUpIndex}`, at: new Date() }); await session.save();
  res.json({ status: 'recorded', history: session.topicHistory });
});
router.post('/sessions/:sessionId/complete', async (req, res) => {
  const session = await sessionAccess(req.params.sessionId, req.user); if (!session) return res.status(404).json({ message: 'Session not found' });
  session.topicHistory.push({ topicId: session.topicId, action: 'completed', at: new Date() });
  if (req.body.earlyCompletion === true) session.reliabilityFlags = [...new Set([...(session.reliabilityFlags || []), 'early_completion'])];
  await session.save(); res.json({ status: 'completed', sessionId: session.sessionId, reliabilityFlags: session.reliabilityFlags });
});
router.get('/sessions/:sessionId/followups', async (req, res) => {
  const session = await sessionAccess(req.params.sessionId, req.user); if (!session) return res.status(404).json({ message: 'Session not found' });
  const topic = await Topic.findOne({ topicId: session.topicId }).lean(); res.json({ followUps_si: topic?.followUps_si || [] });
});
router.post('/sessions/:sessionId/analyze', upload.single('audio'), async (req, res) => {
  const session = await sessionAccess(req.params.sessionId, req.user); if (!session) { if (req.file) fs.unlink(req.file.path, () => {}); return res.status(404).json({ message: 'Session not found' }); }
  if (!req.file && !req.body.recordingReference) return res.status(400).json({ message: 'Upload an audio recording or provide a recordingReference' });
  const aiUrl = process.env.AI_SERVICE_URL;
  if (!aiUrl) { if (req.file) fs.unlink(req.file.path, () => {}); return res.status(503).json({ message: 'AI_SERVICE_URL is not configured' }); }
  session.status = 'processing'; session.asr = { status: 'processing' }; await session.save();
  try {
    let response;
    if (req.file) {
      const FormData = require('form-data'); const form = new FormData(); form.append('audio', fs.createReadStream(req.file.path), { filename: req.file.originalname, contentType: req.file.mimetype });
      response = await axios.post(`${aiUrl.replace(/\/$/, '')}/analyze-language`, form, { headers: form.getHeaders(), timeout: Number(process.env.AI_REQUEST_TIMEOUT_MS || 180000), maxBodyLength: 60 * 1024 * 1024 });
      session.recording = { fileName: req.file.originalname, mimeType: req.file.mimetype, durationSeconds: response.data.durationSeconds, storageReference: 'transient-upload' };
    } else {
      const FormData = require('form-data'); const form = new FormData(); form.append('recordingReference', req.body.recordingReference);
      response = await axios.post(`${aiUrl.replace(/\/$/, '')}/analyze-language`, form, { headers: form.getHeaders(), timeout: Number(process.env.AI_REQUEST_TIMEOUT_MS || 180000) });
    }
    const result = response.data;
    if (!result.transcript || !result.model) throw new Error('AI service returned no transcript/model metadata');
    const previousSessions = await Session.find({ childId: session.childId, status: 'completed', _id: { $ne: session._id } }).select('correctedTranscript originalTranscript').sort({ createdAt: -1 }).limit(3).lean();
    const vocab = previousSessions.flatMap(s => words(s.correctedTranscript || s.originalTranscript || ''));
    const analysis = analyzeTranscript(result.transcript, vocab, previousSessions.length >= 2);
    session.originalTranscript = result.transcript; session.utterances = result.utterances?.length ? result.utterances : analysis.utterances;
    session.languageMeasures = { ...(result.measures || {}), ...analysis.measures }; session.shortSample = analysis.shortSample; session.reliabilityFlags = analysis.reliabilityFlags;
    session.asr = { status: 'completed', model: result.model.name, version: result.model.version || null };
    session.status = 'completed'; session.c1 = { status: 'unavailable', events: [] }; await session.save();
    res.json({ sessionId: session.sessionId, status: session.status, transcript: session.originalTranscript, model: session.asr, utterances: session.utterances, languageMeasures: session.languageMeasures, shortSample: session.shortSample, reliabilityFlags: session.reliabilityFlags, c1: session.c1 });
  } catch (error) {
    session.status = 'failed'; session.asr = { status: 'failed', error: error.response?.data?.detail || 'AI service unavailable or analysis failed' }; await session.save();
    const status = error.response?.status || 503; res.status(status).json({ message: 'Language analysis failed', detail: error.response?.data?.detail || 'AI service unavailable or model unavailable' });
  } finally { if (req.file) fs.unlink(req.file.path, () => {}); }
});
router.put('/sessions/:sessionId/transcript', async (req, res) => {
  const session = await sessionAccess(req.params.sessionId, req.user); if (!session) return res.status(404).json({ message: 'Session not found' });
  if (typeof req.body.transcript !== 'string' || req.body.transcript.length > 30000) return res.status(400).json({ message: 'transcript must be a string up to 30000 characters' });
  const previous = await Session.find({ childId: session.childId, status: 'completed', _id: { $ne: session._id } }).select('correctedTranscript originalTranscript').sort({ createdAt: -1 }).limit(3).lean();
  const analysis = analyzeTranscript(req.body.transcript, previous.flatMap(s => words(s.correctedTranscript || s.originalTranscript || '')), previous.length >= 2);
  session.correctedTranscript = req.body.transcript; session.utterances = analysis.utterances; session.languageMeasures = analysis.measures; session.shortSample = analysis.shortSample; session.reliabilityFlags = analysis.reliabilityFlags; await session.save();
  res.json({ transcript: session.correctedTranscript, languageMeasures: session.languageMeasures, utterances: session.utterances, shortSample: session.shortSample, reliabilityFlags: session.reliabilityFlags });
});
router.get('/:childId/sessions', async (req, res) => {
  const child = await accessibleChild(req.params.childId, req.user); if (!child) return res.status(404).json({ message: 'Child profile not found' });
  res.json(await Session.find({ childId: child._id }).sort({ createdAt: -1 }).lean());
});
router.get('/sessions/:sessionId', async (req, res) => {
  const session = await sessionAccess(req.params.sessionId, req.user); if (!session) return res.status(404).json({ message: 'Session not found' }); res.json(session);
});
router.get('/:childId/export', async (req, res) => {
  const child = await accessibleChild(req.params.childId, req.user); if (!child) return res.status(404).json({ message: 'Child profile not found' });
  const sessions = await Session.find({ childId: child._id, status: 'completed' }).sort({ createdAt: 1 }).lean();
  res.json({ childId: child.childId, speakerId: String(child._id), sessions: sessions.map(s => ({ sessionId: s.sessionId, createdAt: s.createdAt, topicId: s.topicId, languageMeasures: s.languageMeasures, c1: s.c1, utterances: s.utterances })) });
});

module.exports = router;
