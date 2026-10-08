"""
Optional evaluation of each technology's detected events against SLP
ground-truth annotations (section 23).

If no ground truth is supplied, every metric is explicitly reported as
"Not available" rather than omitted or fabricated (section 23: "Never
fabricate these metrics").

Matching strategy: an annotated event and a detected event are considered a
match if their time intervals overlap at all, optionally requiring a
minimum IoU (intersection-over-union) via `min_iou`. This is a simple,
transparent, and reproducible matching rule appropriate for a first-pass
research prototype; it is documented here so it can be scrutinized/replaced
during the actual research analysis.
"""

from typing import Any, Dict, List, Optional

from app.config.settings import BEHAVIORS


def _interval_iou(a_start, a_end, b_start, b_end) -> float:
    inter = max(0.0, min(a_end, b_end) - max(a_start, b_start))
    union = max(a_end, b_end) - min(a_start, b_start)
    if union <= 0:
        return 0.0
    return inter / union


def evaluate_against_ground_truth(
    detected_events: List[Dict[str, Any]],
    annotated_events: List[Dict[str, Any]],
    min_iou: float = 0.1,
) -> Dict[str, Any]:
    """
    detected_events / annotated_events: list of {"start_time","end_time",...}
    Returns precision/recall/F1/false positives/false negatives/
    frequency error/duration error/mean event-timing error, computed only
    from the events actually provided.
    """
    matched_detected = set()
    matched_annotated = set()
    timing_errors = []
    duration_errors = []

    for di, d in enumerate(detected_events):
        best_j, best_iou = None, 0.0
        for aj, a in enumerate(annotated_events):
            if aj in matched_annotated:
                continue
            iou = _interval_iou(d["start_time"], d["end_time"], a["start_time"], a["end_time"])
            if iou > best_iou:
                best_iou = iou
                best_j = aj
        if best_j is not None and best_iou >= min_iou:
            matched_detected.add(di)
            matched_annotated.add(best_j)
            a = annotated_events[best_j]
            timing_errors.append(abs(d["start_time"] - a["start_time"]))
            duration_errors.append(
                abs((d["end_time"] - d["start_time"]) - (a["end_time"] - a["start_time"]))
            )

    tp = len(matched_detected)
    fp = len(detected_events) - tp
    fn = len(annotated_events) - len(matched_annotated)

    precision = tp / (tp + fp) if (tp + fp) > 0 else None
    recall = tp / (tp + fn) if (tp + fn) > 0 else None
    f1 = (
        2 * precision * recall / (precision + recall)
        if precision is not None and recall is not None and (precision + recall) > 0
        else None
    )

    return {
        "true_positives": tp,
        "false_positives": fp,
        "false_negatives": fn,
        "precision": round(precision, 4) if precision is not None else None,
        "recall": round(recall, 4) if recall is not None else None,
        "f1_score": round(f1, 4) if f1 is not None else None,
        "frequency_error": len(detected_events) - len(annotated_events),
        "mean_event_timing_error_s": (
            round(sum(timing_errors) / len(timing_errors), 4) if timing_errors else None
        ),
        "mean_duration_error_s": (
            round(sum(duration_errors) / len(duration_errors), 4) if duration_errors else None
        ),
        "min_iou_for_match": min_iou,
    }


def evaluate_results(
    technology_results: List[Dict[str, Any]],
    ground_truth: Optional[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    technology_results: list of standardized per-technology results.
    ground_truth: {"video": ..., "annotations": [{"behavior","start_time","end_time"}, ...]} or None.

    Returns per-technology, per-behavior metrics, or an explicit
    "Not available" placeholder when no ground truth was provided.
    """
    if not ground_truth or not ground_truth.get("annotations"):
        return {
            "ground_truth_provided": False,
            "ground_truth": "Not provided",
            "evaluation_metrics": "Not available",
        }

    annotations_by_behavior: Dict[str, List[Dict[str, Any]]] = {b: [] for b in BEHAVIORS}
    for ann in ground_truth["annotations"]:
        b = ann.get("behavior")
        if b in annotations_by_behavior:
            annotations_by_behavior[b].append(ann)

    out: Dict[str, Any] = {"ground_truth_provided": True, "per_technology": {}}

    for result in technology_results:
        tech = result.get("technology")
        behaviors = result.get("behaviors", {})
        tech_eval = {}
        for b in BEHAVIORS:
            beh_result = behaviors.get(b, {})
            if beh_result.get("status") != "supported":
                tech_eval[b] = {
                    "evaluated": False,
                    "reason": f"technology status for this behavior was '{beh_result.get('status', 'unsupported')}', not 'supported'",
                }
                continue
            gt_events = annotations_by_behavior.get(b, [])
            if not gt_events:
                tech_eval[b] = {"evaluated": False, "reason": "no ground-truth annotations for this behavior"}
                continue
            detected = beh_result.get("events", [])
            tech_eval[b] = {"evaluated": True, **evaluate_against_ground_truth(detected, gt_events)}
        out["per_technology"][tech] = tech_eval

    return out
