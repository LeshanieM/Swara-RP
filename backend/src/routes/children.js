const express = require('express');
const Child = require('../models/Child');
const { auth } = require('../middleware/auth');

const router = express.Router();

router.use(auth);

// Get all children for the logged-in user
router.get('/', async (req, res) => {
  try {
    const query = req.user.role === 'therapist' 
      ? { therapistId: req.user.id } 
      : { parentId: req.user.id };
      
    const children = await Child.find(query);
    res.json(children);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch children' });
  }
});

// Create a new child profile
router.post('/', async (req, res) => {
  try {
    const count = await Child.countDocuments();
    const childId = `CH-${String(count + 1).padStart(3, '0')}`;
    
    const childData = {
      ...req.body,
      childId,
    };

    if (req.user.role === 'parent') {
      childData.parentId = req.user.id;
    } else if (req.user.role === 'therapist') {
      childData.therapistId = req.user.id;
    }

    const child = new Child(childData);
    await child.save();
    res.status(201).json(child);
  } catch (err) {
    res.status(500).json({ message: 'Failed to create child profile', error: err.message });
  }
});

// Get a specific child by ID or childId
router.get('/:id', async (req, res) => {
  try {
    const query = mongoose.Types.ObjectId.isValid(req.params.id) 
      ? { _id: req.params.id }
      : { childId: req.params.id };

    const child = await Child.findOne(query);
    if (!child) {
      return res.status(404).json({ message: 'Child not found' });
    }
    res.json(child);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch child details' });
  }
});

module.exports = router;
