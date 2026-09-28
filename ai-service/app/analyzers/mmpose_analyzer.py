"""
MMPose analyzer (section 6.5).

Uses MMPose's high-level `MMPoseInferencer` (mmpose >= 1.x) with a
whole-body 2D pose model (COCO-WholeBody, 133 keypoints: 17 body + 6 feet +
68 face + 42 hand). This analyzer only uses the body and hand keypoint
groups - head position (from body keypoints), wrist/hand displacement, and
elbow-wrist (forearm) displacement - per the spec's scope for this
technology (section 6.5: "Primarily investigate: head movement, hand
movement, arm movement"). Face keypoints from the whole-body model are
intentionally not used here, for the same reason given in the 3DDFA-V2
analyzer: eye/lip/jaw are already covered on equal footing by the
dedicated face analyzers, and MMPose's distinctive contribution to this
comparison is body/hand pose.

Configuration: requires `mmpose`, `mmcv`, `mmdet` (and their compiled ops)
to be installed, and a body/whole-body checkpoint available - either the
default one MMPoseInferencer downloads on first use, or explicit
`MMPOSE_CONFIG` / `MMPOSE_CHECKPOINT` env vars for an offline/local model.
If mmpose cannot be imported, `is_available()` reports
`dependency_not_installed` and this technology is skipped for the run
without affecting the others (section 12).
"""

import time
from typing import Any, Dict, List, Optional

from app.analyzers.base_analyzer import BehaviorEvent, BehaviorResult, UnavailableReason, VisionAnalyzer
from app.config.settings import MMPOSE_CHECKPOINT, MMPOSE_CONFIG, THRESHOLDS
from app.processing.feature_extraction import euclidean, wrist_or_joint_velocity
from app.processing.temporal_detection import detect_events_above_threshold

# COCO-WholeBody body-keypoint indices (subset of the 133-point layout).
NOSE = 0
LEFT_SHOULDER, RIGHT_SHOULDER = 5, 6
LEFT_ELBOW, RIGHT_ELBOW = 7, 8
LEFT_WRIST, RIGHT_WRIST = 9, 10


class MMPoseAnalyzer(VisionAnalyzer):
    name = "MMPose"
    version = "unknown (resolved from installed mmpose at runtime)"

    capability_map = {
        "eye_blink": False,
        "lip_movement": False,
        "jaw_movement": False,
        "facial_movement": False,
        "head_movement": True,
        "hand_movement": True,
        "arm_movement": True,
    }

    def is_available(self):
        try:
            from mmpose.apis import MMPoseInferencer  # noqa: F401
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
            "Video processed with MMPoseInferencer('wholebody') at native resolution/fps; "
            "only body and hand keypoint groups are used (face keypoints from the "
            "whole-body model are not used by this analyzer - see module docstring)."
        )

        try:
            from mmpose.apis import MMPoseInferencer

            if MMPOSE_CONFIG and MMPOSE_CHECKPOINT:
                inferencer = MMPoseInferencer(pose2d=MMPOSE_CONFIG, pose2d_weights=MMPOSE_CHECKPOINT)
            else:
                inferencer = MMPoseInferencer("wholebody")

            fps = video_meta.get("fps") or 30.0

            timestamps: List[float] = []
            nose_pos, l_wrist_pos, r_wrist_pos, l_elbow_pos, r_elbow_pos = [], [], [], [], []
            shoulder_width_signal: List[float] = []
            processed, missing, frame_idx = 0, 0, 0

            for result in inferencer(video_path, show=False):
                predictions = result.get("predictions", [[]])[0]
                frame_idx += 1
                t = (frame_idx - 1) / fps
                if not predictions:
                    missing += 1
                    continue

                person = max(predictions, key=lambda p: p.get("bbox_score", 0.0))
                kpts = person.get("keypoints", [])
                if len(kpts) <= RIGHT_WRIST:
                    missing += 1
                    continue

                shoulder_w = euclidean(tuple(kpts[LEFT_SHOULDER][:2]), tuple(kpts[RIGHT_SHOULDER][:2]))
                if shoulder_w <= 0:
                    missing += 1
                    continue

                shoulder_width_signal.append(shoulder_w)
                nose_pos.append(tuple(kpts[NOSE][:2]))
                l_wrist_pos.append(tuple(kpts[LEFT_WRIST][:2]))
                r_wrist_pos.append(tuple(kpts[RIGHT_WRIST][:2]))
                l_elbow_pos.append(tuple(kpts[LEFT_ELBOW][:2]))
                r_elbow_pos.append(tuple(kpts[RIGHT_ELBOW][:2]))
                timestamps.append(t)
                processed += 1

            behaviors: Dict[str, BehaviorResult] = {
                "eye_blink": BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature"),
                "lip_movement": BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature"),
                "jaw_movement": BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature"),
                "facial_movement": BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature"),
            }
            smoothing = THRESHOLDS["smoothing_window_frames"]

            if timestamps:
                mean_scale = sum(shoulder_width_signal) / len(shoulder_width_signal)

                head_speed = wrist_or_joint_velocity(nose_pos, timestamps, mean_scale)
                cfg = THRESHOLDS["head_movement"]
                # MMPose has no direct angular pose here; a normalized head-keypoint
                # speed is used as the head-movement activation signal instead of
                # angular velocity (documented via thresholds_used below), since a
                # single 2D nose keypoint does not give yaw/pitch/roll.
                head_threshold = cfg["angular_velocity_threshold_deg_s"] / 100.0  # rescaled, see note above
                events = detect_events_above_threshold(
                    head_speed, timestamps, head_threshold, cfg["hysteresis_ratio"],
                    cfg["min_event_duration_s"], None, smoothing, direction="above",
                )
                behaviors["head_movement"] = BehaviorResult.from_events(
                    [BehaviorEvent(i.start_time, i.end_time, i.end_time - i.start_time, i.peak_value) for i in events]
                )

                l_hand_speed = wrist_or_joint_velocity(l_wrist_pos, timestamps, mean_scale)
                r_hand_speed = wrist_or_joint_velocity(r_wrist_pos, timestamps, mean_scale)
                hand_speed = [max(a, b) for a, b in zip(l_hand_speed, r_hand_speed)]
                cfg = THRESHOLDS["hand_movement"]
                events = detect_events_above_threshold(
                    hand_speed, timestamps, cfg["velocity_threshold"], cfg["hysteresis_ratio"],
                    cfg["min_event_duration_s"], None, smoothing, direction="above",
                )
                behaviors["hand_movement"] = BehaviorResult.from_events(
                    [BehaviorEvent(i.start_time, i.end_time, i.end_time - i.start_time, i.peak_value) for i in events]
                )

                l_arm_speed = wrist_or_joint_velocity(l_elbow_pos, timestamps, mean_scale)
                r_arm_speed = wrist_or_joint_velocity(r_elbow_pos, timestamps, mean_scale)
                arm_speed = [max(a, b) for a, b in zip(l_arm_speed, r_arm_speed)]
                cfg = THRESHOLDS["arm_movement"]
                events = detect_events_above_threshold(
                    arm_speed, timestamps, cfg["velocity_threshold"], cfg["hysteresis_ratio"],
                    cfg["min_event_duration_s"], None, smoothing, direction="above",
                )
                behaviors["arm_movement"] = BehaviorResult.from_events(
                    [BehaviorEvent(i.start_time, i.end_time, i.end_time - i.start_time, i.peak_value) for i in events]
                )
            else:
                for b in ["head_movement", "hand_movement", "arm_movement"]:
                    behaviors[b] = BehaviorResult.error("runtime_error: no frames with a detected person")

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
                thresholds_used={k: THRESHOLDS[k] for k in ["head_movement", "hand_movement", "arm_movement"]},
            )
        except Exception as exc:
            return self.error_result(video_meta, f"runtime_error: {exc}", time.time() - start)
