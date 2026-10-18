"""Exclude decoder-failed videos and participant 508 from the CASA manifest."""

from __future__ import annotations

import csv
import json
from collections import defaultdict
from pathlib import Path
from typing import Any


SERVICE_ROOT = Path(__file__).resolve().parents[2]
PROCESSED_ROOT = SERVICE_ROOT / "data" / "casa" / "processed"
MANIFEST_PATH = PROCESSED_ROOT / "manifest.csv"
FAILED_PATH = PROCESSED_ROOT / "features" / "failed_videos.json"
FEATURE_ROOT = PROCESSED_ROOT / "features"
EXCLUDED_VIDEOS = {
    ("interview", "29mc"): "decoder failure at 162133 ms",
    ("reading", "29mc"): "decoder failure at 162133 ms",
    ("interview", "503"): "decoder failure at 67467 ms",
    ("reading", "503"): "decoder failure at 67467 ms",
}
EXCLUDED_PARTICIPANTS = {
    "508": "48.9% face-detection validity; only 25 windows; 0 FG positives",
}


def read_rows(path: Path) -> tuple[list[dict[str, str]], list[str]]:
    with path.open("r", newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        fields = list(reader.fieldnames or [])
    return rows, fields


def is_usable(row: dict[str, str]) -> bool:
    return row.get("mask", "").strip() == "1"


def main() -> int:
    if not MANIFEST_PATH.is_file():
        raise SystemExit(f"Missing manifest: {MANIFEST_PATH}")
    if not FAILED_PATH.is_file():
        raise SystemExit(f"Missing extraction failure report: {FAILED_PATH}")

    try:
        failure_records: list[dict[str, Any]] = json.loads(FAILED_PATH.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, TypeError) as error:
        raise SystemExit(f"Invalid failure report {FAILED_PATH}: {error}") from error

    failed_keys = {
        (str(record.get("task", "")).strip().casefold(),
         str(record.get("media_file", "")).strip().casefold())
        for record in failure_records
    }
    requested_keys = {(task.casefold(), media.casefold()) for task, media in EXCLUDED_VIDEOS}
    missing_from_failures = sorted(requested_keys - failed_keys)
    if missing_from_failures:
        print(f"DISCREPANCY: requested videos are not in failed_videos.json: {missing_from_failures}")
        return 1

    # A feature file for a reported failure is evidence that the failure report and
    # on-disk outputs disagree; stop before changing the manifest.
    discrepancies = []
    for record in failure_records:
        task = str(record.get("task", "")).strip()
        media_file = str(record.get("media_file", "")).strip()
        split = str(record.get("split", "")).strip()
        if not task or not media_file:
            continue
        candidate_paths = ([FEATURE_ROOT / split / task / f"{media_file}.npz"] if split else
                           list(FEATURE_ROOT.glob(f"*/{task}/{media_file}.npz")))
        found = [path for path in candidate_paths if path.is_file()]
        if found:
            discrepancies.append({"task": task, "media_file": media_file,
                                  "feature_files": [str(path) for path in found]})
    if discrepancies:
        print("DISCREPANCY: failed_videos.json entries have feature files; manifest was not changed:")
        print(json.dumps(discrepancies, indent=2))
        return 1

    rows, fields = read_rows(MANIFEST_PATH)
    required = {"task", "media_file", "participant_id", "split", "mask", "FG", "HM"}
    missing = sorted(required - set(fields))
    if missing:
        print(f"Manifest missing required columns: {missing}")
        return 1

    kept: list[dict[str, str]] = []
    removed: list[dict[str, str]] = []
    for row in rows:
        video_key = (row["task"].strip().casefold(), row["media_file"].strip().casefold())
        pid = row["participant_id"].strip()
        if video_key in requested_keys or pid in EXCLUDED_PARTICIPANTS:
            removed.append(row)
        else:
            kept.append(row)

    feature_missing = []
    media_keys = {(row["split"].strip(), row["task"].strip(), row["media_file"].strip())
                  for row in kept}
    for split, task, media_file in sorted(media_keys):
        feature_path = FEATURE_ROOT / split / task / f"{media_file}.npz"
        if not feature_path.is_file():
            feature_missing.append({"split": split, "task": task,
                                    "media_file": media_file, "expected": str(feature_path)})
    if feature_missing:
        print("ASSERTION FAILURE: remaining manifest media without extracted features:")
        print(json.dumps(feature_missing, indent=2))
        return 1

    split_pids = {split: {row["participant_id"].strip() for row in kept
                          if row["split"].strip() == split and is_usable(row)}
                  for split in ("train", "val", "test")}
    overlaps = {
        "train_val": sorted(split_pids["train"] & split_pids["val"]),
        "train_test": sorted(split_pids["train"] & split_pids["test"]),
        "val_test": sorted(split_pids["val"] & split_pids["test"]),
    }
    split_metrics: dict[str, dict[str, int]] = {}
    for split in ("train", "val", "test"):
        usable = [row for row in kept if row["split"].strip() == split and is_usable(row)]
        split_metrics[split] = {
            "n_windows": len(usable),
            "n_participants": len({row["participant_id"].strip() for row in usable}),
            "FG_pos": sum(row["FG"].strip() == "1" for row in usable),
            "HM_pos": sum(row["HM"].strip() == "1" for row in usable),
        }
    failures = []
    if any(overlaps.values()):
        failures.append(f"participant overlap: {overlaps}")
    if split_metrics["test"]["n_windows"] < 2000:
        failures.append(f"test usable windows={split_metrics['test']['n_windows']} < 2000")
    if split_metrics["test"]["FG_pos"] < 20:
        failures.append(f"test FG+={split_metrics['test']['FG_pos']} < 20")
    if split_metrics["test"]["HM_pos"] < 10:
        failures.append(f"test HM+={split_metrics['test']['HM_pos']} < 10")
    if failures:
        print("ASSERTION FAILURE: " + "; ".join(failures))
        print("Counts:", json.dumps(split_metrics, sort_keys=True))
        return 1

    PROCESSED_ROOT.mkdir(parents=True, exist_ok=True)
    with MANIFEST_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(kept)

    removed_video_keys = {
        (row["task"].strip().casefold(), row["media_file"].strip().casefold())
        for row in removed
        if (row["task"].strip().casefold(), row["media_file"].strip().casefold()) in requested_keys
    }
    removed_participant_ids = {row["participant_id"].strip() for row in removed}
    usable_removed = sum(is_usable(row) for row in removed)
    usable_remaining = sum(is_usable(row) for row in kept)
    report = {
        "excluded_videos": [
            {"task": task, "media_file": media_file, "reason": reason}
            for (task, media_file), reason in EXCLUDED_VIDEOS.items()
        ],
        "excluded_participants": [
            {"participant_id": pid, "reason": reason}
            for pid, reason in EXCLUDED_PARTICIPANTS.items()
        ],
        "windows_removed": len(removed),
        "windows_remaining": len(kept),
        "usable_windows_removed": usable_removed,
        "usable_windows_remaining": usable_remaining,
        "per_split_after": {split: split_metrics[split]["n_windows"] for split in ("train", "val", "test")},
    }
    (PROCESSED_ROOT / "excluded.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(f"Removed: {len(removed)} windows ({len(removed_video_keys)} videos, "
          f"{len(removed_participant_ids)} participants affected; "
          f"{len(EXCLUDED_PARTICIPANTS)} participant excluded)")
    print("Remaining per split:")
    for split in ("train", "val", "test"):
        info = split_metrics[split]
        print(f"  {split}: {info['n_windows']} windows, {info['n_participants']} participants, "
              f"FG+ {info['FG_pos']}, HM+ {info['HM_pos']}")
    print(f"Usable windows removed: {usable_removed}; usable windows remaining: {usable_remaining}")
    print(f"All assertions passed. Exclusion report: {PROCESSED_ROOT / 'excluded.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
