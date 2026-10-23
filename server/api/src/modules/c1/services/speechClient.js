const fs = require('fs');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');
const env = require('../../../config/env');

/** Failure talking to the speech service; `code` is stored on the failed assessment. */
class SpeechServiceError extends Error {
  constructor(code, message, status) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

const http = axios.create({ baseURL: env.speechServiceUrl });

async function health() {
  const { data } = await http.get('/health', { timeout: 3000 });
  return data;
}

async function analyze({ filePath, originalName, taskType, language, passageText, transcript, concomitantScore }) {
  const form = new FormData();
  form.append('audio', fs.createReadStream(filePath), { filename: originalName || path.basename(filePath) });
  form.append('task_type', taskType);
  form.append('language', language);
  if (passageText) form.append('passage_text', passageText);
  if (transcript) form.append('transcript', transcript);
  if (concomitantScore !== undefined && concomitantScore !== null) form.append('concomitant_score', String(concomitantScore));

  try {
    const { data } = await http.post('/analyze-speech', form, {
      headers: form.getHeaders(),
      timeout: env.speechTimeoutMs,
      maxBodyLength: Infinity,
    });
    return data;
  } catch (err) {
    if (err.response) {
      const e = err.response.data?.error;
      throw new SpeechServiceError(e?.code || 'speech_service_error', e?.message || `Speech service returned ${err.response.status}.`, err.response.status);
    }
    if (err.code === 'ECONNABORTED' || err.code === 'ETIMEDOUT') {
      throw new SpeechServiceError('speech_service_timeout', `Speech service did not answer within ${env.speechTimeoutMs} ms.`);
    }
    throw new SpeechServiceError('speech_service_unavailable', `Speech service unreachable at ${env.speechServiceUrl} (${err.code || err.message}).`);
  }
}

module.exports = { analyze, health, SpeechServiceError };
