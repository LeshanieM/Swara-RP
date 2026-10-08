"""Run Component 2 TMMF feature extraction for locally available CASA videos.

Uses only exact media_file/video-stem matches. Outputs normalized landmark
features and labels, never copies source video, and uses CASA's BAU aggregate.
"""
import json
import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from app.analyzers.mediapipe_analyzer import MediaPipeAnalyzer
from app.processing.tmmf import (
    label_casa_windows,
    load_casa_annotations,
    speaker_independent_evaluation,
)


DATA = ROOT / "data" / "casa" / "interview"
VIDEO_DIR = DATA / "videos"
CSV = DATA / "total_dataset.csv"
OUTPUT_DIR = ROOT / "results" / "casa_tmmf"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--media-files", default="all",
                        help="Comma-separated matched CASA media_file IDs, or 'all'")
    parser.add_argument("--target-fps", type=float, default=10.0,
                        help="Landmark inference sampling rate for this research pilot")
    args = parser.parse_args()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    annotations = load_casa_annotations(str(CSV), annotator="bau")
    by_media = {}
    for ann in annotations:
        by_media.setdefault(ann["media_file"], []).append(ann)

    all_matches = {p.stem for p in VIDEO_DIR.glob("*.mp4") if p.stem in by_media}
    selected_media = all_matches if args.media_files.strip().casefold() == "all" else {
        value.strip() for value in args.media_files.split(",") if value.strip()
    }
    video_paths = sorted(p for p in VIDEO_DIR.glob("*.mp4")
                         if p.stem in by_media and p.stem in selected_media)
    unmatched = sorted(p.name for p in VIDEO_DIR.glob("*.mp4") if p.stem not in by_media)
    if not video_paths:
        raise SystemExit("No video filename stems match media_file in total_dataset.csv")

    analyzer = MediaPipeAnalyzer()
    records_path = OUTPUT_DIR / "training_windows.json"
    summary_path = OUTPUT_DIR / "summary.json"
    cached_records = json.loads(records_path.read_text(encoding="utf-8")) if records_path.exists() else []
    cached_summary = json.loads(summary_path.read_text(encoding="utf-8")) if summary_path.exists() else {}
    cache_valid = cached_summary.get("sampling_fps") == args.target_fps
    records = cached_records if cache_valid else []
    cached_by_media = {item["media_file"]: item for item in cached_summary.get("matched_videos", [])} if cache_valid else {}
    summary = {"dataset": "CASA interview", "annotator": "bau",
               "sampling_fps": args.target_fps,
               "window_s": 2.0, "overlap": 0.5, "positive_fraction": 0.1,
               "annotation_coverage": 0.1, "matched_videos": [],
               "unmatched_videos": unmatched, "errors": []}

    for video_path in video_paths:
        if video_path.stem in cached_by_media:
            summary["matched_videos"].append(cached_by_media[video_path.stem])
            print(f"Using cached features for {video_path.name}", flush=True)
            continue
        print(f"Analyzing {video_path.name}...", flush=True)
        result = analyzer.analyze(str(video_path), generate_overlay=False,
                                  target_fps=args.target_fps)
        item = {"media_file": video_path.stem, "status": result.get("status"),
                "processing_time": result.get("processing_time"),
                "tracking": result.get("tracking", {}),
                "behavior_events": {key: value for key, value in result.get("behaviors", {}).items()
                                    if key in ("eye_blink", "lip_movement", "jaw_movement", "head_movement")}}
        if result.get("status") != "completed" or not result.get("tmmf", {}).get("windows"):
            item["error"] = result.get("reason") or result.get("error") or "No temporal features returned"
            summary["errors"].append(item)
            print(f"  skipped: {item['error']}", flush=True)
            continue

        windows = []
        for source in result["tmmf"]["windows"]:
            windows.append({**source, "media_file": video_path.stem, "task": "interview"})
        labelled = label_casa_windows(
            windows, by_media[video_path.stem], positive_fraction=0.1,
            annotation_coverage=0.1,
        )
        for row in labelled:
            features = row["features"]
            records.append({
                "speaker_id": row["speaker_id"], "media_file": video_path.stem,
                "start_time": row["start_time"], "end_time": row["end_time"],
                "features": features,
                "baseline_features": {k: v for k, v in features.items()
                                      if k.endswith(("_mean", "_max", "_std"))},
                "labels": row["labels"], "annotator": row["annotator"],
            })
        item["feature_windows"] = len(windows)
        item["labelled_windows"] = len(labelled)
        item["label_counts"] = {category: sum(r["labels"][category] for r in labelled)
                                for category in ("FG", "HM")}
        summary["matched_videos"].append(item)
        print(f"  {item['feature_windows']} feature windows; {item['labelled_windows']} annotated windows",
              flush=True)

    summary["record_count"] = len(records)
    summary["speakers"] = sorted({r["speaker_id"] for r in records})
    summary["labels"] = {category: {"positive": sum(r["labels"][category] for r in records),
                                   "negative": sum(not r["labels"][category] for r in records)}
                         for category in ("FG", "HM")}
    summary["scope_limit"] = (
        "CASA FG includes tongue protrusion and jaw muscle tension, outside the selected Swara FG scope."
    )
    if len(summary["speakers"]) >= 2 and records:
        try:
            summary["evaluation"] = speaker_independent_evaluation(records, n_splits=5)
        except (ValueError, KeyError) as exc:
            summary["evaluation"] = {"status": "unavailable", "reason": str(exc)}
    else:
        summary["evaluation"] = {
            "status": "unavailable",
            "reason": "At least two speakers with labeled feature windows are required.",
        }

    # Store intermediate features for reproducible research, excluding video bytes.
    with records_path.open("w", encoding="utf-8") as f:
        json.dump(records, f, indent=2)
    with summary_path.open("w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)
    print(f"Saved {len(records)} labeled windows to {OUTPUT_DIR}", flush=True)


if __name__ == "__main__":
    main()
