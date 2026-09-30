const express = require('express');
const router = express.Router();
const therapySessionController = require('../../controllers/component3/therapySessionController');
const { auth } = require('../../middleware/auth'); // Assuming auth is implemented

router.use(auth);

// POST /api/c3/therapy-sessions
router.post('/', therapySessionController.createSession);

// POST /api/c3/therapy-sessions/:sessionId/activity-result
router.post('/:sessionId/activity-result', therapySessionController.recordActivityResult);

// POST /api/c3/therapy-sessions/:sessionId/complete
router.post('/:sessionId/complete', therapySessionController.completeSession);

// GET /api/c3/therapy-sessions/history/:childId
router.get('/history/:childId', therapySessionController.getTherapyHistory);

module.exports = router;
