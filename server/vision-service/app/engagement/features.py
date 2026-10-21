"""C3 engagement camera features: per-frame face samples → one window's summary numbers.

The phone computes the same numbers from Google ML Kit (mobile/lib/core/engagement/camera_features.dart);
training computes them from MediaPipe on DAiSEE clips. Both must follow this definition exactly, and
server/contracts/c3/engagement-camera-features.example.json checks that they do.

A sample is {"face": bool, "yaw": deg, "pitch": deg, "eyeOpen": 0–1 | None, "smile": 0–1 | None}.
Everything except facePresentRatio is computed over the frames with a face only; a window with no face
gets None for those, and the server treats it as missing data rather than disengagement.
"""
import math

WINDOW_SEC = 10.0  # DAiSEE clips are 10 s, so the phone summarises each 10 s of an activity
LOOK_AWAY_YAW_DEG = 25.0
LOOK_AWAY_PITCH_DEG = 20.0
EYES_CLOSED_BELOW = 0.3

FEATURES = (
    "facePresentRatio", "yawStdDeg", "pitchStdDeg", "yawAbsMeanDeg", "pitchAbsMeanDeg",
    "lookAwayRatio", "eyeOpenMean", "eyesClosedRatio", "smileMean",
)


def _mean(xs):
    return sum(xs) / len(xs) if xs else None


def _std(xs):
    # Population SD (ddof 0), as on the phone.
    m = _mean(xs)
    return math.sqrt(sum((x - m) ** 2 for x in xs) / len(xs)) if xs else None


def _share(flags):
    return sum(1 for f in flags if f) / len(flags) if flags else None


def window_features(samples: list[dict]) -> dict:
    faces = [s for s in samples if s.get("face")]
    yaw = [float(s["yaw"]) for s in faces]
    pitch = [float(s["pitch"]) for s in faces]
    eyes = [float(s["eyeOpen"]) for s in faces if s.get("eyeOpen") is not None]
    smiles = [float(s["smile"]) for s in faces if s.get("smile") is not None]
    return {
        "facePresentRatio": len(faces) / len(samples) if samples else 0.0,
        "yawStdDeg": _std(yaw),
        "pitchStdDeg": _std(pitch),
        "yawAbsMeanDeg": _mean([abs(v) for v in yaw]),
        "pitchAbsMeanDeg": _mean([abs(v) for v in pitch]),
        "lookAwayRatio": _share([abs(y) > LOOK_AWAY_YAW_DEG or abs(p) > LOOK_AWAY_PITCH_DEG for y, p in zip(yaw, pitch)]),
        "eyeOpenMean": _mean(eyes),
        "eyesClosedRatio": _share([e < EYES_CLOSED_BELOW for e in eyes]),
        "smileMean": _mean(smiles),
    }


def sample_from_mediapipe(raw: dict | None) -> dict:
    """One frame of landmarks.track(keep_raw=True) → a sample. MediaPipe has no eye-open or smile
    probability, so they come from the blendshapes: eye open = 1 − eyeBlink, smile = mouthSmile."""
    if raw is None:
        return {"face": False}
    bs, pose = raw["blendshapes"], raw["pose"]
    blink = [bs[k] for k in ("eyeBlinkLeft", "eyeBlinkRight") if k in bs]
    smile = [bs[k] for k in ("mouthSmileLeft", "mouthSmileRight") if k in bs]
    return {
        "face": True,
        "yaw": pose["yaw"],
        "pitch": pose["pitch"],
        "eyeOpen": 1.0 - sum(blink) / len(blink) if blink else None,
        "smile": sum(smile) / len(smile) if smile else None,
    }
