"""Acoustic features of one 3-second window, for the trained C1 head (the plan's MFCC / pitch / energy input).

Training (``training/``) and the detector (``detection/xlsr.py``) both call ``window_features``, so a model always
sees the same numbers it was trained on. Each feature targets a stuttering cue:

- MFCC means / spreads and their frame-to-frame change: what is said and how fast it changes.
- Energy: level, its spread, the share of near-silence and the longest silent run (blocks: silent, tense stops).
- Pitch (YIN, 60–500 Hz): voiced share, level and spread in semitones, and the longest stretch of steady voiced
  pitch (prolongations hold one sound).
- Spectral flux and zero-crossing rate: abruptness of sound onsets.
- Self-similarity: the best match between MFCC frames 0.15–0.6 s apart (sound and word repetitions repeat a
  short pattern).
"""
import numpy as np
import librosa

N_FFT = 400  # 25 ms at 16 kHz
HOP = 160  # 10 ms
N_MFCC = 13
F0_MIN, F0_MAX = 60.0, 500.0
SILENCE_BELOW_DB = 30.0  # frames this far below the window's loudest count as near-silence
STEADY_SEMITONES = 0.3  # pitch change per frame below this counts as steady
REPEAT_LAGS_SEC = (0.15, 0.6)

MFCC_NAMES = [f"mfcc{i}" for i in range(1, N_MFCC)]
FEATURES = (
    [f"{n}.mean" for n in MFCC_NAMES] + [f"{n}.sd" for n in MFCC_NAMES] + [f"{n}.delta" for n in MFCC_NAMES]
    + ["energy.mean", "energy.sd", "energy.range", "silence.share", "silence.longestSec"]
    + ["voiced.share", "f0.median", "f0.sd", "f0.range", "steadyPitch.longestSec"]
    + ["flux.mean", "flux.sd", "zcr.mean", "selfSimilarity.max", "selfSimilarity.lagSec"]
)


def _longest_run(mask: np.ndarray) -> int:
    best = run = 0
    for v in mask:
        run = run + 1 if v else 0
        best = max(best, run)
    return best


def window_features(signal: np.ndarray, sr: int) -> np.ndarray:
    """Feature vector (len(FEATURES),) for one window. Silent or very short windows give finite values, not NaN."""
    hop_sec = HOP / sr
    if len(signal) < N_FFT * 2 or not np.any(signal):
        return np.zeros(len(FEATURES), dtype=np.float32)

    mfcc = librosa.feature.mfcc(y=signal, sr=sr, n_mfcc=N_MFCC, n_fft=N_FFT, hop_length=HOP, n_mels=40)[1:]
    delta = np.abs(np.diff(mfcc, axis=1)).mean(axis=1) if mfcc.shape[1] > 1 else np.zeros(N_MFCC - 1)

    rms = librosa.feature.rms(y=signal, frame_length=N_FFT, hop_length=HOP)[0]
    db = librosa.amplitude_to_db(rms, ref=np.max, top_db=80.0)
    silent = db < -SILENCE_BELOW_DB
    energy = [db.mean(), db.std(), np.percentile(db, 90) - np.percentile(db, 10), silent.mean(), _longest_run(silent) * hop_sec]

    f0 = librosa.yin(signal, fmin=F0_MIN, fmax=F0_MAX, sr=sr, frame_length=1024, hop_length=HOP)
    n = min(len(f0), len(db))
    voiced = (~silent[:n]) & np.isfinite(f0[:n]) & (f0[:n] > F0_MIN * 1.05) & (f0[:n] < F0_MAX * 0.95)
    if voiced.sum() >= 3:
        semis = 12 * np.log2(f0[:n][voiced] / 100.0)
        steady = np.zeros(n, dtype=bool)
        st = 12 * np.log2(np.clip(f0[:n], 1e-3, None) / 100.0)
        steady[1:] = voiced[1:] & voiced[:-1] & (np.abs(np.diff(st)) < STEADY_SEMITONES)
        pitch = [voiced.mean(), np.median(semis), semis.std(), np.percentile(semis, 95) - np.percentile(semis, 5),
                 _longest_run(steady) * hop_sec]
    else:
        pitch = [voiced.mean(), 0.0, 0.0, 0.0, 0.0]

    spec = np.abs(librosa.stft(signal, n_fft=N_FFT, hop_length=HOP))
    flux = np.sqrt((np.diff(spec, axis=1).clip(min=0) ** 2).sum(axis=0)) if spec.shape[1] > 1 else np.zeros(1)
    flux = flux / (flux.max() + 1e-9)
    zcr = librosa.feature.zero_crossing_rate(signal, frame_length=N_FFT, hop_length=HOP)[0]

    # Self-similarity of loud frames at short lags: repetitions repeat a pattern.
    unit = mfcc / (np.linalg.norm(mfcc, axis=0, keepdims=True) + 1e-8)
    loud = ~silent[: unit.shape[1]]
    best, best_lag = 0.0, 0.0
    for lag in range(int(REPEAT_LAGS_SEC[0] / hop_sec), int(REPEAT_LAGS_SEC[1] / hop_sec) + 1):
        if lag >= unit.shape[1] - 5:
            break
        both = loud[:-lag] & loud[lag:]
        if both.sum() < 5:
            continue
        sim = float((unit[:, :-lag] * unit[:, lag:]).sum(axis=0)[both].mean())
        if sim > best:
            best, best_lag = sim, lag * hop_sec

    out = np.concatenate([
        mfcc.mean(axis=1), mfcc.std(axis=1), delta, energy, pitch,
        [flux.mean(), flux.std(), zcr.mean(), best, best_lag],
    ]).astype(np.float32)
    return np.nan_to_num(out, nan=0.0, posinf=0.0, neginf=0.0)


def windows_features(signal: np.ndarray, sr: int, windows: list[tuple[float, float]]) -> np.ndarray:
    return np.stack([window_features(signal[int(s * sr): int(e * sr)], sr) for s, e in windows]) if windows \
        else np.zeros((0, len(FEATURES)), dtype=np.float32)
