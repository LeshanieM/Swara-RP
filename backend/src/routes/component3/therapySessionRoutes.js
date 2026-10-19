const express = require('express');
const router = express.Router();
const therapySessionController = require('../../controllers/component3/therapySessionController');
const { verifySpeech } = require('../../controllers/component3/speechVerificationController');
const { auth } = require('../../middleware/auth'); // Assuming auth is implemented
const multer = require('multer');
const memoryUpload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 } });

router.use(auth);

// POST /api/c3/therapy-sessions
router.post('/', therapySessionController.createSession);

// GET /api/c3/therapy-sessions/history/account  — MUST be before /:sessionId
router.get('/history/account', therapySessionController.getAccountTherapyHistory);

// GET /api/c3/therapy-sessions/history/:childId  — MUST be before /:sessionId
router.get('/history/:childId', therapySessionController.getTherapyHistory);

// GET /api/c3/therapy-sessions/:sessionId
router.get('/:sessionId', therapySessionController.getSession);

// POST /api/c3/therapy-sessions/:sessionId/activity-result
router.post('/:sessionId/activity-result', therapySessionController.recordActivityResult);
router.post('/:sessionId/speech-verification', memoryUpload.single('audio'), verifySpeech);

// POST /api/c3/therapy-sessions/:sessionId/complete
router.post('/:sessionId/complete', therapySessionController.completeSession);

// POST /api/c3/therapy-sessions/:sessionId/questionnaire
router.post('/:sessionId/questionnaire', therapySessionController.submitQuestionnaire);

module.exports = router;
