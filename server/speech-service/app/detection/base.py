"""Detector interface shared by every C1 detector."""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field

import numpy as np

from app.audio.features import FrameAnalysis

LABELS = ("block", "prolongation", "sound_repetition", "word_repetition", "interjection")
# Interjections are reported but are not stuttering-like disfluencies.
STUTTER_LABELS = ("block", "prolongation", "sound_repetition", "word_repetition")


@dataclass
class Candidate:
    """A fine-grained segment proposed by a detector (seconds)."""

    label: str
    start: float
    end: float
    score: float
    detail: dict = field(default_factory=dict)


@dataclass
class DetectionOutput:
    windows: list[tuple[float, float]]
    probs: np.ndarray  # (n_windows, len(LABELS))
    candidates: list[Candidate] = field(default_factory=list)


class Detector(ABC):
    name: str
    version: str

    @abstractmethod
    def availability(self) -> dict:
        """{"status": "available"} or {"status": "unavailable", "reason": ...}."""

    @abstractmethod
    def detect(self, signal: np.ndarray, sr: int, frames: FrameAnalysis) -> DetectionOutput: ...
