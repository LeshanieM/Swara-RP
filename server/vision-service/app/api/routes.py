import json
import os
import threading
from typing import Annotated

from fastapi import APIRouter, File, Form, UploadFile
from fastapi.responses import Response
from pydantic import TypeAdapter, ValidationError

from app.config import SERVICE_VERSION, get_settings
from app.detection import registry
from app.errors import ServiceError
from app.pipeline import analyze
from app.schemas import AnalysisResponse, StutterMomentIn
from app.video import io as vio
from app.video.audio import extract_wav
from app.video.landmarks import FaceModelUnavailable

router = APIRouter()
_slots = threading.BoundedSemaphore(get_settings().max_concurrent_analyses)
SLOT_WAIT_SEC = 120
_moments = TypeAdapter(list[StutterMomentIn])


def _read_upload(video: UploadFile) -> bytes:
    settings = get_settings()
    ext = os.path.splitext(video.filename or "")[1].lower()
    if ext not in vio.ALLOWED_EXT:
        raise ServiceError(422, "unsupported_video_type",
                           f"Video must be one of {', '.join(vio.ALLOWED_EXT)}; got \"{ext or 'no extension'}\".")
    data = video.file.read(settings.max_upload_mb * 1024 * 1024 + 1)
    if len(data) > settings.max_upload_mb * 1024 * 1024:
        raise ServiceError(413, "file_too_large", f"Video exceeds {settings.max_upload_mb} MB.")
    if not data:
        raise ServiceError(422, "empty_file", "The uploaded video is empty.")
    return data


def _parse_moments(raw: str | None) -> list[dict]:
    if raw is None or not raw.strip():
        return []
    try:
        items = _moments.validate_python(json.loads(raw))
    except (json.JSONDecodeError, ValidationError) as exc:
        raise ServiceError(422, "invalid_stutter_moments",
                           "stutter_moments must be a JSON list of {start, end, types?} in seconds.", str(exc)[:500]) from exc
    bad = [i for i, m in enumerate(items) if m.end <= m.start]
    if bad:
        raise ServiceError(422, "invalid_stutter_moments", f"Moments {bad} end before they start.")
    return [m.model_dump() for m in items]


@router.get("/health")
def health() -> dict:
    s = get_settings()
    return {
        "status": "ok",
        "service": "swara-vision",
        "version": SERVICE_VERSION,
        "faceModel": {"status": "available" if s.face_model_path.is_file() else "missing", "file": s.face_model_path.name},
        "activeDetector": s.detector,
        "detectors": registry.status(),
        "limits": {"minDurationSec": s.min_duration_sec, "maxDurationSec": s.max_duration_sec,
                   "maxUploadMb": s.max_upload_mb, "targetFps": s.target_fps},
    }


# Plain `def` endpoints run in FastAPI's thread pool; the semaphore caps concurrent analyses.
@router.post("/analyze-video", response_model=AnalysisResponse, response_model_exclude_unset=True)
def analyze_video(
    video: Annotated[UploadFile, File(description="Face video; mp4/mov/m4v/webm/mkv/avi")],
    stutter_moments: Annotated[str | None, Form(description="JSON list of {start, end, types?} in seconds")] = None,
    target_fps: Annotated[float | None, Form(ge=5, le=30)] = None,
    include_frames: Annotated[bool, Form()] = False,
):
    settings = get_settings()
    moments = _parse_moments(stutter_moments)
    data = _read_upload(video)
    if not _slots.acquire(timeout=SLOT_WAIT_SEC):
        raise ServiceError(503, "busy", "Too many analyses in progress; retry shortly.")
    try:
        result = analyze(data, video.filename, moments, settings, target_fps, include_frames)
        if not include_frames:
            result.pop("frames", None)
        return result
    except vio.VideoError as exc:
        raise ServiceError(422, exc.code, exc.message) from exc
    except FaceModelUnavailable as exc:
        raise ServiceError(503, "face_model_unavailable", str(exc)) from exc
    finally:
        _slots.release()


@router.post("/extract-audio")
def extract_audio(video: Annotated[UploadFile, File()]):
    data = _read_upload(video)
    try:
        with vio.temp_file(data, video.filename) as path:
            info = vio.probe(path)
            vio.validate(info, get_settings().min_duration_sec, get_settings().max_duration_sec)
            wav, duration = extract_wav(path)
    except vio.VideoError as exc:
        raise ServiceError(422, exc.code, exc.message) from exc
    return Response(content=wav, media_type="audio/wav",
                    headers={"X-Audio-Duration-Sec": str(duration), "X-Video-Duration-Sec": str(info.duration_sec)})
