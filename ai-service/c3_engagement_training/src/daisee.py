"""DAiSEE label and split utilities.

The official dataset distributes TrainLabels.csv, ValidationLabels.csv and
TestLabels.csv.  Their Engagement column is ordinal: 0=very low, 1=low,
2=high and 3=very high.  This module deliberately makes a binary conversion
an explicit experiment choice instead of silently treating it as ground truth.
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

import pandas as pd


SPLITS = ("Train", "Validation", "Test")
VIDEO_SUFFIXES = (".avi", ".mp4", ".mov", ".mkv")


def read_official_labels(labels_root: Path, split: str) -> pd.DataFrame:
    """Load one official DAiSEE split, accepting the common file-name casing."""
    candidates = [
        labels_root / f"{split}Labels.csv",
        labels_root / f"{split.lower()}Labels.csv",
        labels_root / f"{split.lower()}_labels.csv",
    ]
    label_file = next((path for path in candidates if path.exists()), None)
    if label_file is None:
        names = ", ".join(path.name for path in candidates)
        raise FileNotFoundError(f"Could not find {split} labels in {labels_root}. Tried: {names}")

    frame = pd.read_csv(label_file)
    normalized = {column.strip().lower(): column for column in frame.columns}
    clip_column = next(
        (normalized[name] for name in ("clipid", "clip_id", "clip") if name in normalized), None
    )
    engagement_column = normalized.get("engagement")
    if clip_column is None or engagement_column is None:
        raise ValueError(
            f"{label_file.name} must contain ClipID and Engagement columns; found {list(frame.columns)}"
        )

    result = frame.rename(columns={clip_column: "clip_id", engagement_column: "engagement_level"})[
        ["clip_id", "engagement_level"]
    ].copy()
    # Official DAiSEE label files store ClipID values such as
    # ``1100011002.avi`` while the video index naturally uses the file stem.
    # Normalize only known video extensions so both representations match.
    result["clip_id"] = (
        result["clip_id"].astype(str).str.strip().str.replace(r"\.(avi|mp4|mov|mkv)$", "", regex=True, case=False)
    )
    result["engagement_level"] = pd.to_numeric(result["engagement_level"], errors="raise").astype(int)
    invalid = result.loc[~result["engagement_level"].isin([0, 1, 2, 3])]
    if not invalid.empty:
        raise ValueError(f"Unexpected DAiSEE Engagement values in {label_file}: {invalid.head().to_dict('records')}")
    result["split"] = split.lower()
    return result


def make_binary_target(labels: pd.DataFrame, positive_min_level: int) -> pd.DataFrame:
    """Add binary_engaged, with 0/1 below threshold and threshold..3 above it."""
    if positive_min_level not in (1, 2, 3):
        raise ValueError("positive_min_level must be 1, 2, or 3")
    result = labels.copy()
    result["binary_engaged"] = (result["engagement_level"] >= positive_min_level).astype(int)
    return result


def locate_video(videos_root: Path, split: str, clip_id: str) -> Path | None:
    """Find a clip in common official layouts without assuming one layout."""
    direct_roots: Iterable[Path] = (
        videos_root / split,
        videos_root / split.lower(),
        videos_root,
    )
    for root in direct_roots:
        if not root.exists():
            continue
        for suffix in VIDEO_SUFFIXES:
            direct = root / f"{clip_id}{suffix}"
            if direct.exists():
                return direct
        matches = [
            path for path in root.rglob("*")
            if path.is_file() and path.stem == clip_id and path.suffix.lower() in VIDEO_SUFFIXES
        ]
        if matches:
            return matches[0]
    return None


def subject_from_video_path(video_path: Path) -> str:
    """Read the participant folder from the official split/subject/clip layout.

    DAiSEE.zip stores videos as ``DataSet/Train/<subject>/<clip>/<clip>.avi``.
    We deliberately do not infer a participant ID by slicing the clip filename.
    """
    split_names = {"train", "validation", "test"}
    for ancestor in video_path.parents:
        if ancestor.name.lower() in split_names:
            relative = video_path.relative_to(ancestor)
            if len(relative.parts) >= 3:
                return relative.parts[0]
    raise ValueError(
        f"Cannot identify the participant folder for {video_path}. Expected a Train/Validation/Test parent folder."
    )
