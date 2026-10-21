"""Window scores -> events (start, end, type) -> stutter moments."""
from dataclasses import dataclass, field

import numpy as np

from app.audio.features import FrameAnalysis, runs
from app.detection.base import LABELS, STUTTER_LABELS, Candidate, DetectionOutput

CLUSTER_GAP_SEC = 0.25  # same-type candidates closer than this form one event
MOMENT_GAP_SEC = 0.1  # different-type events closer than this form one stutter moment


@dataclass
class Event:
    type: str
    start: float
    end: float
    confidence: float
    detail: dict = field(default_factory=dict)

    @property
    def duration(self) -> float:
        return self.end - self.start


@dataclass
class Moment:
    start: float
    end: float
    types: list[str]

    @property
    def duration(self) -> float:
        return self.end - self.start


def _cluster(cands: list[Candidate]) -> list[list[Candidate]]:
    groups: list[list[Candidate]] = []
    for c in sorted(cands, key=lambda c: c.start):
        if groups and c.start - max(g.end for g in groups[-1]) <= CLUSTER_GAP_SEC:
            groups[-1].append(c)
        else:
            groups.append([c])
    return groups


def _trim_to_speech(fa: FrameAnalysis, start: float, end: float) -> tuple[float, float]:
    a, b = fa.frame(start), min(fa.frame(end), fa.n_frames)
    active = np.flatnonzero(fa.active[a:b])
    if active.size == 0:
        return start, end
    return fa.t(a + active[0]), fa.t(a + active[-1] + 1)


def build_events(output: DetectionOutput, frames: FrameAnalysis, threshold: float) -> list[Event]:
    """Merge consecutive positive windows per label into events.

    When the detector proposed fine-grained candidates inside a merged span,
    the event boundaries come from those candidates; otherwise the span is
    trimmed to the speech it contains (window-only detectors such as XLS-R).
    """
    events: list[Event] = []
    used: set[int] = set()
    for col, label in enumerate(LABELS):
        positive = output.probs[:, col] >= threshold
        for a, b in runs(positive):
            span_start, span_end = output.windows[a][0], output.windows[b - 1][1]
            inside = [
                c
                for c in output.candidates
                if c.label == label and c.score >= threshold and id(c) not in used
                and c.start < span_end and span_start < c.end
            ]
            if inside:
                used.update(id(c) for c in inside)
                for group in _cluster(inside):
                    events.append(
                        Event(
                            type=label,
                            start=min(c.start for c in group),
                            end=max(c.end for c in group),
                            confidence=max(c.score for c in group),
                            detail=group[0].detail if len(group) == 1 else {"merged": len(group)},
                        )
                    )
            else:
                start, end = (span_start, span_end) if label == "block" else _trim_to_speech(frames, span_start, span_end)
                events.append(Event(type=label, start=start, end=end, confidence=float(output.probs[a:b, col].max())))
    return sorted(events, key=lambda e: (e.start, e.type))


def stutter_moments(events: list[Event]) -> list[Moment]:
    """Union of overlapping stuttering-like events; each moment counts as one stuttered syllable."""
    moments: list[Moment] = []
    for e in sorted((e for e in events if e.type in STUTTER_LABELS), key=lambda e: e.start):
        if moments and e.start - moments[-1].end <= MOMENT_GAP_SEC:
            last = moments[-1]
            last.end = max(last.end, e.end)
            if e.type not in last.types:
                last.types.append(e.type)
        else:
            moments.append(Moment(start=e.start, end=e.end, types=[e.type]))
    return moments
