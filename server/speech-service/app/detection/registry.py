"""Detector selection with graceful fallback to the acoustic detector."""
from app.detection.acoustic import AcousticDetector
from app.detection.base import Detector
from app.detection.xlsr import XlsrDetector

DEFAULT = "acoustic"
_DETECTORS: dict[str, Detector] = {"acoustic": AcousticDetector(), "xlsr": XlsrDetector()}


def names() -> list[str]:
    return list(_DETECTORS)


def status() -> dict:
    return {name: {"name": d.name, "version": d.version, **d.availability()} for name, d in _DETECTORS.items()}


def resolve(requested: str) -> tuple[Detector, dict]:
    """Return the detector to use and how it was chosen."""
    info = {"requested": requested, "fallback": False, "fallbackReason": None}
    detector = _DETECTORS.get(requested)
    if detector is None:
        info.update(fallback=True, fallbackReason=f"unknown_detector:{requested}")
        return _DETECTORS[DEFAULT], info
    availability = detector.availability()
    if availability["status"] != "available":
        info.update(fallback=True, fallbackReason=availability.get("reason", "unavailable"))
        return _DETECTORS[DEFAULT], info
    return detector, info
