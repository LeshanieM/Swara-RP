"""
Registry of all CV analyzers (section 8/12).

Building this list is defensive on purpose: importing one analyzer module
must never prevent the others from being registered, even if that
analyzer's own optional third-party library is missing at *import* time
(most guard their heavy imports inside `analyze()`/`is_available()`, but we
don't rely on that discipline here - a broken analyzer module is treated
exactly like an unavailable technology, not a reason to fail startup).
"""

import logging
from typing import Dict, List

from app.analyzers.base_analyzer import UnavailableReason, VisionAnalyzer
from app.config.settings import TECHNOLOGIES

logger = logging.getLogger("swara.vision.registry")

_KEY_TO_IMPORT = {
    "mediapipe": ("app.analyzers.mediapipe_analyzer", "MediaPipeAnalyzer"),
    "openface": ("app.analyzers.openface_analyzer", "OpenFaceAnalyzer"),
    "openseeface": ("app.analyzers.openseeface_analyzer", "OpenSeeFaceAnalyzer"),
    "3ddfa_v2": ("app.analyzers.dddfa_analyzer", "DDFAv2Analyzer"),
    "mmpose": ("app.analyzers.mmpose_analyzer", "MMPoseAnalyzer"),
}


class _BrokenAnalyzer(VisionAnalyzer):
    """Stand-in used when an analyzer module itself fails to import (e.g. a
    syntax error, or a required *top-level* import that isn't guarded). It
    reports `unavailable` for every behavior instead of taking down the
    whole registry, consistent with section 12/30."""

    def __init__(self, key: str, reason: str):
        self.name = key
        self._reason = reason

    def is_available(self):
        return False, UnavailableReason.RUNTIME_ERROR.value

    def analyze(self, video_path, generate_overlay=False, preprocessing_notes=None):
        return self.unavailable_result({}, self._reason)


def get_all_analyzers() -> Dict[str, VisionAnalyzer]:
    """Returns {technology_key: analyzer_instance} for every technology
    listed in settings.TECHNOLOGIES, in that order."""
    analyzers: Dict[str, VisionAnalyzer] = {}
    for key in TECHNOLOGIES:
        module_name, class_name = _KEY_TO_IMPORT[key]
        try:
            module = __import__(module_name, fromlist=[class_name])
            cls = getattr(module, class_name)
            analyzers[key] = cls()
        except Exception as exc:  # noqa: BLE001 - intentionally broad, see docstring
            logger.warning("Analyzer %s failed to load: %s", key, exc)
            analyzers[key] = _BrokenAnalyzer(key, f"runtime_error: analyzer module failed to load: {exc}")
    return analyzers


def get_analyzers_for(selection: List[str]) -> Dict[str, VisionAnalyzer]:
    """`selection` is either ["all"] or a subset of TECHNOLOGIES keys (as
    validated by the API layer)."""
    all_analyzers = get_all_analyzers()
    if not selection or selection == ["all"]:
        return all_analyzers
    return {k: v for k, v in all_analyzers.items() if k in selection}
