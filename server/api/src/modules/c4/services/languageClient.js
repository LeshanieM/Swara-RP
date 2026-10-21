const fs = require('fs');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');
const env = require('../../../config/env');
const ApiError = require('../../../lib/ApiError');

/** Failure talking to the language service; `code` is stored on the failed sample. */
class LanguageServiceError extends Error {
  constructor(code, message, status) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

const http = axios.create({ baseURL: env.languageServiceUrl });

function mapError(err) {
  if (err.response) {
    const e = err.response.data?.error;
    return new LanguageServiceError(e?.code || 'language_service_error', e?.message || `Language service returned ${err.response.status}.`, err.response.status);
  }
  if (err.code === 'ECONNABORTED' || err.code === 'ETIMEDOUT') {
    return new LanguageServiceError('language_service_timeout', `Language service did not answer within ${env.languageTimeoutMs} ms.`);
  }
  return new LanguageServiceError('language_service_unavailable', `Language service unreachable at ${env.languageServiceUrl} (${err.code || err.message}).`);
}

async function health() {
  const { data } = await http.get('/health', { timeout: 3000 });
  return data;
}

async function transcribe({ filePath, originalName }) {
  const form = new FormData();
  form.append('audio', fs.createReadStream(filePath), { filename: originalName || path.basename(filePath) });
  try {
    const { data } = await http.post('/transcribe', form, {
      headers: form.getHeaders(), timeout: env.languageTimeoutMs, maxBodyLength: Infinity,
    });
    return data;
  } catch (err) {
    throw mapError(err);
  }
}

/** Text-only analysis: timed words and/or a typed transcript, plus C1 events. */
async function measures(body) {
  try {
    const { data } = await http.post('/measures', body, { timeout: 60000 });
    return data;
  } catch (err) {
    throw mapError(err);
  }
}

/**
 * For calls made while a client waits (corrections, known words): report the
 * language service's own failure, so the shared error handler doesn't read
 * "ECONNREFUSED" in the message as a database outage.
 */
function toApiError(err) {
  if (!(err instanceof LanguageServiceError)) return err;
  const down = ['language_service_unavailable', 'language_service_timeout', 'busy'].includes(err.code);
  return new ApiError(down ? 503 : (err.status === 422 ? 422 : 502), err.code, err.message);
}

module.exports = {
  health, transcribe, measures, toApiError, LanguageServiceError,
};
