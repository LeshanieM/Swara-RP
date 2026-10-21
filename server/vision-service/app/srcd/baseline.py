"""The speaker's own movement baseline, built from their fluent speech.

Fluent frames = face visible and at least ``guard`` seconds away from every
stutter moment. From them the baseline keeps, per scored feature, a robust
centre (median) and spread (the larger of MAD × 1.4826 and the inter-decile
range / 2.563, floored per feature), which turn
values into "SDs from this child's normal". It also marks the fluent windows,
which ``deviation.NullModel`` uses as the null ("how far does this child move
in ordinary fluent speech?").

No labels are needed, which is what lets SRCD run on unlabelled children.
"""
from dataclasses import dataclass

import numpy as np

from app.features import catalog

MAD_TO_SD = 1.4826
IDR_TO_SD = 2.5631  # (p90 − p10) of a normal distribution in SDs
MIN_FRAMES = 5


@dataclass
class Baseline:
    centre: np.ndarray
    spread: np.ndarray
    fluent_windows: np.ndarray  # bool per window start: the k-frame window is entirely fluent
    source: str  # "fluent_spans" | "whole_recording"
    frames: int
    duration_sec: float


def held(series: np.ndarray, k: int) -> tuple[np.ndarray, np.ndarray]:
    """For the window starting at each frame (k frames long), the level held throughout it.

    held_hi = window minimum (how high it stays), held_lo = window maximum (how low it stays).
    Windows that run past the end or contain a missing face are NaN.
    """
    n, f = series.shape
    hi = np.full((n, f), np.nan)
    lo = np.full((n, f), np.nan)
    if n >= k:
        win = np.lib.stride_tricks.sliding_window_view(series, k, axis=0)  # (n-k+1, f, k)
        hi[: n - k + 1] = win.min(axis=2)  # NaN propagates: a window with a missing face stays NaN
        lo[: n - k + 1] = win.max(axis=2)
    return hi, lo


def fluent_mask(times: np.ndarray, face: np.ndarray, moments: list[tuple[float, float]], guard: float) -> np.ndarray:
    mask = face.copy()
    for start, end in moments:
        mask &= ~((times >= start - guard) & (times <= end + guard))
    return mask


def build(series: np.ndarray, times: np.ndarray, face: np.ndarray, moments: list[tuple[float, float]],
          fps: float, guard: float, min_sec: float, k: int) -> tuple[Baseline, list[dict]]:
    warnings = []
    usable = face & ~np.isnan(series).any(axis=1)
    mask = fluent_mask(times, usable, moments, guard)
    source = "fluent_spans"
    if mask.sum() / fps < min_sec:
        warnings.append({
            "code": "insufficient_fluent_baseline",
            "message": f"Only {mask.sum() / fps:.1f} s of fluent, face-visible video (need {min_sec:g} s); "
                       "the baseline uses the whole recording, which makes deviations harder to detect.",
        })
        mask = usable
        source = "whole_recording"
    if mask.sum() < MIN_FRAMES:
        mask = usable
    rows = series[mask]
    floors = np.array([f.floor for f in catalog.SCORED])
    centre = np.nanmedian(rows, axis=0)
    # Both estimates equal σ for Gaussian data. The inter-decile one keeps sparse features
    # (near 0 most of the time, e.g. lip puckering) from getting a collapsed MAD, which
    # would make an ordinary pucker look like a 17 SD event.
    mad = np.nanmedian(np.abs(rows - centre), axis=0) * MAD_TO_SD
    p10, p90 = np.nanpercentile(rows, [10, 90], axis=0)
    spread = np.maximum.reduce([mad, (p90 - p10) / IDR_TO_SD, floors])

    windows = np.zeros(len(times), dtype=bool)
    if len(times) >= k:
        windows[: len(times) - k + 1] = np.lib.stride_tricks.sliding_window_view(mask, k).all(axis=1)
    return Baseline(centre, spread, windows, source, int(mask.sum()), round(mask.sum() / fps, 2)), warnings
