"""B0-style acoustic detector: hand-written signal rules, no training.

It exists so C1 runs end to end on real audio before a trained model is
available, and it is the handcrafted baseline row of the comparison. Every
threshold below is PROVISIONAL: it was set on spliced TTS clips and must be
re-tuned on labelled child recordings.

Cues:
- repetition: adjacent syllable-sized units that are near-identical (DTW over
  MFCCs). One short unit -> sound repetition; a longer or multi-syllable unit
  -> word repetition.
- prolongation: a run of active frames whose spectrum hardly changes.
- block: a silent gap where the speech before it is cut off abruptly (no
  natural decay), i.e. the airflow stops mid-sound.
- interjection: a short, isolated, fricative/plosive-free unit ("um", "uh")
  bounded by pauses.
"""
from dataclasses import dataclass

import librosa
import numpy as np

from app.audio.features import FrameAnalysis, runs
from app.config import get_settings
from app.detection.base import Candidate, DetectionOutput, Detector
from app.detection.windows import candidates_to_probs, make_windows


@dataclass(frozen=True)
class AcousticThresholds:
    # Repetition
    rep_similarity: float = 0.8  # 1 - normalised DTW cosine cost
    # Fluent speech has adjacent look-alike syllables ("lit-tle"); a single
    # repeat with no break between the units must be much closer to count.
    rep_single_contiguous_similarity: float = 0.92
    rep_max_unit_chunks: int = 3
    rep_max_gap_sec: float = 0.5
    rep_min_duration_ratio: float = 0.5
    sound_rep_max_unit_sec: float = 0.25
    # Prolongation
    prolong_max_change: float = 0.035  # smoothed cosine distance between frames
    prolong_min_sec: float = 0.45
    # Block
    block_min_gap_sec: float = 0.25
    block_max_gap_sec: float = 3.0
    block_abrupt_db: float = -3.0  # drop at offset >= this -> fully abrupt
    block_gradual_db: float = -12.0  # drop at offset <= this -> natural decay
    # Interjection
    interj_min_sec: float = 0.15
    interj_max_sec: float = 0.9
    interj_min_pause_sec: float = 0.2
    interj_max_hf_ratio: float = 0.1  # 95th pct share of energy above 2.5 kHz
    hf_cutoff_hz: float = 2500.0


T = AcousticThresholds()


def _ramp(x: float, lo: float, hi: float) -> float:
    return float(np.clip((x - lo) / (hi - lo), 0.0, 1.0))


def _mostly_inside(c: Candidate, others: list[Candidate]) -> bool:
    overlap = sum(max(0.0, min(c.end, o.end) - max(c.start, o.start)) for o in others)
    return overlap >= 0.5 * (c.end - c.start)


class AcousticDetector(Detector):
    name = "acoustic-b0"
    version = "0.1.0-provisional"

    def availability(self) -> dict:
        return {"status": "available"}

    def detect(self, signal: np.ndarray, sr: int, frames: FrameAnalysis) -> DetectionOutput:
        settings = get_settings()
        # A held sound has a slight energy ripple that can split it into
        # look-alike "syllables"; repetitions mostly inside a prolongation are dropped.
        prolongations = self._prolongations(frames)
        repetitions = [r for r in self._repetitions(frames) if not _mostly_inside(r, prolongations)]
        candidates = repetitions + prolongations + self._blocks(frames)
        candidates += self._interjections(signal, frames, candidates)
        candidates.sort(key=lambda c: c.start)
        windows = make_windows(frames.duration_sec, settings.window_sec, settings.hop_sec)
        return DetectionOutput(windows=windows, probs=candidates_to_probs(candidates, windows), candidates=candidates)

    # -- repetitions -------------------------------------------------------
    @staticmethod
    def _similarity(fa: FrameAnalysis, a: tuple[int, int], b: tuple[int, int]) -> float:
        x, y = fa.mfcc[:, a[0] : a[1]], fa.mfcc[:, b[0] : b[1]]
        if x.shape[1] < 2 or y.shape[1] < 2:
            return 0.0
        cost, path = librosa.sequence.dtw(X=x, Y=y, metric="cosine")
        return float(1.0 - cost[-1, -1] / len(path))

    def _repetitions(self, fa: FrameAnalysis) -> list[Candidate]:
        """One pass per unit size, smallest first, so "park park" is matched as
        single-chunk units before any longer unit can swallow its neighbours."""
        chunks, used, out = fa.chunks, set(), []
        for k in range(1, T.rep_max_unit_chunks + 1):
            i = 0
            while i + 2 * k <= len(chunks):
                units, sims, j = [], [], i
                while j + 2 * k <= len(chunks) and not used & set(range(j, j + 2 * k)):
                    u1 = (chunks[j][0], chunks[j + k - 1][1])
                    u2 = (chunks[j + k][0], chunks[j + 2 * k - 1][1])
                    d1, d2 = u1[1] - u1[0], u2[1] - u2[0]
                    if (u2[0] - u1[1]) * fa.hop_sec > T.rep_max_gap_sec:
                        break
                    if min(d1, d2) / max(d1, d2) < T.rep_min_duration_ratio:
                        break
                    sim = self._similarity(fa, u1, u2)
                    if sim < T.rep_similarity:
                        break
                    units = units or [u1]
                    units.append(u2)
                    sims.append(sim)
                    j += k
                if not units:
                    i += 1
                    continue
                mean_sim = float(np.mean(sims))
                contiguous = bool(fa.active[units[0][0] : units[-1][1]].all())
                if len(units) == 2 and contiguous and mean_sim < T.rep_single_contiguous_similarity:
                    i += 1
                    continue
                used.update(range(i, i + k * len(units)))
                unit_sec = float(np.mean([(u[1] - u[0]) * fa.hop_sec for u in units]))
                label = "sound_repetition" if k == 1 and unit_sec < T.sound_rep_max_unit_sec else "word_repetition"
                out.append(
                    Candidate(
                        label=label,
                        start=fa.t(units[0][0]),
                        end=fa.t(units[-1][1]),
                        score=round(0.5 + 0.5 * _ramp(mean_sim, T.rep_similarity, 1.0), 3),
                        detail={"units": len(units), "unitSec": round(unit_sec, 3), "similarity": round(mean_sim, 3)},
                    )
                )
                i += k * len(units)
        return sorted(out, key=lambda c: c.start)

    # -- prolongations -----------------------------------------------------
    def _prolongations(self, fa: FrameAnalysis) -> list[Candidate]:
        smooth = np.convolve(fa.change, np.ones(5) / 5, mode="same")
        stable = (smooth < T.prolong_max_change) & fa.active
        out = []
        for a, b in runs(stable):
            dur = (b - a) * fa.hop_sec
            start, end = fa.t(a), fa.t(b)
            if dur < T.prolong_min_sec:
                continue
            out.append(
                Candidate(
                    label="prolongation",
                    start=start,
                    end=end,
                    score=round(0.55 + 0.4 * _ramp(dur, T.prolong_min_sec, 1.2), 3),
                    detail={"meanChange": round(float(smooth[a:b].mean()), 4)},
                )
            )
        return out

    # -- blocks ------------------------------------------------------------
    def _blocks(self, fa: FrameAnalysis) -> list[Candidate]:
        level, out = fa.level_db, []
        edge, ctx = 3, int(0.3 / fa.hop_sec)  # 30 ms edge vs 300 ms context
        for (a0, a1), (b0, b1) in zip(fa.segments, fa.segments[1:]):
            gap = (b0 - a1) * fa.hop_sec
            if not T.block_min_gap_sec <= gap <= T.block_max_gap_sec:
                continue
            off_drop = level[a1 - edge : a1].max() - level[max(a0, a1 - ctx) : a1].max()
            on_drop = level[b0 : b0 + edge].max() - level[b0 : min(b1, b0 + ctx)].max()
            abrupt_off = _ramp(off_drop, T.block_gradual_db, T.block_abrupt_db)
            abrupt_on = _ramp(on_drop, T.block_gradual_db, T.block_abrupt_db)
            score = abrupt_off * (0.7 + 0.3 * abrupt_on) * min(1.0, gap / 0.5)
            if score <= 0:
                continue
            out.append(
                Candidate(
                    label="block",
                    start=fa.t(a1),
                    end=fa.t(b0),
                    score=round(score, 3),
                    detail={"offsetDropDb": round(float(off_drop), 1), "onsetDropDb": round(float(on_drop), 1)},
                )
            )
        return out

    # -- interjections -----------------------------------------------------
    def _interjections(self, signal: np.ndarray, fa: FrameAnalysis, taken: list[Candidate]) -> list[Candidate]:
        power = np.abs(librosa.stft(signal, n_fft=400, hop_length=160)) ** 2
        freqs = librosa.fft_frequencies(sr=fa.sample_rate, n_fft=400)
        hf_ratio = power[freqs >= T.hf_cutoff_hz].sum(axis=0) / (power.sum(axis=0) + 1e-12)
        segs, out = fa.segments, []
        for idx, (a, b) in enumerate(segs):
            dur = (b - a) * fa.hop_sec
            before = (a - segs[idx - 1][1]) * fa.hop_sec if idx > 0 else np.inf
            after = (segs[idx + 1][0] - b) * fa.hop_sec if idx + 1 < len(segs) else np.inf
            nuclei = sum(a <= n < b for n in fa.nuclei)
            start, end = fa.t(a), fa.t(b)
            if not (T.interj_min_sec <= dur <= T.interj_max_sec and nuclei <= 2):
                continue
            if min(before, after) < T.interj_min_pause_sec:
                continue
            if any(c.start < end and start < c.end and c.label != "block" for c in taken):
                continue
            hf = float(np.percentile(hf_ratio[a:b], 95))
            if hf >= T.interj_max_hf_ratio:
                continue
            out.append(
                Candidate(
                    label="interjection",
                    start=start,
                    end=end,
                    score=round(0.55 + 0.4 * (1.0 - hf / T.interj_max_hf_ratio), 3),
                    detail={"hfRatio": round(hf, 3)},
                )
            )
        return out
