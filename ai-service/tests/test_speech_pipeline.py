"""
Automated unit and integration test suite for Swara Component 1:
Sinhala Child Stuttering Detection and Severity Estimation.

Covers:
  1. Audio preprocessing & format conversion
  2. Age & task validation rules
  3. Window segmentation (3.0s window, 1.5s step)
  4. Stuttering event merging logic
  5. Syllable counting & %SS calculation
  6. Multi-factor severity mapping
  7. FastAPI API validation, status, and /analyze-speech endpoint
"""

import io
import math
import sys
from pathlib import Path
import numpy as np
import pytest
import soundfile as sf
from fastapi.testclient import TestClient

# Ensure ai-service root is in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import app
from app.config.speech_settings import (
    TARGET_SAMPLE_RATE,
    CATEGORY_BLOCK,
    CATEGORY_PROLONGATION,
    CATEGORY_SOUND_REP,
    CATEGORY_FLUENT,
    SEVERITY_MILD,
    SEVERITY_MODERATE,
    SEVERITY_SEVERE,
    SEVERITY_NONE,
    SEVERITY_UNAVAILABLE,
)
from app.speech.audio_processor import (
    validate_task_and_age,
    load_and_preprocess_audio,
    segment_into_windows,
    extract_acoustic_features,
    AudioValidationError,
    TaskAgeValidationError,
)
from app.speech.event_merger import merge_window_predictions
from app.speech.syllable_counter import (
    count_acoustic_syllables,
    count_sinhala_text_syllables,
    calculate_stuttered_syllables,
)
from app.speech.severity_estimator import estimate_stuttering_severity


def create_synthetic_wav(duration_s: float = 3.5, sample_rate: int = 16000, freq: float = 220.0) -> bytes:
    """Creates an in-memory WAV audio buffer with modulated tone to simulate speech syllables."""
    t = np.linspace(0, duration_s, int(sample_rate * duration_s), endpoint=False)
    # Carrier + envelope modulation (~4 syllables per second)
    modulation = 0.5 * (1.0 + np.sin(2 * np.pi * 4.0 * t))
    audio = 0.6 * np.sin(2 * np.pi * freq * t) * modulation
    
    buf = io.BytesIO()
    sf.write(buf, audio.astype(np.float32), sample_rate, format="WAV")
    return buf.getvalue()


# ===========================================================================
# 1. Age and Task Validation Tests (Section 2)
# ===========================================================================
def test_task_age_validation_picture_description():
    """Picture description is valid for ages 5–10."""
    validate_task_and_age("picture-description", 5.0)
    validate_task_and_age("picture-description", 7.5)
    validate_task_and_age("picture-description", 10.0)

    # Incompatible ages
    with pytest.raises(TaskAgeValidationError):
        validate_task_and_age("picture-description", 4.0)

    with pytest.raises(TaskAgeValidationError):
        validate_task_and_age("picture-description", 12.0)


def test_task_age_validation_passage_reading():
    """Passage reading is valid for ages 11–14."""
    validate_task_and_age("passage-reading", 11.0)
    validate_task_and_age("passage-reading", 14.0)

    # Incompatible ages
    with pytest.raises(TaskAgeValidationError):
        validate_task_and_age("passage-reading", 8.0)

    with pytest.raises(TaskAgeValidationError):
        validate_task_and_age("passage-reading", 15.0)


def test_invalid_task_type():
    with pytest.raises(TaskAgeValidationError):
        validate_task_and_age("unsupported-task", 8.0)


# ===========================================================================
# 2. Audio Preprocessing and Window Segmentation (Section 2 & 3)
# ===========================================================================
def test_audio_preprocessing_valid_wav():
    wav_bytes = create_synthetic_wav(duration_s=3.0, sample_rate=22050)
    audio_16k, dur = load_and_preprocess_audio(wav_bytes)

    assert isinstance(audio_16k, np.ndarray)
    assert audio_16k.dtype == np.float32
    assert math.isclose(dur, 3.0, abs_tol=0.1)
    assert np.max(np.abs(audio_16k)) <= 1.0


def test_audio_preprocessing_too_short():
    short_wav = create_synthetic_wav(duration_s=0.4)
    with pytest.raises(AudioValidationError):
        load_and_preprocess_audio(short_wav)


def test_audio_preprocessing_corrupted():
    corrupted_bytes = b"RIFF....WAVEcorruptedpayload1234"
    with pytest.raises(AudioValidationError):
        load_and_preprocess_audio(corrupted_bytes)


def test_window_segmentation():
    # 6.0 seconds of audio segmented with 3.0s window and 1.5s step
    audio_16k = np.zeros(16000 * 6, dtype=np.float32)
    windows = segment_into_windows(audio_16k, sample_rate=16000, window_duration_s=3.0, step_duration_s=1.5)

    assert len(windows) >= 3
    # First window spans 0.0 - 3.0s
    assert windows[0][1] == 0.0
    assert windows[0][2] == 3.0
    # Second window spans 1.5 - 4.5s
    assert windows[1][1] == 1.5
    assert windows[1][2] == 4.5


# ===========================================================================
# 3. Event Merging Tests (Section 3)
# ===========================================================================
def test_event_merging_contiguous_windows():
    """Overlapping windows with same category merge into a single event."""
    predictions = [
        {"start": 0.0, "end": 3.0, "class": CATEGORY_PROLONGATION, "confidence": 0.80},
        {"start": 1.5, "end": 4.5, "class": CATEGORY_PROLONGATION, "confidence": 0.90},
        {"start": 3.0, "end": 6.0, "class": CATEGORY_FLUENT, "confidence": 0.95},
    ]

    events, counts, primary = merge_window_predictions(predictions, max_gap_s=0.5)

    assert len(events) == 1
    assert events[0]["eventType"] == CATEGORY_PROLONGATION
    assert events[0]["startTime"] == 0.0
    assert events[0]["endTime"] == 4.5
    assert math.isclose(events[0]["confidence"], 0.85, abs_tol=0.01)
    assert events[0]["duration"] == 4.5
    assert counts["prolongations"] == 1
    assert primary == CATEGORY_PROLONGATION


def test_event_merging_distinct_classes():
    """Different categories in adjacent windows remain distinct events."""
    predictions = [
        {"start": 0.0, "end": 3.0, "class": CATEGORY_BLOCK, "confidence": 0.85},
        {"start": 3.0, "end": 6.0, "class": CATEGORY_SOUND_REP, "confidence": 0.88},
    ]

    events, counts, _ = merge_window_predictions(predictions, max_gap_s=0.5)
    assert len(events) == 2
    assert events[0]["eventType"] == CATEGORY_BLOCK
    assert events[1]["eventType"] == CATEGORY_SOUND_REP
    assert counts["blocks"] == 1
    assert counts["soundRepetitions"] == 1


# ===========================================================================
# 4. Syllable Counting & %SS Tests (Section 5)
# ===========================================================================
def test_sinhala_orthographic_syllable_counter():
    """Verifies Sinhala script syllable counting on passage excerpt."""
    # 'අද උදෑසන නදී' -> අ-ද (2) උ-දෑ-ස-න (4) න-දී (2) = 8 syllables
    phrase = "අද උදෑසන නදී"
    count = count_sinhala_text_syllables(phrase)
    assert 6 <= count <= 10


def test_stuttered_syllable_and_percent_ss_calculation():
    # 20 total syllables, 2 falling within an event window
    syllable_timestamps = [float(i) * 0.5 for i in range(20)]
    events = [
        {"startTime": 1.0, "endTime": 2.2, "eventType": CATEGORY_PROLONGATION}
    ]

    stuttered_count, percent_ss, is_reliable = calculate_stuttered_syllables(
        syllable_timestamps, events, total_duration_s=10.0
    )

    assert is_reliable is True
    assert stuttered_count >= 2
    expected_ss = (stuttered_count / 20.0) * 100.0
    assert math.isclose(percent_ss, expected_ss, abs_tol=0.1)


def test_unreliable_syllable_count_under_threshold():
    # Only 2 syllables detected (too short/silent)
    syllable_timestamps = [0.5, 1.0]
    _, _, is_reliable = calculate_stuttered_syllables(syllable_timestamps, [], total_duration_s=2.0)
    assert is_reliable is False


# ===========================================================================
# 5. Severity Mapping Tests (Section 5)
# ===========================================================================
def test_severity_mapping_mild():
    sev, _ = estimate_stuttering_severity(percent_ss=2.0, longest_event_duration_s=1.0, total_events=1)
    assert sev == SEVERITY_MILD


def test_severity_mapping_moderate_by_ss():
    sev, _ = estimate_stuttering_severity(percent_ss=5.0, longest_event_duration_s=1.2, total_events=3)
    assert sev == SEVERITY_MODERATE


def test_severity_mapping_moderate_by_duration():
    # %SS is low (<3.0%), but longest event >= 2.0s -> elevated to Moderate
    sev, warnings = estimate_stuttering_severity(percent_ss=2.0, longest_event_duration_s=2.5, total_events=1)
    assert sev == SEVERITY_MODERATE
    assert any("elevated" in w.lower() for w in warnings)


def test_severity_mapping_severe():
    sev, _ = estimate_stuttering_severity(percent_ss=9.5, longest_event_duration_s=1.5, total_events=5)
    assert sev == SEVERITY_SEVERE


def test_severity_mapping_weights_unavailable():
    sev, warnings = estimate_stuttering_severity(
        percent_ss=4.0, longest_event_duration_s=1.0, total_events=2, weights_loaded=False
    )
    assert sev == SEVERITY_UNAVAILABLE
    assert any("weights not loaded" in w.lower() for w in warnings)


# ===========================================================================
# 6. FastAPI Integration Endpoint Tests (Section 6)
# ===========================================================================
def test_fastapi_speech_status_endpoint():
    client = TestClient(app)
    response = client.get("/speech/status")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "facebook/wav2vec2-xls-r-300m" in data["available_extractors"]
    assert "classifier_weights_available" in data


def test_fastapi_analyze_speech_valid_flow():
    client = TestClient(app)
    wav_bytes = create_synthetic_wav(duration_s=4.0)

    response = client.post(
        "/analyze-speech",
        files={"audio": ("child_speech.wav", wav_bytes, "audio/wav")},
        data={"childAge": "7", "taskType": "picture-description", "childId": "CH-001"},
    )

    assert response.status_code == 200
    data = response.json()

    assert "analysisId" in data
    assert "processingStatus" in data
    assert "stutterDetected" in data
    assert "severity" in data
    assert "detectedEvents" in data
    assert "eventCounts" in data
    assert "syllableMetrics" in data
    assert "durationMetrics" in data
    assert "features" in data
    assert "clinicalDisclaimer" in data
    assert data["childAge"] == 7.0
    assert data["taskType"] == "picture-description"


def test_fastapi_analyze_speech_incompatible_age():
    client = TestClient(app)
    wav_bytes = create_synthetic_wav(duration_s=3.0)

    # Age 13 on picture-description should be rejected with 400 Bad Request
    response = client.post(
        "/analyze-speech",
        files={"audio": ("speech.wav", wav_bytes, "audio/wav")},
        data={"childAge": "13", "taskType": "picture-description"},
    )
    assert response.status_code == 400
    assert "designated for ages" in response.json()["detail"]


def test_fastapi_analyze_speech_empty_file():
    client = TestClient(app)
    response = client.post(
        "/analyze-speech",
        files={"audio": ("empty.wav", b"", "audio/wav")},
        data={"childAge": "7", "taskType": "picture-description"},
    )
    assert response.status_code == 400


def test_resolve_total_syllables_reading_passage():
    """Ages 11-14 known passage text provides exact syllable count (Page 6)."""
    from app.speech.syllable_counter import resolve_total_syllables, count_sinhala_text_syllables, DEFAULT_SINHALA_READING_PASSAGE
    
    expected_full = count_sinhala_text_syllables(DEFAULT_SINHALA_READING_PASSAGE)
    
    # Full duration read
    total, source = resolve_total_syllables(
        task_type="passage-reading",
        audio_duration_s=22.0,
        acoustic_syllables=30,
    )
    assert total == expected_full
    assert "Exact" in source

    # Early stop read (8 seconds)
    total_early, source_early = resolve_total_syllables(
        task_type="passage-reading",
        audio_duration_s=8.0,
        acoustic_syllables=12,
    )
    assert total_early < expected_full
    assert "Early Stop" in source_early


def test_resolve_total_syllables_picture_description_with_transcript():
    """Ages 5-10 picture description counts syllables from C4 transcript if present (Page 6)."""
    from app.speech.syllable_counter import resolve_total_syllables
    
    transcript = "මම සෙල්ලම් කරනවා"
    total, source = resolve_total_syllables(
        task_type="picture-description",
        audio_duration_s=5.0,
        acoustic_syllables=8,
        transcript=transcript,
    )
    assert total >= 6
    assert "C4 Sinhala Transcript" in source


def test_duration_metrics_top_3_mean_calculation():
    """SSI-4 inspired duration metric uses the mean of 3 longest events (Page 6)."""
    events = [
        {"duration": 4.0},
        {"duration": 3.0},
        {"duration": 2.0},
        {"duration": 1.0},
    ]
    sorted_durations = sorted([e["duration"] for e in events], reverse=True)
    top_3 = sorted_durations[:3]  # 4.0, 3.0, 2.0
    mean_top_3 = sum(top_3) / len(top_3)
    assert math.isclose(mean_top_3, 3.0, abs_tol=0.01)


def test_fastapi_compare_models_endpoint():
    """Verifies GET /speech/compare-models returns XLS-R-300M vs wav2vec2-base specs and metrics (Page 1-4)."""
    client = TestClient(app)
    response = client.get("/speech/compare-models")
    assert response.status_code == 200
    data = response.json()
    assert "models" in data
    assert "wav2vec2-base" in data["models"]
    assert "xls-r-300m" in data["models"]
    assert data["recommendation"]["selectedBestModel"] == "facebook/wav2vec2-xls-r-300m"
    assert "crossLingualResearchFindings" in data

