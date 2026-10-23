"""Comparison baseline: MiMi's chunk-ratio severity, recomputed on our windows.

MiMi divides speech into word chunks; here the chunks are the same 3 s
windows the detector scores, so the two severities differ only in method.
"""
import numpy as np

from app.detection.base import LABELS, STUTTER_LABELS, DetectionOutput
from app.severity import config as cfg


def mimi_chunk_ratio(output: DetectionOutput, threshold: float) -> dict:
    cols = [LABELS.index(label) for label in STUTTER_LABELS]
    stuttered = int((output.probs[:, cols] >= threshold).any(axis=1).sum())
    total = len(output.windows)
    ratio = round(100.0 * stuttered / total, 2) if total else 0.0
    label = next(name for upper, name in cfg.MIMI_BANDS if ratio <= upper)
    return {"stutteredChunks": stuttered, "totalChunks": total, "ratioPercent": ratio, "label": label}
