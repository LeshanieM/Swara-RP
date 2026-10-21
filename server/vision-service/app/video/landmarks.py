"""Per-frame face tracking with MediaPipe Face Landmarker (Tasks API, VIDEO mode).

For every analysed frame it keeps all 52 blendshapes, head pose (yaw, pitch,
roll and translation from the facial transformation matrix) and three
geometric measures (EAR, lip opening, chin drop, mouth width; all normalised by
the inter-ocular distance). Frames without a usable face are kept as missing,
never dropped, so time stays aligned with the audio.

The landmark indices and geometry follow the earlier C2 prototype.
"""
import math
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np

from app.features import catalog
from app.video.io import VideoError

RIGHT_EYE_EAR_IDX = (33, 160, 158, 133, 153, 144)
LEFT_EYE_EAR_IDX = (362, 385, 387, 263, 373, 380)
MOUTH_TOP, MOUTH_BOTTOM, MOUTH_LEFT, MOUTH_RIGHT = 13, 14, 61, 291
CHIN, NOSE_TIP = 152, 1
LEFT_EYE_OUTER, RIGHT_EYE_OUTER = 33, 263


class FaceModelUnavailable(Exception):
    pass


@dataclass
class Tracks:
    times: np.ndarray  # seconds, one per analysed frame
    face: np.ndarray  # bool, a usable face was found
    scored: np.ndarray  # frames × catalog.SCORED (raw, NaN where no face)
    analysed_fps: float
    frames_read: int
    small_face_frames: int
    raw: list[dict] = field(default_factory=list)  # per-frame blendshapes + pose + geometry (None if no face)


def _dist(a, b) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


def _ear(points) -> float:
    p1, p2, p3, p4, p5, p6 = points
    horizontal = 2.0 * _dist(p1, p4)
    return (_dist(p2, p6) + _dist(p3, p5)) / horizontal if horizontal else 0.0


def _euler_deg(r) -> tuple[float, float, float]:
    """(yaw, pitch, roll) in degrees from a 3×3 rotation matrix."""
    sy = math.sqrt(r[0][0] ** 2 + r[1][0] ** 2)
    if sy >= 1e-6:
        pitch = math.degrees(math.atan2(r[2][1], r[2][2]))
        yaw = math.degrees(math.atan2(-r[2][0], sy))
        roll = math.degrees(math.atan2(r[1][0], r[0][0]))
    else:
        pitch = math.degrees(math.atan2(-r[1][2], r[1][1]))
        yaw = math.degrees(math.atan2(-r[2][0], sy))
        roll = 0.0
    return yaw, pitch, roll


def _geometry(pts, width: int, height: int) -> dict | None:
    # Landmarks are normalised to [0, 1] per axis; convert to pixels so distances are isotropic.
    px = [(x * width, y * height) for x, y in pts]
    scale = _dist(px[LEFT_EYE_OUTER], px[RIGHT_EYE_OUTER])
    if scale <= 0:
        return None
    ear = (_ear([px[i] for i in RIGHT_EYE_EAR_IDX]) + _ear([px[i] for i in LEFT_EYE_EAR_IDX])) / 2.0
    xs = [p[0] for p in px]
    return {
        "ear": ear,
        "lipOpening": _dist(px[MOUTH_TOP], px[MOUTH_BOTTOM]) / scale,
        "mouthWidth": _dist(px[MOUTH_LEFT], px[MOUTH_RIGHT]) / scale,
        "jawOpening": _dist(px[CHIN], px[NOSE_TIP]) / scale,
        "faceWidthRatio": (max(xs) - min(xs)) / width if width else 0.0,
    }


def track(path: str, model_path: Path, target_fps: float, src_fps: float,
          min_face_width_ratio: float, keep_raw: bool = False) -> Tracks:
    if not model_path.is_file():
        raise FaceModelUnavailable(f"MediaPipe model not found at {model_path}; run scripts/fetch_face_model.py.")

    import cv2
    import mediapipe as mp
    from mediapipe.tasks import python as mp_python
    from mediapipe.tasks.python import vision

    cap = cv2.VideoCapture(path)
    if not cap.isOpened():
        raise VideoError("unreadable_video", "OpenCV could not open the video.")
    fps = src_fps or cap.get(cv2.CAP_PROP_FPS) or 30.0
    step = 1.0 / min(target_fps, fps) if target_fps > 0 else 0.0

    options = vision.FaceLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=str(model_path)),
        running_mode=vision.RunningMode.VIDEO,
        num_faces=1,
        output_face_blendshapes=True,
        output_facial_transformation_matrixes=True,
    )
    times, face, rows, raw = [], [], [], []
    frames_read = small = 0
    next_t = 0.0
    last_ms = -1
    nan_row = [math.nan] * len(catalog.SCORED_NAMES)

    with vision.FaceLandmarker.create_from_options(options) as landmarker:
        while True:
            if not cap.grab():
                break
            idx = frames_read
            frames_read += 1
            pos_ms = cap.get(cv2.CAP_PROP_POS_MSEC)
            t = pos_ms / 1000.0 if (pos_ms > 0 or idx == 0) else idx / fps
            if t + 1e-6 < next_t:
                continue
            next_t = t + step if step else t
            ok, frame = cap.retrieve()
            if not ok:
                continue
            ms = max(int(round(t * 1000)), last_ms + 1)  # VIDEO mode needs strictly increasing timestamps
            last_ms = ms
            h, w = frame.shape[:2]
            res = landmarker.detect_for_video(
                mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)), ms)

            times.append(t)
            geo = None
            if res.face_landmarks:
                geo = _geometry([(p.x, p.y) for p in res.face_landmarks[0]], w, h)
                if geo is not None and geo["faceWidthRatio"] < min_face_width_ratio:
                    small += 1
                    geo = None
            if geo is None:
                face.append(False)
                rows.append(nan_row)
                if keep_raw:
                    raw.append(None)
                continue

            bs = {c.category_name: float(c.score) for c in res.face_blendshapes[0]} if res.face_blendshapes else {}
            if res.facial_transformation_matrixes:
                m = np.asarray(res.facial_transformation_matrixes[0])
                yaw, pitch, roll = _euler_deg(m[:3, :3])
                pose = {"yaw": yaw, "pitch": pitch, "roll": roll, "x": float(m[0, 3]), "y": float(m[1, 3]), "z": float(m[2, 3])}
            else:
                pose = {"yaw": 0.0, "pitch": 0.0, "roll": 0.0, "x": 0.0, "y": 0.0, "z": 0.0}
            scored = catalog.scored_from_frame(bs, geo, pose)
            face.append(True)
            rows.append([scored[n] for n in catalog.SCORED_NAMES])
            if keep_raw:
                raw.append({"blendshapes": {k: round(v, 4) for k, v in bs.items()},
                            "pose": {k: round(v, 3) for k, v in pose.items()},
                            "geometry": {k: round(v, 4) for k, v in geo.items()}})
    cap.release()

    if not times:
        raise VideoError("unreadable_video", "No frames could be decoded from the video.")
    t_arr = np.asarray(times, dtype=float)
    span = t_arr[-1] - t_arr[0]
    analysed_fps = (len(t_arr) - 1) / span if span > 0 else float(min(target_fps, fps))
    return Tracks(
        times=t_arr,
        face=np.asarray(face, dtype=bool),
        scored=np.asarray(rows, dtype=float),
        analysed_fps=round(analysed_fps, 3),
        frames_read=frames_read,
        small_face_frames=small,
        raw=raw,
    )
