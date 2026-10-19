"""Private, local Sinhala speech transcription endpoint for Component 3.

Audio is processed from the request stream in a temporary file and removed in
all cases. Do not enable this endpoint for child research data without consent.
"""
from __future__ import annotations

import math
import os
import tempfile
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile

router = APIRouter(prefix="/speech", tags=["speech"])
_models: dict[str, object] = {}


def get_model(model_name: str):
    """Load once per service process; model weights remain only in memory."""
    if model_name not in _models:
        try:
            from faster_whisper import WhisperModel
        except ImportError as error:
            raise HTTPException(status_code=503, detail="Local speech model is not installed") from error
        _models[model_name] = WhisperModel(
            model_name, device="cpu", compute_type="int8"
        )
    return _models[model_name]


@router.post("/transcribe")
async def transcribe_sinhala(audio: UploadFile = File(...)):
    if not audio.filename:
        raise HTTPException(status_code=400, detail="Audio filename is required")
    suffix = Path(audio.filename).suffix or ".m4a"
    path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temporary:
            path = temporary.name
            temporary.write(await audio.read())
        # `base` is a practical CPU default for the project's 8 GB development
        # laptop. Deployments may opt into `small` through C3_WHISPER_MODEL.
        model_name = os.getenv("C3_WHISPER_MODEL", "base")
        model = get_model(model_name)
        segments, info = model.transcribe(path, language="si", vad_filter=True, beam_size=5)
        segments = list(segments)
        text = " ".join(segment.text.strip() for segment in segments).strip()
        if not text:
            return {"text": "", "confidence": 0.0, "language": "si"}
        log_probs = [segment.avg_logprob for segment in segments if segment.avg_logprob is not None]
        confidence = math.exp(sum(log_probs) / len(log_probs)) if log_probs else 0.0
        # no_speech probability is considered; this is an uncertainty signal,
        # not a claim about the child's participation.
        no_speech = max((segment.no_speech_prob or 0.0) for segment in segments)
        confidence = max(0.0, min(1.0, confidence * (1.0 - no_speech)))
        return {"text": text, "confidence": confidence, "language": getattr(info, "language", "si")}
    finally:
        if path:
            try:
                os.remove(path)
            except OSError:
                pass
