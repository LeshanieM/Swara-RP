const express = require('express');
const { auth } = require('../middleware/auth');
const PsychologicalAssessment = require('../models/PsychologicalAssessment');

const router = express.Router();

router.use(auth);

router.post('/assessment', async (req, res) => {
  try {
    const { childId, answers } = req.body;
    
    // Mock processing for prototype
    const mockResult = {
      score: 55.0,
      level: 'Medium',
      childId: childId,
      supportAreas: [
        {
          area: 'Speaking Confidence',
          score: 45,
          suggestions: [
            'Positive reinforcement during conversations',
            'Family speaking activities',
            'Encouraging daily speech activities',
          ],
        },
        {
          area: 'Emotion Expression',
          score: 60,
          suggestions: [
            'Emotion expression through drawing',
            'Choosing emotions from picture cards',
            'Talking with a parent about the child\'s day',
          ],
        },
        {
          area: 'Social Participation',
          score: 50,
          suggestions: [
            'Group storytelling activities',
            'Sharing time at school',
            'Supervised peer interaction',
          ],
        },
      ],
      caregiverGuidance: 'Encourage the child to communicate without interrupting or showing negative reactions to stuttering. Create a calm and supportive environment for speech practice.',
      isPrototype: true,
    };

    res.json(mockResult);
  } catch (err) {
    res.status(500).json({ message: 'Failed to process assessment', error: err.message });
  }
});

router.get('/:childId', async (req, res) => {
    // Return history
    res.json({});
});

module.exports = router;
