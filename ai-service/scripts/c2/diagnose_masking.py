"""Diagnose annotation coverage and exclusion scaling behind a masked manifest."""

from __future__ import annotations

import csv
from pathlib import Path
from statistics import median
from collections import defaultdict


SERVICE_ROOT = Path(__file__).resolve().parents[2]
CASA_ROOT = SERVICE_ROOT / "data" / "casa"
TASKS = ("interview", "reading")
RATERS = {"A1", "A2", "A3"}
WINDOWS = ((0, 2000), (500, 2500), (1000, 3000))


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def values(rows: list[dict[str, str]], column: str) -> list[float]:
    out = []
    for row in rows:
        try:
            out.append(float(row[column]))
        except (KeyError, TypeError, ValueError):
            pass
    return out


def describe(label: str, vals: list[float]) -> str:
    if not vals:
        return f"{label}: no numeric values"
    return (f"{label}: min={min(vals):g}, max={max(vals):g}, "
            f"median={median(vals):g}")


def merged_duration(intervals: list[tuple[float, float]]) -> float:
    valid = sorted((lo, hi) for lo, hi in intervals if hi > lo)
    if not valid:
        return 0.0
    total = 0.0
    left, right = valid[0]
    for next_left, next_right in valid[1:]:
        if next_left <= right:
            right = max(right, next_right)
        else:
            total += right - left
            left, right = next_left, next_right
    return total + right - left


def overlap_duration(start: float, end: float,
                     intervals: list[tuple[float, float]]) -> float:
    clipped = [(max(start, lo), min(end, hi)) for lo, hi in intervals
               if lo < end and hi > start]
    return merged_duration(clipped)


def annotate_task(task: str) -> dict:
    task_root = CASA_ROOT / task
    annotation_path = task_root / "total_dataset.csv"
    exclusion_path = task_root / "exclusions.csv"
    if not annotation_path.is_file():
        print(f"\n===== {task.upper()} =====\nMISSING annotation CSV: {annotation_path}")
        return {"missing": True}

    annotations = read_rows(annotation_path)
    start_values = values(annotations, "start")
    end_values = values(annotations, "end")
    print(f"\n===== {task.upper()} =====")
    print("Timestamp scale check:")
    print("  " + describe("total_dataset.csv start", start_values))
    print("  " + describe("total_dataset.csv end", end_values))

    if exclusion_path.is_file():
        exclusions = read_rows(exclusion_path)
        ex_starts = values(exclusions, "start")
        ex_ends = values(exclusions, "end")
        print(f"  exclusions.csv: {exclusion_path}")
        print("  " + describe("exclusions.csv start", ex_starts))
        print("  " + describe("exclusions.csv end", ex_ends))
        annotation_end_max = max(end_values, default=float("nan"))
        ex_max = max(ex_ends, default=float("nan"))
        h1_seconds = bool(ex_ends and annotation_end_max > 0 and ex_max < annotation_end_max / 10)
        scale = 1000.0 if h1_seconds else 1.0
        print("  Scale comment: exclusions appear to be " +
              ("seconds by comparison with annotation timestamps; convert to milliseconds with x1000." if scale == 1000
               else "milliseconds (max is not < 1000); no seconds conversion indicated."))
        print(f"  H1: exclusions appear to be in seconds = {h1_seconds} "
              f"(max exclusions.end={ex_max:g}, max total_dataset.end={annotation_end_max:g})")
        ex_by_media: dict[str, list[tuple[float, float]]] = defaultdict(list)
        for row in exclusions:
            try:
                lo, hi = float(row["start"]) * scale, float(row["end"]) * scale
            except (KeyError, ValueError, TypeError):
                continue
            if hi > lo:
                ex_by_media[str(row.get("media_file", "")).strip()].append((lo, hi))
    else:
        exclusions = []
        ex_starts, ex_ends = [], []
        scale = 1.0
        h1_seconds = False
        ex_by_media = defaultdict(list)
        print(f"  exclusions.csv: MISSING ({exclusion_path})")
        print("  exclusions.csv start/end: no values")
        print("  Scale comment: unavailable because exclusions.csv is missing.")

    ends_by_media: dict[str, list[float]] = defaultdict(list)
    rater_intervals: dict[str, list[tuple[float, float]]] = defaultdict(list)
    for row in annotations:
        media = str(row.get("media_file", "")).strip()
        try:
            lo, hi = float(row["start"]), float(row["end"])
        except (KeyError, ValueError, TypeError):
            continue
        if media and hi > lo:
            ends_by_media[media].append(hi)
            if str(row.get("annotator", "")).strip().upper() in RATERS:
                rater_intervals[media].append((lo, hi))

    video_ends = {media: max(ends) for media, ends in ends_by_media.items() if ends}
    exclusion_ratios = []
    exclusion_ratios_x1000 = []
    for media, video_end in video_ends.items():
        duration = merged_duration(ex_by_media.get(media, []))
        exclusion_ratios.append((media, duration / video_end if video_end > 0 else 0.0,
                                 duration, video_end))
        duration_x1000 = merged_duration([(lo * 1000, hi * 1000)
                                          for lo, hi in ex_by_media.get(media, [])])
        exclusion_ratios_x1000.append((media, duration_x1000 / video_end if video_end > 0 else 0.0,
                                       duration_x1000, video_end))
    exclusion_ratios.sort(key=lambda item: item[1], reverse=True)
    exclusion_ratios_x1000.sort(key=lambda item: item[1], reverse=True)
    ex_ratio_values = [item[1] for item in exclusion_ratios]
    print("\nExclusion coverage per video (duration uses merged exclusion intervals / max annotated end):")
    if exclusion_ratios:
        print("  10 highest exclusion ratios:")
        for media, ratio, duration, video_end in exclusion_ratios[:10]:
            print(f"    {media}: {ratio:.3%} ({duration:.0f} / {video_end:.0f} ms)")
        print(f"  Mean exclusion ratio: {sum(ex_ratio_values)/len(ex_ratio_values):.3%}")
        print(f"  Videos with exclusions >90%: {sum(ratio > .9 for ratio in ex_ratio_values)}")
        print(f"  Videos with exclusions >50%: {sum(ratio > .5 for ratio in ex_ratio_values)}")
        if scale != 1000 and exclusions:
            alt_values = [item[1] for item in exclusion_ratios_x1000]
            print("  If raw exclusion values are seconds (x1000):")
            print(f"    Mean exclusion ratio: {sum(alt_values)/len(alt_values):.3%}")
            print(f"    Videos with exclusions >90%: {sum(ratio > .9 for ratio in alt_values)}")
            print(f"    Videos with exclusions >50%: {sum(ratio > .5 for ratio in alt_values)}")
    else:
        print("  No videos with valid annotated end times.")

    coverage = []
    unique_interval_lengths = set()
    for media, video_end in video_ends.items():
        intervals = rater_intervals.get(media, [])
        for lo, hi in intervals:
            unique_interval_lengths.add((lo, hi))
        duration = merged_duration(intervals)
        coverage.append((media, duration / video_end if video_end > 0 else 0.0,
                         duration, video_end))
    coverage.sort(key=lambda item: item[1])
    coverage_values = [item[1] for item in coverage]
    print("\nConsensus coverage per video (union of all A1/A2/A3 intervals / max annotated end):")
    if coverage:
        print("  10 lowest consensus coverage values:")
        for media, ratio, duration, video_end in coverage[:10]:
            print(f"    {media}: {ratio:.3%} ({duration:.0f} / {video_end:.0f} ms)")
        print(f"  Mean consensus coverage: {sum(coverage_values)/len(coverage_values):.3%}")
        print(f"  Videos with consensus coverage <10%: {sum(ratio < .1 for ratio in coverage_values)}")
        print(f"  Videos with consensus coverage >=99%: {sum(ratio >= .99 for ratio in coverage_values)}")
        median_coverage = median(coverage_values)
    else:
        median_coverage = float("nan")
        print("  No videos with valid annotated end times.")

    print("\nManual trace (alphabetically first media_file; union coverage shown, plus summed rater overlap):")
    if video_ends:
        first_media = sorted(video_ends, key=str.casefold)[0]
        intervals = rater_intervals.get(first_media, [])
        media_exclusions = ex_by_media.get(first_media, [])
        print(f"  media_file={first_media}")
        for start, end in WINDOWS:
            overlapping = [(lo, hi) for lo, hi in intervals if lo < end and hi > start]
            union_ms = overlap_duration(start, end, overlapping)
            summed_ms = sum(max(0.0, min(end, hi) - max(start, lo)) for lo, hi in overlapping)
            exclusion_count = sum(lo < end and hi > start for lo, hi in media_exclusions)
            exclusion_count_x1000 = sum(lo * 1000 < end and hi * 1000 > start
                                        for lo, hi in media_exclusions)
            coverage_ok = union_ms >= 1800
            if exclusion_count_x1000:
                verdict = "MASKED by overlapping exclusion interval(s)."
            elif not coverage_ok:
                verdict = f"MASKED by insufficient union rater coverage ({union_ms:.0f} ms < 1800 ms)."
            else:
                verdict = "Passes the stated 90% coverage and exclusion checks."
            print(f"  [{start},{end}] ms: overlapping rater intervals={len(overlapping)}, "
                  f"union rater coverage={union_ms:.0f} ms, summed overlap={summed_ms:.0f} ms, "
                  f"required=1800 ms, overlapping exclusions={exclusion_count} under scale x{scale:g} "
                  f"(x1000 interpretation: {exclusion_count_x1000}); {verdict}")
    else:
        print("  No annotated media available for trace.")

    durations = [hi - lo for lo, hi in unique_interval_lengths]
    h1 = h1_seconds
    total_video_duration = sum(video_ends.values())
    total_exclusion_duration = sum(merged_duration(ex_by_media.get(media, []))
                                   for media in video_ends)
    total_exclusion_duration_x1000 = sum(
        merged_duration([(lo * 1000, hi * 1000) for lo, hi in ex_by_media.get(media, [])])
        for media in video_ends
    )
    h2_ratio = (total_exclusion_duration_x1000 if scale != 1000
                else total_exclusion_duration) / total_video_duration if total_video_duration else 0.0
    h2 = h2_ratio > .5
    h3 = median_coverage < .9 if coverage_values else False
    h4 = median(durations) < 500 if durations else False
    print("\nSpecific hypothesis tests:")
    if not exclusions:
        print("  H1: exclusions appear to be in seconds = False (exclusions.csv missing)")
    print(f"  H2: Do exclusions cover >50% of total timeline? {'YES' if h2 else 'NO'} "
          f"(using {'x1000' if scale == 1000 else 'x1'} scale, merged exclusion duration / total video duration = {h2_ratio:.3%})")
    if exclusions and scale != 1000:
        alt_h2_ratio = total_exclusion_duration / total_video_duration if total_video_duration else 0.0
        print(f"    Alternate if exclusions are already milliseconds (x1): {alt_h2_ratio:.3%} "
              f"({'YES' if alt_h2_ratio > .5 else 'NO'} for >50%).")
    print(f"  H3: Is 90% coverage threshold too strict? {'YES' if h3 else 'NO'} "
          f"(median per-video consensus coverage = {median_coverage:.3%})")
    median_interval = median(durations) if durations else float("nan")
    print(f"  H4: Are consensus intervals extremely short (<500 ms median)? {'YES' if h4 else 'NO'} "
          f"(median unique A1/A2/A3 interval duration = {median_interval:.1f} ms)")
    print("  Note: H2 uses annotated max-end timeline durations and merged exclusions, not probed video durations.")
    return {"missing": False}


def main() -> None:
    for task in TASKS:
        annotate_task(task)


if __name__ == "__main__":
    main()
