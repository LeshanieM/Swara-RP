"""XLS-R detector: frozen multilingual encoder + a small trained head.

Loaded lazily and only when ``C1_DETECTOR=xlsr``. It needs the optional
packages (torch, transformers, joblib, scikit-learn) and a head file at
``<C1_MODEL_DIR>/c1_head.joblib`` holding a dict:

    {"layer": int,                 # encoder layer to pool
     "model": estimator,           # predict_proba(X) -> list of (n, 2) arrays, one per label
     "labels": [...],              # label order used by ``model``; must be a permutation of LABELS
     "version": str}

Each 3 s window is mean-pooled over that layer's frames and scored by the head.
"""
import importlib.util
import threading

import numpy as np

from app.audio.features import FrameAnalysis
from app.config import get_settings
from app.detection.base import LABELS, DetectionOutput, Detector
from app.detection.windows import make_windows

HEAD_FILE = "c1_head.joblib"
ENCODER_FPS = 50.0  # wav2vec2-family frame rate (20 ms)


class XlsrDetector(Detector):
    name = "xlsr-head"
    version = "0.1.0"

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._loaded: tuple | None = None

    def availability(self) -> dict:
        missing = [m for m in ("torch", "transformers", "joblib", "sklearn") if importlib.util.find_spec(m) is None]
        if missing:
            return {"status": "unavailable", "reason": "dependency_not_installed", "missing": missing}
        head = get_settings().model_dir / HEAD_FILE
        if not head.exists():
            return {"status": "unavailable", "reason": "model_unavailable", "expected": str(head)}
        return {"status": "available"}

    def _load(self) -> tuple:
        with self._lock:
            if self._loaded is None:
                import joblib
                import torch
                from transformers import AutoFeatureExtractor, AutoModel

                settings = get_settings()
                head = joblib.load(settings.model_dir / HEAD_FILE)
                extractor = AutoFeatureExtractor.from_pretrained(settings.xlsr_model_name)
                encoder = AutoModel.from_pretrained(settings.xlsr_model_name).eval()
                self._loaded = (torch, extractor, encoder, head)
            return self._loaded

    def detect(self, signal: np.ndarray, sr: int, frames: FrameAnalysis) -> DetectionOutput:
        torch, extractor, encoder, head = self._load()
        settings = get_settings()
        inputs = extractor(signal, sampling_rate=sr, return_tensors="pt")
        with torch.inference_mode():
            hidden = encoder(**inputs, output_hidden_states=True).hidden_states[head["layer"]][0].numpy()

        windows = make_windows(frames.duration_sec, settings.window_sec, settings.hop_sec)
        pooled = np.stack(
            [hidden[int(s * ENCODER_FPS) : max(int(s * ENCODER_FPS) + 1, int(e * ENCODER_FPS))].mean(axis=0) for s, e in windows]
        )
        per_label = head["model"].predict_proba(pooled)
        probs = np.zeros((len(windows), len(LABELS)))
        for i, label in enumerate(head["labels"]):
            probs[:, LABELS.index(label)] = per_label[i][:, 1]
        return DetectionOutput(windows=windows, probs=probs, candidates=[])
