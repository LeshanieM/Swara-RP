const crypto = require('crypto');
const TherapySession = require('../../models/component3/TherapySession');
const ActivityResult = require('../../models/component3/ActivityResult');
const ParentQuestionnaire = require('../../models/component3/ParentQuestionnaire');
const Child = require('../../models/Child');
const { calculateAndSaveTSS } = require('../../services/component3/tssService');
const { addLogsOnlyEngagement } = require('../../services/component3/recommendationService');

// ---------------------------------------------------------------------------
// Access helpers
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// POST /api/c3/therapy-sessions
// ---------------------------------------------------------------------------
const createSession = async (req, res) => {
  try {
    const { childId, planId, selectedActivities, contextSnapshot, modelVersion } = req.body;

    let effectiveChildId = childId;
    if (effectiveChildId) {
      if (!await canAccessChild(effectiveChildId, req.user)) {
        return res.status(404).json({ success: false, message: 'Child profile not found' });
      }
    } else {
      const child = await Child.findOne({ parentId: req.user.id }).select('_id').lean();
      if (child) effectiveChildId = child._id;
    }

    const sessionId = `sess_${crypto.randomUUID()}`;
    let snapshot = contextSnapshot || null;
    if (!snapshot && effectiveChildId) {
      try {
        const { vector } = await require('../../services/component3/contextBuilder').buildContext(effectiveChildId, sessionId);
        snapshot = vector; // store only the numeric array — schema type is [Number]
      } catch (_) {}
    }

    const newSession = new TherapySession({
      sessionId,
      ownerId: req.user.id,
      childId: effectiveChildId,
      planId,
      selectedActivities: selectedActivities || [],
      status: 'In Progress',
      contextSnapshot: snapshot,
      modelVersion: modelVersion || 'hybrid_linucb_v1',
    });

    await newSession.save();
    res.status(201).json({ success: true, data: { sessionId: newSession.sessionId, _id: newSession._id } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ---------------------------------------------------------------------------
// POST /api/c3/therapy-sessions/:sessionId/activity-result
// ---------------------------------------------------------------------------
const recordActivityResult = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const {
      activityId,
      targetOpportunities,
      successfulOpportunities,
      completionFraction,
      attempted,
      completed,
      skipped,
      skipReason,
      durationSeconds,
      responseTimeMs,
      parentDifficultyFeedback,
      parentHelpLevel,
      engagementScore,
      engagementMode,
      recommendationActionId,
      contextSnapshot,
    } = req.body;

    const session = await TherapySession.findOne({ sessionId });
    if (!session) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }
    if (!await canAccessSession(session, req.user)) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }
    if (session.status === 'Completed' || session.status === 'Terminated') {
      return res.status(409).json({
        success: false,
        message: `Cannot add result to a ${session.status} session`,
      });
    }

    if (!activityId) {
      return res.status(400).json({ success: false, message: 'activityId is required' });
    }

    const result = new ActivityResult({
      sessionId: session._id,
      activityId,
      targetOpportunities: targetOpportunities ?? null,
      successfulOpportunities: successfulOpportunities ?? null,
      completionFraction: completionFraction ?? null,
      attempted: attempted ?? true,
      completed: completed ?? false,
      skipped: skipped ?? false,
      skipReason: skipReason ?? null,
      durationSeconds: durationSeconds ?? null,
      responseTimeMs: responseTimeMs ?? null,
      parentDifficultyFeedback: parentDifficultyFeedback ?? null,
      parentHelpLevel: parentHelpLevel ?? null,
      engagementScore: engagementScore ?? null,
      engagementMode: engagementMode || 'unavailable',
      recommendationActionId: recommendationActionId ?? null,
      contextSnapshot: contextSnapshot ?? null,
    });

    await result.save(); // triggers P and reward computation in pre-save hook

    // If no engagement score was provided, compute logs-only estimate.
    if (result.engagementScore === null) {
      try {
        await addLogsOnlyEngagement(result._id.toString());
        await result.reload?.(); // refresh if method exists; result is re-fetched below
      } catch (engErr) {
        // Non-fatal — engagement estimate is optional.
        console.error('[C3] Engagement estimation error:', engErr.message);
      }
    }

    // Re-fetch to return computed fields.
    const saved = await ActivityResult.findById(result._id);
    res.status(201).json({ success: true, data: saved });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ---------------------------------------------------------------------------
// POST /api/c3/therapy-sessions/:sessionId/complete
// ---------------------------------------------------------------------------
const completeSession = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { resultSummary } = req.body;

    const existingSession = await TherapySession.findOne({ sessionId });
    if (!existingSession || !await canAccessSession(existingSession, req.user)) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }
    if (existingSession.status === 'Completed') {
      // Idempotent — return existing outcome.
      return res.json({
        success: true,
        data: { session: existingSession, outcome: { tss: existingSession.tss } },
        note: 'Session was already completed',
      });
    }

    // Update status and end time.
    const updates = { status: 'Completed', endTime: Date.now() };
    if (resultSummary && typeof resultSummary === 'object') {
      updates.resultSummary = resultSummary;
    }
    const session = await TherapySession.findByIdAndUpdate(
      existingSession._id, updates, { new: true }
    );
    if (!session) return res.status(404).json({ success: false, message: 'Session not found' });

    // Calculate TSS (uses the fixed findOne({ sessionId }) internally).
    let outcome = null;
    try {
      outcome = await calculateAndSaveTSS(sessionId);
    } catch (tssErr) {
      console.error('[C3] TSS calculation error:', tssErr.message);
      // Non-fatal — session is still completed, TSS remains null.
    }

    res.json({ success: true, data: { session, outcome } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ---------------------------------------------------------------------------
// GET /api/c3/therapy-sessions/history/account
// ---------------------------------------------------------------------------
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
    }).sort({ createdAt: -1 }).limit(50);
    res.json({ success: true, data: sessions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ---------------------------------------------------------------------------
// GET /api/c3/therapy-sessions/history/:childId
// ---------------------------------------------------------------------------
const getTherapyHistory = async (req, res) => {
  try {
    const { childId } = req.params;
    if (!await canAccessChild(childId, req.user)) {
      return res.status(404).json({ success: false, message: 'Child profile not found' });
    }
    const sessions = await TherapySession.find({ childId }).sort({ createdAt: -1 }).limit(50);
    res.json({ success: true, data: sessions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ---------------------------------------------------------------------------
// GET /api/c3/therapy-sessions/:sessionId
// ---------------------------------------------------------------------------
const getSession = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const session = await TherapySession.findOne({ sessionId });
    if (!session || !await canAccessSession(session, req.user)) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }
    const results = await ActivityResult.find({ sessionId: session._id });
    res.json({ success: true, data: { session, activityResults: results } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ---------------------------------------------------------------------------
// POST /api/c3/therapy-sessions/:sessionId/questionnaire
// ---------------------------------------------------------------------------
const submitQuestionnaire = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { version, responses } = req.body;

    if (!version || !responses || typeof responses !== 'object') {
      return res.status(400).json({
        success: false,
        message: 'version and responses are required',
      });
    }

    const session = await TherapySession.findOne({ sessionId });
    if (!session || !await canAccessSession(session, req.user)) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }

    // Convert responses object to Map for mongoose.
    const responseMap = new Map(Object.entries(responses).map(([k, v]) => [k, Number(v)]));

    // Upsert questionnaire to allow parent to adjust rating without errors.
    let questionnaire = await ParentQuestionnaire.findOne({ sessionId: session._id });
    if (questionnaire) {
      questionnaire.responses = responseMap;
      questionnaire.version = version;
      questionnaire.completedAt = new Date();
      await questionnaire.save();
    } else {
      questionnaire = new ParentQuestionnaire({
        sessionId: session._id,
        ownerId: req.user.id,
        version,
        responses: responseMap,
        completedAt: new Date(),
      });
      await questionnaire.save();
    }

    // Update session with questionnaire result (full object to avoid dot-notation on null).
    await TherapySession.findByIdAndUpdate(session._id, {
      parentQuestionnaire: {
        version: questionnaire.version,
        responses: Object.fromEntries(responseMap),
        rawScore: questionnaire.rawScore,
        scaledScore: questionnaire.scaledScore,
        completedAt: questionnaire.completedAt,
      },
    });

    // Recalculate TSS with questionnaire included (if session is completed).
    let tssResult = null;
    if (session.status === 'Completed') {
      try {
        tssResult = await calculateAndSaveTSS(sessionId);
      } catch (e) {
        console.error('[C3] TSS recalculation error after questionnaire:', e.message);
      }
    }

    res.status(201).json({
      success: true,
      data: {
        questionnaire: {
          version: questionnaire.version,
          rawScore: questionnaire.rawScore,
          scaledScore: questionnaire.scaledScore,
        },
        tss: tssResult,
      },
    });
  } catch (error) {
    console.error('[C3] submitQuestionnaire error:', error);
    if (error.name === 'ValidationError' || error.message.includes('Questionnaire version')) {
      return res.status(400).json({ success: false, message: error.message });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  createSession,
  recordActivityResult,
  completeSession,
  getSession,
  getTherapyHistory,
  getAccountTherapyHistory,
  submitQuestionnaire,
};
