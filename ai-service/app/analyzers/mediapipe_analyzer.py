"""
MediaPipe Face Landmarker analyzer (section 6.1), built on the MediaPipe
Tasks API (`mediapipe.tasks.python.vision.FaceLandmarker`).

Investigates: eye blinking, lip movement, jaw movement, facial movement,
head movement. Hand/arm movement are `unsupported` (a face landmarker has
no body/hand signal; that belongs to MMPose, section 6.5).

Visual features used (section 6.1: landmarks, blendshapes, head pose):
  * eye blink   -> Eye Aspect Ratio from 478-point landmarks, cross-checked
                   by the `eyeBlinkLeft/Right` blendshape mean (stored in the
                   feature summary; event detection uses EAR so the same
                   detector definition is shared with the other face analyzers)
  * lip movement -> normalized mouth opening (landmarks 13/14)
  * jaw movement -> normalized chin-to-nose distance (landmarks 152/1)
  * facial movement -> mean landmark displacement of a coarse landmark set
  * head movement -> yaw/pitch/roll from `facial_transformation_matrixes`,
                   angular velocity -> events

MediaPipe provides visual features only. Nothing here claims to detect
"secondary stuttering behaviors" (sections 4 and 29).

The `.task` model bundle is NOT downloaded automatically (see
settings.MEDIAPIPE_FACE_MODEL_PATH); if missing, this analyzer reports
`unavailable` / `model_unavailable`.
"""

import os
import logging
import time
from typing import Any, Dict, List, Optional

import numpy as np

from app import c2_inference as c2
from app.analyzers.base_analyzer import BehaviorEvent, BehaviorResult, UnavailableReason, VisionAnalyzer
from app.config.settings import MEDIAPIPE_FACE_MODEL_PATH, RESULTS_DIR, THRESHOLDS
from app.processing import feature_extraction as fx
from app.processing.temporal_detection import angular_velocity_deg, detect_events_above_threshold
from app.processing.tmmf import extract_windows
from app.visualization.overlays import OverlayWriter

RIGHT_EYE_EAR_IDX = [33, 160, 158, 133, 153, 144]
LEFT_EYE_EAR_IDX = [362, 385, 387, 263, 373, 380]
MOUTH_TOP, MOUTH_BOTTOM, MOUTH_LEFT, MOUTH_RIGHT = 13, 14, 61, 291
CHIN, NOSE_TIP = 152, 1
LEFT_EYE_OUTER, RIGHT_EYE_OUTER = 33, 263
FACE_SAMPLE = [10, 152, 234, 454, 1, 168]
logger = logging.getLogger("swara.vision.mediapipe")


def _to_events(intervals) -> List[BehaviorEvent]:
    return [BehaviorEvent(i.start_time, i.end_time, i.end_time - i.start_time, i.peak_value) for i in intervals]


class MediaPipeAnalyzer(VisionAnalyzer):
    name = "MediaPipe"
    version = "Tasks API FaceLandmarker"

    capability_map = {
        "eye_blink": True,
        "lip_movement": True,
        "jaw_movement": True,
        "facial_movement": True,
        "head_movement": True,
        "hand_movement": False,
        "arm_movement": False,
    }

    def unavailable_result(self, video_meta: Dict[str, Any], reason: str) -> Dict[str, Any]:
        result = super().unavailable_result(video_meta, reason)
        result.update({"c2_predictions": None, "c2_status": "unavailable", "c2_reason": reason})
        return result

    def error_result(
        self, video_meta: Dict[str, Any], reason: str, processing_time: float = 0.0
    ) -> Dict[str, Any]:
        result = super().error_result(video_meta, reason, processing_time)
        result.update({"c2_predictions": None, "c2_status": "unavailable", "c2_reason": reason})
        return result

    def is_available(self):
        try:
            import cv2  # noqa: F401
            import mediapipe  # noqa: F401
            from mediapipe.tasks.python import vision  # noqa: F401
        except ImportError:
            return False, UnavailableReason.DEPENDENCY_NOT_INSTALLED.value
        if not os.path.isfile(MEDIAPIPE_FACE_MODEL_PATH):
            return False, UnavailableReason.MODEL_UNAVAILABLE.value
        return True, None

    def analyze(
        self,
        video_path: str,
        generate_overlay: bool = False,
        preprocessing_notes: Optional[List[str]] = None,
        target_fps: Optional[float] = None,
    ) -> Dict[str, Any]:
        video_meta = _probe_video(video_path)
        available, reason = self.is_available()
        if not available:
            return self.unavailable_result(video_meta, reason)

        start = time.time()
        notes = list(preprocessing_notes or [])
        notes.append(
            "Frames read at native resolution/FPS; no resize, crop, or frame-rate change. "
            "FaceLandmarker run in VIDEO mode (single face) with blendshapes and facial "
            "transformation matrices enabled."
        )
        if target_fps and target_fps > 0:
            notes.append(f"Research sampling target: {target_fps:g} frames/s.")

        try:
            import cv2
            import mediapipe as mp
            from mediapipe.tasks import python as mp_python
            from mediapipe.tasks.python import vision

            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                return self.error_result(video_meta, "runtime_error: could not open video file")

            fps = video_meta.get("fps") or 30.0
            frame_stride = max(1, round(fps / target_fps)) if target_fps and target_fps > 0 else 1
            width, height = video_meta.get("width") or 0, video_meta.get("height") or 0

            options = vision.FaceLandmarkerOptions(
                base_options=mp_python.BaseOptions(model_asset_path=MEDIAPIPE_FACE_MODEL_PATH),
                running_mode=vision.RunningMode.VIDEO,
                num_faces=1,
                output_face_blendshapes=True,
                output_facial_transformation_matrixes=True,
            )
            landmarker = vision.FaceLandmarker.create_from_options(options)

            overlay = None
            if generate_overlay and width and height:
                overlay = OverlayWriter(_overlay_path(video_path, self.name), width, height, fps)

            ts: List[float] = []
            ear, lip, jaw, face_mv = [], [], [], []
            yaw_s, pitch_s, roll_s, blink_bs = [], [], [], []
            c2_frame_rows: List[np.ndarray] = []
            c2_frame_times: List[int] = []
            c2_face_flags: List[int] = []
            prev = None
            processed = missing = frame_idx = 0

            while True:
                ok, frame = cap.read()
                if not ok:
                    break
                t = frame_idx / fps
                current_frame = frame_idx
                frame_idx += 1
                if current_frame % frame_stride:
                    if overlay is not None and overlay.enabled:
                        overlay.write(frame)
                    continue
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
                res = landmarker.detect_for_video(mp_image, int(t * 1000))

                if c2.C2_AVAILABLE:
                    c2_frame, c2_has_face = _c2_frame_features(res)
                    c2_frame_rows.append(c2_frame)
                    c2_frame_times.append(int(round(t * 1000)))
                    c2_face_flags.append(int(c2_has_face))

                if not res.face_landmarks:
                    missing += 1
                    if overlay is not None and overlay.enabled:
                        overlay.write(frame)
                    continue

                lm = res.face_landmarks[0]
                pts = [(p.x, p.y) for p in lm]
                px = [(p.x * width, p.y * height) for p in lm]
                scale = fx.euclidean(pts[LEFT_EYE_OUTER], pts[RIGHT_EYE_OUTER])
                if scale <= 0:
                    missing += 1
                    continue

                r = fx.eye_aspect_ratio([pts[i] for i in RIGHT_EYE_EAR_IDX])
                l = fx.eye_aspect_ratio([pts[i] for i in LEFT_EYE_EAR_IDX])
                ear.append((r + l) / 2.0)
                opening, _w = fx.mouth_opening_width(
                    pts[MOUTH_TOP], pts[MOUTH_BOTTOM], pts[MOUTH_LEFT], pts[MOUTH_RIGHT], scale
                )
                lip.append(opening)
                jaw.append(fx.jaw_opening(pts[CHIN], pts[NOSE_TIP], scale))
                if prev is not None:
                    face_mv.append(
                        fx.mean_landmark_displacement(
                            [prev[i] for i in FACE_SAMPLE], [pts[i] for i in FACE_SAMPLE], scale
                        )
                    )
                else:
                    face_mv.append(0.0)
                prev = pts

                if res.facial_transformation_matrixes:
                    m = res.facial_transformation_matrixes[0]
                    yaw, pitch, roll = fx.rotation_matrix_to_euler_deg(m[:3, :3])
                else:
                    yaw = pitch = roll = 0.0
                yaw_s.append(yaw)
                pitch_s.append(pitch)
                roll_s.append(roll)

                if res.face_blendshapes:
                    scores = {c.category_name: c.score for c in res.face_blendshapes[0]}
                    blink_bs.append((scores.get("eyeBlinkLeft", 0.0) + scores.get("eyeBlinkRight", 0.0)) / 2.0)

                ts.append(t)
                processed += 1

                if overlay is not None and overlay.enabled:
                    overlay.draw_points(frame, [px[i] for i in RIGHT_EYE_EAR_IDX + LEFT_EYE_EAR_IDX], (0, 255, 0), 2)
                    overlay.draw_points(frame, [px[i] for i in (MOUTH_TOP, MOUTH_BOTTOM, MOUTH_LEFT, MOUTH_RIGHT)], (0, 165, 255), 2)
                    overlay.draw_points(frame, [px[CHIN], px[NOSE_TIP]], (255, 0, 0), 2)
                    overlay.put_text(frame, f"yaw {yaw:.0f} pitch {pitch:.0f} roll {roll:.0f}")
                    overlay.write(frame)

            cap.release()
            landmarker.close()
            overlay_path = overlay.close() if overlay is not None else None

            sm = THRESHOLDS["smoothing_window_frames"]
            behaviors: Dict[str, BehaviorResult] = {}

            c = THRESHOLDS["eye_blink"]
            behaviors["eye_blink"] = BehaviorResult.from_events(_to_events(detect_events_above_threshold(
                ear, ts, c["ear_threshold"], c["ear_hysteresis_ratio"], c["min_event_duration_s"],
                c["max_event_duration_s"], sm, direction="below")))
            if blink_bs:
                behaviors["eye_blink"].feature_summary = {
                    "mean_blink_blendshape": round(sum(blink_bs) / len(blink_bs), 4),
                    "max_blink_blendshape": round(max(blink_bs), 4),
                }

            for key, sig in (("lip_movement", lip), ("jaw_movement", jaw), ("facial_movement", face_mv)):
                c = THRESHOLDS[key]
                behaviors[key] = BehaviorResult.from_events(_to_events(detect_events_above_threshold(
                    sig, ts, c["activation_threshold"], c["hysteresis_ratio"], c["min_event_duration_s"],
                    None, sm, direction="above")))

            c = THRESHOLDS["head_movement"]
            vel = ([max(a, b, d) for a, b, d in zip(
                angular_velocity_deg(yaw_s, ts), angular_velocity_deg(pitch_s, ts), angular_velocity_deg(roll_s, ts))]
                if ts else [])
            behaviors["head_movement"] = BehaviorResult.from_events(_to_events(detect_events_above_threshold(
                vel, ts, c["angular_velocity_threshold_deg_s"], c["hysteresis_ratio"],
                c["min_event_duration_s"], None, sm, direction="above")))

            behaviors["hand_movement"] = BehaviorResult.unsupported("technology_does_not_provide_this_feature")
            behaviors["arm_movement"] = BehaviorResult.unsupported("technology_does_not_provide_this_feature")

            result = self.build_result(
                status="completed",
                processing_time=time.time() - start,
                video_meta=video_meta,
                behaviors=behaviors,
                tracking={
                    "processed_frames": processed,
                    "missing_frames": missing,
                    "tracking_failures": missing,
                    "total_frames_read": frame_idx,
                },
                preprocessing_notes=notes,
                thresholds_used={k: THRESHOLDS[k] for k in (
                    "eye_blink", "lip_movement", "jaw_movement", "facial_movement", "head_movement")}
                | {"smoothing_window_frames": sm},
            )
            if overlay_path:
                result["overlay_video_path"] = overlay_path
            # Preserve existing event results while exposing the shared,
            # technology-neutral temporal representation for research/training.
            # EAR/lip/jaw signals are normalized by inter-ocular distance above.
            frames = [{"timestamp": t,
                       "eye": abs(ear[i] - ear[i - 1]) if i else 0.0,
                       "lip": abs(lip[i] - lip[i - 1]) if i else 0.0,
                       "jaw": abs(jaw[i] - jaw[i - 1]) if i else 0.0,
                       "head": vel[i]}
                      for i, t in enumerate(ts)]
            result["tmmf"] = {"status": "features_only",
                              "method": "Temporal Multimodal Movement Fusion",
                              "window_s": 2.0, "overlap": 0.5,
                              "target_fps": round(fps / frame_stride, 3),
                              "windows": extract_windows(frames),
                              "note": "Predictions require speaker-labeled expert training data; no labels are inferred here."}
            result["c2_predictions"] = None
            result["c2_status"] = "unavailable"
            if not c2.C2_AVAILABLE:
                result["c2_reason"] = c2.C2_UNAVAILABLE_REASON or "model_unavailable"
            else:
                try:
                    sampled_frames, sampled_times, sampled_faces = c2.resample_to_15_fps(
                        np.asarray(c2_frame_rows, dtype=np.float32).reshape(-1, 56),
                        np.asarray(c2_frame_times, dtype=np.int32),
                        np.asarray(c2_face_flags, dtype=np.uint8),
                        duration_ms=frame_idx / fps * 1000.0,
                    )
                    tracking_quality = c2.face_tracking_quality(sampled_faces)
                    result["tracking_quality"] = tracking_quality
                    tracking_status = c2.status_for_tracking(sampled_faces)
                    if tracking_status:
                        result["c2_status"] = tracking_status
                        result["c2_reason"] = "Face detected in fewer than half of sampled frames."
                    else:
                        result["c2_predictions"] = c2.predict_c2(
                            sampled_frames, sampled_times, sampled_faces
                        )
                        result["c2_status"] = "assessed"
                        result["inference_ms"] = result["c2_predictions"]["inference_ms"]
                except Exception as exc:  # C2 failures must not erase legacy feature results.
                    logger.exception("C2 GRU inference failed")
                    result["c2_status"] = "unavailable"
                    result["c2_reason"] = f"inference_error: {exc}"
            return result
        except Exception as exc:  # one technology failing must not stop the experiment
            return self.error_result(video_meta, f"runtime_error: {exc}", time.time() - start)


def _c2_frame_features(result: Any) -> tuple[np.ndarray, bool]:
    """Create the training-order 56 raw channels from an existing MP result."""
    landmarks = getattr(result, "face_landmarks", None) or []
    has_face = bool(landmarks)
    blendshapes = np.full(52, np.nan, dtype=np.float32)
    pose = np.full(3, np.nan, dtype=np.float32)
    categories = getattr(result, "face_blendshapes", None) or []
    if has_face and categories:
        scores = {str(item.category_name): float(item.score) for item in categories[0]}
        expected = c2.BLENDSHAPE_NAMES
        if len(expected) == 52 and all(name in scores for name in expected):
            blendshapes = np.asarray([scores[name] for name in expected], dtype=np.float32)
    matrices = getattr(result, "facial_transformation_matrixes", None) or []
    if has_face and matrices:
        pose = c2.euler_pitch_yaw_roll(matrices[0])
    return np.concatenate([blendshapes, pose, np.asarray([float(has_face)], dtype=np.float32)]), has_face


def _probe_video(video_path: str) -> Dict[str, Any]:
    try:
        import cv2

        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS) or 0.0
        n = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
        meta = {
            "duration": round(n / fps, 3) if fps else 0.0,
            "fps": round(fps, 3),
            "width": int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) or 0),
            "height": int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0),
            "total_frames": n,
        }
        cap.release()
        return meta
    except Exception:
        return {"duration": 0.0, "fps": 0.0, "width": 0, "height": 0, "total_frames": 0}


def _overlay_path(video_path: str, technology: str) -> str:
    base = os.path.splitext(os.path.basename(video_path))[0]
    tech_dir = RESULTS_DIR / technology.lower().replace(" ", "_")
    tech_dir.mkdir(parents=True, exist_ok=True)
    return str(tech_dir / f"{base}_overlay.mp4")
