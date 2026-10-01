const recommendationService = require('../../services/component3/recommendationService');
const Child = require('../../models/Child');

const canAccessChild = (childId, user) => {
  const ownership = user.role === 'therapist'
    ? { therapistId: user.id }
    : { parentId: user.id };
  return Child.exists({ _id: childId, ...ownership });
};

const getNextActivity = async (req, res) => {
  try {
    const { childId, sessionId } = req.body;
    
    if (!childId || !sessionId) {
      return res.status(400).json({ message: 'childId and sessionId are required' });
    }

    if (!await canAccessChild(childId, req.user)) {
      return res.status(404).json({ message: 'Child profile not found' });
    }

    const activity = await recommendationService.recommendNextActivity(childId, sessionId);
    
    res.json({
      success: true,
      data: activity
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getNextActivity
};
