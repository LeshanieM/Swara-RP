"""
Severity estimation module for Component 1.
Computes estimated stuttering severity (Mild, Moderate, Severe, or None) based on:
  - Percentage of Syllables Stuttered (%SS)
  - Longest stuttering event duration (seconds)
  - Event frequency

Documented Research Thresholds:
-------------------------------
  %SS < 3.0%:
    - Longest event < 2.0s  => Mild
    - Longest event >= 2.0s => Moderate (duration-elevated)
  3.0% <= %SS < 8.0%:
    - Longest event < 2.0s  => Moderate
    - Longest event >= 2.0s => Severe (duration-elevated)
  %SS >= 8.0%:
    - Severe

All thresholds are configurable via app.config.speech_settings.
Explicitly caveats that results are research approximations, not validated clinical diagnoses.
"""

from typing import Tuple, List
from app.config.speech_settings import (
    SEVERITY_NONE,
    SEVERITY_MILD,
    SEVERITY_MODERATE,
    SEVERITY_SEVERE,
    SEVERITY_UNAVAILABLE,
    SEVERITY_MILD_MAX_SS,
    SEVERITY_MODERATE_MAX_SS,
    LONG_EVENT_THRESHOLD_S,
    CLINICAL_DISCLAIMER,
)


def estimate_stuttering_severity(
    percent_ss: float,
    longest_event_duration_s: float,
    total_events: int,
    is_reliable_syllables: bool = True,
    weights_loaded: bool = True,
) -> Tuple[str, List[str]]:
    """
    Computes rule-based severity rating and applicable caveats.

    Returns:
        severity: One of 'None', 'Mild', 'Moderate', 'Severe', 'Unavailable'.
        warnings: List of caveats or limitation notices.
    """
    warnings = []

    # 1. Check if model weights were loaded
    if not weights_loaded:
        warnings.append(
            "Classifier weights not loaded. Stuttering severity cannot be computed without a trained model."
        )
        return SEVERITY_UNAVAILABLE, warnings

    # 2. Check if syllable counting was reliable
    if not is_reliable_syllables:
        warnings.append(
            "Insufficient spoken syllables detected to compute reliable %SS. Severity estimation unavailable."
        )
        return SEVERITY_UNAVAILABLE, warnings

    # 3. No stuttering events detected
    if total_events == 0 or percent_ss < 0.5:
        return SEVERITY_NONE, warnings

    # 4. Multi-factor rule-based severity mapping
    if percent_ss < SEVERITY_MILD_MAX_SS:
        if longest_event_duration_s >= LONG_EVENT_THRESHOLD_S:
            severity = SEVERITY_MODERATE
            warnings.append(
                f"Severity elevated to Moderate due to a prolonged event ({longest_event_duration_s:.1f}s >= {LONG_EVENT_THRESHOLD_S:.1f}s)."
            )
        else:
            severity = SEVERITY_MILD
    elif percent_ss < SEVERITY_MODERATE_MAX_SS:
        if longest_event_duration_s >= LONG_EVENT_THRESHOLD_S:
            severity = SEVERITY_SEVERE
            warnings.append(
                f"Severity elevated to Severe due to a prolonged event ({longest_event_duration_s:.1f}s >= {LONG_EVENT_THRESHOLD_S:.1f}s)."
            )
        else:
            severity = SEVERITY_MODERATE
    else:
        severity = SEVERITY_SEVERE

    return severity, warnings
