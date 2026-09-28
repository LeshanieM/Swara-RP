"""
OpenSeeFace analyzer (section 6.3).

OpenSeeFace (github.com/emilianavt/OpenSeeFace) is distributed as a Python
source checkout, not a pip package. This analyzer imports its `Tracker`
class directly (from `tracker.py` in the checkout) and runs it frame-by-
frame, rather than shelling out to `facetracker.py` (which is written for
live webcam capture + UDP streaming, not batch video analysis).

Configuration: set `OPENSEEFACE_DIR` to the path of a cloned OpenSeeFace
repo (containing `tracker.py` and its `models/` directory). If not
configured, or the import fails, `is_available()` reports
`dependency_not_installed` and this technology is skipped for the run
without affecting the others (section 12).

Investigates: eye blinking, lip movement, jaw movement, facial movement,
head movement (section 6.3), using landmark trajectories and temporal
movement features - the same feature/threshold definitions as the other
face analyzers, for comparability. No hand/arm signal.
"""

import os
import sys
import time
from typing import Any, Dict, List, Optional

from app.analyzers.base_analyzer import BehaviorEvent, BehaviorResult, UnavailableReason, VisionAnalyzer
from app.config.settings import OPENSEEFACE_DIR, THRESHOLDS
from app.processing import feature_extraction as fx
from app.processing.temporal_detection import angular_velocity_deg, detect_events_above_threshold

# OpenSeeFace's 68-point landmark layout matches the same dlib-family scheme
# used by OpenFace.
RIGHT_EYE_IDX = [36, 37, 38, 39, 40, 41]
LEFT_EYE_IDX = [42, 43, 44, 45, 46, 47]
MOUTH_LEFT, MOUTH_RIGHT = 48, 54
MOUTH_TOP_INNER, MOUTH_BOTTOM_INNER = 62, 66
CHIN = 8
NOSE_TIP = 30


class OpenSeeFaceAnalyzer(VisionAnalyzer):
    name = "OpenSeeFace"
    version = "unknown (loaded from OPENSEEFACE_DIR at runtime)"

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
        if not OPENSEEFACE_DIR or not os.path.isdir(OPENSEEFACE_DIR):
            return False, UnavailableReason.DEPENDENCY_NOT_INSTALLED.value
        if not os.path.isfile(os.path.join(OPENSEEFACE_DIR, "tracker.py")):
            return False, UnavailableReason.DEPENDENCY_NOT_INSTALLED.value
        try:
            if OPENSEEFACE_DIR not in sys.path:
                sys.path.insert(0, OPENSEEFACE_DIR)
            import tracker  # noqa: F401
        except ImportError:
            return False, UnavailableReason.DEPENDENCY_NOT_INSTALLED.value
        return True, None

    def analyze(
        self,
        video_path: str,
        generate_overlay: bool = False,
        preprocessing_notes: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        from app.analyzers.mediapipe_analyzer import _probe_video

        video_meta = _probe_video(video_path)
        available, reason = self.is_available()
        if not available:
            return self.unavailable_result(video_meta, reason)

        start = time.time()
        preprocessing_notes = list(preprocessing_notes or [])
        preprocessing_notes.append(
            "Frames decoded via OpenCV and passed to OpenSeeFace's Tracker.predict() one at "
            "a time (batch mode), rather than its live-webcam UDP pipeline."
        )

        try:
            import cv2
            import numpy as np
            from tracker import Tracker  # from OPENSEEFACE_DIR, inserted onto sys.path

            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                return self.error_result(video_meta, "runtime_error: could not open video file")

            width = video_meta.get("width") or int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = video_meta.get("height") or int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            fps = video_meta.get("fps") or (cap.get(cv2.CAP_PROP_FPS) or 30.0)

            tracker = Tracker(width, height, threshold=0.6, max_faces=1, discard_after=0, scan_every=0, silent=True)

            timestamps, ear_signal, lip_signal, jaw_signal, face_signal = [], [], [], [], []
            yaw_signal, pitch_signal, roll_signal = [], [], []
            prev_xy = None
            processed, missing, frame_idx = 0, 0, 0

            while True:
                ok, frame = cap.read()
                if not ok:
                    break
                t = frame_idx / fps
                faces = tracker.predict(frame)
                frame_idx += 1

                if not faces or not getattr(faces[0], "success", False):
                    missing += 1
                    continue

                face = faces[0]
                pts = [(p[1], p[0]) for p in face.lms[:68, 0:2]]  # OpenSeeFace lms are (row, col) = (y, x)
                face_scale = fx.euclidean(pts[36], pts[45])
                if face_scale <= 0:
                    missing += 1
                    continue

                right_ear = fx.eye_aspect_ratio([pts[i] for i in RIGHT_EYE_IDX])
                left_ear = fx.eye_aspect_ratio([pts[i] for i in LEFT_EYE_IDX])
                ear_signal.append((right_ear + left_ear) / 2.0)

                opening, _w = fx.mouth_opening_width(
                    pts[MOUTH_TOP_INNER], pts[MOUTH_BOTTOM_INNER], pts[MOUTH_LEFT], pts[MOUTH_RIGHT], face_scale
                )
                lip_signal.append(opening)
                jaw_signal.append(fx.jaw_opening(pts[CHIN], pts[NOSE_TIP], face_scale))

                if prev_xy is not None:
                    face_signal.append(fx.mean_landmark_displacement(prev_xy, pts, face_scale))
                else:
                    face_signal.append(0.0)
                prev_xy = pts

                euler = getattr(face, "euler", None)
                if euler is not None:
                    pitch, yaw, roll = float(euler[0]), float(euler[1]), float(euler[2])
                else:
                    pitch = yaw = roll = 0.0
                yaw_signal.append(yaw)
                pitch_signal.append(pitch)
                roll_signal.append(roll)

                timestamps.append(t)
                processed += 1

            cap.release()

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
                "processed_frames": processed,
                "missing_frames": missing,
                "tracking_failures": missing,
                "total_frames_read": frame_idx,
            }

            return self.build_result(
                status="completed",
                processing_time=time.time() - start,
                video_meta=video_meta,
                behaviors=behaviors,
                tracking=tracking,
                preprocessing_notes=preprocessing_notes,
                thresholds_used={k: THRESHOLDS[k] for k in [
                    "eye_blink", "lip_movement", "jaw_movement", "facial_movement", "head_movement"
                ]},
            )
        except Exception as exc:
            return self.error_result(video_meta, f"runtime_error: {exc}", time.time() - start)
