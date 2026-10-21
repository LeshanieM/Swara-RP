// The language service's word check (POST /verify-word). The service and its CTC model are shared with C4.
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');
const env = require('../../../config/env');
const ApiError = require('../../../lib/ApiError');

const http = axios.create({ baseURL: env.languageServiceUrl });

/** Reports the language service's own failure, so the shared error handler doesn't read ECONNREFUSED as a database outage. */
function toApiError(err) {
  if (err.response) {
    const e = err.response.data?.error;
    const code = e?.code || 'word_check_failed';
    const message = e?.message || `Language service returned ${err.response.status}.`;
    // 422s are about the clip (too short, silent, unreadable): the app should record the word again.
    if (err.response.status === 422 || err.response.status === 413) return new ApiError(422, code, message);
    if (err.response.status === 503) return new ApiError(503, 'word_check_unavailable', message);
    return new ApiError(502, code, message);
  }
  if (err.code === 'ECONNABORTED' || err.code === 'ETIMEDOUT') {
    return new ApiError(503, 'word_check_unavailable', `Language service did not answer within ${env.c3WordCheckTimeoutMs} ms.`);
  }
  return new ApiError(503, 'word_check_unavailable', `Language service unreachable at ${env.languageServiceUrl} (${err.code || err.message}).`);
}

async function health() {
  try {
    const { data } = await http.get('/health', { timeout: 3000 });
    return { status: 'ok', ctc: data.engines?.ctc?.status ?? 'unknown' };
  } catch (err) {
    return { status: 'unreachable', error: err.code || err.message };
  }
}

async function verify({ filePath, originalName, expected, alternatives }) {
  const form = new FormData();
  form.append('audio', fs.createReadStream(filePath), { filename: originalName || path.basename(filePath) });
  form.append('expected', expected);
  if (alternatives.length) form.append('alternatives', JSON.stringify(alternatives));
  try {
    const { data } = await http.post('/verify-word', form, {
      headers: form.getHeaders(), timeout: env.c3WordCheckTimeoutMs, maxBodyLength: Infinity,
    });
    return data;
  } catch (err) {
    throw toApiError(err);
  }
}

/** C3 reading / picture description (POST /check-speech): transcribes, then compares with the passage or keywords. */
async function checkSpeech({ filePath, originalName, mode, reference, keywords }) {
  const form = new FormData();
  form.append('audio', fs.createReadStream(filePath), { filename: originalName || path.basename(filePath) });
  form.append('mode', mode);
  if (reference) form.append('reference', reference);
  if (keywords) form.append('keywords', JSON.stringify(keywords));
  try {
    const { data } = await http.post('/check-speech', form, {
      // A passage takes longer to transcribe than one word.
      headers: form.getHeaders(), timeout: Math.max(env.c3WordCheckTimeoutMs, 120000), maxBodyLength: Infinity,
    });
    return data;
  } catch (err) {
    throw toApiError(err);
  }
}

module.exports = { health, verify, checkSpeech };
