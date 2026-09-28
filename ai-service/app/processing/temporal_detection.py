"""
Generic temporal event detection over a per-frame scalar signal.

Implements the pipeline described in section 11 of the spec:

    baseline -> movement begins -> increases -> peak -> decreases -> baseline
    == one event

This module is technology-agnostic: any analyzer that can reduce its
per-frame visual features to a single scalar "activation" signal (EAR for
blinks, normalized jaw opening, angular head velocity, etc.) can reuse it.
This keeps event-detection logic identical across technologies, which is
important for a comparison experiment - differences in reported events
should come from the underlying visual features, not from five different
ad-hoc thresholding implementations.

Technique used: moving-average smoothing + a two-threshold (hysteresis)
state machine, which avoids flagging a single noisy frame as an event while
still catching genuine sustained movement. This matches the "state-based
detection" + "adaptive thresholds via hysteresis" options listed in the spec.
"""

from dataclasses import dataclass
from typing import List, Optional, Sequence, Tuple


def moving_average(values: Sequence[float], window: int) -> List[float]:
    """Centered moving average. window<=1 returns values unchanged."""
    n = len(values)
    if window <= 1 or n == 0:
        return list(values)
    half = window // 2
    out = []
    for i in range(n):
        lo = max(0, i - half)
        hi = min(n, i + half + 1)
        chunk = values[lo:hi]
        out.append(sum(chunk) / len(chunk))
    return out


@dataclass
class DetectedInterval:
    start_index: int
    end_index: int
    start_time: float
    end_time: float
    peak_value: float


def detect_events_above_threshold(
    signal: Sequence[float],
    timestamps: Sequence[float],
    activation_threshold: float,
    hysteresis_ratio: float = 0.7,
    min_event_duration_s: float = 0.08,
    max_event_duration_s: Optional[float] = None,
    smoothing_window: int = 3,
    direction: str = "above",
) -> List[DetectedInterval]:
    """
    Two-threshold (hysteresis) state-machine event detector.

    An event starts the frame the (smoothed) signal crosses
    `activation_threshold` in `direction`, and ends when it crosses back
    past `activation_threshold * hysteresis_ratio` (the release threshold).
    Events shorter than `min_event_duration_s` are discarded as noise, per
    section 11 ("do not treat a single frame with movement as a behavior
    event"). Events longer than `max_event_duration_s` (if given) are kept
    but flagged by the caller as unusually long, useful for e.g. an eye
    staying closed rather than blinking.

    direction="above": event = signal is ABOVE threshold (e.g. movement
        magnitude, angular velocity).
    direction="below": event = signal is BELOW threshold (e.g. Eye Aspect
        Ratio drops during a blink).
    """
    assert len(signal) == len(timestamps)
    if len(signal) == 0:
        return []

    smoothed = moving_average(signal, smoothing_window)

    release_threshold = (
        activation_threshold * hysteresis_ratio
        if direction == "above"
        else activation_threshold + (activation_threshold * (1 - hysteresis_ratio) * -1)
    )
    # For "below" direction (e.g. EAR), release threshold should be a bit
    # *above* the activation threshold so the event ends once the signal has
    # clearly recovered (hysteresis_ratio > 1 is expected for this case,
    # e.g. 1.15).
    if direction == "below":
        release_threshold = activation_threshold * hysteresis_ratio

    events: List[DetectedInterval] = []
    active = False
    start_idx = None
    peak_val = None

    def is_active_sample(v):
        return v > activation_threshold if direction == "above" else v < activation_threshold

    def is_release_sample(v):
        return v < release_threshold if direction == "above" else v > release_threshold

    for i, v in enumerate(smoothed):
        if not active:
            if is_active_sample(v):
                active = True
                start_idx = i
                peak_val = v
        else:
            if direction == "above":
                peak_val = max(peak_val, v)
            else:
                peak_val = min(peak_val, v)
            if is_release_sample(v):
                active = False
                end_idx = i
                start_time = timestamps[start_idx]
                end_time = timestamps[end_idx]
                duration = end_time - start_time
                if duration >= min_event_duration_s:
                    if max_event_duration_s is None or duration <= max_event_duration_s:
                        events.append(
                            DetectedInterval(
                                start_index=start_idx,
                                end_index=end_idx,
                                start_time=start_time,
                                end_time=end_time,
                                peak_value=peak_val,
                            )
                        )
                start_idx = None
                peak_val = None

    # Signal still active at the end of the video: close the event at the
    # last frame rather than dropping it.
    if active and start_idx is not None:
        end_idx = len(smoothed) - 1
        start_time = timestamps[start_idx]
        end_time = timestamps[end_idx]
        duration = end_time - start_time
        if duration >= min_event_duration_s:
            if max_event_duration_s is None or duration <= max_event_duration_s:
                events.append(
                    DetectedInterval(
                        start_index=start_idx,
                        end_index=end_idx,
                        start_time=start_time,
                        end_time=end_time,
                        peak_value=peak_val,
                    )
                )

    return events


def velocity(values: Sequence[float], timestamps: Sequence[float]) -> List[float]:
    """First-order derivative (per-second) of a signal, same length as input
    (first sample's velocity is 0)."""
    out = [0.0]
    for i in range(1, len(values)):
        dt = timestamps[i] - timestamps[i - 1]
        if dt <= 0:
            out.append(0.0)
        else:
            out.append((values[i] - values[i - 1]) / dt)
    return out


def angular_velocity_deg(angles_deg: Sequence[float], timestamps: Sequence[float]) -> List[float]:
    """Absolute angular velocity in degrees/second, handling wraparound is
    not needed here since yaw/pitch/roll from landmark geometry stay within
    a bounded range for a front-facing speech video."""
    v = velocity(angles_deg, timestamps)
    return [abs(x) for x in v]
