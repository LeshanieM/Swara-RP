"""Temporal Multimodal Movement Fusion (TMMF) research extension.

Consumes technology-neutral per-frame movement features emitted by Component 2
landmark analyzers. No classifier is trained or clinical label inferred unless
expert annotations and speaker identifiers are supplied.
"""
from __future__ import annotations

from collections import defaultdict
from typing import Any, Dict, List, Optional, Sequence
import math
import csv

CHANNELS = ("eye", "lip", "jaw", "head")
CATEGORIES = ("FG", "HM")


def _union_duration(intervals: Sequence[tuple[float, float]]) -> float:
    merged: List[List[float]] = []
    for lo, hi in sorted(intervals):
        if not merged or lo > merged[-1][1]:
            merged.append([lo, hi])
        else:
            merged[-1][1] = max(merged[-1][1], hi)
    return sum(hi - lo for lo, hi in merged)


def load_casa_annotations(csv_path: str, task: Optional[str] = None,
                          annotator: str = "Gold") -> List[Dict[str, Any]]:
    """Read CASA's timed annotation CSV (start/end are milliseconds).

    CASA video assets may be separately licensed/distributed; this importer
    reads only the annotation CSV and never downloads media.
    """
    required = {"media_file", "start", "end", "annotator", "FG", "HM"}
    with open(csv_path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        if not required.issubset(set(reader.fieldnames or [])):
            raise ValueError(f"CASA CSV missing columns: {sorted(required - set(reader.fieldnames or []))}")
        rows = []
        for row in reader:
            if annotator and str(row.get("annotator", "")).strip().casefold() != annotator.casefold():
                continue
            if task and "task" in row and str(row.get("task", "")).strip() \
                    and str(row.get("task", "")).strip().casefold() != task.casefold():
                continue
            try:
                start, end = float(row["start"]) / 1000.0, float(row["end"]) / 1000.0
                fg, hm = int(float(row["FG"])), int(float(row["HM"]))
            except (TypeError, ValueError):
                continue
            if start < 0 or end <= start or fg not in (0, 1) or hm not in (0, 1):
                continue
            rows.append({"media_file": str(row["media_file"]).strip(),
                         "task": str(row.get("task", "")).strip(),
                         "split": str(row.get("split", "")).strip(),
                         "speaker_id": str(row["media_file"]).strip(),
                         "annotator": str(row["annotator"]).strip(),
                         "start_time": start, "end_time": end, "FG": fg, "HM": hm})
    if not rows:
        raise ValueError("No usable CASA rows matched the requested task/annotator")
    return rows


def label_casa_windows(windows: Sequence[Dict[str, Any]], annotations: Sequence[Dict[str, Any]],
                       positive_fraction: float = 0.5,
                       annotation_coverage: float = 0.5) -> List[Dict[str, Any]]:
    """Label feature windows from CASA rows, omitting unannotated windows.

    Windows need `media_file` (and `task` if annotations carry task). A row's
    zero label is used only inside the interval that CASA annotated; time
    outside annotation coverage is not presumed negative.
    """
    if not 0 <= positive_fraction <= 1 or not 0 < annotation_coverage <= 1:
        raise ValueError("label fractions must be within [0, 1], with coverage > 0")
    by_video: Dict[tuple, List[Dict[str, Any]]] = defaultdict(list)
    for ann in annotations:
        by_video[(ann["media_file"], ann.get("task", ""))].append(ann)
    labelled = []
    for win in windows:
        key = (win.get("media_file"), win.get("task", ""))
        anns = by_video.get(key, []) or by_video.get((key[0], ""), [])
        duration = float(win["end_time"]) - float(win["start_time"])
        if duration <= 0 or not anns:
            continue
        overlaps = []
        for ann in anns:
            lo = max(float(win["start_time"]), ann["start_time"])
            hi = min(float(win["end_time"]), ann["end_time"])
            if hi > lo:
                overlaps.append((lo, hi, ann))
        covered = _union_duration([(lo, hi) for lo, hi, _ in overlaps])
        if covered / duration < annotation_coverage:
            continue
        labels = {}
        for category in CATEGORIES:
            positive = _union_duration([(lo, hi) for lo, hi, ann in overlaps
                                        if int(ann[category]) == 1])
            labels[category] = int(positive / duration >= positive_fraction)
        labelled.append({**win, "speaker_id": anns[0]["speaker_id"], "labels": labels,
                         "annotator": anns[0].get("annotator"), "label_source": "CASA"})
    return labelled


def _stats(values: Sequence[float], timestamps: Sequence[float], prefix: str) -> Dict[str, float]:
    vals = [float(v) if math.isfinite(float(v)) else 0.0 for v in values]
    if not vals:
        vals = [0.0]
    dt = [max(0.0, timestamps[i] - timestamps[i - 1]) for i in range(1, len(timestamps))]
    speeds = [abs(vals[i] - vals[i - 1]) / dt[i - 1] if dt and dt[i - 1] > 0 else 0.0
              for i in range(1, len(vals))]
    accels = [abs(speeds[i] - speeds[i - 1]) / dt[i]
              for i in range(1, len(speeds)) if dt and dt[i] > 0]
    mean = sum(vals) / len(vals)
    sd = math.sqrt(sum((x - mean) ** 2 for x in vals) / len(vals))
    peaks = sum(1 for i in range(1, len(vals) - 1) if vals[i] > vals[i - 1] and vals[i] >= vals[i + 1])
    return {f"{prefix}_{k}": v for k, v in {
        "mean": mean, "max": max(vals), "min": min(vals), "std": sd,
        "mean_velocity": sum(speeds) / len(speeds) if speeds else 0.0,
        "max_velocity": max(speeds, default=0.0),
        "mean_acceleration": sum(accels) / len(accels) if accels else 0.0,
        "peak_count": float(peaks), "active_duration_s": sum(dt),
        "frequency_hz": peaks / sum(dt) if sum(dt) > 0 else 0.0,
    }.items()}


def extract_windows(frames: Sequence[Dict[str, Any]], window_s: float = 2.0,
                    overlap: float = 0.5) -> List[Dict[str, Any]]:
    """Aggregate normalized movement channels into overlapping TMMF windows.

    Each frame has timestamp and optional scalar channels eye/lip/jaw/head.
    Face-size normalization is the analyzer's responsibility; channel units
    must be documented by the caller.
    """
    if window_s <= 0 or not 0 <= overlap < 1:
        raise ValueError("window_s must be positive and overlap in [0, 1)")
    rows = sorted(frames, key=lambda f: float(f["timestamp"]))
    if not rows:
        return []
    start, finish = float(rows[0]["timestamp"]), float(rows[-1]["timestamp"])
    step = window_s * (1.0 - overlap)
    result = []
    cursor = start
    while cursor <= finish:
        end = cursor + window_s
        selected = [r for r in rows if cursor <= float(r["timestamp"]) < end]
        if selected:
            times = [float(r["timestamp"]) for r in selected]
            features: Dict[str, float] = {}
            for channel in CHANNELS:
                features.update(_stats([r.get(channel, 0.0) for r in selected], times, channel))
            result.append({"start_time": cursor, "end_time": min(end, finish),
                           "features": features})
        cursor += step
    return result


def label_windows(windows: Sequence[Dict[str, Any]], annotations: Sequence[Dict[str, Any]],
                  overlap_fraction: float = 0.5) -> List[Dict[str, Any]]:
    """Attach independent FG/HM labels using overlap / window-duration."""
    if not 0 <= overlap_fraction <= 1:
        raise ValueError("overlap_fraction must be in [0, 1]")
    output = []
    for window in windows:
        duration = max(0.0, window["end_time"] - window["start_time"])
        labels = {}
        for category in CATEGORIES:
            aliases = {"FG": {"FG", "facial_grimace", "facial_grimaces"},
                       "HM": {"HM", "head_movement", "head_movements"}}[category]
            overlap = sum(max(0.0, min(window["end_time"], a["end_time"])
                            - max(window["start_time"], a["start_time"]))
                          for a in annotations if a.get("behavior") in aliases)
            labels[category] = int(duration > 0 and overlap / duration >= overlap_fraction)
        output.append({**window, "labels": labels})
    return output


def merge_predictions(windows: Sequence[Dict[str, Any]], predictions: Sequence[Dict[str, int]],
                      max_gap_s: float = 0.0, min_duration_s: float = 0.0) -> Dict[str, List[Dict[str, float]]]:
    """Merge predicted positive windows separately into FG and HM events."""
    if len(windows) != len(predictions):
        raise ValueError("windows and predictions must have equal length")
    events = {}
    for category in CATEGORIES:
        spans = []
        for win, pred in zip(windows, predictions):
            if pred.get(category, 0):
                lo, hi = float(win["start_time"]), float(win["end_time"])
                if spans and lo - spans[-1]["end_time"] <= max_gap_s:
                    spans[-1]["end_time"] = max(spans[-1]["end_time"], hi)
                else:
                    spans.append({"start_time": lo, "end_time": hi})
        events[category] = [{**e, "duration": e["end_time"] - e["start_time"]}
                            for e in spans if e["end_time"] - e["start_time"] >= min_duration_s]
    return events


def _rule_predict(rows: Sequence[Dict[str, Any]]) -> List[Dict[str, int]]:
    out = []
    for row in rows:
        f = row["features"]
        # Explicit, configurable research baseline defaults; tune only on train folds.
        out.append({"FG": int(any(f.get(f"{c}_max_velocity", 0) > 0.08 for c in ("eye", "lip", "jaw"))),
                    "HM": int(f.get("head_max_velocity", 0) > 0.08)})
    return out


def speaker_independent_evaluation(records: Sequence[Dict[str, Any]], n_splits: int = 5) -> Dict[str, Any]:
    """Compare rule, non-temporal RF, TMMF RF and TMMF SVM with speaker folds.

    Records must include speaker_id, feature mapping and labels mapping.
    Any split lacking both classes reports its metrics as unavailable.
    """
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import GroupKFold
    from sklearn.pipeline import make_pipeline
    from sklearn.preprocessing import StandardScaler
    from sklearn.svm import SVC
    from sklearn.metrics import precision_recall_fscore_support, accuracy_score, average_precision_score
    if len({r["speaker_id"] for r in records}) < 2:
        raise ValueError("At least two distinct speaker_id groups are required")
    keys = sorted({k for r in records for k in r["features"]})
    baseline_keys = sorted({k for r in records for k in r.get("baseline_features", r["features"])})
    X = [[float(r["features"].get(k, 0.0)) for k in keys] for r in records]
    X_baseline = [[float(r.get("baseline_features", r["features"]).get(k, 0.0))
                   for k in baseline_keys] for r in records]
    groups = [r["speaker_id"] for r in records]
    splitter = GroupKFold(n_splits=min(n_splits, len(set(groups))))
    results = {m: {c: [] for c in CATEGORIES} for m in ("rule_based", "rf_non_temporal", "rf_tmmf", "svm_tmmf")}
    for train, test in splitter.split(X, groups=groups):
        for category in CATEGORIES:
            y = [int(r["labels"][category]) for r in records]
            if len({y[i] for i in train}) < 2:
                continue
            for model_name in results:
                if model_name == "rule_based":
                    pred = [_rule_predict([records[i]])[0][category] for i in test]
                    scores = pred
                else:
                    estimator = (RandomForestClassifier(n_estimators=200, class_weight="balanced", random_state=17)
                                 if model_name.startswith("rf") else
                                 make_pipeline(StandardScaler(), SVC(class_weight="balanced", probability=True, random_state=17)))
                    matrix = X_baseline if model_name == "rf_non_temporal" else X
                    estimator.fit([matrix[i] for i in train], [y[i] for i in train])
                    pred = estimator.predict([matrix[i] for i in test]).tolist()
                    scores = estimator.predict_proba([matrix[i] for i in test])[:, 1].tolist()
                p, r, f, _ = precision_recall_fscore_support([y[i] for i in test], pred, average="binary", zero_division=0)
                item = {"precision": float(p), "recall": float(r), "f1": float(f),
                        "accuracy": float(accuracy_score([y[i] for i in test], pred)),
                        "pr_auc": float(average_precision_score([y[i] for i in test], scores)) if len(set(y[i] for i in test)) > 1 else None,
                        "test_speakers": sorted({groups[i] for i in test})}
                results[model_name][category].append(item)
    summary = {}
    for model, cats in results.items():
        summary[model] = {}
        for category, folds in cats.items():
            summary[model][category] = {"folds": folds, "mean_std": {
                metric: {"mean": sum(x[metric] for x in folds if x[metric] is not None) / max(1, sum(x[metric] is not None for x in folds)),
                         "std": (sum((x[metric] - sum(y[metric] for y in folds if y[metric] is not None) / max(1, sum(y[metric] is not None for y in folds))) ** 2 for x in folds if x[metric] is not None) / max(1, sum(x[metric] is not None for x in folds))) ** 0.5}
                for metric in ("precision", "recall", "f1", "accuracy", "pr_auc")}}
    return {"split": "speaker-independent GroupKFold", "n_splits": splitter.get_n_splits(),
            "tmmf_features": keys, "non_temporal_features": baseline_keys,
            "results": summary, "note": "Metrics are research estimates, not clinical validation."}
