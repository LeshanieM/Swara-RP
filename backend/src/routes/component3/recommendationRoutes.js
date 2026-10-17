const express = require('express');
const router = express.Router();
const recommendationController = require('../../controllers/component3/recommendationController');
const { auth } = require('../../middleware/auth');

router.use(auth);

// GET /api/c3/recommendations/context
router.get('/context', recommendationController.getContext);

// GET /api/c3/recommendations/shared-state
router.get('/shared-state', recommendationController.getSharedState);

// POST /api/c3/recommendations/sync
router.post('/sync', recommendationController.syncState);

// POST /api/c3/recommendations/next-activity
router.post('/next-activity', recommendationController.getNextActivity);

module.exports = router;
