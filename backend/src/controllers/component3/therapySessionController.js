const TherapySession = require('../../models/component3/TherapySession');
const ActivityResult = require('../../models/component3/ActivityResult');
const tssService = require('../../services/component3/tssService');

const createSession = async (req, res) => {
  try {
    const { childId, planId, selectedActivities } = req.body;
    
    // In production, sessionId would be uniquely generated
    const newSession = new TherapySession({
      sessionId: `sess_${Date.now()}`,
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

    const result = new ActivityResult({
      sessionId,
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
    
    // Mark session as completed
    const session = await TherapySession.findByIdAndUpdate(
      sessionId, 
      { status: 'Completed', endTime: Date.now() },
      { new: true }
    );
    
    if (!session) return res.status(404).json({ success: false, message: 'Session not found' });

    // Calculate TSS and update LinUCB (via tssService)
    const outcome = await tssService.calculatePlanTSS(sessionId);

    res.json({ success: true, data: { session, outcome } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getTherapyHistory = async (req, res) => {
  try {
    const { childId } = req.params;
    const sessions = await TherapySession.find({ childId }).sort({ createdAt: -1 });
    res.json({ success: true, data: sessions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  createSession,
  recordActivityResult,
  completeSession,
  getTherapyHistory
};
