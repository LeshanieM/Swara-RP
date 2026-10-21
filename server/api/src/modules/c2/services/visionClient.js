const fs = require('fs');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');
const env = require('../../../config/env');

/** Failure talking to the vision service; `code` is stored on the failed analysis. */
class VisionServiceError extends Error {
  constructor(code, message, status) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

const http = axios.create({ baseURL: env.visionServiceUrl });

function toError(err) {
  if (err.response) {
    let body = err.response.data;
    if (Buffer.isBuffer(body)) {
      try { body = JSON.parse(body.toString('utf8')); } catch { body = null; }
    }
    const e = body?.error;
    return new VisionServiceError(e?.code || 'vision_service_error', e?.message || `Vision service returned ${err.response.status}.`, err.response.status);
  }
  if (err.code === 'ECONNABORTED' || err.code === 'ETIMEDOUT') {
    return new VisionServiceError('vision_service_timeout', `Vision service did not answer within ${env.visionTimeoutMs} ms.`);
  }
  return new VisionServiceError('vision_service_unavailable', `Vision service unreachable at ${env.visionServiceUrl} (${err.code || err.message}).`);
}

const videoForm = (filePath, originalName) => {
  const form = new FormData();
  form.append('video', fs.createReadStream(filePath), { filename: originalName || path.basename(filePath) });
  return form;
};

async function health() {
  const { data } = await http.get('/health', { timeout: 3000 });
  return data;
}

/** Returns { wav: Buffer, durationSec } for the video's audio track (16 kHz mono). */
async function extractAudio({ filePath, originalName }) {
  const form = videoForm(filePath, originalName);
  try {
    const res = await http.post('/extract-audio', form, {
      headers: form.getHeaders(), timeout: env.visionTimeoutMs, maxBodyLength: Infinity, responseType: 'arraybuffer',
    });
    return { wav: Buffer.from(res.data), durationSec: Number(res.headers['x-audio-duration-sec']) };
  } catch (err) {
    throw toError(err);
  }
}

async function analyze({ filePath, originalName, moments, targetFps }) {
  const form = videoForm(filePath, originalName);
  form.append('stutter_moments', JSON.stringify(moments));
  if (targetFps) form.append('target_fps', String(targetFps));
  try {
    const { data } = await http.post('/analyze-video', form, {
      headers: form.getHeaders(), timeout: env.visionTimeoutMs, maxBodyLength: Infinity,
    });
    return data;
  } catch (err) {
    throw toError(err);
  }
}

module.exports = {
  health, extractAudio, analyze, VisionServiceError,
};
