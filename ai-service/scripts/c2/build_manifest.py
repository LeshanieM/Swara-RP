"""Build a conservative, window-level CASA annotation manifest."""

from __future__ import annotations

import csv
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable

try:
    import cv2
except ImportError as error:  # pragma: no cover - dependency is declared by ai-service
    raise SystemExit(f"OpenCV is required to determine video durations: {error}")


SERVICE_ROOT = Path(__file__).resolve().parents[2]
CASA_ROOT = SERVICE_ROOT / "data" / "casa"
PROCESSED_ROOT = CASA_ROOT / "processed"
MANIFEST_PATH = PROCESSED_ROOT / "manifest.csv"
SUMMARY_PATH = PROCESSED_ROOT / "manifest_summary.json"
TASKS = ("interview", "reading")
RATERS = ("A1", "A2", "A3")
WINDOW_MS = 2_000
STRIDE_MS = 500
VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv"}
FIELDNAMES = ["task", "media_file", "participant_id", "window_start_ms",
              "window_end_ms", "FG", "HM", "mask", "mask_reason"]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def parse_time(value: str, *, path: Path, line_no: int) -> int:
    try:
        number = float(value)
    except (TypeError, ValueError) as error:
        raise ValueError(f"Invalid timestamp in {path} at CSV row {line_no}: {value!r}") from error
    if not number.is_integer():
        raise ValueError(f"Non-integer millisecond timestamp in {path} at CSV row {line_no}: {value!r}")
    return int(number)


def parse_binary(value: str, *, path: Path, line_no: int, column: str) -> int:
    try:
        number = int(value)
    except (TypeError, ValueError) as error:
        raise ValueError(f"Invalid {column} value in {path} at CSV row {line_no}: {value!r}") from error
    if number not in (0, 1):
        raise ValueError(f"Non-binary {column} value in {path} at CSV row {line_no}: {value!r}")
    return number


def participant_id(media_file: str) -> str:
    match = re.match(r"^(\d+)", media_file)
    if not match:
        raise ValueError(f"Cannot derive participant ID from media_file {media_file!r}")
    return match.group(1)


def merged_duration(intervals: Iterable[tuple[int, int]]) -> int:
    ordered = sorted(intervals)
    if not ordered:
        return 0
    total = 0
    left, right = ordered[0]
    for next_left, next_right in ordered[1:]:
        if next_left <= right:
            right = max(right, next_right)
        else:
            total += right - left
            left, right = next_left, next_right
    return total + right - left


def overlap_union_ms(start: int, end: int, intervals: Iterable[tuple[int, int]]) -> int:
    clipped = [(max(start, lo), min(end, hi)) for lo, hi in intervals if hi > start and lo < end]
    return merged_duration((lo, hi) for lo, hi in clipped if hi > lo)


def probe_duration_ms(video_path: Path) -> int:
    capture = cv2.VideoCapture(str(video_path))
    try:
        if not capture.isOpened():
            raise RuntimeError(f"Could not open video to determine duration: {video_path}")
        fps = float(capture.get(cv2.CAP_PROP_FPS))
        frame_count = float(capture.get(cv2.CAP_PROP_FRAME_COUNT))
        if fps <= 0 or frame_count <= 0:
            raise RuntimeError(f"Could not determine video duration: {video_path}")
        return int(round(frame_count / fps * 1000))
    finally:
        capture.release()


def load_rater_intervals(annotation_path: Path) -> dict[str, dict[str, list[dict[str, int]]]]:
    """Keep each rater's independently timed intervals for window-level voting."""
    output: dict[str, dict[str, list[dict[str, int]]]] = {
        rater: defaultdict(list) for rater in RATERS
    }
    for line_no, row in enumerate(read_csv(annotation_path), start=2):
        rater = str(row.get("annotator", "")).strip().upper()
        if rater not in RATERS:
            continue
        media_file = str(row.get("media_file", "")).strip()
        if not media_file:
            continue
        start = parse_time(row.get("start", ""), path=annotation_path, line_no=line_no)
        end = parse_time(row.get("end", ""), path=annotation_path, line_no=line_no)
        if start < 0 or end <= start:
            raise ValueError(f"Invalid annotation interval in {annotation_path} at CSV row {line_no}: {start}-{end}")
        output[rater][media_file].append({
            "start": start,
            "end": end,
            "FG": parse_binary(row.get("FG", ""), path=annotation_path,
                               line_no=line_no, column="FG"),
            "HM": parse_binary(row.get("HM", ""), path=annotation_path,
                               line_no=line_no, column="HM"),
        })
    return output


def read_exclusions(path: Path) -> dict[str, list[tuple[int, int]]]:
    by_media: dict[str, list[tuple[int, int]]] = defaultdict(list)
    if not path.is_file():
        return by_media
    rows = read_csv(path)
    raw_ends = []
    for row in rows:
        try:
            raw_ends.append(float(row.get("end", "")))
        except (TypeError, ValueError):
            continue
    if raw_ends:
        max_end = max(raw_ends)
        assert max_end < 1200, (
            f"Unexpected exclusion scale: max end = {max_end}. Expected seconds."
        )
    for line_no, row in enumerate(rows, start=2):
        media_file = str(row.get("media_file", "")).strip()
        if not media_file:
            continue
        try:
            start = int(round(float(row.get("start", "")) * 1000))
            end = int(round(float(row.get("end", "")) * 1000))
        except (TypeError, ValueError) as error:
            raise ValueError(f"Invalid exclusion timestamp in {path} at CSV row {line_no}") from error
        if start < 0 or end <= start:
            raise ValueError(f"Invalid exclusion interval in {path} at CSV row {line_no}: {start}-{end}")
        by_media[media_file].append((start, end))
    return by_media


def make_video_index(video_dir: Path) -> dict[str, Path]:
    index: dict[str, Path] = {}
    if not video_dir.is_dir():
        return index
    for path in sorted(video_dir.iterdir(), key=lambda candidate: candidate.name.casefold()):
        if path.is_file() and path.suffix.casefold() in VIDEO_EXTENSIONS:
            key = path.stem.casefold()
            if key in index:
                raise ValueError(f"Ambiguous video stems in {video_dir}: {index[key].name}, {path.name}")
            index[key] = path
    return index


def rater_window_votes(start: int, end: int,
                       rater_intervals: dict[str, list[dict[str, int]]]
                       ) -> tuple[dict[str, int], dict[str, int]]:
    fg_votes: dict[str, int] = {}
    hm_votes: dict[str, int] = {}
    for rater, intervals in rater_intervals.items():
        overlapping = [row for row in intervals
                       if row["end"] > start and row["start"] < end]
        if not overlapping:
            continue
        fg_votes[rater] = int(any(row["FG"] == 1 for row in overlapping))
        hm_votes[rater] = int(any(row["HM"] == 1 for row in overlapping))
    return fg_votes, hm_votes


def window_labels(start: int, end: int,
                  rater_intervals: dict[str, list[dict[str, int]]],
                  exclusions_ms: list[tuple[int, int]]) -> tuple[int | None, int | None, int, str]:
    exclusion_hits = [(lo, hi) for lo, hi in exclusions_ms if lo < end and hi > start]
    if exclusion_hits:
        return None, None, 0, "exclusion_overlap"

    fg_votes, hm_votes = rater_window_votes(start, end, rater_intervals)
    if not fg_votes:
        return None, None, 0, "no_consensus_overlap"

    def aggregate(votes: dict[str, int]) -> int | None:
        values = list(votes.values())
        if any(value == 1 for value in values):
            return 1
        if all(value == 0 for value in values):
            return 0
        return None

    fg = aggregate(fg_votes)
    hm = aggregate(hm_votes)
    if fg is None or hm is None:
        return None, None, 0, "label_unknown"
    return fg, hm, 1, "usable"


def main() -> None:
    PROCESSED_ROOT.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, str | int]] = []
    per_task: dict[str, dict[str, int]] = {}
    unmatched: dict[str, list[str]] = {}
    rater_interval_counts: dict[str, int] = {}
    mask_reason_counts: dict[str, dict[str, int]] = {}
    exclusions_missing: list[str] = []

    for task in TASKS:
        task_root = CASA_ROOT / task
        annotation_path = task_root / "total_dataset.csv"
        if not annotation_path.is_file():
            raise FileNotFoundError(f"Required annotation CSV is missing: {annotation_path}")
        rater_intervals = load_rater_intervals(annotation_path)
        annotations = {media for by_media in rater_intervals.values() for media in by_media}
        exclusion_path = task_root / "exclusions.csv"
        if not exclusion_path.is_file():
            exclusions_missing.append(task)
        excl_ms = read_exclusions(exclusion_path)
        exclusion_rows = [interval for media_intervals in excl_ms.values()
                          for interval in media_intervals]
        max_exclusion_end_ms = max((end for _, end in exclusion_rows), default=0.0)
        print(f"[exclusions] {task}: rows={len(exclusion_rows)}, "
              f"max_end_ms={max_exclusion_end_ms:.1f}")
        video_index = make_video_index(task_root / "videos")
        video_media = {key: path for key, path in video_index.items()}
        annotation_media_by_fold = {media.casefold(): media for media in annotations}
        matching_keys = sorted(video_media.keys() & annotation_media_by_fold.keys())
        unmatched[task] = sorted(annotation_media_by_fold[key] for key in
                                 annotation_media_by_fold.keys() - video_media.keys())
        total_for_task = usable_for_task = fg_for_task = hm_for_task = both_for_task = 0
        task_reason_counts = {reason: 0 for reason in
                              ("usable", "exclusion_overlap", "no_consensus_overlap", "label_unknown")}
        exclusion_debug_count = 0
        rater_interval_counts[task] = sum(
            len(intervals) for by_media in rater_intervals.values()
            for intervals in by_media.values()
        )
        label_unknown_debug_count = 0

        for key in matching_keys:
            media_file = annotation_media_by_fold[key]
            video_path = video_media[key]
            duration_ms = probe_duration_ms(video_path)
            participant = participant_id(media_file)
            per_video = {
                rater: by_media[media_file]
                for rater, by_media in rater_intervals.items()
                if media_file in by_media
            }
            media_exclusions_ms = excl_ms.get(media_file, [])
            for start in range(0, duration_ms - WINDOW_MS + 1, STRIDE_MS):
                end = start + WINDOW_MS
                fg, hm, mask, mask_reason = window_labels(
                    start, end, per_video, media_exclusions_ms
                )
                if mask_reason == "exclusion_overlap" and exclusion_debug_count < 3:
                    exclusion_hits = [(lo, hi) for lo, hi in media_exclusions_ms
                                      if lo < end and hi > start]
                    hit_start, hit_end = exclusion_hits[0]
                    print(f"DEBUG exclusion: task={task} media={media_file} "
                          f"win=[{start},{end}] exclusion_hits={len(exclusion_hits)} "
                          f"first_hit=[{hit_start},{hit_end}]")
                    exclusion_debug_count += 1
                if mask_reason == "label_unknown" and label_unknown_debug_count < 5:
                    fg_votes, hm_votes = rater_window_votes(start, end, per_video)
                    print(f"DEBUG label_unknown: task={task} media={media_file} "
                          f"win=[{start},{end}] rater_coverage={len(fg_votes)} "
                          f"fg_votes={fg_votes} hm_votes={hm_votes}")
                    label_unknown_debug_count += 1
                record = {"task": task, "media_file": media_file,
                          "participant_id": participant, "window_start_ms": start,
                          "window_end_ms": end, "FG": "" if fg is None else fg,
                          "HM": "" if hm is None else hm, "mask": mask,
                          "mask_reason": mask_reason}
                records.append(record)
                total_for_task += 1
                task_reason_counts[mask_reason] += 1
                if mask:
                    usable_for_task += 1
                    fg_for_task += int(fg == 1)
                    hm_for_task += int(hm == 1)
                    both_for_task += int(fg == 1 and hm == 1)

        mask_reason_counts[task] = task_reason_counts
        per_task[task] = {"total_windows": total_for_task,
                          "masked_count": total_for_task - usable_for_task,
                          "usable_count": usable_for_task, "FG_positive_count": fg_for_task,
                          "HM_positive_count": hm_for_task, "both_positive_count": both_for_task,
                          "matched_videos": len(matching_keys),
                          "annotated_media_without_video": len(unmatched[task]),
                          "rater_interval_count": rater_interval_counts[task]}

    with MANIFEST_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(records)

    usable_records = [row for row in records if row["mask"] == 1]
    n_participants_usable = len({str(row["participant_id"]) for row in usable_records})
    summary = {
        "window_length_ms": WINDOW_MS,
        "stride_ms": STRIDE_MS,
        "coverage_threshold": None,
        "consensus_protocol": "Per window, each of A1/A2/A3 with an overlapping interval votes 1 if any of their overlapping intervals is positive for the category, otherwise 0. Category is positive if any covering rater votes 1 and negative if all covering raters vote 0; no covering raters means no_consensus_overlap.",
        "window_policy": "usable if (a) overlaps >= 1 rater interval and (b) does not overlap any exclusion. For each category, each rater votes 1 iff any of that rater's overlapping intervals is positive; otherwise 0. The window label is 1 iff any covering rater votes 1, and 0 iff all covering raters vote 0. Windows with no rater overlap are masked as no_consensus_overlap. No percentage-of-window coverage threshold is applied.",
        "timestamp_units": "total_dataset.csv start/end are milliseconds.",
        "exclusions_units": "seconds_converted_to_milliseconds",
        "participant_id_rule": "Leading digits of media_file.",
        "total_windows": len(records),
        "masked_count": sum(row["mask"] == 0 for row in records),
        "usable_count": len(usable_records),
        "unique_participants": n_participants_usable,
        "n_participants_usable": n_participants_usable,
        "unique_participants_all_windows": len({str(row["participant_id"]) for row in records}),
        "FG_positive_count": sum(row["FG"] == 1 for row in usable_records),
        "HM_positive_count": sum(row["HM"] == 1 for row in usable_records),
        "both_positive_count": sum(row["FG"] == 1 and row["HM"] == 1 for row in usable_records),
        "per_task_usable_counts": {task: per_task[task]["usable_count"] for task in TASKS},
        "per_task": per_task,
        "mask_reasons": mask_reason_counts,
        "exclusions_missing": exclusions_missing,
        "annotated_media_without_video": unmatched,
        "gold_rows_used_for_training_labels": False,
        "aggregation_annotators_discarded": ["bau", "mas", "sad"],
    }
    SUMMARY_PATH.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    print(f"Manifest: {MANIFEST_PATH}")
    print(f"Summary: {SUMMARY_PATH}")
    usable_count = len(usable_records)
    if usable_count == 0:
        raise RuntimeError(f"No usable windows. mask_reasons={mask_reason_counts}")


if __name__ == "__main__":
    main()
