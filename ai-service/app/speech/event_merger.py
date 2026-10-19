"""
Event merging module for overlapping 3-second window predictions.
Fuses overlapping or closely spaced same-category window predictions
into contiguous, clinical-style stuttering events with explicit start, end,
type, duration, and confidence.
"""

from typing import List, Dict, Any, Tuple
from app.config.speech_settings import (
    EVENT_MERGE_MAX_GAP_S,
    MIN_EVENT_CONFIDENCE,
    CATEGORY_FLUENT,
    CATEGORY_BLOCK,
    CATEGORY_PROLONGATION,
    CATEGORY_SOUND_REP,
    CATEGORY_WORD_REP,
    CATEGORY_INTERJECTION,
    STUTTER_CATEGORIES,
)


def merge_window_predictions(
    window_predictions: List[Dict[str, Any]],
    max_gap_s: float = EVENT_MERGE_MAX_GAP_S,
    min_confidence: float = MIN_EVENT_CONFIDENCE,
) -> Tuple[List[Dict[str, Any]], Dict[str, int], str]:
    """
    Fuses sliding window predictions into stuttering events.

    Args:
        window_predictions: List of dicts containing:
            {"start": float, "end": float, "class": str, "confidence": float}
        max_gap_s: Maximum temporal gap (seconds) between windows of the same class to merge.
        min_confidence: Minimum prediction confidence required to consider a stutter event.

    Returns:
        merged_events: List of consolidated event dicts:
            [{"startTime": float, "endTime": float, "eventType": str, "confidence": float, "duration": float}]
        event_counts: Dict with counts per stutter category and total.
        primary_stutter_type: The most frequent stuttering type, or 'None'.
    """
    # 1. Filter out fluent windows or low-confidence predictions
    stutter_windows = [
        w for w in window_predictions
        if w.get("class") != CATEGORY_FLUENT
        and w.get("class") in STUTTER_CATEGORIES
        and w.get("confidence", 0.0) >= min_confidence
    ]

    if not stutter_windows:
        counts = {
            "blocks": 0,
            "prolongations": 0,
            "soundRepetitions": 0,
            "wordRepetitions": 0,
            "interjections": 0,
            "total": 0,
        }
        return [], counts, "None"

    # Sort windows by start time
    stutter_windows.sort(key=lambda x: x["start"])

    # 2. Merge contiguous or overlapping windows with identical category
    merged_events: List[Dict[str, Any]] = []
    current_event = None

    for win in stutter_windows:
        w_start = win["start"]
        w_end = win["end"]
        w_class = win["class"]
        w_conf = win["confidence"]

        if current_event is None:
            current_event = {
                "eventType": w_class,
                "startTime": w_start,
                "endTime": w_end,
                "confidences": [w_conf],
            }
        else:
            # Check if same class and overlapping or adjacent within max_gap_s
            is_same_class = (current_event["eventType"] == w_class)
            is_adjacent = (w_start <= current_event["endTime"] + max_gap_s)

            if is_same_class and is_adjacent:
                # Merge into current event
                current_event["endTime"] = max(current_event["endTime"], w_end)
                current_event["confidences"].append(w_conf)
            else:
                # Finalize previous event
                duration = round(current_event["endTime"] - current_event["startTime"], 2)
                avg_conf = round(sum(current_event["confidences"]) / len(current_event["confidences"]), 3)
                merged_events.append({
                    "startTime": round(current_event["startTime"], 2),
                    "endTime": round(current_event["endTime"], 2),
                    "eventType": current_event["eventType"],
                    "confidence": avg_conf,
                    "duration": max(0.1, duration),
                })
                # Start new event
                current_event = {
                    "eventType": w_class,
                    "startTime": w_start,
                    "endTime": w_end,
                    "confidences": [w_conf],
                }

    if current_event is not None:
        duration = round(current_event["endTime"] - current_event["startTime"], 2)
        avg_conf = round(sum(current_event["confidences"]) / len(current_event["confidences"]), 3)
        merged_events.append({
            "startTime": round(current_event["startTime"], 2),
            "endTime": round(current_event["endTime"], 2),
            "eventType": current_event["eventType"],
            "confidence": avg_conf,
            "duration": max(0.1, duration),
        })

    # 3. Compute event counts per category
    category_counts = {cat: 0 for cat in STUTTER_CATEGORIES}
    for ev in merged_events:
        t = ev["eventType"]
        if t in category_counts:
            category_counts[t] += 1

    counts = {
        "blocks": category_counts[CATEGORY_BLOCK],
        "prolongations": category_counts[CATEGORY_PROLONGATION],
        "soundRepetitions": category_counts[CATEGORY_SOUND_REP],
        "wordRepetitions": category_counts[CATEGORY_WORD_REP],
        "interjections": category_counts[CATEGORY_INTERJECTION],
        "total": len(merged_events),
    }

    # 4. Determine primary stuttering type
    if merged_events:
        primary_stutter_type = max(category_counts, key=category_counts.get)
        if category_counts[primary_stutter_type] == 0:
            primary_stutter_type = "None"
    else:
        primary_stutter_type = "None"

    return merged_events, counts, primary_stutter_type
