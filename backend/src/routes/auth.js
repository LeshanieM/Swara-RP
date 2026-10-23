const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();
const allowedRoles = new Set(['parent', 'therapist', 'child']);

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

function createToken(user) {
  return jwt.sign(
    { id: user._id, role: user.role },
    process.env.JWT_SECRET || 'swara_research_jwt_secret_change_in_production',
    { expiresIn: '7d' },
  );
}

function validName(name, maxLength) {
  return typeof name === 'string' && name.trim().length > 0 && name.trim().length <= maxLength;
}

function validAge(age) {
  return Number.isInteger(age) && age >= 5 && age <= 14;
}

router.get('/me', auth, async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'Profile not found.' });
    return res.json({ user: publicUser(user) });
  } catch (error) {
    return next(error);
  }
});

router.patch('/me', auth, async (req, res, next) => {
  try {
    const { name, childFirstName, childAge } = req.body;
    if (name !== undefined && !validName(name, 100)) {
      return res.status(400).json({ message: 'Enter a name up to 100 characters.' });
    }
    if (childFirstName !== undefined && !validName(childFirstName, 80)) {
      return res.status(400).json({ message: 'Enter the child name up to 80 characters.' });
    }
    if (childAge !== undefined && !validAge(childAge)) {
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
  } catch (error) {
    return next(error);
  }
});

router.post('/register', async (req, res, next) => {
  try {
    const { name, email, password, role, child } = req.body;
    const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';
    if (!validName(name, 100)) {
      return res.status(400).json({ message: 'Enter a name up to 100 characters.' });
    }
    if (
      normalizedEmail.length > 200 ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)
    ) {
      return res.status(400).json({ message: 'Enter a valid email address.' });
    }
    if (typeof password !== 'string' || password.length < 6 || password.length > 200) {
      return res.status(400).json({ message: 'Password must be between 6 and 200 characters.' });
    }
    if (!allowedRoles.has(role)) {
      return res.status(400).json({ message: 'Choose a valid account role.' });
    }
    if (
      role === 'child' &&
      child !== undefined &&
      (
        !child ||
        typeof child !== 'object' ||
        !validName(child.firstName, 80) ||
        !validAge(child.age)
      )
    ) {
      return res.status(400).json({ message: 'Enter a child name and age between 5 and 14.' });
    }

    if (await User.findOne({ email: normalizedEmail })) {
      return res.status(400).json({ message: 'Email already registered.' });
    }

    const user = new User({
      name: name.trim(),
      email: normalizedEmail,
      password: await bcrypt.hash(password, 10),
      role,
      child: role === 'child' && child ? child : undefined,
    });
    await user.save();

    const userData = publicUser(user);
    return res.status(201).json({
      ...userData,
      user: userData,
      token: createToken(user),
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Email already registered.' });
    }
    return next(error);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';
    if (!normalizedEmail || typeof password !== 'string') {
      return res.status(400).json({ message: 'Email and password are required.' });
    }

    const user = await User.findOne({ email: normalizedEmail });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(400).json({ message: 'Invalid credentials.' });
    }

    const userData = publicUser(user);
    return res.json({
      ...userData,
      user: userData,
      token: createToken(user),
    });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
