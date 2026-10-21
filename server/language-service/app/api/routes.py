import json
import threading
import time
from typing import Annotated

from fastapi import APIRouter, File, Form, UploadFile
from pydantic import TypeAdapter, ValidationError

from app.asr import registry
from app.asr.base import EngineUnavailable
from app.audio.io import AudioError, load_audio
from app.config import METHOD_VERSION, SERVICE_VERSION, SPEECH_CHECK_METHOD_VERSION, VERIFY_METHOD_VERSION, get_settings
from app.errors import ServiceError
from app.evaluation import evaluate
from app.language.pipeline import analyse_transcript
from app.verify.speech import check_keywords, check_reading
from app.verify.word import verify
from app.schemas import (
    AnalyzeLanguageOut, C1Event, C1Moment, EngineName, EvaluateRequest, MeasuresRequest, TranscriptionOut, WordCheckOut,
)

router = APIRouter()
_slots = threading.BoundedSemaphore(get_settings().max_concurrent_jobs)
SLOT_WAIT_SEC = 300


@router.get("/health")
def health() -> dict:
    s = get_settings()
    return {
        "status": "ok",
        "service": "swara-language",
        "version": SERVICE_VERSION,
        "methodVersion": METHOD_VERSION,
        "activeEngine": s.asr_engine,
        "engines": registry.status(),
        "limits": {"minDurationSec": s.min_duration_sec, "maxDurationSec": s.max_duration_sec, "maxUploadMb": s.max_upload_mb},
        "utterancePauseSec": s.utterance_pause_sec,
    }


def _read_audio(audio: UploadFile, min_sec: float | None = None, max_sec: float | None = None):
    s = get_settings()
    data = audio.file.read(s.max_upload_mb * 1024 * 1024 + 1)
    if len(data) > s.max_upload_mb * 1024 * 1024:
        raise ServiceError(413, "file_too_large", f"Audio exceeds {s.max_upload_mb} MB.")
    try:
        return load_audio(data, s.sample_rate, min_sec or s.min_duration_sec, max_sec or s.max_duration_sec)
    except AudioError as exc:
        raise ServiceError(422, exc.code, exc.message) from exc


def _transcribe(audio: UploadFile, engine_name: str | None) -> dict:
    loaded = _read_audio(audio)
    try:
        engine = registry.get(engine_name)
    except EngineUnavailable as exc:
        raise ServiceError(503, "asr_unavailable", f"ASR engine is unavailable: {exc}") from exc
    if not _slots.acquire(timeout=SLOT_WAIT_SEC):
        raise ServiceError(503, "busy", "Too many transcriptions in progress; retry shortly.")
    try:
        t0 = time.perf_counter()
        out = engine.transcribe(loaded.signal, loaded.sample_rate)
        elapsed = time.perf_counter() - t0
    finally:
        _slots.release()
    return {
        "engine": engine.info(),
        **out,
        "audio": {
            "durationSec": round(loaded.duration_sec, 3), "sampleRate": loaded.sample_rate,
            "originalSampleRate": loaded.original_sample_rate, "channels": loaded.channels, "format": loaded.format,
        },
        "processingSec": round(elapsed, 2),
    }


def _json_list(raw: str | None, item, field: str):
    if raw is None or raw == "":
        return None
    try:
        return [m.model_dump() for m in TypeAdapter(list[item]).validate_python(json.loads(raw))]
    except (json.JSONDecodeError, ValidationError) as exc:
        raise ServiceError(422, "validation_error", f"{field} must be a JSON list of {item.__name__} objects.") from exc


# Plain `def` endpoints run in FastAPI's thread pool, so ASR never blocks the event loop.
@router.post("/transcribe", response_model=TranscriptionOut)
def transcribe(
    audio: Annotated[UploadFile, File(description="Speech recording; 16 kHz mono WAV preferred")],
    engine: Annotated[EngineName | None, Form()] = None,
) -> dict:
    return _transcribe(audio, engine)


@router.post("/measures")
def measures(req: MeasuresRequest) -> dict:
    return analyse_transcript(
        words=[w.model_dump() for w in req.words] if req.words is not None else None,
        text=req.text,
        source=req.source,
        c1_events=[e.model_dump() for e in req.c1Events] if req.c1Events is not None else None,
        c1_moments=[m.model_dump() for m in req.c1Moments] if req.c1Moments is not None else None,
        duration_sec=req.durationSec,
        pause_sec=req.pauseSec or get_settings().utterance_pause_sec,
    )


@router.post("/analyze-language", response_model=AnalyzeLanguageOut)
def analyze_language(
    audio: Annotated[UploadFile | None, File()] = None,
    transcript: Annotated[str | None, Form(max_length=50000)] = None,
    source: Annotated[str, Form()] = "manual",
    engine: Annotated[EngineName | None, Form()] = None,
    c1_events: Annotated[str | None, Form()] = None,
    c1_moments: Annotated[str | None, Form()] = None,
    pause_sec: Annotated[float | None, Form(ge=0.2, le=5.0)] = None,
) -> dict:
    """Audio and/or a typed transcript in, full language analysis out (for direct experiments)."""
    if audio is None and not (transcript and transcript.strip()):
        raise ServiceError(422, "input_required", "Send audio, a transcript, or both.")
    if transcript and source not in ("corrected", "manual"):
        raise ServiceError(422, "validation_error", "source must be 'corrected' or 'manual' for a typed transcript.")
    events = _json_list(c1_events, C1Event, "c1_events")
    moments = _json_list(c1_moments, C1Moment, "c1_moments")
    transcription = _transcribe(audio, engine) if audio is not None else None
    analysis = analyse_transcript(
        words=transcription["words"] if transcription else None,
        text=transcript if transcript and transcript.strip() else None,
        source=source if transcript else "asr",
        c1_events=events,
        c1_moments=moments,
        duration_sec=transcription["audio"]["durationSec"] if transcription else None,
        pause_sec=pause_sec or get_settings().utterance_pause_sec,
    )
    return {"transcription": transcription, "analysis": analysis}


@router.post("/verify-word", response_model=WordCheckOut)
def verify_word(
    audio: Annotated[UploadFile, File(description="One word, about 0.5-5 s; 16 kHz mono WAV preferred")],
    expected: Annotated[str, Form(min_length=1, max_length=100)],
    alternatives: Annotated[str | None, Form(max_length=5000)] = None,
) -> dict:
    """C3 word activities: did the child say ``expected``? Always uses the CTC engine (it needs frame scores)."""
    s = get_settings()
    alts = None
    if alternatives:
        try:
            alts = TypeAdapter(list[str]).validate_python(json.loads(alternatives))
        except (json.JSONDecodeError, ValidationError) as exc:
            raise ServiceError(422, "validation_error", "alternatives must be a JSON list of words.") from exc
        if len(alts) > 30:
            raise ServiceError(422, "validation_error", "Send at most 30 alternatives.")
    loaded = _read_audio(audio, s.verify_min_sec, s.verify_max_sec)
    try:
        engine = registry.get("ctc")
    except EngineUnavailable as exc:
        raise ServiceError(503, "asr_unavailable", f"CTC engine is unavailable: {exc}") from exc
    if not _slots.acquire(timeout=SLOT_WAIT_SEC):
        raise ServiceError(503, "busy", "Too many analyses in progress; retry shortly.")
    try:
        out = verify(engine, loaded.signal, loaded.sample_rate, expected, alts)
    finally:
        _slots.release()
    return {
        **out,
        "engine": engine.info(),
        "methodVersion": VERIFY_METHOD_VERSION,
        "audio": {"durationSec": round(loaded.duration_sec, 3), "sampleRate": loaded.sample_rate},
    }


@router.post("/check-speech")
def check_speech(
    audio: Annotated[UploadFile, File(description="The child reading a passage or describing a picture; 16 kHz mono WAV preferred")],
    mode: Annotated[str, Form(pattern="^(reading|keywords)$")],
    reference: Annotated[str | None, Form(max_length=5000)] = None,
    keywords: Annotated[str | None, Form(max_length=5000)] = None,
    engine: Annotated[EngineName | None, Form()] = None,
) -> dict:
    """C3 reading (mode=reading, the passage in ``reference``) and picture description (mode=keywords, a JSON list of
    the words the description should mention). Transcribes, removes stutter repetitions and fillers, then compares."""
    kws = None
    if mode == "reading" and not (reference and reference.strip()):
        raise ServiceError(422, "validation_error", "reference (the passage text) is required for mode=reading.")
    if mode == "keywords":
        try:
            kws = [k for k in TypeAdapter(list[str]).validate_python(json.loads(keywords or "[]")) if k.strip()]
        except (json.JSONDecodeError, ValidationError) as exc:
            raise ServiceError(422, "validation_error", "keywords must be a JSON list of words.") from exc
        if not kws or len(kws) > 30:
            raise ServiceError(422, "validation_error", "Send 1 to 30 keywords.")
    transcription = _transcribe(audio, engine)
    words = transcription["words"]
    out = check_reading(reference, words=words) if mode == "reading" else check_keywords(kws, words=words)
    return {
        "mode": mode,
        **out,
        "heardRaw": transcription["text"],
        "engine": transcription["engine"],
        "methodVersion": SPEECH_CHECK_METHOD_VERSION,
        "audio": transcription["audio"],
    }


@router.post("/evaluate-asr")
def evaluate_asr(req: EvaluateRequest) -> dict:
    return evaluate(req.reference, req.hypothesis)
