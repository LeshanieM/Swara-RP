const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const env = require('../../config/env');
const ApiError = require('../../lib/ApiError');

const ALLOWED_EXT = ['.wav', '.flac', '.ogg', '.mp3'];
// Each component keeps its uploads in its own subfolder.
const UPLOAD_DIR = path.join(env.uploadDir, 'c1');

fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const storage = multer.diskStorage({
  destination: UPLOAD_DIR,
  // Keep the extension: the speech service decodes by content, but it helps people and tools.
  filename: (_req, file, cb) => cb(null, `${crypto.randomUUID()}${path.extname(file.originalname).toLowerCase()}`),
});

const audioUpload = multer({
  storage,
  limits: { fileSize: env.maxUploadMb * 1024 * 1024, files: 1, fields: 20 },
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

module.exports = { audioUpload, ALLOWED_EXT };
