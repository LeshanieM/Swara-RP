const express = require('express');
const router = express.Router();
const recommendationController = require('../../controllers/component3/recommendationController');
const { auth } = require('../../middleware/auth');

router.use(auth);

// POST /api/c3/recommendations/next-activity
router.post('/next-activity', recommendationController.getNextActivity);

module.exports = router;
