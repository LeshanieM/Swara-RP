"""The interface every ASR engine implements."""
from abc import ABC, abstractmethod

import numpy as np


class EngineUnavailable(RuntimeError):
    """The engine can't be used (dependency missing, model not downloadable, disabled)."""


class AsrEngine(ABC):
    name: str
    # Whether the engine keeps disfluent repetitions (CTC) or tends to delete them (Whisper).
    repetition_preserving: bool

    def __init__(self, model_id: str, device: str):
        self.model_id = model_id
        self.device = device

    @abstractmethod
    def transcribe(self, signal: np.ndarray, sample_rate: int) -> dict:
        """Returns {"text": str, "words": [{"word", "start", "end", "confidence"}], "wordTimings": "ctc" | "word" | "segment"}."""

    def info(self) -> dict:
        return {"name": self.name, "model": self.model_id, "repetitionPreserving": self.repetition_preserving}
