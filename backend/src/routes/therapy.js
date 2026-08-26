const express = require('express');
const { auth } = require('../middleware/auth');
const TherapyActivity = require('../models/TherapyActivity');
const TherapySession = require('../models/TherapySession');

const router = express.Router();

router.use(auth);

router.get('/recommendations/:childId', async (req, res) => {
  try {
    // Mock recommendation engine
    const mockRecommendations = {
      childId: req.params.childId,
      theme: 'Animal Adventure',
      activities: [
        {
          id: 'act_001',
          name: 'Slow Speech Practice',
          description: 'Practice speaking slowly and clearly using animal-themed sentences.',
          duration: 10,
          difficulty: 'Beginner',
          type: 'speech',
        },
        {
          id: 'act_002',
          name: 'Easy Onset Practice',
          description: 'Start sentences gently without forcing air through blocked sounds.',
          duration: 8,
          difficulty: 'Beginner',
          type: 'breathing',
        }
      ],
      sessionId: 'demo_session_001',
      isPrototype: true,
    };
    res.json(mockRecommendations);
  } catch (err) {
    res.status(500).json({ message: 'Failed to get recommendations' });
  }
});

router.post('/sessions', async (req, res) => {
  res.json({ sessionId: 'demo_session_001' });
});

router.get('/activities', async (req, res) => {
    try {
        const activities = await TherapyActivity.find();
        res.json(activities);
    } catch (e) {
        res.status(500).json({message: 'Failed to fetch activities'});
    }
})

module.exports = router;
