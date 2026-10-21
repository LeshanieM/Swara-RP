"""Stutter-locked, speaker-relative deviation (the SRCD score) with a fluent-speech null.

1. **Held deviation.** For each feature and each k-frame window (k = minimum
   behaviour duration), the level the feature holds through the window (window
   min upwards, window max downwards) is turned into SDs from the child's fluent
   baseline. A single jittery frame or an ordinary blink cannot create a behaviour.
2. **Span score.** A feature's score for a moment is its largest held deviation
   over the windows inside the (padded) moment.
3. **Null from the child's own fluent speech.** The same score is computed for
   every equally long fluent stretch (``NullModel``). A feature deviates only if
   fluent stretches rarely score as high (p ≤ alpha / features in the category)
   and it is at least ``min_sd`` SDs. Movements the child also makes when fluent
   (nods, lip rounding) don't count however large they are in SD, and testing
   many features and windows doesn't inflate false positives.

A signal (eye, lip, jaw, cheek, head) reports its most significant feature.
"""
from dataclasses import dataclass, field

import numpy as np

from app.features import catalog
from app.srcd.baseline import Baseline, held

Z_CLIP = 10.0  # frame-level z fed to the learned detectors
SCORE_CLIP = 50.0  # held deviation used for scoring; high so strong movements don't tie with the null's maximum
SIGNAL_COLS = {s: [j for j, f in enumerate(catalog.SCORED) if f.signal == s] for s in catalog.SIGNALS}


@dataclass
class SignalScore:
    deviation: float  # SDs from this child's fluent baseline, held for k frames
    direction: str  # "above" | "below"
    top_feature: str
    window: int | None  # absolute start frame of the strongest window
    threshold: float  # the bar this moment had to clear (SD)
    p_value: float | None  # share of equally long fluent stretches scoring at least as high
    null_spans: int  # how many fluent stretches formed the null
    present: bool = False
    run: tuple[int, int] | None = None  # absolute frame range where the top feature stays deviant


@dataclass
class MomentScore:
    index: int
    start: float
    end: float
    span: np.ndarray  # absolute frame indices examined
    face_ratio: float
    assessed: bool
    signals: dict[str, SignalScore] = field(default_factory=dict)
    types: list[str] = field(default_factory=list)  # C1 event types inside the moment, if known


@dataclass
class Deviation:
    z: np.ndarray  # frame-level z, clipped (NaN where no face); input to the learned detectors
    effective: np.ndarray  # per window start × feature: held |z| (0 where the window has no face)
    sign: np.ndarray  # +1 above, -1 below
    k: int


def normalise(series: np.ndarray, base: Baseline, k: int) -> Deviation:
    z = np.clip((series - base.centre) / base.spread, -Z_CLIP, Z_CLIP)
    hi, lo = held(series, k)
    z_hi = np.clip(np.nan_to_num((hi - base.centre) / base.spread, nan=0.0), 0, SCORE_CLIP)
    z_lo = np.clip(np.nan_to_num((base.centre - lo) / base.spread, nan=0.0), 0, SCORE_CLIP)
    effective = np.maximum(z_hi, z_lo)
    sign = np.where(z_hi >= z_lo, 1, -1)
    return Deviation(z, effective, sign, k)


FEATURES_PER_CATEGORY = {c: sum(1 for f in catalog.SCORED if catalog.CATEGORY_OF_SIGNAL[f.signal] == c) for c in catalog.CATEGORIES}
TAIL_FROM = 0.8  # the exponential tail is fitted above this quantile of the fluent span scores
# The tail scale is shrunk towards a generic prior (settings.tail_prior_sd per e-fold, worth
# PRIOR_N excesses), weighted by how many *independent* fluent stretches the recording holds.
# Short recordings therefore lean on the prior instead of extrapolating from a few stretches.
PRIOR_N = 5.0
MIN_TAIL_SCALE = 0.25  # SD; stops a near-constant feature from giving vanishing p-values


@dataclass
class _FeatureNull:
    scores: np.ndarray  # sorted span scores over the child's fluent stretches
    u0: float  # tail start (TAIL_FROM quantile)
    beta: float  # exponential tail scale (mean excess over u0)

    def p(self, x: float) -> float:
        """P(a fluent stretch scores ≥ x): empirical up to u0, exponential tail beyond it."""
        if x <= self.u0:
            return float((self.scores.size - np.searchsorted(self.scores, x, side="left")) / self.scores.size)
        return float((1 - TAIL_FROM) * np.exp(-(x - self.u0) / self.beta))

    def x_at(self, p: float) -> float:
        """Smallest score with exceedance probability ≤ p (inverse of ``p``)."""
        if p >= 1 - TAIL_FROM:
            return float(np.quantile(self.scores, 1 - p))
        return float(self.u0 + self.beta * np.log((1 - TAIL_FROM) / p))


class NullModel:
    """How far this child moves in ordinary fluent speech, per feature and span length.

    For every fluent stretch as long as the moment, each feature's span score
    (its largest held deviation) forms that feature's null. Overlapping
    stretches from ~30 s of speech hold only a few dozen independent samples,
    so the null's upper tail is modelled as exponential above its 80th
    percentile, with its scale shrunk towards a generic prior when there is
    little fluent speech; the p-value of an observed score is the modelled share of
    fluent stretches scoring at least as high. A feature deviates when
    p ≤ alpha / (features in its category) (Bonferroni, so each category's
    false-positive rate on fluent speech stays ≤ alpha) and its deviation is
    at least ``min_sd``. Sparse, heavy-tailed features (lip puckering) get a
    wide null of their own and cannot raise the bar for other features.
    """

    def __init__(self, dev: Deviation, base: Baseline, alpha: float, min_sd: float, min_spans: int, prior_beta: float):
        self.dev, self.base, self.alpha, self.min_sd, self.min_spans = dev, base, alpha, min_sd, min_spans
        self.prior_beta = prior_beta
        self._cache: dict[tuple[int, int], _FeatureNull | None] = {}

    def level(self, signal: str) -> float:
        return self.alpha / FEATURES_PER_CATEGORY[catalog.CATEGORY_OF_SIGNAL[signal]]

    def _null(self, j: int, n_windows: int) -> _FeatureNull | None:
        key = (j, n_windows)
        if key not in self._cache:
            ok = self.base.fluent_windows
            null = None
            if n_windows <= len(ok):
                spans_ok = np.lib.stride_tricks.sliding_window_view(ok, n_windows).all(axis=1)
                if spans_ok.sum() >= self.min_spans:
                    scores = np.sort(np.lib.stride_tricks.sliding_window_view(self.dev.effective[:, j], n_windows).max(axis=1)[spans_ok])
                    u0 = float(np.quantile(scores, TAIL_FROM))
                    excess = scores[scores > u0] - u0
                    beta_hat = float(excess.mean()) if excess.size else 0.0
                    # Overlapping stretches: about one independent stretch per n_windows windows.
                    independent_excesses = (1 - TAIL_FROM) * scores.size / n_windows
                    beta = (independent_excesses * beta_hat + PRIOR_N * self.prior_beta) / (independent_excesses + PRIOR_N)
                    null = _FeatureNull(scores, u0, max(MIN_TAIL_SCALE, beta))
            self._cache[key] = null
        return self._cache[key]

    def test(self, signal: str, n_windows: int, feature_scores: np.ndarray) -> tuple[int, float | None, float, int]:
        """Return (top feature position, p-value, SD bar for that feature, null size) for one moment."""
        cols = SIGNAL_COLS[signal]
        nulls = [self._null(j, n_windows) for j in cols]
        if any(n is None for n in nulls):  # too little fluent speech: fixed SD bar only
            return int(feature_scores.argmax()), None, self.min_sd, 0
        ps = np.array([n.p(float(x)) if x >= self.min_sd else 1.0 for n, x in zip(nulls, feature_scores)])
        top = int(np.lexsort((-feature_scores, ps))[0])  # smallest p, ties broken by larger SD
        bar = max(self.min_sd, nulls[top].x_at(self.level(signal)))
        return top, max(1e-4, round(float(ps[top]), 4)), round(bar, 2), int(nulls[top].scores.size)

    def decide(self, signal: str, observed: float, p_value: float | None) -> bool:
        if observed < self.min_sd:
            return False
        return True if p_value is None else p_value <= self.level(signal)


def score_moment(index: int, start: float, end: float, times: np.ndarray, face: np.ndarray, dev: Deviation,
                 null: NullModel, pad: float, min_face_ratio: float) -> MomentScore:
    span = np.flatnonzero((times >= start - pad) & (times <= end + pad))
    face_ratio = float(face[span].mean()) if span.size else 0.0
    m = MomentScore(index, start, end, span, round(face_ratio, 3), assessed=span.size > 0 and face_ratio >= min_face_ratio)
    if not m.assessed:
        return m

    k = dev.k
    last_start = max(span[0], span[-1] - k + 1)
    starts = np.arange(span[0], last_start + 1)
    for signal, cols in SIGNAL_COLS.items():
        block = dev.effective[np.ix_(starts, cols)]  # windows × features
        feature_scores = block.max(axis=0)
        c, p_value, thr, n_null = null.test(signal, starts.size, feature_scores)
        j = cols[c]
        w = int(block[:, c].argmax())
        observed = float(feature_scores[c])
        s = SignalScore(
            deviation=round(observed, 2),
            direction="below" if dev.sign[starts[w], j] < 0 else "above",
            top_feature=catalog.SCORED[j].name,
            window=int(starts[w]),
            threshold=round(thr, 2),
            p_value=p_value,
            null_spans=n_null,
        )
        s.present = null.decide(signal, observed, s.p_value)
        if s.present:
            # Frames covered by consecutive windows where the top feature stays above the bar.
            col = dev.effective[:, j]
            bar = min(thr, observed)
            lo = hi = s.window
            while lo - 1 >= starts[0] and col[lo - 1] >= bar:
                lo -= 1
            while hi + 1 <= starts[-1] and col[hi + 1] >= bar:
                hi += 1
            s.run = (lo, min(hi + k - 1, len(times) - 1))
        m.signals[signal] = s
    return m


def explanation(signal: str, s: SignalScore) -> str:
    """e.g. 'jaw +4.1 SD above this child's normal (chin drop); seen in 1% of fluent stretches'."""
    label = catalog.FEATURE_BY_NAME[s.top_feature].label
    sign = "-" if s.direction == "below" else "+"
    text = f"{signal} {sign}{s.deviation:.1f} SD {s.direction} this child's normal ({label})"
    if s.p_value is None:
        return text
    # The tail model extrapolates; don't claim more precision than ~30 s of fluent speech supports.
    if s.p_value >= 0.2:
        return text + "; within this child's usual fluent range"
    if s.p_value >= 0.001:
        return text + f"; about 1 in {round(1 / s.p_value):,} fluent stretches move this much"
    return text + "; rarer than 1 in 1,000 fluent stretches"
