const express = require('express');
const { auth } = require('../middleware/auth');
const Child = require('../models/Child');
const C4Session = require('../models/component4/Session');

const router = express.Router();

router.use(auth);

router.use('/c4', require('./component4'));

router.post('/analyze', async (req, res) => {
  res.status(410).json({ message: 'This legacy mock endpoint is retired. Create a C4 session and submit its recording through /api/communication/c4/sessions/:sessionId/analyze.' });
});

router.get('/:childId', async (req, res, next) => {
  try {
    const ownership = req.user.role === 'therapist' ? { therapistId: req.user.id } : { parentId: req.user.id };
    const query = /^[a-f\d]{24}$/i.test(req.params.childId) ? { _id: req.params.childId } : { childId: req.params.childId };
    const child = await Child.findOne({ ...query, ...ownership });
    if (!child) return res.status(404).json({ message: 'Child profile not found' });
    const sessions = await C4Session.find({ childId: child._id }).sort({ createdAt: -1 }).lean();
    res.json(sessions);
  } catch (error) { next(error); }
});

module.exports = router;
