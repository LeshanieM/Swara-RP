const axios = require('axios');
const TherapySession = require('../../models/component3/TherapySession');
const ActivityResult = require('../../models/component3/ActivityResult');
const Child = require('../../models/Child');
const { verifyExpectedAnswer } = require('../../services/component3/speechMatcher');

const canAccessSession = async (session, user) => {
  if (session.ownerId && String(session.ownerId) === String(user.id)) return true;
  if (!session.childId) return false;
  const ownership = user.role === 'therapist'
    ? { therapistId: user.id }
    : { parentId: user.id };
  return Boolean(await Child.exists({ _id: session.childId, ...ownership }));
};

const verifySpeech = async (req, res) => {
  try {
    const session = await TherapySession.findOne({ sessionId: req.params.sessionId });
    if (!session || !await canAccessSession(session, req.user)) return res.status(404).json({ success: false, message: 'Session not found' });
    if (!req.file || !req.body.activityId || !req.body.expectedAnswers) return res.status(400).json({ success: false, message: 'audio, activityId and expectedAnswers are required' });
    const expectedAnswers = JSON.parse(req.body.expectedAnswers);
    if (!Array.isArray(expectedAnswers) || !expectedAnswers.every((item) => typeof item === 'string')) return res.status(400).json({ success: false, message: 'expectedAnswers must be a JSON array of strings' });
    // Node 18 FormData keeps this buffer in memory. The route never writes audio to disk.
    const form = new FormData();
    form.append('audio', new Blob([req.file.buffer], { type: req.file.mimetype || 'audio/mp4' }), req.file.originalname || 'response.m4a');
    let transcription;
    try {
      transcription = (await axios.post(`${process.env.AI_SERVICE_URL || 'http://localhost:8000'}/speech/transcribe`, form, { timeout: 30000 })).data;
    } catch (_) {
      return res.status(503).json({ success: false, status: 'could_not_recognize', message: 'Sinhala recognition is unavailable. Please try again later.' });
    }
    const verification = verifyExpectedAnswer({ transcript: transcription.text, confidence: transcription.confidence, expectedAnswers });
    const saved = await ActivityResult.create({
      sessionId: session._id, activityId: req.body.activityId, attempted: true,
      speechVerification: { promptId: req.body.promptId || null, expectedAnswers, recognizedText: transcription.text || '', confidence: transcription.confidence ?? null, status: verification.status, similarity: verification.similarity },
    });
    res.json({ success: true, data: { ...verification, recognizedText: transcription.text || '', confidence: transcription.confidence ?? null, activityResultId: saved._id } });
  } catch (error) { res.status(500).json({ success: false, message: error.message }); }
};
module.exports = { verifySpeech };
