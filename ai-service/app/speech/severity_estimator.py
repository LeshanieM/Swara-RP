"""
Severity estimation module for Component 1.
Computes estimated stuttering severity (Mild, Moderate, Severe, or None) based on:
  - Percentage of Syllables Stuttered (%SS)
  - Mean length of the 3 longest events (following SSI-4 duration scoring)
  - Longest stuttering event duration
  - Task type calibration (Reader 11–14 vs Non-reader 5–10)
  - Optional C2 concomitant-behavior score (video physical concomitants)

Output:
  - SSI-4-inspired audio-based severity estimate
  - Clear fluent vs stuttering distinction: 'no / very mild stuttering detected' for sub-threshold %SS.
"""

from typing import Tuple, List, Optional
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

ESTIMATE_TYPE_AUDIO = "SSI-4-inspired audio-based severity estimate"
ESTIMATE_TYPE_MULTIMODAL = "SSI-4-inspired multimodal severity estimate (audio + video concomitants)"
STATUS_FLUENT_OR_MINIMAL = "No / very mild stuttering detected"


def estimate_stuttering_severity_detailed(
    percent_ss: float,
    longest_event_duration_s: float,
    total_events: int,
    mean_top_3_duration_s: Optional[float] = None,
    task_type: str = "picture-description",
    concomitant_score: Optional[float] = None,
    is_reliable_syllables: bool = True,
    weights_loaded: bool = True,
) -> Tuple[str, str, str, List[str]]:
    """
    Computes SSI-4-inspired severity rating, clinical status, estimate type, and caveats.

    Returns:
        severity: 'None', 'Mild', 'Moderate', 'Severe', or 'Unavailable'.
        clinical_status: Descriptive status (e.g. 'No / very mild stuttering detected' or '<Severity> stuttering detected').
        estimate_type: 'SSI-4-inspired audio-based severity estimate' or multimodal variant.
        warnings: List of caveats, threshold notes, or elevation reasons.
    """
    warnings = []
    estimate_type = (
        ESTIMATE_TYPE_MULTIMODAL
        if (concomitant_score is not None and concomitant_score > 0.0)
        else ESTIMATE_TYPE_AUDIO
    )

    # 1. Model weights check
    if not weights_loaded:
        warnings.append(
            "Classifier weights not loaded. Stuttering severity cannot be computed without a trained model."
        )
        return SEVERITY_UNAVAILABLE, "Classifier weights unavailable", estimate_type, warnings

    # 2. Syllable reliability check
    if not is_reliable_syllables:
        warnings.append(
            "Insufficient spoken syllables detected to compute reliable %SS. Severity estimation unavailable."
        )
        return SEVERITY_UNAVAILABLE, "Insufficient syllables detected", estimate_type, warnings

    # 3. Fluent vs Stuttering check (PDF Page 6 point 6)
    # A child whose %SS is below the lowest cut-off (<1.0% or no events) is reported as 'no / very mild stuttering detected'.
    is_reading = "read" in (task_type or "").lower() or "passage" in (task_type or "").lower()
    lowest_ss_cutoff = 0.8 if is_reading else 1.0

    # Calculate effective duration metric (mean of 3 longest events, falling back to longest event)
    duration_metric = (
        mean_top_3_duration_s
        if (mean_top_3_duration_s is not None and mean_top_3_duration_s > 0)
        else longest_event_duration_s
    )

    if total_events == 0 or (percent_ss < lowest_ss_cutoff and duration_metric < 1.2):
        return SEVERITY_NONE, STATUS_FLUENT_OR_MINIMAL, estimate_type, warnings

    # 4. Multi-factor rule-based severity mapping
    # Calibrated cut-offs separated by task (readers vs non-readers)
    mild_cutoff = 3.5 if is_reading else 4.5
    mod_cutoff = 8.0 if is_reading else 9.5

    if percent_ss < mild_cutoff:
        # Check if duration elevates severity
        # Following SSI-4: long blocks/prolongations (mean of 3 longest >= 2.0s or single event >= 2.5s) elevate severity
        if duration_metric >= LONG_EVENT_THRESHOLD_S or longest_event_duration_s >= 2.5:
            severity = SEVERITY_MODERATE
            warnings.append(
                f"Severity elevated to Moderate due to prolonged disfluency duration "
                f"(top-3 mean {duration_metric:.2f}s, longest {longest_event_duration_s:.1f}s >= {LONG_EVENT_THRESHOLD_S:.1f}s)."
            )
        else:
            severity = SEVERITY_MILD
    elif percent_ss < mod_cutoff:
        if duration_metric >= LONG_EVENT_THRESHOLD_S or longest_event_duration_s >= 2.5:
            severity = SEVERITY_SEVERE
            warnings.append(
                f"Severity elevated to Severe due to prolonged disfluency duration "
                f"(top-3 mean {duration_metric:.2f}s, longest {longest_event_duration_s:.1f}s >= {LONG_EVENT_THRESHOLD_S:.1f}s)."
            )
        else:
            severity = SEVERITY_MODERATE
    else:
        severity = SEVERITY_SEVERE

    # 5. Optional physical concomitant factor (from C2 video analysis)
    if concomitant_score is not None and concomitant_score >= 0.6:
        warnings.append(
            f"Component 2 detected significant physical concomitant behaviors (score: {concomitant_score:.2f})."
        )
        if severity == SEVERITY_MILD and percent_ss >= (mild_cutoff * 0.75):
            severity = SEVERITY_MODERATE
            warnings.append("Severity elevated from Mild to Moderate due to secondary concomitant behaviors.")

    clinical_status = f"{severity} stuttering detected"
    return severity, clinical_status, estimate_type, warnings


def estimate_stuttering_severity(
    percent_ss: float,
    longest_event_duration_s: float,
    total_events: int,
    mean_top_3_duration_s: Optional[float] = None,
    task_type: str = "picture-description",
    concomitant_score: Optional[float] = None,
    is_reliable_syllables: bool = True,
    weights_loaded: bool = True,
) -> Tuple[str, List[str]]:
    """
    Backward-compatible wrapper returning (severity, warnings).
    """
    severity, _, _, warnings = estimate_stuttering_severity_detailed(
        percent_ss=percent_ss,
        longest_event_duration_s=longest_event_duration_s,
        total_events=total_events,
        mean_top_3_duration_s=mean_top_3_duration_s,
        task_type=task_type,
        concomitant_score=concomitant_score,
        is_reliable_syllables=is_reliable_syllables,
        weights_loaded=weights_loaded,
    )
    return severity, warnings
