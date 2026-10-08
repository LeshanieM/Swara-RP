"""
Builds the cross-technology comparison table and measurement summary from
the *actual* standardized results returned by each analyzer.

Per section 21/22 of the spec:
  - The support matrix must be generated from real analyzer output, never
    hard-coded.
  - No "best technology" ranking or score is ever produced here.
"""

from typing import Any, Dict, List

from app.config.settings import BEHAVIORS, TECHNOLOGIES


def build_comparison(results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    `results` is the list of standardized per-technology result dicts
    (whatever analyze()/unavailable_result()/error_result() produced) for
    this analysis run, one per technology that was requested.

    Returns:
        {
          "technologies": [...],
          "support_matrix": { behavior: { technology: status } },
          "measurements": { behavior: { technology: {frequency, total_duration, ...} } },
          "processing_summary": { technology: {status, processing_time, tracking...} }
        }
    """
    by_tech = {r.get("technology"): r for r in results}

    support_matrix: Dict[str, Dict[str, str]] = {b: {} for b in BEHAVIORS}
    measurements: Dict[str, Dict[str, Any]] = {b: {} for b in BEHAVIORS}
    processing_summary: Dict[str, Any] = {}

    for tech_key, result in by_tech.items():
        processing_summary[tech_key] = {
            "status": result.get("status"),
            "processing_time": result.get("processing_time"),
            "tracking": result.get("tracking", {}),
            "reason": result.get("reason") or result.get("error"),
        }
        behaviors = result.get("behaviors", {})
        for b in BEHAVIORS:
            beh_result = behaviors.get(b, {"status": "unsupported"})
            support_matrix[b][tech_key] = beh_result.get("status", "unsupported")
            measurements[b][tech_key] = {
                "frequency": beh_result.get("frequency", 0),
                "total_duration": beh_result.get("total_duration", 0.0),
                "detected": beh_result.get("detected", False),
                "status": beh_result.get("status"),
            }

    return {
        "technologies": list(by_tech.keys()),
        "support_matrix": support_matrix,
        "measurements": measurements,
        "processing_summary": processing_summary,
        "note": (
            "This table reflects only what each analyzer actually reported for this "
            "video. No ranking, score, or 'best technology' determination is computed. "
            "Support status is a property of the underlying technology/analyzer, not a "
            "measure of accuracy."
        ),
    }
