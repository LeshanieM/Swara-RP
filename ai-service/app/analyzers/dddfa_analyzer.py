"""
3DDFA-V2 analyzer (section 6.4).

3DDFA_V2 (github.com/cleardusk/3DDFA_V2) is a Python source checkout with
compiled Cython extensions (FaceBoxes for detection, Sim3DR for rendering),
not a pip package. This analyzer imports its `TDDFA` class and, per frame,
runs face detection + 3D model fitting, then uses `calc_pose()` to get
yaw/pitch/roll directly and the fitted 3D vertices for jaw/facial movement.

Configuration: set `DDFA_V2_DIR` to the path of a cloned+built 3DDFA_V2
repo (must include its compiled `FaceBoxes` and `Sim3DR` extensions and
`configs/mb1_120x120.yml` + weights). If not configured, or the import
fails, `is_available()` reports `dependency_not_installed` /
`model_unavailable` and this technology is skipped for the run without
affecting the others (section 12).

Scope (section 6.4: "Primarily investigate: jaw movement, facial movement,
head movement"): this analyzer deliberately reports eye_blink and
lip_movement as `unsupported` rather than deriving a second, redundant EAR/
mouth-opening estimate from its coarser dense-alignment landmarks - those
behaviors are already covered by the three landmark-based analyzers on
equal footing (same feature/threshold code), and 3DDFA-V2's distinctive
contribution to the comparison is its 3D pose/geometry, not a re-derived 2D
metric of lower fidelity ("if a behavior cannot reasonably be obtained,
return unsupported").
"""

import time
from typing import Any, Dict, List, Optional

from app.analyzers.base_analyzer import BehaviorEvent, BehaviorResult, UnavailableReason, VisionAnalyzer
from app.config.settings import DDFA_V2_DIR, THRESHOLDS
from app.processing import feature_extraction as fx
from app.processing.temporal_detection import angular_velocity_deg, detect_events_above_threshold

# Index of a chin vertex and a nose-bridge vertex in the standard 68-point
# subset that TDDFA can also output via `tddfa.recon_vers(..., dense_flag=False)`.
CHIN = 8
NOSE_TIP = 30


class DDFAv2Analyzer(VisionAnalyzer):
    name = "3DDFA-V2"
    version = "unknown (loaded from DDFA_V2_DIR at runtime)"

    capability_map = {
        "eye_blink": False,
        "lip_movement": False,
        "jaw_movement": True,
        "facial_movement": True,
        "head_movement": True,
        "hand_movement": False,
        "arm_movement": False,
    }

    def is_available(self):
        import os
        import sys

        if not DDFA_V2_DIR or not os.path.isdir(DDFA_V2_DIR):
            return False, UnavailableReason.DEPENDENCY_NOT_INSTALLED.value
        try:
            if DDFA_V2_DIR not in sys.path:
                sys.path.insert(0, DDFA_V2_DIR)
            import TDDFA  # noqa: F401
            import FaceBoxes  # noqa: F401
        except ImportError:
            return False, UnavailableReason.DEPENDENCY_NOT_INSTALLED.value
        cfg_path = os.path.join(DDFA_V2_DIR, "configs", "mb1_120x120.yml")
        if not os.path.isfile(cfg_path):
            return False, UnavailableReason.MODEL_UNAVAILABLE.value
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
            "Each frame passed independently to FaceBoxes for detection, then to TDDFA "
            "for 3D model fitting; no temporal smoothing applied by 3DDFA-V2 itself "
            "(smoothing/event detection is applied afterwards by this pipeline)."
        )

        try:
            import os

            import cv2
            import yaml
            from FaceBoxes import FaceBoxes
            from TDDFA import TDDFA
            from utils.pose import calc_pose  # provided by the 3DDFA_V2 repo

            cfg_path = os.path.join(DDFA_V2_DIR, "configs", "mb1_120x120.yml")
            cfg = yaml.safe_load(open(cfg_path))
            tddfa = TDDFA(gpu_mode=False, **cfg)
            face_boxes = FaceBoxes()

            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                return self.error_result(video_meta, "runtime_error: could not open video file")
            fps = video_meta.get("fps") or (cap.get(cv2.CAP_PROP_FPS) or 30.0)

            timestamps, jaw_signal, face_signal, yaw_signal, pitch_signal, roll_signal = [], [], [], [], [], []
            prev_pts = None
            processed, missing, frame_idx = 0, 0, 0

            while True:
                ok, frame = cap.read()
                if not ok:
                    break
                t = frame_idx / fps
                boxes = face_boxes(frame)
                frame_idx += 1
                if not boxes:
                    missing += 1
                    continue

                param_lst, roi_box_lst = tddfa(frame, [boxes[0]])
                ver_lst = tddfa.recon_vers(param_lst, roi_box_lst, dense_flag=False)
                pts_3d = ver_lst[0].T  # Nx3: 68 3D landmark points in image-plane coords

                pts_2d = [(p[0], p[1]) for p in pts_3d]
                face_scale = fx.euclidean(pts_2d[36], pts_2d[45]) if len(pts_2d) > 45 else 0.0
                if face_scale <= 0:
                    missing += 1
                    continue

                jaw_signal.append(fx.jaw_opening(pts_2d[CHIN], pts_2d[NOSE_TIP], face_scale))
                if prev_pts is not None:
                    face_signal.append(fx.mean_landmark_displacement(prev_pts, pts_2d, face_scale))
                else:
                    face_signal.append(0.0)
                prev_pts = pts_2d

                _P, pose = calc_pose(param_lst[0])  # (yaw, pitch, roll) in degrees, per 3DDFA_V2's own utils
                yaw_signal.append(float(pose[0]))
                pitch_signal.append(float(pose[1]))
                roll_signal.append(float(pose[2]))

                timestamps.append(t)
                processed += 1

            cap.release()

            behaviors: Dict[str, BehaviorResult] = {
                "eye_blink": BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature"),
                "lip_movement": BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature"),
                "hand_movement": BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature"),
                "arm_movement": BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature"),
            }
            smoothing = THRESHOLDS["smoothing_window_frames"]

            if timestamps:
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
                for b in ["jaw_movement", "facial_movement", "head_movement"]:
                    behaviors[b] = BehaviorResult.error("runtime_error: no frames with a detected face")

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
                thresholds_used={k: THRESHOLDS[k] for k in ["jaw_movement", "facial_movement", "head_movement"]},
            )
        except Exception as exc:
            return self.error_result(video_meta, f"runtime_error: {exc}", time.time() - start)
