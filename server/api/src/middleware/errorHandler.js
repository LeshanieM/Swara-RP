const fs = require('fs');
const multer = require('multer');
const { ZodError } = require('zod');
const mongoose = require('mongoose');
const env = require('../config/env');
const ApiError = require('../lib/ApiError');

const send = (res, status, code, message, details) => res.status(status).json({ error: { code, message, details: details ?? null } });

const DB_DOWN = /ServerSelection|NotConnected|buffering timed out|ECONNREFUSED|connection .* closed/i;
const isDatabaseDown = (err) => DB_DOWN.test(err.name || '') || DB_DOWN.test(err.message || '');

function notFound(req, res) {
  send(res, 404, 'route_not_found', `No route for ${req.method} ${req.originalUrl}`);
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, _next) {
  // A request that failed after its upload was written must not leave audio behind.
  if (req.file?.path) fs.rm(req.file.path, { force: true }, () => {});

  if (err instanceof ApiError) return send(res, err.status, err.code, err.message, err.details);
  if (err instanceof ZodError) {
    const details = err.issues.map((i) => ({ field: i.path.join('.') || null, message: i.message }));
    return send(res, 422, 'validation_error', 'Invalid request.', details);
  }
  if (err instanceof multer.MulterError) {
    // Each upload middleware sets req.uploadLimit ({ kind, mb }); C1's audio limit is the default.
    if (err.code === 'LIMIT_FILE_SIZE') {
      const { kind, mb } = req.uploadLimit || { kind: 'Audio', mb: env.maxUploadMb };
      return send(res, 413, 'file_too_large', `${kind} exceeds ${mb} MB.`);
    }
    return send(res, 400, 'invalid_upload', `${err.message}${err.field ? ` (${err.field})` : ''}`);
  }
  if (err instanceof mongoose.Error.CastError) return send(res, 400, 'invalid_id', `Invalid ${err.path}.`);
  if (isDatabaseDown(err)) return send(res, 503, 'database_unavailable', 'The database is unavailable; retry shortly.');
  if (err.type === 'entity.parse.failed') return send(res, 400, 'invalid_json', 'Request body is not valid JSON.');

  console.error('[api] unhandled error:', err);
  return send(res, 500, 'internal_error', 'Something went wrong.');
}

module.exports = { errorHandler, notFound };
