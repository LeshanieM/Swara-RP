"""Detector interface: decide FG / HM for each stutter moment.

Every detector receives the same context (frames, baseline-normalised z, the
SRCD moment scores) so they can be swapped and compared on identical input.
"""
from dataclasses import dataclass

import numpy as np

from app.srcd.deviation import MomentScore


@dataclass
class Context:
    times: np.ndarray
    face: np.ndarray
    raw: np.ndarray  # frames × scored features, smoothed, not normalised (NaN = no face)
    z: np.ndarray  # frames × scored features, baseline-normalised
    fps: float
    moments: list[MomentScore]
    threshold: float  # SRCD deviation threshold (SD)


@dataclass
class CategoryDecision:
    present: bool
    score: float
    score_type: str  # "deviation_sd" | "rule" | "probability"


class Detector:
    name = "base"
    version = "0"

    def available(self) -> tuple[bool, str | None]:
        return True, None

    def thresholds(self) -> dict:
        return {}

    def predict(self, ctx: Context) -> list[dict[str, CategoryDecision] | None]:
        """One entry per moment: {"FG": decision, "HM": decision}, or None if the moment was not assessed."""
        raise NotImplementedError
