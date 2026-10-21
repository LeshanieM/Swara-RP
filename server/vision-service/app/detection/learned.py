"""Learned SRCD detector (GRU or transformer), loaded lazily from a checkpoint.

Checkpoint (written by training/train_srcd.py, read with torch.load):
    {"arch": "gru" | "transformer", "version": str, "features": [scored feature names],
     "seq_len": int, "n_input": int, "model_kwargs": {...}, "state_dict": {...},
     "thresholds": {"FG": float, "HM": float}, "assessed": {"FG": bool, "HM": bool}, "audio_dim": 0, "training": {...}}
The detector refuses a checkpoint whose feature list differs from the
service's, because the inputs would silently mean something else. A class the
checkpoint marks as not assessed (it failed the validation precision bar in
training) is decided by the label-free SRCD test instead, and the response says so.
"""
import logging
from pathlib import Path

import numpy as np

from app.detection.base import CategoryDecision, Context, Detector
from app.detection.sequences import moment_sequence
from app.features import catalog

log = logging.getLogger("c2.learned")


class LearnedSRCD(Detector):
    def __init__(self, arch: str, path: Path):
        self.arch = arch
        self.name = arch
        self.path = path
        self.version = f"{arch}-unloaded"
        self._model = None
        self._ckpt = None
        self._error: str | None = None

    def _load(self):
        if self._model is not None or self._error:
            return
        try:
            import torch

            from app.detection import nets
        except ImportError:
            self._error = "dependency_not_installed: torch"
            return
        if not self.path.is_file():
            self._error = f"model_not_found: {self.path.name}"
            return
        try:
            ckpt = torch.load(self.path, map_location="cpu", weights_only=False)
            if ckpt.get("arch") != self.arch:
                self._error = f"model_arch_mismatch: file is {ckpt.get('arch')!r}, detector is {self.arch!r}"
                return
            if list(ckpt.get("features", [])) != list(catalog.SCORED_NAMES):
                self._error = "feature_mismatch: checkpoint was trained on a different feature list"
                return
            model = nets.build(ckpt["arch"], ckpt["n_input"], ckpt["seq_len"], **ckpt.get("model_kwargs", {}))
            model.load_state_dict(ckpt["state_dict"])
            model.eval()
            self._model, self._ckpt = model, ckpt
            self.version = ckpt.get("version", f"{self.arch}-unknown")
            log.info("loaded %s (%s)", self.path.name, self.version)
        except Exception as exc:  # a broken file must not stop the service
            self._error = f"model_load_failed: {type(exc).__name__}: {exc}"

    def available(self):
        self._load()
        return (self._model is not None), self._error

    def thresholds(self) -> dict:
        self._load()
        return dict(self._ckpt.get("thresholds", {})) if self._ckpt else {}

    def info(self) -> dict:
        self._load()
        if not self._ckpt:
            return {}
        return {"training": self._ckpt.get("training", {}), "audioDim": self._ckpt.get("audio_dim", 0),
                "assessed": self.assessed()}

    def assessed(self) -> dict:
        """Classes the model decides; False = label-free SRCD decides that class (older checkpoints: all True)."""
        self._load()
        flags = (self._ckpt or {}).get("assessed") or {}
        return {c: bool(flags.get(c, True)) for c in catalog.CATEGORIES}

    def predict(self, ctx: Context):
        import torch

        self._load()
        seq_len = self._ckpt["seq_len"]
        thr = self._ckpt.get("thresholds", {"FG": 0.5, "HM": 0.5})
        assessed = [m for m in ctx.moments if m.assessed]
        probs = {}
        if assessed:
            batch = np.stack([moment_sequence(ctx.z, ctx.face, m.span, seq_len) for m in assessed])
            with torch.no_grad():
                p = torch.sigmoid(self._model(torch.from_numpy(batch))).numpy()
            probs = {m.index: p[i] for i, m in enumerate(assessed)}
        ok = self.assessed()
        fallback = None
        if not all(ok.values()):
            from app.detection.registry import get  # label-free SRCD for the classes the model is not trusted on

            fallback = get("srcd").predict(ctx)
        out = []
        for k, m in enumerate(ctx.moments):
            if not m.assessed:
                out.append(None)
                continue
            fg, hm = (float(v) for v in probs[m.index])
            dec = {
                "FG": CategoryDecision(fg >= thr.get("FG", 0.5), round(fg, 3), "probability"),
                "HM": CategoryDecision(hm >= thr.get("HM", 0.5), round(hm, 3), "probability"),
            }
            for c in dec:
                if not ok[c]:
                    dec[c] = fallback[k][c]
            out.append(dec)
        return out
