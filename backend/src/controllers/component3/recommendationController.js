const recommendationService = require('../../services/component3/recommendationService');

const getNextActivity = async (req, res) => {
  try {
    const { childId, sessionId } = req.body;
    
    if (!childId || !sessionId) {
      return res.status(400).json({ message: 'childId and sessionId are required' });
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
