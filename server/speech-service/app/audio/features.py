"""Frame-level analysis shared by the detectors and the pipeline.

Frames are 25 ms long with a 10 ms hop. Everything here is deterministic
signal processing; nothing is learned.
"""
from dataclasses import dataclass, field

import librosa
import numpy as np
from scipy.signal import find_peaks

N_FFT = 400  # 25 ms at 16 kHz
HOP = 160  # 10 ms at 16 kHz
N_MFCC = 13

# Activity detection.
MIN_GAP_FILL_SEC = 0.06  # gaps shorter than this inside speech are closed
MIN_ACTIVE_SEC = 0.04  # active bursts shorter than this are dropped
PAUSE_MIN_SEC = 0.25  # silent gaps at least this long count as pauses

# Syllable nuclei (intensity peaks, after de Jong & Wempe 2009).
NUCLEUS_PROMINENCE_DB = 2.5
NUCLEUS_MIN_DISTANCE_SEC = 0.08
NUCLEUS_MIN_LEVEL_BELOW_PEAK_DB = 25.0


@dataclass
class FrameAnalysis:
    sample_rate: int
    hop_sec: float
    n_frames: int
    duration_sec: float
    level_db: np.ndarray  # smoothed frame level, dB relative to the loudest frame
    threshold_db: float
    active: np.ndarray  # bool per frame: speech activity
    segments: list[tuple[int, int]]  # active segments as [start, end) frame indices
    mfcc: np.ndarray  # (N_MFCC - 1, n_frames), c0 dropped, mean-normalised
    change: np.ndarray  # cosine distance between consecutive MFCC frames
    nuclei: np.ndarray  # frame indices of syllable nuclei
    chunks: list[tuple[int, int]] = field(default_factory=list)  # syllable-sized chunks

    def t(self, frame: int) -> float:
        return frame * self.hop_sec

    def frame(self, seconds: float) -> int:
        return int(round(seconds / self.hop_sec))


def runs(mask: np.ndarray) -> list[tuple[int, int]]:
    """[start, end) index pairs of True runs."""
    padded = np.concatenate([[False], mask, [False]]).astype(int)
    diff = np.diff(padded)
    return list(zip(np.flatnonzero(diff == 1), np.flatnonzero(diff == -1)))


def _activity(level_db: np.ndarray, hop_sec: float) -> tuple[np.ndarray, float]:
    noise, peak = np.percentile(level_db, [5, 95])
    threshold = float(np.clip(noise + 0.25 * (peak - noise), peak - 40.0, peak - 20.0))
    active = level_db > threshold
    # Close short gaps, then drop short bursts.
    for start, end in runs(~active):
        if start > 0 and end < len(active) and (end - start) * hop_sec < MIN_GAP_FILL_SEC:
            active[start:end] = True
    for start, end in runs(active):
        if (end - start) * hop_sec < MIN_ACTIVE_SEC:
            active[start:end] = False
    return active, float(threshold)


def _nuclei(level_db: np.ndarray, active: np.ndarray, hop_sec: float) -> np.ndarray:
    peaks, _ = find_peaks(
        level_db,
        prominence=NUCLEUS_PROMINENCE_DB,
        distance=max(1, int(NUCLEUS_MIN_DISTANCE_SEC / hop_sec)),
    )
    floor = level_db.max() - NUCLEUS_MIN_LEVEL_BELOW_PEAK_DB
    return np.array([p for p in peaks if active[p] and level_db[p] > floor], dtype=int)


def _chunks(nuclei: np.ndarray, level_db: np.ndarray, segments: list[tuple[int, int]]) -> list[tuple[int, int]]:
    """Split each active segment at the level minima between its nuclei."""
    chunks: list[tuple[int, int]] = []
    for seg_start, seg_end in segments:
        inside = [n for n in nuclei if seg_start <= n < seg_end]
        if not inside:
            continue
        bounds = [seg_start]
        for a, b in zip(inside, inside[1:]):
            bounds.append(a + int(np.argmin(level_db[a:b])))
        bounds.append(seg_end)
        chunks.extend(zip(bounds, bounds[1:]))
    return chunks


def analyse_frames(signal: np.ndarray, sr: int) -> FrameAnalysis:
    hop_sec = HOP / sr
    rms = librosa.feature.rms(y=signal, frame_length=N_FFT, hop_length=HOP)[0]
    level_db = librosa.amplitude_to_db(rms, ref=np.max, top_db=80.0)
    level_db = np.convolve(level_db, np.ones(3) / 3, mode="same")
    active, threshold = _activity(level_db, hop_sec)

    mfcc = librosa.feature.mfcc(y=signal, sr=sr, n_mfcc=N_MFCC, n_fft=N_FFT, hop_length=HOP, n_mels=40)[1:]
    mfcc = mfcc[:, : len(level_db)]
    if active.any():
        mfcc = mfcc - mfcc[:, active].mean(axis=1, keepdims=True)
    norms = np.linalg.norm(mfcc, axis=0) + 1e-8
    cos = np.sum(mfcc[:, 1:] * mfcc[:, :-1], axis=0) / (norms[1:] * norms[:-1])
    change = np.concatenate([[0.0], 1.0 - cos])

    segments = runs(active)
    nuclei = _nuclei(level_db, active, hop_sec)
    return FrameAnalysis(
        sample_rate=sr,
        hop_sec=hop_sec,
        n_frames=len(level_db),
        duration_sec=len(signal) / sr,
        level_db=level_db,
        threshold_db=threshold,
        active=active,
        segments=segments,
        mfcc=mfcc,
        change=change,
        nuclei=nuclei,
        chunks=_chunks(nuclei, level_db, segments),
    )


def pauses(fa: FrameAnalysis) -> list[tuple[float, float]]:
    """Silent gaps between active segments that are long enough to be pauses."""
    gaps = []
    for (_, a_end), (b_start, _) in zip(fa.segments, fa.segments[1:]):
        if (b_start - a_end) * fa.hop_sec >= PAUSE_MIN_SEC:
            gaps.append((fa.t(a_end), fa.t(b_start)))
    return gaps


def speech_features(fa: FrameAnalysis, syllables: int) -> dict:
    gaps = pauses(fa)
    durations = [end - start for start, end in gaps]
    speech_sec = float(fa.active.sum() * fa.hop_sec)
    return {
        "duration": round(fa.duration_sec, 3),
        "speechDuration": round(speech_sec, 3),
        "pauseCount": len(gaps),
        "averagePauseDuration": round(float(np.mean(durations)), 3) if durations else 0.0,
        "longestPause": round(float(max(durations)), 3) if durations else 0.0,
        "speechRate": round(syllables / fa.duration_sec, 3) if fa.duration_sec else 0.0,
        "articulationRate": round(syllables / speech_sec, 3) if speech_sec else 0.0,
        "estimatedSyllables": int(len(fa.nuclei)),
    }
