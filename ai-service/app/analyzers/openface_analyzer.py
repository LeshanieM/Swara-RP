"""
OpenFace analyzer (section 6.2).

OpenFace ships as a compiled command-line tool (`FeatureExtraction`), not a
pip package, so this analyzer shells out to it and parses the per-frame CSV
it writes (landmarks, head pose in radians, gaze, and Action Units).

Configuration: set the `OPENFACE_BIN` environment variable to the path of
the built `FeatureExtraction` executable (see OpenFace's own build
instructions - it is not bundled with this project). If it is not
configured or not found, `is_available()` reports
`executable_not_found` and this technology is skipped for the run without
affecting the others (section 12).

Investigates: eye blinking, lip movement, jaw/mouth movement, facial
movement, head movement (section 6.2). No body/hand signal, so
hand/arm_movement are `unsupported`. Action Units are used only as inputs
to generic movement-magnitude/EAR-style signals - they are not asserted to
represent secondary stuttering behaviors (section 6.2: "Do not assume that
an Action Unit directly represents a stuttering behavior").
"""

import csv
import os
import shutil
import subprocess
import tempfile
import time
from typing import Any, Dict, List, Optional

from app.analyzers.base_analyzer import BehaviorEvent, BehaviorResult, UnavailableReason, VisionAnalyzer
from app.config.settings import OPENFACE_BIN, THRESHOLDS
from app.processing import feature_extraction as fx
from app.processing.temporal_detection import angular_velocity_deg, detect_events_above_threshold

# OpenFace's 68-point landmark scheme (same layout family as dlib):
RIGHT_EYE_IDX = [36, 37, 38, 39, 40, 41]
LEFT_EYE_IDX = [42, 43, 44, 45, 46, 47]
MOUTH_LEFT, MOUTH_RIGHT = 48, 54
MOUTH_TOP_INNER, MOUTH_BOTTOM_INNER = 62, 66
CHIN = 8
NOSE_TIP = 30


class OpenFaceAnalyzer(VisionAnalyzer):
    name = "OpenFace"
    version = "2.x (FeatureExtraction CLI)"

    capability_map = {
        "eye_blink": True,
        "lip_movement": True,
        "jaw_movement": True,
        "facial_movement": True,
        "head_movement": True,
        "hand_movement": False,
        "arm_movement": False,
    }

    def is_available(self):
        binary = OPENFACE_BIN
        if not binary or not os.path.isfile(binary) or not os.access(binary, os.X_OK):
            return False, UnavailableReason.EXECUTABLE_NOT_FOUND.value
        return True, None

    def analyze(
        self,
        video_path: str,
        generate_overlay: bool = False,
        preprocessing_notes: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        from app.analyzers.mediapipe_analyzer import _probe_video  # reuse the same OpenCV probe

        video_meta = _probe_video(video_path)
        available, reason = self.is_available()
        if not available:
            return self.unavailable_result(video_meta, reason)

        start = time.time()
        preprocessing_notes = list(preprocessing_notes or [])
        preprocessing_notes.append(
            "Video passed to OpenFace FeatureExtraction unmodified; OpenFace performs its "
            "own internal face detection/tracking per frame."
        )

        out_dir = tempfile.mkdtemp(prefix="openface_")
        try:
            proc = subprocess.run(
                [OPENFACE_BIN, "-f", video_path, "-out_dir", out_dir, "-2Dfp", "-pose", "-aus"],
                capture_output=True,
                text=True,
                timeout=60 * 20,
            )
            if proc.returncode != 0:
                return self.error_result(
                    video_meta, f"runtime_error: OpenFace exited with code {proc.returncode}: {proc.stderr[-500:]}",
                    time.time() - start,
                )

            csv_path = _find_output_csv(out_dir, video_path)
            if not csv_path:
                return self.error_result(video_meta, "runtime_error: OpenFace produced no output CSV", time.time() - start)

            rows = _read_openface_csv(csv_path)
            if not rows:
                return self.error_result(video_meta, "runtime_error: OpenFace output CSV was empty", time.time() - start)

            behaviors, tracking = _compute_behaviors_from_rows(rows)

            result = self.build_result(
                status="completed",
                processing_time=time.time() - start,
                video_meta=video_meta,
                behaviors=behaviors,
                tracking=tracking,
                preprocessing_notes=preprocessing_notes,
                thresholds_used={
                    "eye_blink": THRESHOLDS["eye_blink"],
                    "lip_movement": THRESHOLDS["lip_movement"],
                    "jaw_movement": THRESHOLDS["jaw_movement"],
                    "facial_movement": THRESHOLDS["facial_movement"],
                    "head_movement": THRESHOLDS["head_movement"],
                },
            )
            return result
        except subprocess.TimeoutExpired:
            return self.error_result(video_meta, "runtime_error: OpenFace processing timed out", time.time() - start)
        except Exception as exc:  # defensive: one technology failing must not stop the experiment
            return self.error_result(video_meta, f"runtime_error: {exc}", time.time() - start)
        finally:
            shutil.rmtree(out_dir, ignore_errors=True)


def _find_output_csv(out_dir: str, video_path: str) -> Optional[str]:
    base = os.path.splitext(os.path.basename(video_path))[0]
    candidate = os.path.join(out_dir, f"{base}.csv")
    if os.path.isfile(candidate):
        return candidate
    for fname in os.listdir(out_dir):
        if fname.endswith(".csv"):
            return os.path.join(out_dir, fname)
    return None


def _read_openface_csv(csv_path: str) -> List[Dict[str, str]]:
    with open(csv_path, newline="") as f:
        reader = csv.DictReader(f, skipinitialspace=True)
        return [row for row in reader]


def _compute_behaviors_from_rows(rows: List[Dict[str, str]]):
    def g(row, key, default=0.0):
        try:
            return float(row.get(key, default))
        except (TypeError, ValueError):
            return default

    timestamps, ear_signal, lip_signal, jaw_signal, face_signal = [], [], [], [], []
    yaw_signal, pitch_signal, roll_signal = [], [], []
    prev_xy = None
    missing_frames = 0

    for row in rows:
        success = g(row, "success", 1.0)
        confidence = g(row, "confidence", 1.0)
        t = g(row, "timestamp", 0.0)

        if success < 0.5 or confidence < 0.2 or "x_0" not in row:
            missing_frames += 1
            continue

        xs = [g(row, f"x_{i}") for i in range(68)]
        ys = [g(row, f"y_{i}") for i in range(68)]
        pts = list(zip(xs, ys))

        face_scale = fx.euclidean(pts[36], pts[45])  # outer eye corners, both eyes
        if face_scale <= 0:
            missing_frames += 1
            continue

        right_ear = fx.eye_aspect_ratio([pts[i] for i in RIGHT_EYE_IDX])
        left_ear = fx.eye_aspect_ratio([pts[i] for i in LEFT_EYE_IDX])
        ear_signal.append((right_ear + left_ear) / 2.0)

        opening, _width = fx.mouth_opening_width(
            pts[MOUTH_TOP_INNER], pts[MOUTH_BOTTOM_INNER], pts[MOUTH_LEFT], pts[MOUTH_RIGHT], face_scale
        )
        lip_signal.append(opening)
        jaw_signal.append(fx.jaw_opening(pts[CHIN], pts[NOSE_TIP], face_scale))

        if prev_xy is not None:
            face_signal.append(fx.mean_landmark_displacement(prev_xy, pts, face_scale))
        else:
            face_signal.append(0.0)
        prev_xy = pts

        # OpenFace reports head pose directly (radians): pose_Rx (pitch),
        # pose_Ry (yaw), pose_Rz (roll).
        import math

        yaw_signal.append(math.degrees(g(row, "pose_Ry")))
        pitch_signal.append(math.degrees(g(row, "pose_Rx")))
        roll_signal.append(math.degrees(g(row, "pose_Rz")))

        timestamps.append(t)

    behaviors: Dict[str, BehaviorResult] = {}
    smoothing = THRESHOLDS["smoothing_window_frames"]

    if timestamps:
        cfg = THRESHOLDS["eye_blink"]
        events = detect_events_above_threshold(
            ear_signal, timestamps, cfg["ear_threshold"], cfg["ear_hysteresis_ratio"],
            cfg["min_event_duration_s"], cfg["max_event_duration_s"], smoothing, direction="below",
        )
        behaviors["eye_blink"] = BehaviorResult.from_events(
            [BehaviorEvent(i.start_time, i.end_time, i.end_time - i.start_time, i.peak_value) for i in events]
        )

        cfg = THRESHOLDS["lip_movement"]
        events = detect_events_above_threshold(
            lip_signal, timestamps, cfg["activation_threshold"], cfg["hysteresis_ratio"],
            cfg["min_event_duration_s"], None, smoothing, direction="above",
        )
        behaviors["lip_movement"] = BehaviorResult.from_events(
            [BehaviorEvent(i.start_time, i.end_time, i.end_time - i.start_time, i.peak_value) for i in events]
        )

        cfg = THRESHOLDS["jaw_movement"]
        events = detect_events_above_threshold(
            jaw_signal, timestamps, cfg["activation_threshold"], cfg["hysteresis_ratio"],
            cfg["min_event_duration_s"], None, smoothing, direction="above",
        )
        behaviors["jaw_movement"] = BehaviorResult.from_events(
            [BehaviorEvent(i.start_time, i.end_time, i.end_time - i.start_time, i.peak_value) for i in events]
        )

        cfg = THRESHOLDS["facial_movement"]
        events = detect_events_above_threshold(
            face_signal, timestamps, cfg["activation_threshold"], cfg["hysteresis_ratio"],
            cfg["min_event_duration_s"], None, smoothing, direction="above",
        )
        behaviors["facial_movement"] = BehaviorResult.from_events(
            [BehaviorEvent(i.start_time, i.end_time, i.end_time - i.start_time, i.peak_value) for i in events]
        )

        cfg = THRESHOLDS["head_movement"]
        yaw_vel = angular_velocity_deg(yaw_signal, timestamps)
        pitch_vel = angular_velocity_deg(pitch_signal, timestamps)
        roll_vel = angular_velocity_deg(roll_signal, timestamps)
        combined = [max(a, b, c) for a, b, c in zip(yaw_vel, pitch_vel, roll_vel)]
        events = detect_events_above_threshold(
            combined, timestamps, cfg["angular_velocity_threshold_deg_s"], cfg["hysteresis_ratio"],
            cfg["min_event_duration_s"], None, smoothing, direction="above",
        )
        behaviors["head_movement"] = BehaviorResult.from_events(
            [BehaviorEvent(i.start_time, i.end_time, i.end_time - i.start_time, i.peak_value) for i in events]
        )
    else:
        for b in ["eye_blink", "lip_movement", "jaw_movement", "facial_movement", "head_movement"]:
            behaviors[b] = BehaviorResult.error("runtime_error: no frames with a successfully tracked face")

    behaviors["hand_movement"] = BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature")
    behaviors["arm_movement"] = BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature")

    tracking = {
        "processed_frames": len(timestamps),
        "missing_frames": missing_frames,
        "tracking_failures": missing_frames,
        "total_frames_read": len(rows),
    }
    return behaviors, tracking
