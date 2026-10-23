"""Trained detector: a small head on XLS-R embeddings and/or acoustic features (MFCC, pitch, energy).

Loaded lazily and only when ``C1_DETECTOR=xlsr``. The head file ``<C1_MODEL_DIR>/c1_head.joblib`` is written by
``notebooks/c1_03_train.ipynb`` and holds a dict:

    {"inputs": ["xlsr", "acoustic"],   # which features the head reads, in this order (default ["xlsr"])
     "layer": int,                     # XLS-R layer to pool (when "xlsr" is an input)
     "encoder": str,                   # Hugging Face model id the head was trained on (optional; else C1_XLSR_MODEL_NAME)
     "model": estimator,               # predict_proba(X) -> list of (n, 2) arrays per label, or an (n, labels) array
     "labels": [...],                  # label order used by ``model``; a permutation of (a subset of) LABELS
     "thresholds": {label: p},         # optional per-label decision thresholds tuned on the dev split
     "version": str}

Each 3 s window is mean-pooled over that layer's frames and/or described by ``audio.prosody.window_features``.
Per-label thresholds are applied by moving each probability so that its threshold lands on the pipeline's
common window threshold (``C1_WINDOW_THRESHOLD``), so events are built the same way for every detector.
Only torch and transformers are needed when the head reads XLS-R features.
"""
import importlib.util
import threading

import numpy as np

from app.audio.features import FrameAnalysis
from app.audio.prosody import windows_features
from app.config import get_settings
from app.detection.base import LABELS, DetectionOutput, Detector
from app.detection.windows import make_windows

HEAD_FILE = "c1_head.joblib"
ENCODER_FPS = 50.0  # wav2vec2-family frame rate (20 ms)


def _logit(p):
    p = np.clip(p, 1e-6, 1 - 1e-6)
    return np.log(p / (1 - p))


def shift_to_threshold(p: np.ndarray, threshold: float, target: float) -> np.ndarray:
    """Monotone rescaling that maps ``threshold`` onto ``target`` (decisions unchanged, just re-centred)."""
    return 1 / (1 + np.exp(-(_logit(p) - _logit(threshold) + _logit(target))))


class XlsrDetector(Detector):
    name = "xlsr-head"
    version = "0.2.0"

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._loaded: tuple | None = None

    def _head_path(self):
        return get_settings().model_dir / HEAD_FILE

    def availability(self) -> dict:
        missing = [m for m in ("joblib", "sklearn") if importlib.util.find_spec(m) is None]
        if missing:
            return {"status": "unavailable", "reason": "dependency_not_installed", "missing": missing}
        head_path = self._head_path()
        if not head_path.exists():
            return {"status": "unavailable", "reason": "model_unavailable", "expected": str(head_path)}
        try:
            import joblib
            inputs = joblib.load(head_path).get("inputs", ["xlsr"])
        except Exception as exc:  # a corrupt file is reported, not raised
            return {"status": "unavailable", "reason": "model_load_failed", "error": str(exc)}
        if "xlsr" in inputs:
            missing = [m for m in ("torch", "transformers") if importlib.util.find_spec(m) is None]
            if missing:
                return {"status": "unavailable", "reason": "dependency_not_installed", "missing": missing}
        return {"status": "available", "inputs": inputs}

    def _load(self) -> tuple:
        with self._lock:
            if self._loaded is None:
                import joblib

                settings = get_settings()
                head = joblib.load(self._head_path())
                encoder = None
                if "xlsr" in head.get("inputs", ["xlsr"]):
                    import torch
                    from transformers import AutoFeatureExtractor, AutoModel

                    name = head.get("encoder") or settings.xlsr_model_name
                    encoder = (torch, AutoFeatureExtractor.from_pretrained(name), AutoModel.from_pretrained(name).eval())
                self._loaded = (head, encoder)
                self.version = f"0.2.0+{head.get('version', 'head')}"
            return self._loaded

    def detect(self, signal: np.ndarray, sr: int, frames: FrameAnalysis) -> DetectionOutput:
        head, encoder = self._load()
        settings = get_settings()
        windows = make_windows(frames.duration_sec, settings.window_sec, settings.hop_sec)
        parts = []
        for source in head.get("inputs", ["xlsr"]):
            if source == "xlsr":
                torch, extractor, model = encoder
                inputs = extractor(signal, sampling_rate=sr, return_tensors="pt")
                with torch.inference_mode():
                    hidden = model(**inputs, output_hidden_states=True).hidden_states[head["layer"]][0].numpy()
                parts.append(np.stack([
                    hidden[int(s * ENCODER_FPS): max(int(s * ENCODER_FPS) + 1, int(e * ENCODER_FPS))].mean(axis=0)
                    for s, e in windows
                ]))
            elif source == "acoustic":
                parts.append(windows_features(signal, sr, windows))
            else:
                raise ValueError(f"unknown head input {source!r}")
        X = np.concatenate(parts, axis=1)

        raw = head["model"].predict_proba(X)
        per_label = np.stack([p[:, 1] for p in raw], axis=1) if isinstance(raw, list) else np.asarray(raw)
        thresholds = head.get("thresholds") or {}
        probs = np.zeros((len(windows), len(LABELS)))
        for i, label in enumerate(head["labels"]):
            p = per_label[:, i]
            if label in thresholds:
                p = shift_to_threshold(p, thresholds[label], settings.window_threshold)
            probs[:, LABELS.index(label)] = p
        return DetectionOutput(windows=windows, probs=probs, candidates=[])
