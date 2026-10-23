import threading
from typing import Annotated

from fastapi import APIRouter, File, Form, UploadFile

from app.audio.io import AudioError
from app.config import SERVICE_VERSION, get_settings
from app.detection import registry
from app.errors import ServiceError
from app.pipeline import analyze
from app.schemas import AnalysisResponse, Language, TaskType
from app.severity import config as severity_config

router = APIRouter()
_slots = threading.BoundedSemaphore(get_settings().max_concurrent_analyses)
SLOT_WAIT_SEC = 120


@router.get("/health")
def health() -> dict:
    settings = get_settings()
    return {
        "status": "ok",
        "service": "swara-speech",
        "version": SERVICE_VERSION,
        "activeDetector": settings.detector,
        "detectors": registry.status(),
        "severityVersion": severity_config.SEVERITY_VERSION,
        "limits": {
            "minDurationSec": settings.min_duration_sec,
            "maxDurationSec": settings.max_duration_sec,
            "maxUploadMb": settings.max_upload_mb,
        },
    }


# A plain `def` endpoint: FastAPI runs it in its thread pool, so analysis never
# blocks the event loop. The semaphore caps how many run at once.
# exclude_unset drops only windowScores when not requested; null fields such as
# primaryType stay in the payload because the contract requires them.
@router.post("/analyze-speech", response_model=AnalysisResponse, response_model_exclude_unset=True)
def analyze_speech(
    audio: Annotated[UploadFile, File(description="Speech recording; 16 kHz mono WAV preferred")],
    task_type: Annotated[TaskType, Form()],
    language: Annotated[Language, Form()] = "si",
    passage_text: Annotated[str | None, Form(max_length=5000)] = None,
    transcript: Annotated[str | None, Form(max_length=10000)] = None,
    concomitant_score: Annotated[float | None, Form(ge=0.0, le=1.0)] = None,
    include_windows: Annotated[bool, Form()] = False,
) -> AnalysisResponse:
    settings = get_settings()
    if task_type == "reading" and not (passage_text and passage_text.strip()):
        raise ServiceError(422, "passage_required", "passage_text is required for the reading task.")

    data = audio.file.read(settings.max_upload_mb * 1024 * 1024 + 1)
    if len(data) > settings.max_upload_mb * 1024 * 1024:
        raise ServiceError(413, "file_too_large", f"Audio exceeds {settings.max_upload_mb} MB.")

    if not _slots.acquire(timeout=SLOT_WAIT_SEC):
        raise ServiceError(503, "busy", "Too many analyses in progress; retry shortly.")
    try:
        return analyze(data, task_type, language, passage_text, transcript, concomitant_score, include_windows)
    except AudioError as exc:
        raise ServiceError(422, exc.code, exc.message) from exc
    finally:
        _slots.release()
