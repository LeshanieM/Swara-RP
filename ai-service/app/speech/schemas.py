"""
Pydantic schemas for Component 1: Speech Assessment API.
Provides type validation, serialization, and both snake_case and camelCase field aliases
for seamless compatibility with the Flutter client, Express backend, and C2/C3 services.
"""

from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, ConfigDict


class StutterEventType(str, Enum):
    BLOCK = "Block"
    PROLONGATION = "Prolongation"
    SOUND_REPETITION = "Sound Repetition"
    WORD_REPETITION = "Word Repetition"
    INTERJECTION = "Interjection"
    FLUENT = "Fluent"


class TaskType(str, Enum):
    PICTURE_DESCRIPTION = "picture-description"
    PASSAGE_READING = "passage-reading"


class SeverityLevel(str, Enum):
    NONE = "None"
    MILD = "Mild"
    MODERATE = "Moderate"
    SEVERE = "Severe"
    UNAVAILABLE = "Unavailable"


class ProcessingStatus(str, Enum):
    COMPLETED = "completed"
    PARTIAL = "partial"
    WEIGHTS_UNAVAILABLE = "weights_unavailable"
    FAILED = "failed"


class DetectedEvent(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    start_time: float = Field(..., alias="startTime", description="Event start time in seconds")
    end_time: float = Field(..., alias="endTime", description="Event end time in seconds")
    event_type: str = Field(..., alias="eventType", description="Stuttering event type")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Model confidence score")
    duration: float = Field(..., description="Duration in seconds")


class EventCounts(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    blocks: int = 0
    prolongations: int = 0
    sound_repetitions: int = Field(0, alias="soundRepetitions")
    word_repetitions: int = Field(0, alias="wordRepetitions")
    interjections: int = 0
    total: int = 0


class SyllableMetrics(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    total_syllables: int = Field(..., alias="totalSyllables", description="Total detected or counted syllables")
    stuttered_syllables: int = Field(..., alias="stutteredSyllables", description="Number of syllables stuttered")
    percent_syllables_stuttered: float = Field(
        ..., alias="percentSyllablesStuttered", description="Percentage of syllables stuttered (%SS)"
    )
    syllable_count_method: str = Field(
        ..., alias="syllableCountMethod", description="Documented method used for syllable counting"
    )
    reference_syllables_source: Optional[str] = Field(
        None, alias="referenceSyllablesSource", description="Source of reference syllables (Passage, C4 transcript, or acoustic)"
    )
    is_reliable: bool = Field(
        True, alias="isReliable", description="Whether sufficient syllables were detected for reliable estimation"
    )


class DurationMetrics(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    total_duration: float = Field(..., alias="totalDuration", description="Total audio duration in seconds")
    speech_duration: float = Field(..., alias="speechDuration", description="Active speech duration in seconds")
    longest_event_duration: float = Field(
        ..., alias="longestEventDuration", description="Duration of the longest stuttering event"
    )
    mean_three_longest_events_duration: float = Field(
        0.0, alias="meanThreeLongestEventsDuration", description="Mean duration of top 3 longest events (SSI-4 duration metric)"
    )
    average_event_duration: float = Field(
        ..., alias="averageEventDuration", description="Average stuttering event duration"
    )


class ModelInfo(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    model_name: str = Field("Swara Speech Stuttering Detector", alias="modelName")
    feature_extractor: str = Field(..., alias="featureExtractor")
    classifier_type: str = Field(..., alias="classifierType")
    weights_loaded: bool = Field(..., alias="weightsLoaded")
    is_trained: bool = Field(..., alias="isTrained")
    version: str = "1.0.0"


class SpeechFeatures(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    duration: float = Field(..., description="Total duration in seconds")
    pause_count: int = Field(0, alias="pauseCount", description="Number of detected silent pauses")
    average_pause_duration: float = Field(
        0.0, alias="averagePauseDuration", description="Average pause duration in seconds"
    )
    speech_rate: float = Field(
        0.0, alias="speechRate", description="Syllables per second during active speech"
    )
    estimated_word_count: int = Field(
        0, alias="estimatedWordCount", description="Estimated word count based on syllable rate"
    )


class SpeechAnalysisResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    analysis_id: str = Field(..., alias="analysisId")
    processing_status: ProcessingStatus = Field(..., alias="processingStatus")
    child_id: Optional[str] = Field(None, alias="childId")
    child_age: float = Field(..., alias="childAge")
    task_type: str = Field(..., alias="taskType")
    
    # Core classification results
    stutter_detected: bool = Field(..., alias="stutterDetected")
    stutter_type: str = Field(..., alias="stutterType")
    severity: str = Field(..., alias="severity")
    clinical_status: str = Field("No / very mild stuttering detected", alias="clinicalStatus")
    severity_estimate_type: str = Field("SSI-4-inspired audio-based severity estimate", alias="severityEstimateType")
    concomitant_score: Optional[float] = Field(None, alias="concomitantScore")
    confidence: float = Field(..., ge=0.0, le=1.0)
    
    # Granular timeline and metrics
    detected_events: List[DetectedEvent] = Field(default_factory=list, alias="detectedEvents")
    event_counts: EventCounts = Field(default_factory=EventCounts, alias="eventCounts")
    syllable_metrics: SyllableMetrics = Field(..., alias="syllableMetrics")
    duration_metrics: DurationMetrics = Field(..., alias="durationMetrics")
    features: SpeechFeatures = Field(..., alias="features")
    model_info: ModelInfo = Field(..., alias="modelInfo")
    
    warnings: List[str] = Field(default_factory=list)
    is_prototype: bool = Field(True, alias="isPrototype")
    clinical_disclaimer: str = Field(..., alias="clinicalDisclaimer")


class SpeechStatusResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    status: str
    service: str = "swara-speech-service"
    version: str = "1.0.0"
    available_extractors: List[str]
    default_extractor: str
    classifier_weights_available: bool
    classifier_path: str
