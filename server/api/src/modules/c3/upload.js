const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const env = require('../../config/env');
const ApiError = require('../../lib/ApiError');

const ALLOWED_EXT = ['.wav', '.flac', '.ogg', '.mp3'];
// One spoken word per clip; a few seconds of WAV is well under this.
const MAX_WORD_CLIP_MB = 10;
// Each component keeps its uploads in its own subfolder.
const UPLOAD_DIR = path.join(env.uploadDir, 'c3');

fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const storage = multer.diskStorage({
  destination: UPLOAD_DIR,
  filename: (_req, file, cb) => cb(null, `${crypto.randomUUID()}${path.extname(file.originalname).toLowerCase()}`),
});

const upload = multer({
  storage,
  limits: { fileSize: MAX_WORD_CLIP_MB * 1024 * 1024, files: 1, fields: 5 },
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (!ALLOWED_EXT.includes(ext)) {
      return cb(ApiError.unprocessable(
        'unsupported_audio_type',
        `Audio must be one of ${ALLOWED_EXT.join(', ')} (16 kHz mono WAV preferred); got "${ext || 'no extension'}".`,
      ));
    }
    return cb(null, true);
  },
}).single('audio');

// The error handler reads req.uploadLimit to word the "too large" message.
function wordClipUpload(req, res, next) {
  req.uploadLimit = { kind: 'Audio', mb: MAX_WORD_CLIP_MB };
  upload(req, res, next);
}

module.exports = { wordClipUpload, UPLOAD_DIR, ALLOWED_EXT };
