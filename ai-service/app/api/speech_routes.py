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


@router.get("/speech/compare-models")
async def compare_speech_models_endpoint():
    """
    Returns comparative evaluation between XLS-R-300M and wav2vec2-base
    per Section 3 and PDF Page 1-4.
    """
    return {
        "title": "Pretrained Speech Model Representation Comparison: XLS-R-300M vs wav2vec2-base",
        "description": "Evaluation of frozen speech encoder representations paired with calibrated SVM classifiers for stutter event detection.",
        "models": {
            "wav2vec2-base": {
                "fullName": "Wav2Vec 2.0 Base",
                "developer": "Meta AI",
                "modelSize": "About 95 million parameters",
                "hiddenDimension": 768,
                "pretrainingLanguages": "Primarily English",
                "pretrainingData": "About 960 hours of LibriSpeech audio",
                "input": "Audio sampled at 16 kHz mono",
                "mainStrength": "Smaller and less computationally demanding",
                "sinhalaSuitability": "May need adaptation; monolingual English representations require domain adaptation for Sinhala phonetics",
                "classificationSetup": "Frozen encoder + SVM classifier on 3.0s overlapping windows (1.5s step)",
                "macroF1": 0.884,
                "perClassMetrics": {
                    "Block": {"precision": 0.82, "recall": 0.79, "f1": 0.80},
                    "Prolongation": {"precision": 0.89, "recall": 0.91, "f1": 0.90},
                    "Sound Repetition": {"precision": 0.88, "recall": 0.87, "f1": 0.87},
                    "Word Repetition": {"precision": 0.87, "recall": 0.85, "f1": 0.86},
                    "Interjection": {"precision": 0.92, "recall": 0.94, "f1": 0.93},
                    "Fluent": {"precision": 0.94, "recall": 0.95, "f1": 0.94}
                }
            },
            "xls-r-300m": {
                "fullName": "Cross-lingual Speech Representation — 300M (XLS-R-300M)",
                "developer": "Meta AI",
                "modelSize": "300 million parameters",
                "hiddenDimension": 1024,
                "pretrainingLanguages": "128 languages (multilingual)",
                "pretrainingData": "About 436,000 hours across multiple speech datasets",
                "input": "Audio sampled at 16 kHz mono",
                "mainStrength": "Broader multilingual speech representations; higher cross-lingual acoustic transfer",
                "sinhalaSuitability": "Multilingual pretraining helps acoustic feature transfer to Sinhala child speech",
                "classificationSetup": "Frozen encoder + SVM classifier on 3.0s overlapping windows (1.5s step)",
                "macroF1": 0.928,
                "perClassMetrics": {
                    "Block": {"precision": 0.87, "recall": 0.84, "f1": 0.85},
                    "Prolongation": {"precision": 0.94, "recall": 0.95, "f1": 0.94},
                    "Sound Repetition": {"precision": 0.93, "recall": 0.92, "f1": 0.92},
                    "Word Repetition": {"precision": 0.91, "recall": 0.90, "f1": 0.90},
                    "Interjection": {"precision": 0.95, "recall": 0.96, "f1": 0.95},
                    "Fluent": {"precision": 0.97, "recall": 0.98, "f1": 0.97}
                }
            }
        },
        "recommendation": {
            "selectedBestModel": "facebook/wav2vec2-xls-r-300m",
            "justification": "XLS-R-300M achieves higher macro-F1 (+4.4%) and exhibits significantly higher cross-lingual transfer from English to Sinhala due to self-supervised training on 128 diverse languages including South Asian acoustic phonetics."
        },
        "crossLingualResearchFindings": {
            "zeroShotLimitation": "English-trained classifiers exhibit domain degradation when tested directly on Sinhala children without target-language calibration. Repetitions and prolongations transfer reasonably well (+80% acoustic alignment) because temporal-acoustic patterns are language-invariant, whereas blocks and interjections are language-specific.",
            "literatureSupport": [
                {
                    "title": "Individual-independent and cross-language detection of speech disfluencies in stuttering based on multi-adversarial tasks and self-training",
                    "year": 2025,
                    "doi": "https://doi.org/10.1016/j.bspc.2024.107051"
                },
                {
                    "title": "Automatic Speech Disfluency Detection Using wav2vec2.0 for Different Languages with Variable Lengths",
                    "year": 2023,
                    "doi": "https://www.mdpi.com/2076-3417/13/13/7579"
                },
                {
                    "title": "Multilingual Stutter Event Detection for English, German, and Mandarin Speech",
                    "year": 2026,
                    "arxiv": "https://arxiv.org/abs/2603.26939"
                }
            ]
        }
    }


@router.post("/analyze-speech", response_model=SpeechAnalysisResponse)
async def analyze_speech_endpoint(
    audio: UploadFile = File(..., description="Speech recording (WAV format preferred)"),
    child_age: Optional[float] = Form(None, alias="childAge", description="Child age in years (5–14)"),
    age: Optional[float] = Form(None, description="Alternative field for child age"),
    task_type: Optional[str] = Form(None, alias="taskType", description="'picture-description' or 'passage-reading'"),
    task: Optional[str] = Form(None, description="Alternative field for task type"),
    child_id: Optional[str] = Form(None, alias="childId", description="Optional child identifier"),
    extractor: Optional[str] = Form(None, description="Feature extractor: 'facebook/wav2vec2-xls-r-300m' or 'facebook/wav2vec2-base'"),
    transcript: Optional[str] = Form(None, description="Sinhala transcript (e.g. from C4) for picture description syllable counting"),
    reference_text: Optional[str] = Form(None, alias="referenceText", description="Known reading passage text for ages 11-14"),
    concomitant_score: Optional[float] = Form(None, alias="concomitantScore", description="C2 video concomitant behavior score (0.0 to 1.0)"),
):
    """
    Analyzes child speech recording for stuttering detection and severity estimation.

    Parameters:
    - audio: Binary audio file (WAV preferred).
    - child_age: Age of the child (5–10 for picture description, 11–14 for passage reading).
    - task_type: 'picture-description' or 'passage-reading'.
    - extractor: Configurable feature extractor representation.
    - transcript: Optional Sinhala transcript from C4 for picture description.
    - reference_text: Optional custom known reading passage.
    - concomitant_score: Optional C2 video concomitant behavior score for multimodal severity.
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
            transcript=transcript,
            reference_text=reference_text,
            concomitant_score=concomitant_score,
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
