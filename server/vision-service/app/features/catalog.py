"""The features SRCD scores, the signal each belongs to, and each signal's category.

Every frame keeps all 52 MediaPipe blendshapes plus head pose and geometry (see
``video/landmarks.py``). Scoring all of them would multiply chance deviations, so
SRCD scores this curated set: left/right pairs are averaged, and expressions that
are not concomitant behaviours (smiles, dimples) are kept in the frames only.

Signals map to the two CASA categories:
  FG (facial): eye (incl. brows and gaze), lip, jaw, cheek (incl. nose)
  HM (head):   head
"""
import warnings
from dataclasses import dataclass

import numpy as np

SIGNALS = ("eye", "lip", "jaw", "cheek", "head")
CATEGORY_OF_SIGNAL = {"eye": "FG", "lip": "FG", "jaw": "FG", "cheek": "FG", "head": "HM"}
CATEGORIES = ("FG", "HM")


@dataclass(frozen=True)
class Feature:
    name: str
    signal: str
    label: str  # used in explanations
    floor: float  # smallest robust spread, in the feature's own units
    detrend: bool = False  # remove slow drift (posture) with a rolling median


SCORED = (
    Feature("eyeBlink", "eye", "eye closure", 0.03),
    Feature("eyeSquint", "eye", "eye squint", 0.03),
    Feature("eyeWide", "eye", "eye widening", 0.03),
    Feature("browDown", "eye", "brow lowering", 0.03),
    Feature("browInnerUp", "eye", "inner brow raise", 0.03),
    Feature("ear", "eye", "eye opening (EAR)", 0.012),
    Feature("gazeHorizontal", "eye", "sideways gaze", 0.04),
    Feature("gazeVertical", "eye", "vertical gaze", 0.04),
    Feature("mouthPress", "lip", "lip pressing", 0.03),
    Feature("mouthPucker", "lip", "lip puckering", 0.03),
    Feature("mouthFunnel", "lip", "lip funnelling", 0.03),
    Feature("mouthStretch", "lip", "lip stretching", 0.03),
    Feature("mouthRollLower", "lip", "lower lip roll", 0.03),
    Feature("mouthRollUpper", "lip", "upper lip roll", 0.03),
    Feature("lipOpening", "lip", "lip opening", 0.015),
    Feature("mouthWidth", "lip", "mouth width", 0.015),
    Feature("jawOpen", "jaw", "jaw opening", 0.03),
    Feature("jawForward", "jaw", "jaw thrust", 0.03),
    Feature("jawLateral", "jaw", "sideways jaw", 0.03),
    Feature("jawOpening", "jaw", "chin drop", 0.015),
    Feature("cheekPuff", "cheek", "cheek puffing", 0.03),
    Feature("cheekSquint", "cheek", "cheek tension", 0.03),
    Feature("noseSneer", "cheek", "nose wrinkling", 0.03),
    Feature("yaw", "head", "head turn", 1.5, detrend=True),
    Feature("pitch", "head", "head nod/tilt back", 1.5, detrend=True),
    Feature("roll", "head", "head tilt", 1.5, detrend=True),
    Feature("headX", "head", "sideways head shift", 0.3, detrend=True),
    Feature("headY", "head", "vertical head shift", 0.3, detrend=True),
    Feature("headZ", "head", "head moving forward/back", 0.5, detrend=True),
    Feature("headSpeed", "head", "head movement speed", 8.0),
)
SCORED_NAMES = tuple(f.name for f in SCORED)
FEATURE_BY_NAME = {f.name: f for f in SCORED}

DETREND_SEC = 5.0  # rolling-median window for posture drift
SMOOTH_FRAMES = 3  # rolling median against landmark jitter


def _pair(bs: dict, base: str) -> float:
    return (bs.get(f"{base}Left", 0.0) + bs.get(f"{base}Right", 0.0)) / 2.0


def scored_from_frame(bs: dict, geo: dict, pose: dict) -> dict:
    """Map one frame's raw values (blendshapes, geometry, pose) onto the scored features.

    headSpeed is filled in later from consecutive frames (see ``derive_series``).
    """
    # Looking towards the subject's left = left eye looks out + right eye looks in.
    gaze_left = (bs.get("eyeLookOutLeft", 0.0) + bs.get("eyeLookInRight", 0.0)) / 2.0
    gaze_right = (bs.get("eyeLookOutRight", 0.0) + bs.get("eyeLookInLeft", 0.0)) / 2.0
    return {
        "eyeBlink": _pair(bs, "eyeBlink"),
        "eyeSquint": _pair(bs, "eyeSquint"),
        "eyeWide": _pair(bs, "eyeWide"),
        "browDown": _pair(bs, "browDown"),
        "browInnerUp": bs.get("browInnerUp", 0.0),
        "ear": geo["ear"],
        "gazeHorizontal": gaze_left - gaze_right,
        "gazeVertical": _pair(bs, "eyeLookUp") - _pair(bs, "eyeLookDown"),
        "mouthPress": _pair(bs, "mouthPress"),
        "mouthPucker": bs.get("mouthPucker", 0.0),
        "mouthFunnel": bs.get("mouthFunnel", 0.0),
        "mouthStretch": _pair(bs, "mouthStretch"),
        "mouthRollLower": bs.get("mouthRollLower", 0.0),
        "mouthRollUpper": bs.get("mouthRollUpper", 0.0),
        "lipOpening": geo["lipOpening"],
        "mouthWidth": geo["mouthWidth"],
        "jawOpen": bs.get("jawOpen", 0.0),
        "jawForward": bs.get("jawForward", 0.0),
        "jawLateral": bs.get("jawLeft", 0.0) - bs.get("jawRight", 0.0),
        "jawOpening": geo["jawOpening"],
        "cheekPuff": bs.get("cheekPuff", 0.0),
        "cheekSquint": _pair(bs, "cheekSquint"),
        "noseSneer": _pair(bs, "noseSneer"),
        "yaw": pose["yaw"],
        "pitch": pose["pitch"],
        "roll": pose["roll"],
        "headX": pose["x"],
        "headY": pose["y"],
        "headZ": pose["z"],
        "headSpeed": 0.0,
    }


def _rolling_median(x: np.ndarray, size: int) -> np.ndarray:
    """Centered rolling median that ignores NaN (missing-face frames)."""
    if size <= 1 or x.size == 0:
        return x.copy()
    half = size // 2
    padded = np.pad(x, half, mode="edge")
    windows = np.lib.stride_tricks.sliding_window_view(padded, size)[: x.size]
    with warnings.catch_warnings():
        # A window with no face at all is expected (child turned away); its median is NaN.
        warnings.simplefilter("ignore", RuntimeWarning)
        return np.nanmedian(windows, axis=1)


def derive_series(matrix: np.ndarray, times: np.ndarray, fps: float) -> np.ndarray:
    """Smooth, detrend posture features and fill headSpeed. NaN rows mean no face.

    ``matrix`` is frames × SCORED features, in SCORED order.
    """
    out = matrix.copy()
    smooth = max(1, SMOOTH_FRAMES)
    for j in range(out.shape[1]):
        out[:, j] = _rolling_median(out[:, j], smooth)

    # Head speed (deg/s) from the smoothed, not yet detrended, angles.
    idx = {n: i for i, n in enumerate(SCORED_NAMES)}
    angles = out[:, [idx["yaw"], idx["pitch"], idx["roll"]]]
    speed = np.full(len(times), np.nan)
    if len(times) > 1:
        dt = np.diff(times)
        dt[dt <= 0] = np.nan
        step = np.abs(np.diff(angles, axis=0)).max(axis=1) / dt
        speed[1:] = step
    out[:, idx["headSpeed"]] = speed

    detrend_frames = max(3, int(round(DETREND_SEC * fps)) | 1)
    for f in SCORED:
        if f.detrend:
            j = idx[f.name]
            out[:, j] = out[:, j] - _rolling_median(out[:, j], detrend_frames)
    return out
