const express = require('express');
const { auth } = require('../middleware/auth');

const router = express.Router();

router.use(auth);

router.post('/analyze', async (req, res) => {
  try {
    const mockResult = {
        childId: req.body.childId,
        scores: {
          keywordRelevance: 8.0,
          responseLength: 7.0,
          speechFluency: 6.0,
          responseOrganization: 8.0,
        },
        overallScore: 7.25,
        status: 'Improving',
        isPrototype: true,
      };
    res.json(mockResult);
  } catch (err) {
    res.status(500).json({ message: 'Failed to analyze communication' });
  }
});

router.get('/:childId', async (req, res) => {
    res.json([]);
});

module.exports = router;
