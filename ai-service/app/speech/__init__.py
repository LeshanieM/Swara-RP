"""
Swara Component 1: Sinhala Child Stuttering Detection and Severity Estimation
Speech Analysis Package.
"""

from app.speech.pipeline import SpeechAnalysisPipeline
from app.speech.schemas import (
    SpeechAnalysisResponse,
    SpeechStatusResponse,
    DetectedEvent,
    EventCounts,
    SyllableMetrics,
    DurationMetrics,
    ModelInfo,
    SpeechFeatures,
)
from app.speech.audio_processor import (
    validate_task_and_age,
    load_and_preprocess_audio,
    segment_into_windows,
    extract_acoustic_features,
    AudioValidationError,
    TaskAgeValidationError,
)

__all__ = [
    "SpeechAnalysisPipeline",
    "SpeechAnalysisResponse",
    "SpeechStatusResponse",
    "DetectedEvent",
    "EventCounts",
    "SyllableMetrics",
    "DurationMetrics",
    "ModelInfo",
    "SpeechFeatures",
    "validate_task_and_age",
    "load_and_preprocess_audio",
    "segment_into_windows",
    "extract_acoustic_features",
    "AudioValidationError",
    "TaskAgeValidationError",
]
