"""
FastAPI route definitions for Component 1: Sinhala Child Stuttering Detection.
Provides POST /analyze-speech and GET /speech/status endpoints.
Uses starlette.concurrency.run_in_threadpool to keep inference non-blocking.
"""

import logging
from typing import Optional
from fastapi import APIRouter, File, UploadFile, Form, HTTPException, status
from starlette.concurrency import run_in_threadpool

from app.config.speech_settings import (
    DEFAULT_EXTRACTOR,
    SUPPORTED_EXTRACTORS,
    CLASSIFIER_WEIGHTS_FILE,
    SOFTWARE_VERSION,
    MAX_FILE_SIZE_BYTES,
)
from app.speech.pipeline import SpeechAnalysisPipeline
from app.speech.schemas import SpeechAnalysisResponse, SpeechStatusResponse
from app.speech.audio_processor import AudioValidationError, TaskAgeValidationError

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Component 1 - Speech Assessment"])

# Lazily initialized global pipeline instance
_PIPELINE: Optional[SpeechAnalysisPipeline] = None


def get_pipeline() -> SpeechAnalysisPipeline:
    global _PIPELINE
    if _PIPELINE is None:
        _PIPELINE = SpeechAnalysisPipeline(extractor_name=DEFAULT_EXTRACTOR)
    return _PIPELINE


@router.get("/speech/status", response_model=SpeechStatusResponse)
async def get_speech_service_status():
    """
    Returns the operational status, loaded weights availability,
    and feature extractor configurations for Component 1.
    """
    pipeline = get_pipeline()
    return SpeechStatusResponse(
        status="healthy",
        service="swara-speech-service",
        version=SOFTWARE_VERSION,
        available_extractors=SUPPORTED_EXTRACTORS,
        default_extractor=DEFAULT_EXTRACTOR,
        classifier_weights_available=pipeline.classifier.weights_loaded,
        classifier_path=str(CLASSIFIER_WEIGHTS_FILE),
    )


@router.post("/analyze-speech", response_model=SpeechAnalysisResponse)
async def analyze_speech_endpoint(
    audio: UploadFile = File(..., description="Speech recording (WAV format preferred)"),
    child_age: Optional[float] = Form(None, alias="childAge", description="Child age in years (5–14)"),
    age: Optional[float] = Form(None, description="Alternative field for child age"),
    task_type: Optional[str] = Form(None, alias="taskType", description="'picture-description' or 'passage-reading'"),
    task: Optional[str] = Form(None, description="Alternative field for task type"),
    child_id: Optional[str] = Form(None, alias="childId", description="Optional child identifier"),
    extractor: Optional[str] = Form(None, description="Feature extractor: 'facebook/wav2vec2-xls-r-300m' or 'facebook/wav2vec2-base'"),
):
    """
    Analyzes child speech recording for stuttering detection and severity estimation.

    Parameters:
    - audio: Binary audio file (WAV preferred).
    - child_age: Age of the child (5–10 for picture description, 11–14 for passage reading).
    - task_type: 'picture-description' or 'passage-reading'.
    - extractor: Configurable feature extractor representation.
    """
    # Normalize inputs
    resolved_age = child_age if child_age is not None else age
    resolved_task = task_type if task_type is not None else task

    if resolved_age is None:
        # Default fallback age if client omitted it in prototype calls
        resolved_age = 7.0

    if resolved_task is None:
        # Infer task based on age if omitted
        resolved_task = "picture-description" if resolved_age <= 10 else "passage-reading"

    # Read uploaded bytes
    try:
        audio_bytes = await audio.read()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to read uploaded audio file: {str(e)}",
        )

    if not audio_bytes or len(audio_bytes) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded audio file is empty.",
        )

    if len(audio_bytes) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Audio file size exceeds maximum permitted limit ({MAX_FILE_SIZE_BYTES // (1024 * 1024)} MB).",
        )

    pipeline = get_pipeline()

    # Execute CPU/GPU inference in a threadpool to prevent blocking the async event loop
    try:
        response: SpeechAnalysisResponse = await run_in_threadpool(
            pipeline.analyze,
            audio_input=audio_bytes,
            child_age=resolved_age,
            task_type=resolved_task,
            child_id=child_id,
            filename=audio.filename or "recording.wav",
            extractor_override=extractor,
        )
        return response

    except TaskAgeValidationError as e:
        logger.warning(f"Task/age validation error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    except AudioValidationError as e:
        logger.warning(f"Audio validation error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    except Exception as e:
        logger.error(f"Speech analysis pipeline failure: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Speech analysis pipeline failed: {str(e)}",
        )
