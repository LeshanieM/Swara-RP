"""The fixed window grid every detector reports on."""
import numpy as np

from app.detection.base import LABELS, Candidate


def make_windows(duration: float, window_sec: float, hop_sec: float) -> list[tuple[float, float]]:
    if duration <= window_sec:
        return [(0.0, duration)]
    starts = list(np.arange(0.0, duration - window_sec + 1e-9, hop_sec))
    if starts[-1] + window_sec < duration - 1e-6:
        starts.append(duration - window_sec)  # last window ends exactly at the end
    return [(round(float(s), 3), round(float(s) + window_sec, 3)) for s in starts]


def candidates_to_probs(candidates: list[Candidate], windows: list[tuple[float, float]]) -> np.ndarray:
    """A window takes, per label, the best score of the candidates it mostly contains."""
    probs = np.zeros((len(windows), len(LABELS)), dtype=float)
    for c in candidates:
        col = LABELS.index(c.label)
        length = max(c.end - c.start, 1e-6)
        for i, (ws, we) in enumerate(windows):
            overlap = min(we, c.end) - max(ws, c.start)
            if overlap >= 0.5 * min(length, we - ws):
                probs[i, col] = max(probs[i, col], c.score)
    return probs
