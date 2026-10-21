"""Fixed-length, baseline-normalised sequences for the learned detectors.

Shared by inference (``learned.py``) and training (``training/``), so both see
exactly the same input: the moment's z-scores (clipped, missing face → 0)
plus a face-present channel, resampled to ``seq_len`` frames.
"""
import warnings

import numpy as np

from app.features import catalog

SEQ_LEN = 32
N_INPUT = len(catalog.SCORED_NAMES) + 1  # + face-present channel
Z_SCALE = 10.0  # z is clipped to ±10 upstream; scale to ±1 for the network


def moment_sequence(z: np.ndarray, face: np.ndarray, span: np.ndarray, seq_len: int = SEQ_LEN) -> np.ndarray:
    if span.size == 0:
        return np.zeros((seq_len, N_INPUT), dtype=np.float32)
    feats = np.nan_to_num(z[span], nan=0.0) / Z_SCALE
    present = face[span].astype(np.float32)[:, None]
    seq = np.concatenate([feats, present], axis=1)
    pick = np.linspace(0, len(span) - 1, seq_len).round().astype(int)
    return seq[pick].astype(np.float32)


def raw_sequence(series: np.ndarray, face: np.ndarray, span: np.ndarray, seq_len: int = SEQ_LEN) -> np.ndarray:
    """The same moment without the speaker-relative step: the raw feature values (NaN where no face),
    for the "GRU without self-comparison" ablation. Training standardises them with population statistics."""
    if span.size == 0:
        return np.full((seq_len, N_INPUT), np.nan, dtype=np.float32)
    seq = np.concatenate([series[span], face[span].astype(np.float32)[:, None]], axis=1)
    pick = np.linspace(0, len(span) - 1, seq_len).round().astype(int)
    return seq[pick].astype(np.float32)


WINDOW_SEC = 2.0
WINDOW_STATS = ("mean", "sd", "range", "meanAbsDiff")


def window_names() -> list[str]:
    return [f"{f}.{s}" for f in catalog.SCORED_NAMES for s in WINDOW_STATS] + ["faceRatio"]


def window_stats(series: np.ndarray, times: np.ndarray, face: np.ndarray, centre: float, width: float = WINDOW_SEC) -> np.ndarray:
    """Summary statistics of each raw feature over a fixed window around the moment (the earlier prototype's
    Random Forest input, 2-s windows). NaN where the window has no face."""
    idx = np.flatnonzero(np.abs(times - centre) <= width / 2)
    n = len(catalog.SCORED_NAMES)
    if idx.size == 0:
        return np.full(n * len(WINDOW_STATS) + 1, np.nan, dtype=np.float32)
    x = series[idx]
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", RuntimeWarning)  # all-NaN columns (no face) stay NaN
        stats = np.stack([
            np.nanmean(x, axis=0),
            np.nanstd(x, axis=0),
            np.nanmax(x, axis=0) - np.nanmin(x, axis=0),
            np.nanmean(np.abs(np.diff(x, axis=0)), axis=0) if len(idx) > 1 else np.full(n, np.nan),
        ], axis=1).reshape(-1)
    return np.append(stats, face[idx].mean()).astype(np.float32)
