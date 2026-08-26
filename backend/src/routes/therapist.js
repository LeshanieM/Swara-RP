const express = require('express');
const { auth, restrictTo } = require('../middleware/auth');
const Child = require('../models/Child');

const router = express.Router();

router.use(auth);
router.use(restrictTo('therapist'));

router.get('/children', async (req, res) => {
  try {
    const children = await Child.find({ therapistId: req.user.id });
    res.json(children);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch therapist children' });
  }
});

module.exports = router;
