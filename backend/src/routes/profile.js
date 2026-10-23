const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const express = require('express');
const multer = require('multer');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();
const photoDirectory = path.join(__dirname, '..', '..', 'uploads', 'profile-photos');
const allowedTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);

const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, callback) => {
      fs.mkdir(photoDirectory, { recursive: true }, (error) => callback(error, photoDirectory));
    },
    filename: (_req, file, callback) => {
      const extension = file.mimetype === 'image/png'
        ? '.png'
        : file.mimetype === 'image/webp' ? '.webp' : '.jpg';
      callback(null, `${crypto.randomUUID()}${extension}`);
    },
  }),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, callback) => {
    if (!allowedTypes.has(file.mimetype)) {
      return callback(new Error('Choose a JPG, PNG, or WebP image.'));
    }
    callback(null, true);
  },
});

router.get('/photo/:filename', auth, async (req, res) => {
  if (!/^[a-f0-9-]{36}\.(jpg|png|webp)$/.test(req.params.filename)) {
    return res.status(404).json({ message: 'Profile image not found.' });
  }
  try {
    const user = await User.findById(req.user.id).select('photoUrl');
    if (!user || path.basename(user.photoUrl || '') !== req.params.filename) {
      return res.status(404).json({ message: 'Profile image not found.' });
    }
    return res.sendFile(path.join(photoDirectory, req.params.filename), (error) => {
      if (error && !res.headersSent) res.status(404).json({ message: 'Profile image not found.' });
    });
  } catch (_error) {
    return res.status(500).json({ message: 'Could not load profile image.' });
  }
});

router.post('/photo', auth, upload.single('photo'), async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'Choose an image to upload.' });

  try {
    const photoUrl = `/api/profile/photo/${req.file.filename}`;
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { photoUrl },
      { new: true, select: 'photoUrl' },
    );
    if (!user) {
      fs.unlink(req.file.path, () => {});
      return res.status(404).json({ message: 'Profile not found.' });
    }
    return res.json({ photoUrl: user.photoUrl });
  } catch (error) {
    fs.unlink(req.file.path, () => {});
    return res.status(500).json({ message: 'Could not save profile image.' });
  }
});

module.exports = router;
