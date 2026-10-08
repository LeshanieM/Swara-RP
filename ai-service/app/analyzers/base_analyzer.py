"""
Common interface every computer-vision analyzer implements.

Research-design rules encoded here (see project spec sections 7, 9, 12, 29):

  * A technology is a source of VISUAL FEATURES, not a stuttering detector.
    Analyzers must never claim to detect "secondary stuttering behaviors" -
    they detect and time-stamp *movement events* for a named behavior
    category. Whether a movement event corresponds to a clinically relevant
    secondary behavior is left to the researcher/SLP using ground truth.

  * Every analyzer reports a status for EVERY canonical behavior
    (section 7), using exactly one of:
        supported   - technology produced a usable signal, event detection ran
        unsupported - this technology does not provide a suitable signal
                       for this behavior (declared in `capability_map`)
        unavailable - technology could in principle support this behavior,
                       but can't run right now (missing dependency/model/binary)
        error       - it was expected to run and produce a result, but failed
    These must never be conflated (section 7).

  * Analyzers must not fabricate results. If a signal cannot be computed,
    report `unsupported` (not "supported, 0 events").
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple

from app.config.settings import BEHAVIORS


class BehaviorStatus(str, Enum):
    SUPPORTED = "supported"
    UNSUPPORTED = "unsupported"
    UNAVAILABLE = "unavailable"
    ERROR = "error"


class UnavailableReason(str, Enum):
    DEPENDENCY_NOT_INSTALLED = "dependency_not_installed"
    MODEL_UNAVAILABLE = "model_unavailable"
    EXECUTABLE_NOT_FOUND = "executable_not_found"
    RUNTIME_ERROR = "runtime_error"
    UNSUPPORTED_PLATFORM = "unsupported_platform"


@dataclass
class BehaviorEvent:
    """One detected movement event for a single behavior."""

    start_time: float
    end_time: float
    duration: float
    peak_value: Optional[float] = None
    meta: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        d = {
            "start_time": round(self.start_time, 3),
            "end_time": round(self.end_time, 3),
            "duration": round(self.duration, 3),
        }
        if self.peak_value is not None:
            d["peak_value"] = round(self.peak_value, 4)
        if self.meta:
            d["meta"] = self.meta
        return d


@dataclass
class BehaviorResult:
    """Result for a single behavior, for a single technology."""

    status: str
    detected: bool = False
    frequency: int = 0
    total_duration: float = 0.0
    events: List[BehaviorEvent] = field(default_factory=list)
    reason: Optional[str] = None
    feature_summary: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        d = {
            "status": self.status,
            "detected": self.detected,
            "frequency": self.frequency,
            "total_duration": round(self.total_duration, 3),
            "events": [e.to_dict() for e in self.events],
        }
        if self.reason:
            d["reason"] = self.reason
        if self.feature_summary:
            d["feature_summary"] = self.feature_summary
        return d

    @staticmethod
    def unsupported(reason: Optional[str] = None) -> "BehaviorResult":
        return BehaviorResult(status=BehaviorStatus.UNSUPPORTED.value, reason=reason)

    @staticmethod
    def unavailable(reason: str) -> "BehaviorResult":
        return BehaviorResult(status=BehaviorStatus.UNAVAILABLE.value, reason=reason)

    @staticmethod
    def error(reason: str) -> "BehaviorResult":
        return BehaviorResult(status=BehaviorStatus.ERROR.value, reason=reason)

    @staticmethod
    def from_events(events: List[BehaviorEvent], fps: float = None) -> "BehaviorResult":
        total = sum(e.duration for e in events)
        return BehaviorResult(
            status=BehaviorStatus.SUPPORTED.value,
            detected=len(events) > 0,
            frequency=len(events),
            total_duration=total,
            events=events,
        )


class VisionAnalyzer(ABC):
    """
    Common interface every CV analyzer implements, per the project spec
    (section 8):

        class VisionAnalyzer:
            name: str
            def analyze(self, video_path): raise NotImplementedError

    Each concrete analyzer lives in its own module and can be added, removed
    or fail to load without affecting the others (section 12/30). The
    registry (registry.py) is the only place that imports all analyzers
    together, and it does so defensively.
    """

    name: str = "base"
    version: str = "unknown"

    # Declares, per behavior, whether this technology can in principle
    # produce a signal for it. This is a property of the TECHNOLOGY, not of
    # whether it currently runs - see `is_available()` for that. Analyzers
    # must not report `supported` for a behavior not marked True here.
    capability_map: Dict[str, bool] = {b: False for b in BEHAVIORS}

    def is_available(self) -> Tuple[bool, Optional[str]]:
        """
        Return (available, reason). `reason` should be one of
        UnavailableReason when available is False. Cheap check only (import
        probing / executable lookup) - must not do heavy model loading.
        """
        return True, None

    @abstractmethod
    def analyze(
        self,
        video_path: str,
        generate_overlay: bool = False,
        preprocessing_notes: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """
        Run the full pipeline (visual features -> temporal features ->
        behavior-event detection) on `video_path` and return a dict matching
        the standardized result schema (see app/api/vision_routes.py /
        section 9 of the spec). Must not raise for a single unsupported
        behavior - only for a hard failure of the whole technology, which
        the caller (registry / job runner) converts into a per-technology
        `error` status without stopping the rest of the experiment.
        """
        raise NotImplementedError

    # -- shared helpers -----------------------------------------------------

    def empty_behaviors(self) -> Dict[str, BehaviorResult]:
        """Every behavior defaulted to `unsupported` for technologies that
        don't declare support for it; subclasses overwrite the supported
        ones with real results."""
        out = {}
        for b in BEHAVIORS:
            if self.capability_map.get(b):
                out[b] = BehaviorResult.unsupported()  # overwritten by analyze() if it runs
            else:
                out[b] = BehaviorResult.unsupported(reason="technology_does_not_provide_this_feature")
        return out

    def unavailable_result(self, video_meta: Dict[str, Any], reason: str) -> Dict[str, Any]:
        """Whole-technology unavailable result (section 12)."""
        behaviors = {}
        for b in BEHAVIORS:
            if self.capability_map.get(b):
                behaviors[b] = BehaviorResult.unavailable(reason=reason).to_dict()
            else:
                behaviors[b] = BehaviorResult.unsupported(
                    reason="technology_does_not_provide_this_feature"
                ).to_dict()
        return {
            "technology": self.name,
            "technology_version": self.version,
            "status": "unavailable",
            "reason": reason,
            "processing_time": 0.0,
            "video": video_meta,
            "behaviors": behaviors,
            "tracking": {},
        }

    def error_result(self, video_meta: Dict[str, Any], reason: str, processing_time: float = 0.0) -> Dict[str, Any]:
        behaviors = {}
        for b in BEHAVIORS:
            if self.capability_map.get(b):
                behaviors[b] = BehaviorResult.error(reason=reason).to_dict()
            else:
                behaviors[b] = BehaviorResult.unsupported(
                    reason="technology_does_not_provide_this_feature"
                ).to_dict()
        return {
            "technology": self.name,
            "technology_version": self.version,
            "status": "error",
            "error": reason,
            "processing_time": round(processing_time, 3),
            "video": video_meta,
            "behaviors": behaviors,
            "tracking": {},
        }

    def build_result(
        self,
        status: str,
        processing_time: float,
        video_meta: Dict[str, Any],
        behaviors: Dict[str, "BehaviorResult"],
        tracking: Dict[str, Any],
        preprocessing_notes: Optional[List[str]] = None,
        thresholds_used: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        result = {
            "technology": self.name,
            "technology_version": self.version,
            "status": status,
            "processing_time": round(processing_time, 3) if processing_time is not None else None,
            "video": video_meta,
            "behaviors": {
                k: (v.to_dict() if isinstance(v, BehaviorResult) else v) for k, v in behaviors.items()
            },
            "tracking": tracking,
        }
        if preprocessing_notes:
            result["preprocessing_notes"] = preprocessing_notes
        if thresholds_used:
            result["thresholds_used"] = thresholds_used
        return result
