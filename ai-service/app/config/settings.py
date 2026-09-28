"""
Central configuration for the Component 2 computer-vision analysis module.

Every temporal-detection threshold used anywhere in the vision pipeline is
defined here (and only here) so that:

  1. Thresholds are documented in one place.
  2. Thresholds are reproducible: the exact values used for a given analysis
     run are written into that run's reproducibility log (see
     app/jobs/store.py) instead of being silently hard-coded inside an
     analyzer.
  3. Thresholds can be overridden via environment variables without touching
     analyzer code, which matters for an experimental research tool where a
     reviewer may want to re-run the same video with different settings.

Nothing in this file tunes thresholds "to make results look better" for any
particular video. Defaults are generic, published-in-literature style
starting points (e.g. EAR ~0.2 for blink detection) and are meant to be
revisited once ground-truth SLP annotations are available (see
app/processing/evaluation.py).
"""

import os
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

AI_SERVICE_ROOT = Path(__file__).resolve().parent.parent.parent

UPLOAD_DIR = Path(os.getenv("VISION_UPLOAD_DIR", AI_SERVICE_ROOT / "uploads"))
RESULTS_DIR = Path(os.getenv("VISION_RESULTS_DIR", AI_SERVICE_ROOT / "results"))

UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

# Delete the uploaded video after processing completes (success or failure).
# Per section 31 (privacy): do not permanently store raw child video by
# default. Set VISION_KEEP_UPLOADS=1 only for local debugging.
DELETE_UPLOAD_AFTER_PROCESSING = os.getenv("VISION_KEEP_UPLOADS", "0") != "1"

# How long a completed/failed job's in-memory record and result files are
# retained before being eligible for cleanup. Not enforced automatically in
# this prototype; exposed so a cleanup task can use it.
JOB_RETENTION_HOURS = float(os.getenv("VISION_JOB_RETENTION_HOURS", "72"))

# ---------------------------------------------------------------------------
# Supported technologies
# ---------------------------------------------------------------------------

# The canonical list/order of CV technologies the experiment compares.
# Analyzer classes are registered against these keys in
# app/analyzers/registry.py. Keeping the list here (not derived from
# whatever happens to be importable) means the comparison table always shows
# every technology the research design calls for, even the ones currently
# unavailable, per section 12.
TECHNOLOGIES = ["mediapipe", "openface", "openseeface", "3ddfa_v2", "mmpose"]

# ---------------------------------------------------------------------------
# Canonical behaviors (section 7)
# ---------------------------------------------------------------------------

BEHAVIORS = [
    "eye_blink",
    "lip_movement",
    "jaw_movement",
    "facial_movement",
    "head_movement",
    "hand_movement",
    "arm_movement",
]

# ---------------------------------------------------------------------------
# Temporal detection thresholds (section 11)
# ---------------------------------------------------------------------------
# All are overridable via env vars for reproducible experimentation without
# code changes. Values are grouped by behavior.

THRESHOLDS = {
    # Smoothing window applied to raw per-frame signals before event
    # detection, in number of frames. Larger = smoother but less temporally
    # precise onsets/offsets.
    "smoothing_window_frames": int(os.getenv("VISION_SMOOTHING_WINDOW", "3")),

    # Eye blink: Eye Aspect Ratio (EAR). A blink is an interval where EAR
    # drops below `ear_threshold` from a baseline, following Soukupova &
    # Cech (2016), "Real-Time Eye Blink Detection using Facial Landmarks".
    "eye_blink": {
        "ear_threshold": float(os.getenv("VISION_EAR_THRESHOLD", "0.21")),
        "ear_hysteresis_ratio": 1.15,  # event ends when EAR rises back above threshold * ratio
        "min_event_duration_s": 0.06,
        "max_event_duration_s": 0.6,
    },

    # Lip / mouth movement: normalized mouth-opening + mouth-width signal.
    "lip_movement": {
        "activation_threshold": float(os.getenv("VISION_LIP_THRESHOLD", "0.06")),
        "hysteresis_ratio": 0.7,
        "min_event_duration_s": 0.1,
    },

    # Jaw movement: normalized jaw-opening displacement from baseline.
    "jaw_movement": {
        "activation_threshold": float(os.getenv("VISION_JAW_THRESHOLD", "0.05")),
        "hysteresis_ratio": 0.7,
        "min_event_duration_s": 0.1,
    },

    # Facial movement: aggregate landmark-displacement magnitude (mean
    # normalized displacement across tracked facial landmarks per frame).
    "facial_movement": {
        "activation_threshold": float(os.getenv("VISION_FACE_THRESHOLD", "0.04")),
        "hysteresis_ratio": 0.7,
        "min_event_duration_s": 0.1,
    },

    # Head movement: angular velocity of head pose (deg/s), from yaw/pitch/
    # roll estimated via facial landmark geometry (or a pose-estimation
    # model where available).
    "head_movement": {
        "angular_velocity_threshold_deg_s": float(os.getenv("VISION_HEAD_THRESHOLD", "25.0")),
        "hysteresis_ratio": 0.7,
        "min_event_duration_s": 0.15,
    },

    # Hand / arm movement: normalized wrist/elbow displacement velocity
    # (units: fraction of frame diagonal per second), from body-pose
    # keypoints.
    "hand_movement": {
        "velocity_threshold": float(os.getenv("VISION_HAND_THRESHOLD", "0.35")),
        "hysteresis_ratio": 0.7,
        "min_event_duration_s": 0.15,
    },
    "arm_movement": {
        "velocity_threshold": float(os.getenv("VISION_ARM_THRESHOLD", "0.30")),
        "hysteresis_ratio": 0.7,
        "min_event_duration_s": 0.15,
    },
}

# ---------------------------------------------------------------------------
# External tool locations (for technologies that are not pure pip installs)
# ---------------------------------------------------------------------------
# These default to "not configured", which is exactly what makes the
# corresponding analyzer report `unavailable` / `executable_not_found`
# rather than crashing the whole experiment (section 12/30).

# MediaPipe's Tasks API (the currently-shipped mediapipe Python API - some
# recent mediapipe builds no longer include the older `mp.solutions`
# module at all) requires a downloaded `.task` model bundle. It is not
# fetched automatically by this project (no implicit network access at
# runtime); download it once and point this at the file, e.g.:
#   curl -L -o models/face_landmarker.task \
#     https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/latest/face_landmarker.task
MEDIAPIPE_FACE_MODEL_PATH = os.getenv(
    "MEDIAPIPE_FACE_MODEL_PATH", str(AI_SERVICE_ROOT / "models" / "face_landmarker.task")
)

OPENFACE_BIN = os.getenv("OPENFACE_BIN")  # path to OpenFace's FeatureExtraction executable
OPENSEEFACE_DIR = os.getenv("OPENSEEFACE_DIR")  # path to a checked-out OpenSeeFace repo (contains facetracker.py)
DDFA_V2_DIR = os.getenv("DDFA_V2_DIR")  # path to a checked-out 3DDFA_V2 repo
MMPOSE_CONFIG = os.getenv("MMPOSE_CONFIG")  # optional explicit mmpose config path
MMPOSE_CHECKPOINT = os.getenv("MMPOSE_CHECKPOINT")  # optional explicit mmpose checkpoint path

# ---------------------------------------------------------------------------
# Overlay / timeline visualization
# ---------------------------------------------------------------------------

GENERATE_OVERLAY_DEFAULT = os.getenv("VISION_GENERATE_OVERLAY_DEFAULT", "0") == "1"
GENERATE_TIMELINE_DEFAULT = True

SOFTWARE_VERSION = "swara-vision-0.1.0"
