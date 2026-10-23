"""Detector selection with fallback: a broken or missing learned model never
stops the service; the label-free SRCD detector is used and the response says so."""
from functools import lru_cache

from app.config import get_settings
from app.detection.learned import LearnedSRCD
from app.detection.rules import RulesDetector
from app.detection.srcd import LabelFreeSRCD

NAMES = ("srcd", "rules", "gru", "transformer")


@lru_cache
def _detectors() -> dict:
    s = get_settings()
    return {
        "srcd": LabelFreeSRCD(s.null_alpha, s.deviation_threshold, s.min_deviation_sec),
        "rules": RulesDetector(),
        "gru": LearnedSRCD("gru", s.learned_model_path),
        "transformer": LearnedSRCD("transformer", s.learned_model_path),
    }


def get(name: str):
    return _detectors()[name]


def resolve() -> tuple[object, dict]:
    """Return (detector, info) for the configured detector, falling back to srcd."""
    requested = get_settings().detector
    if requested not in NAMES:
        return get("srcd"), {"requested": requested, "fallback": True, "fallbackReason": f"unknown_detector: {requested}"}
    det = get(requested)
    ok, reason = det.available()
    if ok:
        return det, {"requested": requested, "fallback": False, "fallbackReason": None}
    return get("srcd"), {"requested": requested, "fallback": True, "fallbackReason": reason}


def status() -> dict:
    out = {}
    for name in NAMES:
        ok, reason = get(name).available()
        out[name] = {"status": "available" if ok else "unavailable", "reason": reason, "version": get(name).version}
    return out
