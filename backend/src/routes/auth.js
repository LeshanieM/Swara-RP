const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();

function publicUser(user) {
  return {
    id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    photoUrl: user.photoUrl || null,
    child: user.child || null,
  };
}

router.get('/me', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'Profile not found.' });
    return res.json({ user: publicUser(user) });
  } catch (_error) {
    return res.status(500).json({ message: 'Could not load profile.' });
  }
});

router.patch('/me', auth, async (req, res) => {
  try {
    const { name, childFirstName, childAge } = req.body;
    if (name !== undefined && (typeof name !== 'string' || !name.trim() || name.trim().length > 100)) {
      return res.status(400).json({ message: 'Enter a name up to 100 characters.' });
    }
    if (childFirstName !== undefined && (typeof childFirstName !== 'string' || !childFirstName.trim() || childFirstName.trim().length > 80)) {
      return res.status(400).json({ message: 'Enter the child name up to 80 characters.' });
    }
    if (childAge !== undefined && (!Number.isInteger(childAge) || childAge < 5 || childAge > 14)) {
      return res.status(400).json({ message: 'Child age must be between 5 and 14.' });
    }

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'Profile not found.' });
    if (name !== undefined) user.name = name.trim();
    if (childFirstName !== undefined || childAge !== undefined) {
      if (!user.child) user.child = { childId: '', firstName: '', age: undefined };
      if (childFirstName !== undefined) user.child.firstName = childFirstName.trim();
      if (childAge !== undefined) user.child.age = childAge;
    }
    await user.save();
    return res.json({ user: publicUser(user) });
  } catch (_error) {
    return res.status(500).json({ message: 'Could not update profile.' });
  }
});

router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role, child } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({
      name,
      email,
      password: hashedPassword,
      role,
      child: role === 'child' && child ? child : undefined,
    });
    await user.save();

    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET ||
        'swara_research_jwt_secret_change_in_production',
      { expiresIn: '7d' },
    );

    res.status(201).json({
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      user: publicUser(user),
      token,
    });
  } catch (err) {
    res
      .status(500)
      .json({ message: 'Registration failed', error: err.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET ||
        'swara_research_jwt_secret_change_in_production',
      { expiresIn: '7d' },
    );

    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      user: publicUser(user),
      token,
    });
  } catch (err) {
    res.status(500).json({ message: 'Login failed', error: err.message });
  }
});

module.exports = router;
