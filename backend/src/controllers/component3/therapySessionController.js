const crypto = require('crypto');
const TherapySession = require('../../models/component3/TherapySession');
const ActivityResult = require('../../models/component3/ActivityResult');
const Child = require('../../models/Child');
const tssService = require('../../services/component3/tssService');

const canAccessChild = (childId, user) => {
  const ownership = user.role === 'therapist'
    ? { therapistId: user.id }
    : { parentId: user.id };
  return Child.exists({ _id: childId, ...ownership });
};

const canAccessSession = async (session, user) => {
  if (session.ownerId && session.ownerId.toString() === user.id) return true;
  return session.childId
    ? Boolean(await canAccessChild(session.childId, user))
    : false;
};

const createSession = async (req, res) => {
  try {
    const { childId, planId, selectedActivities } = req.body;

    if (childId && !await canAccessChild(childId, req.user)) {
      return res.status(404).json({ success: false, message: 'Child profile not found' });
    }

    const newSession = new TherapySession({
      sessionId: `sess_${crypto.randomUUID()}`,
      ownerId: req.user.id,
      childId,
      planId,
      selectedActivities,
      status: 'In Progress'
    });
    
    await newSession.save();
    res.status(201).json({ success: true, data: newSession });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const recordActivityResult = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { activityId, targetOpportunities, successfulOpportunities, attempted, completed, duration } = req.body;
    const session = await TherapySession.findOne({ sessionId });

    if (!session) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }
    if (!await canAccessSession(session, req.user)) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }

    const result = new ActivityResult({
      sessionId: session._id,
      activityId,
      targetOpportunities,
      successfulOpportunities,
      attempted,
      completed,
      duration
    });

    await result.save();
    res.status(201).json({ success: true, data: result });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const completeSession = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { resultSummary } = req.body;
    const existingSession = await TherapySession.findOne({ sessionId });

    if (!existingSession || !await canAccessSession(existingSession, req.user)) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }

    const updates = { status: 'Completed', endTime: Date.now() };
    if (resultSummary && typeof resultSummary === 'object') {
      updates.resultSummary = resultSummary;
    }
    const session = await TherapySession.findByIdAndUpdate(existingSession._id, updates, { new: true });
    
    if (!session) return res.status(404).json({ success: false, message: 'Session not found' });

    // Calculate TSS and update LinUCB (via tssService)
    const outcome = existingSession.planId && existingSession.childId
      ? await tssService.calculatePlanTSS(sessionId)
      : null;

    res.json({ success: true, data: { session, outcome } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getTherapyHistory = async (req, res) => {
  try {
    const { childId } = req.params;
    if (!await canAccessChild(childId, req.user)) {
      return res.status(404).json({ success: false, message: 'Child profile not found' });
    }
    const sessions = await TherapySession.find({ childId }).sort({ createdAt: -1 });
    res.json({ success: true, data: sessions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getAccountTherapyHistory = async (req, res) => {
  try {
    const ownership = req.user.role === 'therapist'
      ? { therapistId: req.user.id }
      : { parentId: req.user.id };
    const ownedChildren = await Child.find(ownership).distinct('_id');
    const sessions = await TherapySession.find({
      $or: [
        { ownerId: req.user.id },
        ...(ownedChildren.length > 0 ? [{ childId: { $in: ownedChildren } }] : []),
      ],
    }).sort({ createdAt: -1 });
    res.json({ success: true, data: sessions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  createSession,
  recordActivityResult,
  completeSession,
  getTherapyHistory,
  getAccountTherapyHistory,
};
