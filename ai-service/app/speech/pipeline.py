"""
Speech analysis pipeline coordinator for Component 1.
Chains audio preprocessing, window segmentation, feature extraction,
stutter classification, event merging, syllable counting, and severity estimation.
"""

import uuid
import logging
from typing import Optional, Dict, Any, Union
from pathlib import Path
import numpy as np

from app.config.speech_settings import (
    DEFAULT_EXTRACTOR,
    CLINICAL_DISCLAIMER,
    SOFTWARE_VERSION,
)
from app.speech.audio_processor import (
    validate_task_and_age,
    load_and_preprocess_audio,
    segment_into_windows,
    extract_acoustic_features,
)
from app.speech.syllable_counter import (
    count_acoustic_syllables,
    calculate_stuttered_syllables,
)
from app.speech.feature_extractor import SpeechFeatureExtractor
from app.speech.classifier import StutterClassifier
from app.speech.event_merger import merge_window_predictions
from app.speech.severity_estimator import estimate_stuttering_severity
from app.speech.schemas import (
    SpeechAnalysisResponse,
    DetectedEvent,
    EventCounts,
    SyllableMetrics,
    DurationMetrics,
    ModelInfo,
    SpeechFeatures,
    ProcessingStatus,
)

logger = logging.getLogger(__name__)


class SpeechAnalysisPipeline:
    """
    End-to-end speech analysis pipeline instance.
    Reuses cached feature extractors and classifiers across requests.
    """

    def __init__(
        self,
        extractor_name: str = DEFAULT_EXTRACTOR,
        classifier: Optional[StutterClassifier] = None,
    ):
        self.extractor_name = extractor_name
        self.extractor = SpeechFeatureExtractor(extractor_name=extractor_name)
        self.classifier = classifier or StutterClassifier()

    def analyze(
        self,
        audio_input: Union[bytes, str, Path],
        child_age: float,
        task_type: str,
        child_id: Optional[str] = None,
        filename: str = "recording.wav",
        extractor_override: Optional[str] = None,
    ) -> SpeechAnalysisResponse:
        """
        Executes the full stuttering detection and severity estimation pipeline.
        """
        analysis_id = str(uuid.uuid4())
        warnings = []

        # 1. Validate age and task type
        validate_task_and_age(task_type, child_age)

        # 2. Audio decoding, validation, and conversion to 16 kHz mono
        audio_16k, total_duration = load_and_preprocess_audio(audio_input, filename=filename)

        # 3. Acoustic features (duration, pauses, speech rate)
        acoustic_feats = extract_acoustic_features(audio_16k)
        active_speech_duration = acoustic_feats.get("activeSpeechDuration", total_duration)

        # 4. Syllable nucleus detection
        total_syllables, syllable_timestamps, _ = count_acoustic_syllables(audio_16k)

        # 5. Segment into 3.0s overlapping windows (1.5s step)
        windows = segment_into_windows(audio_16k)

        # 6. Feature extraction & classification
        extractor = self.extractor
        if extractor_override and extractor_override != self.extractor_name:
            extractor = SpeechFeatureExtractor(extractor_name=extractor_override)

        window_predictions = []
        if not self.classifier.weights_loaded:
            warnings.append(
                "Stutter classifier weights not found on disk. Operating in weights_unavailable mode: "
                "no fabricated stutter predictions generated. Run scripts/train_classifier.py to train."
            )
            processing_status = ProcessingStatus.WEIGHTS_UNAVAILABLE
        else:
            processing_status = ProcessingStatus.COMPLETED

        for chunk, w_start, w_end in windows:
            if self.classifier.weights_loaded:
                embedding = extractor.extract_window_embedding(chunk)
                pred_class, confidence, _ = self.classifier.predict_window(embedding)
                window_predictions.append({
                    "start": w_start,
                    "end": w_end,
                    "class": pred_class,
                    "confidence": confidence,
                })
            else:
                window_predictions.append({
                    "start": w_start,
                    "end": w_end,
                    "class": "Fluent",
                    "confidence": 0.0,
                })

        # 7. Merge overlapping window predictions into stuttering events
        raw_events, event_counts_dict, primary_stutter_type = merge_window_predictions(window_predictions)

        detected_events = [
            DetectedEvent(
                startTime=ev["startTime"],
                endTime=ev["endTime"],
                eventType=ev["eventType"],
                confidence=ev["confidence"],
                duration=ev["duration"],
            )
            for ev in raw_events
        ]

        # 8. Calculate stuttered syllables and %SS
        stuttered_syl_count, percent_ss, is_reliable = calculate_stuttered_syllables(
            syllable_timestamps, raw_events, total_duration
        )

        if not is_reliable:
            warnings.append("Low syllable count detected (< 5 syllables). %SS calculation may be uncalibrated.")

        # 9. Duration metrics and longest event
        event_durations = [ev["duration"] for ev in raw_events]
        longest_event = max(event_durations) if event_durations else 0.0
        avg_event_dur = round(sum(event_durations) / len(event_durations), 2) if event_durations else 0.0

        # 10. Severity estimation
        severity, severity_warnings = estimate_stuttering_severity(
            percent_ss=percent_ss,
            longest_event_duration_s=longest_event,
            total_events=len(detected_events),
            is_reliable_syllables=is_reliable,
            weights_loaded=self.classifier.weights_loaded,
        )
        warnings.extend(severity_warnings)

        # Overall stutter detected boolean
        stutter_detected = len(detected_events) > 0 and self.classifier.weights_loaded

        # Aggregate confidence
        if detected_events:
            overall_confidence = round(
                sum(ev.confidence for ev in detected_events) / len(detected_events), 3
            )
        else:
            overall_confidence = 0.85 if self.classifier.weights_loaded else 0.0

        # Build response payload
        return SpeechAnalysisResponse(
            analysisId=analysis_id,
            processingStatus=processing_status,
            childId=child_id,
            childAge=child_age,
            taskType=task_type,
            stutterDetected=stutter_detected,
            stutterType=primary_stutter_type,
            severity=severity,
            confidence=overall_confidence,
            detectedEvents=detected_events,
            eventCounts=EventCounts(**event_counts_dict),
            syllableMetrics=SyllableMetrics(
                totalSyllables=total_syllables,
                stutteredSyllables=stuttered_syl_count,
                percentSyllablesStuttered=percent_ss,
                syllableCountMethod="Acoustic Intensity Nucleus Peak Detection (de Jong & Wempe)",
                isReliable=is_reliable,
            ),
            durationMetrics=DurationMetrics(
                totalDuration=round(total_duration, 2),
                speechDuration=round(active_speech_duration, 2),
                longestEventDuration=round(longest_event, 2),
                averageEventDuration=round(avg_event_dur, 2),
            ),
            features=SpeechFeatures(
                duration=acoustic_feats["duration"],
                pauseCount=acoustic_feats["pauseCount"],
                averagePauseDuration=acoustic_feats["averagePauseDuration"],
                speechRate=acoustic_feats["speechRate"],
                estimatedWordCount=acoustic_feats["estimatedWordCount"],
            ),
            modelInfo=ModelInfo(
                modelName="Swara Speech Stuttering Detector",
                featureExtractor=extractor.extractor_name,
                classifierType=self.classifier.classifier_type,
                weightsLoaded=self.classifier.weights_loaded,
                isTrained=self.classifier.is_trained,
                version=SOFTWARE_VERSION,
            ),
            warnings=warnings,
            isPrototype=not self.classifier.weights_loaded,
            clinicalDisclaimer=CLINICAL_DISCLAIMER,
        )
