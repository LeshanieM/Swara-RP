"""Runtime loading and inference for the trained ordinary C2 GRU."""

from __future__ import annotations

import json
import logging
import math
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence

import numpy as np

logger = logging.getLogger("swara.c2")
SERVICE_ROOT = Path(__file__).resolve().parents[1]
MODEL_ROOT = SERVICE_ROOT / "models" / "c2_srcd_gru"
CHECKPOINT_PATH = MODEL_ROOT / "best_ordinary.pt"
NORMALIZATION_PATH = MODEL_ROOT / "norm_stats_ordinary.npz"
THRESHOLDS_PATH = MODEL_ROOT / "thresholds_ordinary.json"
BLENDSHAPE_NAMES_PATH = (
    SERVICE_ROOT / "data" / "casa" / "processed" / "features" / "blendshape_names.json"
)
FPS = 15
FRAME_MS = 1000.0 / FPS
WINDOW_FRAMES = 30
WINDOW_MS = 2000
STRIDE_MS = 500
FEATURE_DIM = 111
BASE_FEATURE_DIM = 56
FACE_PRESENT_INDEX = 55
FACE_THRESHOLD_COUNT = WINDOW_FRAMES // 2
INFERENCE_BATCH_SIZE = 64


def euler_pitch_yaw_roll(matrix: Any) -> np.ndarray:
    """Match the feature-extraction script's radians and Euler convention."""
    transform = np.asarray(matrix, dtype=np.float64)
    if transform.size != 16:
        raise ValueError(f"Expected a 4x4 facial transform, got shape {transform.shape}")
    rotation = transform.reshape(4, 4)[:3, :3]
    sy = math.sqrt(rotation[0, 0] ** 2 + rotation[1, 0] ** 2)
    if sy >= 1e-8:
        pitch = math.atan2(rotation[2, 1], rotation[2, 2])
        yaw = math.atan2(-rotation[2, 0], sy)
        roll = math.atan2(rotation[1, 0], rotation[0, 0])
    else:
        pitch = math.atan2(-rotation[1, 2], rotation[1, 1])
        yaw = math.atan2(-rotation[2, 0], sy)
        roll = 0.0
    return np.asarray([pitch, yaw, roll], dtype=np.float32)


@dataclass
class C2Runtime:
    model: Any
    mean: np.ndarray
    std: np.ndarray
    thresholds: dict[str, float]
    checkpoint_relpath: str = "models/c2_srcd_gru/best_ordinary.pt"

    def predict_proba(self, batch: np.ndarray) -> np.ndarray:
        import torch

        x = torch.from_numpy(np.ascontiguousarray(batch, dtype=np.float32))
        mask = torch.ones(x.shape[:2], dtype=torch.bool)
        with torch.no_grad():
            logits = self.model(x, mask)
            probs = torch.sigmoid(logits).cpu().numpy()
        return np.asarray(probs, dtype=np.float32)


def _load_runtime() -> tuple[C2Runtime | None, str | None, list[str]]:
    required = [CHECKPOINT_PATH, NORMALIZATION_PATH, THRESHOLDS_PATH, BLENDSHAPE_NAMES_PATH]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        return None, "model_unavailable: missing files: " + ", ".join(missing), []

    try:
        names = json.loads(BLENDSHAPE_NAMES_PATH.read_text(encoding="utf-8"))
        if not isinstance(names, list) or len(names) != 52 or not all(isinstance(x, str) for x in names):
            raise ValueError("blendshape_names.json must contain 52 canonical names")
    except Exception as exc:
        return None, f"model_unavailable: {exc}", []

    try:
        import torch
        from torch import nn
        torch.manual_seed(42)

        class OrdinaryC2GRU(nn.Module):
            def __init__(self) -> None:
                super().__init__()
                self.gru = nn.GRU(
                    input_size=FEATURE_DIM,
                    hidden_size=64,
                    num_layers=2,
                    batch_first=True,
                    bidirectional=True,
                    dropout=0.2,
                )
                self.dropout = nn.Dropout(0.2)
                self.head = nn.Linear(128, 2)

            def forward(self, x, mask):
                out, _ = self.gru(x)
                out = self.dropout(out)
                weights = mask.unsqueeze(-1).float()
                pooled = (out * weights).sum(1) / weights.sum(1).clamp(min=1e-6)
                return self.head(pooled)

        checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu", weights_only=True)
        if int(checkpoint.get("input_dim", -1)) != FEATURE_DIM:
            raise ValueError(f"Checkpoint input_dim must be {FEATURE_DIM}")
        model = OrdinaryC2GRU()
        model.load_state_dict(checkpoint["model_state_dict"])
        model.eval()

        with np.load(NORMALIZATION_PATH, allow_pickle=False) as stats:
            mean = np.asarray(stats["mean"], dtype=np.float32).copy()
            std = np.asarray(stats["std"], dtype=np.float32).copy()
        if mean.shape != (FEATURE_DIM,) or std.shape != (FEATURE_DIM,):
            raise ValueError(f"Normalization arrays must both have shape ({FEATURE_DIM},)")
        if not np.isfinite(mean).all() or not np.isfinite(std).all() or np.any(std <= 0):
            raise ValueError("Normalization arrays contain non-finite or non-positive values")
        # Training explicitly leaves the binary face-present channel unchanged.
        if mean[FACE_PRESENT_INDEX] != 0 or std[FACE_PRESENT_INDEX] != 1:
            raise ValueError("Saved normalization does not preserve face_present as expected")

        threshold_data = json.loads(THRESHOLDS_PATH.read_text(encoding="utf-8"))
        fg_threshold = threshold_data["FG"]["threshold_precision_0.5"]
        hm_threshold = threshold_data["HM"]["threshold_f1_max"]
        if fg_threshold is None or hm_threshold is None:
            raise ValueError("Expected saved FG constrained and HM F1-max thresholds")
        runtime = C2Runtime(
            model=model,
            mean=mean,
            std=std,
            thresholds={"FG": float(fg_threshold), "HM": float(hm_threshold)},
        )
        return runtime, None, names
    except ImportError as exc:
        return None, f"dependency_not_installed: {exc.name or 'torch'}", names
    except Exception as exc:  # Keep optional C2 inference from preventing API startup.
        return None, f"model_unavailable: {exc}", names


C2_RUNTIME, C2_UNAVAILABLE_REASON, BLENDSHAPE_NAMES = _load_runtime()
C2_AVAILABLE = C2_RUNTIME is not None
if not C2_AVAILABLE:
    logger.warning("C2 GRU inference unavailable: %s", C2_UNAVAILABLE_REASON)


def resample_to_15_fps(
    frame_features: np.ndarray, timestamps_ms: np.ndarray, face_present: np.ndarray,
    duration_ms: float,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Select the source frame nearest each 15-FPS annotation-time sample."""
    if not len(timestamps_ms) or duration_ms <= 0:
        return (np.empty((0, BASE_FEATURE_DIM), dtype=np.float32),
                np.empty((0,), dtype=np.int32), np.empty((0,), dtype=np.uint8))
    target_ms = np.arange(0.0, duration_ms, FRAME_MS, dtype=np.float64)
    source_ms = np.asarray(timestamps_ms, dtype=np.float64)
    indices = np.searchsorted(source_ms, target_ms, side="left")
    indices = np.clip(indices, 0, len(source_ms) - 1)
    previous = np.maximum(indices - 1, 0)
    choose_previous = np.abs(source_ms[previous] - target_ms) < np.abs(source_ms[indices] - target_ms)
    indices = np.where(choose_previous, previous, indices)
    return (
        np.asarray(frame_features[indices], dtype=np.float32),
        np.rint(target_ms).astype(np.int32),
        np.asarray(face_present[indices], dtype=np.uint8),
    )


def face_tracking_quality(face_present: np.ndarray) -> dict[str, Any]:
    rate = float(np.mean(face_present)) if len(face_present) else 0.0
    return {"low": rate < 0.5, "face_detection_rate": rate}


def status_for_tracking(face_present: np.ndarray) -> str | None:
    return "insufficient_face_tracking" if face_tracking_quality(face_present)["low"] else None


def _window_batch(
    base_frames: np.ndarray, timestamps_ms: np.ndarray, face_present: np.ndarray,
) -> tuple[np.ndarray, list[dict[str, int]]]:
    windows: list[np.ndarray] = []
    metadata: list[dict[str, int]] = []
    if len(timestamps_ms) == 0:
        return np.empty((0, WINDOW_FRAMES, FEATURE_DIM), dtype=np.float32), metadata
    end_ms = int(timestamps_ms[-1])
    for start_ms in range(0, end_ms + 1, STRIDE_MS):
        selected = np.flatnonzero(
            (timestamps_ms >= start_ms) & (timestamps_ms < start_ms + WINDOW_MS)
        )
        if len(selected) < WINDOW_FRAMES:
            continue
        if len(selected) > WINDOW_FRAMES:
            offset = (len(selected) - WINDOW_FRAMES) // 2
            selected = selected[offset:offset + WINDOW_FRAMES]
        if int(np.count_nonzero(face_present[selected])) < FACE_THRESHOLD_COUNT:
            continue

        base = np.nan_to_num(base_frames[selected], nan=0.0, posinf=0.0, neginf=0.0)
        face = np.clip(base[:, 55], 0.0, 1.0)
        # The training dataset computes temporal differences within each
        # 30-frame window, so inference follows the same boundary convention.
        velocity = np.diff(
            base[:, :55], axis=0, prepend=np.zeros((1, 55), dtype=np.float32)
        )
        frames = np.concatenate([base[:, :55], face[:, None], velocity], axis=1).astype(np.float32)
        if frames.shape != (WINDOW_FRAMES, FEATURE_DIM):
            raise AssertionError(f"Expected (30, 111), got {frames.shape}")
        windows.append(frames)
        metadata.append({"start_ms": int(start_ms), "end_ms": int(start_ms + WINDOW_MS)})
    if not windows:
        return np.empty((0, WINDOW_FRAMES, FEATURE_DIM), dtype=np.float32), metadata
    return np.stack(windows).astype(np.float32), metadata


def _merge_fg_events(
    probabilities: Sequence[float], metadata: Sequence[dict[str, int]], threshold: float,
) -> list[dict[str, Any]]:
    active: list[tuple[float, dict[str, int]]] = []
    events: list[dict[str, Any]] = []

    def flush() -> None:
        if len(active) >= 2:
            probs = [p for p, _ in active]
            events.append({
                "start_ms": active[0][1]["start_ms"],
                "end_ms": max(item[1]["end_ms"] for item in active),
                "mean_probability": float(np.mean(probs)),
                "n_windows": len(active),
            })
        active.clear()

    for probability, window in zip(probabilities, metadata):
        if probability >= threshold:
            if active and window["start_ms"] != active[-1][1]["start_ms"] + STRIDE_MS:
                flush()
            active.append((float(probability), window))
        else:
            flush()
    flush()
    return events


def predict_c2(
    base_frames: np.ndarray,
    timestamps_ms: np.ndarray,
    face_present: np.ndarray,
    runtime: C2Runtime | Any | None = None,
) -> dict[str, Any]:
    """Run window inference and return the additive C2 result block."""
    runtime = runtime or C2_RUNTIME
    if runtime is None:
        raise RuntimeError(C2_UNAVAILABLE_REASON or "C2 runtime is unavailable")
    batch, metadata = _window_batch(base_frames, timestamps_ms, face_present)
    started = time.perf_counter()
    probabilities: list[np.ndarray] = []
    for offset in range(0, len(batch), INFERENCE_BATCH_SIZE):
        normalized = (batch[offset:offset + INFERENCE_BATCH_SIZE] - runtime.mean) / runtime.std
        normalized[..., FACE_PRESENT_INDEX] = np.clip(
            normalized[..., FACE_PRESENT_INDEX], 0.0, 1.0
        )
        probabilities.append(runtime.predict_proba(normalized.astype(np.float32)))
    inference_ms = max(0.001, (time.perf_counter() - started) * 1000.0)
    probs = np.concatenate(probabilities, axis=0) if probabilities else np.empty((0, 2), dtype=np.float32)
    if probs.shape != (len(metadata), 2):
        raise ValueError(f"Expected model probabilities {(len(metadata), 2)}, got {probs.shape}")

    fg = probs[:, 0] if len(probs) else np.empty((0,), dtype=np.float32)
    hm = probs[:, 1] if len(probs) else np.empty((0,), dtype=np.float32)
    fg_threshold = float(runtime.thresholds["FG"])
    fg_events = _merge_fg_events(fg, metadata, fg_threshold)
    n_positive = int(np.count_nonzero(fg >= fg_threshold))
    return {
        "status": "assessed",
        "model": "srcd_gru_ordinary",
        "checkpoint": "models/c2_srcd_gru/best_ordinary.pt",
        "assessment_status": {"FG": "assessed", "HM": "not_assessed"},
        "thresholds": {"FG": fg_threshold, "HM": None},
        "behaviours": {
            "FG": {
                "n_windows": len(metadata),
                "n_positive_windows": n_positive,
                "positive_rate": float(n_positive / len(metadata)) if metadata else 0.0,
                "max_probability": float(np.max(fg)) if len(fg) else None,
                "mean_probability": float(np.mean(fg)) if len(fg) else None,
                "events": fg_events,
            },
            "HM": {
                "probability": float(np.mean(hm)) if len(hm) else None,
                "detected": None,
                "reason": "not_assessed: no threshold achieves precision >= 0.5 on validation",
                "events": [],
            },
        },
        "hasSecondaryBehaviors": None,
        "inference_ms": inference_ms,
    }
