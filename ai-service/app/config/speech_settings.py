"""
Configuration settings for Component 1: Sinhala Child Stuttering Detection
and Severity Estimation.

Provides explicit, documented parameters for audio validation, feature extraction,
stuttering classification, event merging, syllable counting, and severity mapping.
All values are configurable via environment variables for reproducible experimentation.
"""

import os
from pathlib import Path
from typing import Dict, List

AI_SERVICE_ROOT = Path(__file__).resolve().parent.parent.parent

# ---------------------------------------------------------------------------
# Storage paths
# ---------------------------------------------------------------------------
SPEECH_UPLOAD_DIR = Path(os.getenv("SPEECH_UPLOAD_DIR", AI_SERVICE_ROOT / "uploads" / "speech"))
SPEECH_MODELS_DIR = Path(os.getenv("SPEECH_MODELS_DIR", AI_SERVICE_ROOT / "models" / "speech"))
SPEECH_RESULTS_DIR = Path(os.getenv("SPEECH_RESULTS_DIR", AI_SERVICE_ROOT / "results" / "speech"))

SPEECH_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
SPEECH_MODELS_DIR.mkdir(parents=True, exist_ok=True)
SPEECH_RESULTS_DIR.mkdir(parents=True, exist_ok=True)

# Clean up uploaded audio after processing (privacy compliance: do not retain raw child audio)
SPEECH_DELETE_UPLOADS = os.getenv("SPEECH_KEEP_UPLOADS", "0") != "1"

# ---------------------------------------------------------------------------
# Audio constraints
# ---------------------------------------------------------------------------
TARGET_SAMPLE_RATE = int(os.getenv("SPEECH_TARGET_SAMPLE_RATE", "16000"))
TARGET_CHANNELS = 1  # mono
MIN_AUDIO_DURATION_S = float(os.getenv("SPEECH_MIN_DURATION_S", "1.0"))
MAX_AUDIO_DURATION_S = float(os.getenv("SPEECH_MAX_DURATION_S", "300.0"))
MAX_FILE_SIZE_BYTES = int(os.getenv("SPEECH_MAX_FILE_SIZE_MB", "25")) * 1024 * 1024

# ---------------------------------------------------------------------------
# Age-based task constraints (Section 2)
# ---------------------------------------------------------------------------
TASK_PICTURE_DESCRIPTION = "picture-description"
TASK_PASSAGE_READING = "passage-reading"
ALLOWED_TASK_TYPES = [TASK_PICTURE_DESCRIPTION, TASK_PASSAGE_READING]

TASK_AGE_RANGES: Dict[str, Dict[str, int]] = {
    TASK_PICTURE_DESCRIPTION: {"min_age": 5, "max_age": 10},
    TASK_PASSAGE_READING: {"min_age": 11, "max_age": 14},
}
OVERALL_MIN_AGE = 5
OVERALL_MAX_AGE = 14

# ---------------------------------------------------------------------------
# Feature extraction (Section 3)
# ---------------------------------------------------------------------------
# Supported representation backends for empirical comparison
EXTRACTOR_XLS_R_300M = "facebook/wav2vec2-xls-r-300m"
EXTRACTOR_WAV2VEC2_BASE = "facebook/wav2vec2-base"
SUPPORTED_EXTRACTORS = [EXTRACTOR_XLS_R_300M, EXTRACTOR_WAV2VEC2_BASE]

DEFAULT_EXTRACTOR = os.getenv("SPEECH_DEFAULT_EXTRACTOR", EXTRACTOR_XLS_R_300M)

# 3-second window, 1.5-second step (50% overlap)
WINDOW_DURATION_S = float(os.getenv("SPEECH_WINDOW_DURATION_S", "3.0"))
STEP_DURATION_S = float(os.getenv("SPEECH_STEP_DURATION_S", "1.5"))

# ---------------------------------------------------------------------------
# Stuttering categories (Section 3)
# ---------------------------------------------------------------------------
CATEGORY_BLOCK = "Block"
CATEGORY_PROLONGATION = "Prolongation"
CATEGORY_SOUND_REP = "Sound Repetition"
CATEGORY_WORD_REP = "Word Repetition"
CATEGORY_INTERJECTION = "Interjection"
CATEGORY_FLUENT = "Fluent"

STUTTER_CATEGORIES: List[str] = [
    CATEGORY_BLOCK,
    CATEGORY_PROLONGATION,
    CATEGORY_SOUND_REP,
    CATEGORY_WORD_REP,
    CATEGORY_INTERJECTION,
]

ALL_CATEGORIES: List[str] = STUTTER_CATEGORIES + [CATEGORY_FLUENT]

# ---------------------------------------------------------------------------
# Event merging (Section 3)
# ---------------------------------------------------------------------------
EVENT_MERGE_MAX_GAP_S = float(os.getenv("SPEECH_EVENT_MERGE_MAX_GAP_S", "0.5"))
MIN_EVENT_CONFIDENCE = float(os.getenv("SPEECH_MIN_EVENT_CONFIDENCE", "0.50"))

# ---------------------------------------------------------------------------
# Syllable counting & %SS (Section 5)
# ---------------------------------------------------------------------------
# Minimum energy peak distance in seconds (approx 130 ms ~= 7.7 syllables/s max child speech rate)
MIN_SYLLABLE_DISTANCE_S = float(os.getenv("SPEECH_MIN_SYLLABLE_DISTANCE_S", "0.13"))
MIN_TOTAL_SYLLABLES_FOR_SS = int(os.getenv("SPEECH_MIN_SYLLABLES_FOR_SS", "5"))

# ---------------------------------------------------------------------------
# Severity mapping thresholds (Section 5)
# Documented research estimates: %SS (percentage of syllables stuttered)
# Mild: %SS < 3.0%
# Moderate: 3.0% <= %SS < 8.0%
# Severe: %SS >= 8.0% (or modulated if longest event >= 2.0s)
# ---------------------------------------------------------------------------
SEVERITY_NONE = "None"
SEVERITY_MILD = "Mild"
SEVERITY_MODERATE = "Moderate"
SEVERITY_SEVERE = "Severe"
SEVERITY_UNAVAILABLE = "Unavailable"

SEVERITY_MILD_MAX_SS = float(os.getenv("SPEECH_SEVERITY_MILD_MAX_SS", "3.0"))
SEVERITY_MODERATE_MAX_SS = float(os.getenv("SPEECH_SEVERITY_MODERATE_MAX_SS", "8.0"))
LONG_EVENT_THRESHOLD_S = float(os.getenv("SPEECH_LONG_EVENT_THRESHOLD_S", "2.0"))

CLINICAL_DISCLAIMER = (
    "Research estimate only. This automated analysis is designed as a research prototype "
    "and assistive tool; it does not constitute a clinical diagnosis. Results must be "
    "interpreted by a certified Speech-Language Pathologist (SLP)."
)

# ---------------------------------------------------------------------------
# Classifier paths
# ---------------------------------------------------------------------------
CLASSIFIER_WEIGHTS_FILE = Path(os.getenv("SPEECH_CLASSIFIER_PATH", SPEECH_MODELS_DIR / "stutter_classifier.joblib"))
CLASSIFIER_METADATA_FILE = Path(os.getenv("SPEECH_METADATA_PATH", SPEECH_MODELS_DIR / "classifier_metadata.json"))

SOFTWARE_VERSION = "swara-speech-1.0.0"
