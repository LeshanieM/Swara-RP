const express = require('express');
const router = express.Router();
const activityController = require('../../controllers/component3/activityController');
const { auth } = require('../../middleware/auth');

// Public or authenticated list of activities
router.get('/', activityController.getActivities);
router.get('/:id', activityController.getActivityById);

// Seeding endpoint (authenticated)
router.post('/seed', auth, activityController.seedActivities);

module.exports = router;
