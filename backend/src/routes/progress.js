const express = require('express');
const { auth } = require('../middleware/auth');
const ProgressRecord = require('../models/ProgressRecord');

const router = express.Router();

router.use(auth);

router.get('/:childId', async (req, res) => {
  try {
    const history = [
        { session: 1, date: '2025-11-01', speechScore: 0.0, commScore: 5.4, therapyScore: 0.0 },
        { session: 2, date: '2025-11-08', speechScore: 0.0, commScore: 5.8, therapyScore: 72.0 },
        { session: 3, date: '2025-11-15', speechScore: 0.0, commScore: 6.2, therapyScore: 75.0 },
        { session: 4, date: '2025-11-22', speechScore: 0.0, commScore: 6.9, therapyScore: 80.0 },
        { session: 5, date: '2025-11-29', speechScore: 0.0, commScore: 7.5, therapyScore: 85.0 },
    ];
    res.json(history);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch progress' });
  }
});

module.exports = router;
