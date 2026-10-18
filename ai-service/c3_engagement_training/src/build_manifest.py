"""Create a private manifest linking official labels to local DAiSEE videos."""

from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd

from .daisee import SPLITS, VIDEO_SUFFIXES, make_binary_target, read_official_labels, subject_from_video_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Build DAiSEE clip manifests from official labels and local videos.")
    parser.add_argument("--labels-root", type=Path, required=True, help="Folder containing TrainLabels.csv etc.")
    parser.add_argument("--videos-root", type=Path, required=True, help="Root of the downloaded DAiSEE video folders.")
    parser.add_argument("--output-dir", type=Path, default=Path("manifests"))
    parser.add_argument(
        "--positive-min-level", type=int, default=2,
        help="Binary label policy: level >= this is engaged. Default 2 means high/very high.",
    )
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    # Index once: the official archive contains thousands of clips nested below
    # participant/clip folders, so recursively searching once per label is too slow.
    video_index = {
        path.stem: path
        for path in args.videos_root.rglob("*")
        if path.is_file() and path.suffix.lower() in VIDEO_SUFFIXES
    }
    if not video_index:
        raise FileNotFoundError(f"No DAiSEE videos found below {args.videos_root}")
    all_rows: list[pd.DataFrame] = []
    for split in SPLITS:
        labels = make_binary_target(read_official_labels(args.labels_root, split), args.positive_min_level)
        labels["positive_min_level"] = args.positive_min_level
        paths = labels["clip_id"].map(video_index.get)
        missing = labels.loc[paths.isna(), "clip_id"]
        if not missing.empty:
            raise FileNotFoundError(
                f"{split}: {len(missing)} labelled clips were not found below {args.videos_root}. "
                f"Examples: {missing.head(5).tolist()}"
            )
        labels["video_path"] = paths.map(lambda path: str(path.resolve()))
        labels["subject_id"] = paths.map(lambda path: subject_from_video_path(path))
        labels.to_csv(args.output_dir / f"{split.lower()}.csv", index=False)
        all_rows.append(labels)
        counts = labels["binary_engaged"].value_counts().to_dict()
        print(f"{split}: {len(labels)} clips; binary counts {counts}")

    combined = pd.concat(all_rows, ignore_index=True)
    subject_splits = combined.groupby("subject_id")["split"].nunique()
    overlaps = subject_splits[subject_splits > 1]
    if not overlaps.empty:
        raise ValueError(
            "Official split folders are not subject-disjoint according to their participant directory names. "
            f"Do not report this as subject-safe. Example overlapping identifiers: {overlaps.head().to_dict()}"
        )
    combined.to_csv(args.output_dir / "all.csv", index=False)
    print("Subject-safety check passed: no participant folders appear in more than one official split.")


if __name__ == "__main__":
    main()
