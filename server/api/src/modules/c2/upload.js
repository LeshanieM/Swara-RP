const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const env = require('../../config/env');
const ApiError = require('../../lib/ApiError');

const ALLOWED_EXT = ['.mp4', '.mov', '.m4v', '.webm', '.mkv', '.avi'];
// Each component keeps its uploads in its own subfolder.
const UPLOAD_DIR = path.join(env.uploadDir, 'c2');

fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const storage = multer.diskStorage({
  destination: UPLOAD_DIR,
  filename: (_req, file, cb) => cb(null, `${crypto.randomUUID()}${path.extname(file.originalname).toLowerCase()}`),
});

const upload = multer({
  storage,
  limits: { fileSize: env.maxVideoUploadMb * 1024 * 1024, files: 1, fields: 30 },
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (!ALLOWED_EXT.includes(ext)) {
      return cb(ApiError.unprocessable(
        'unsupported_video_type',
        `Video must be one of ${ALLOWED_EXT.join(', ')}; got "${ext || 'no extension'}".`,
      ));
    }
    return cb(null, true);
  },
}).single('video');

// The error handler reads req.uploadLimit to word the "too large" message.
const videoUpload = (req, res, next) => {
  req.uploadLimit = { kind: 'Video', mb: env.maxVideoUploadMb };
  upload(req, res, next);
};

module.exports = { videoUpload, ALLOWED_EXT, UPLOAD_DIR };
