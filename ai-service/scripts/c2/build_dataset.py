"""Build fixed-length, frame-level CASA datasets from manifest windows."""

from __future__ import annotations

import csv
from pathlib import Path
from typing import Any

import numpy as np


SERVICE_ROOT = Path(__file__).resolve().parents[2]
PROCESSED_ROOT = SERVICE_ROOT / "data" / "casa" / "processed"
MANIFEST_PATH = PROCESSED_ROOT / "manifest.csv"
FEATURE_ROOT = PROCESSED_ROOT / "features"
WINDOW_ROOT = PROCESSED_ROOT / "windows"
FPS = 15
WINDOW_LENGTH_MS = 2000
SEQ_LEN = int(WINDOW_LENGTH_MS / 1000 * FPS)
N_BLENDSHAPES = 52
N_POSE = 3
N_FACE_FLAG = 1
N_VELOCITY = 52 + 3
N_FEATURES = N_BLENDSHAPES + N_POSE + N_FACE_FLAG + N_VELOCITY
SPLITS = ("train", "val", "test")


def read_manifest() -> list[dict[str, str]]:
    with MANIFEST_PATH.open("r", newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    required = {"task", "media_file", "participant_id", "window_start_ms",
                "window_end_ms", "FG", "HM", "mask", "split"}
    missing = sorted(required - set(rows[0] if rows else ()))
    if missing:
        raise ValueError(f"Manifest is missing required columns: {missing}")
    return rows


def load_feature_file(path: Path) -> dict[str, np.ndarray]:
    with np.load(path, allow_pickle=False) as data:
        result = {name: data[name] for name in (
            "blendshapes", "head_pose", "face_present", "timestamps_ms", "fps")}
    if int(result["fps"]) != FPS:
        raise ValueError(f"Expected {FPS} FPS in {path}, got {int(result['fps'])}")
    if result["blendshapes"].ndim != 2 or result["blendshapes"].shape[1] != N_BLENDSHAPES:
        raise ValueError(f"Invalid blendshape shape in {path}: {result['blendshapes'].shape}")
    if result["head_pose"].shape != (len(result["blendshapes"]), N_POSE):
        raise ValueError(f"Invalid head-pose shape in {path}: {result['head_pose'].shape}")
    if result["face_present"].shape != (len(result["blendshapes"]),):
        raise ValueError(f"Invalid face_present shape in {path}: {result['face_present'].shape}")
    if result["timestamps_ms"].shape != (len(result["blendshapes"]),):
        raise ValueError(f"Invalid timestamp shape in {path}: {result['timestamps_ms'].shape}")
    return result


def window_features(feature_data: dict[str, np.ndarray], start_ms: int,
                    end_ms: int) -> tuple[np.ndarray, np.ndarray]:
    timestamps = feature_data["timestamps_ms"]
    selection = (timestamps >= start_ms) & (timestamps < end_ms)
    blendshapes = feature_data["blendshapes"][selection].astype(np.float32, copy=True)
    pose = feature_data["head_pose"][selection].astype(np.float32, copy=True)
    face = feature_data["face_present"][selection].astype(np.float32, copy=False)

    if len(blendshapes) > SEQ_LEN:
        offset = (len(blendshapes) - SEQ_LEN) // 2
        blendshapes = blendshapes[offset:offset + SEQ_LEN]
        pose = pose[offset:offset + SEQ_LEN]
        face = face[offset:offset + SEQ_LEN]

    # Missing face/pose values are represented by zeros; face_present remains an
    # explicit channel, and zero-filling before differencing prevents NaN velocity.
    blendshapes = np.nan_to_num(blendshapes, nan=0.0, posinf=0.0, neginf=0.0)
    pose = np.nan_to_num(pose, nan=0.0, posinf=0.0, neginf=0.0)
    face = np.nan_to_num(face, nan=0.0, posinf=0.0, neginf=0.0)

    velocity_blendshapes = np.diff(
        blendshapes, axis=0,
        prepend=np.zeros((1, N_BLENDSHAPES), dtype=np.float32),
    )
    velocity_pose = np.diff(
        pose, axis=0,
        prepend=np.zeros((1, N_POSE), dtype=np.float32),
    )
    frames = np.concatenate(
        [blendshapes, pose, face[:, None], velocity_blendshapes, velocity_pose], axis=1
    ).astype(np.float32, copy=False)
    if frames.shape[1] != N_FEATURES:
        raise AssertionError(f"Expected {N_FEATURES} channels, received {frames.shape[1]}")

    frame_mask = np.zeros(SEQ_LEN, dtype=np.bool_)
    frame_mask[:len(frames)] = True
    padded = np.zeros((SEQ_LEN, N_FEATURES), dtype=np.float32)
    padded[:len(frames)] = frames
    return padded, frame_mask


def build_split(split: str, rows: list[dict[str, str]], cache: dict[tuple[str, str, str], dict[str, np.ndarray]]) -> dict[str, Any]:
    selected_rows = [row for row in rows
                     if row["split"].strip() == split and row["mask"].strip() == "1"]
    n_samples = len(selected_rows)
    x = np.zeros((n_samples, SEQ_LEN, N_FEATURES), dtype=np.float32)
    frame_mask = np.zeros((n_samples, SEQ_LEN), dtype=np.bool_)
    y = np.zeros((n_samples, 2), dtype=np.float32)
    participant_ids = np.empty(n_samples, dtype=object)
    tasks = np.empty(n_samples, dtype=object)
    media_files = np.empty(n_samples, dtype=object)
    starts = np.empty(n_samples, dtype=np.int32)
    ends = np.empty(n_samples, dtype=np.int32)

    for index, row in enumerate(selected_rows):
        task = row["task"].strip()
        media_file = row["media_file"].strip()
        key = (split, task, media_file)
        if key not in cache:
            path = FEATURE_ROOT / split / task / f"{media_file}.npz"
            if not path.is_file():
                raise FileNotFoundError(f"Missing feature file for manifest window: {path}")
            cache[key] = load_feature_file(path)
        start_ms = int(row["window_start_ms"])
        end_ms = int(row["window_end_ms"])
        x[index], frame_mask[index] = window_features(cache[key], start_ms, end_ms)
        y[index] = (int(row["FG"]), int(row["HM"]))
        participant_ids[index] = row["participant_id"].strip()
        tasks[index] = task
        media_files[index] = media_file
        starts[index] = start_ms
        ends[index] = end_ms

    output_path = WINDOW_ROOT / f"{split}.npz"
    WINDOW_ROOT.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(
        output_path,
        X=x,
        frame_mask=frame_mask,
        y=y,
        participant_id=participant_ids,
        task=tasks,
        media_file=media_files,
        window_start_ms=starts,
        window_end_ms=ends,
    )
    return {
        "path": output_path,
        "X": x,
        "frame_mask": frame_mask,
        "y": y,
        "participants": participant_ids,
        "tasks": tasks,
    }


def main() -> int:
    if SEQ_LEN != 30:
        raise AssertionError(f"Expected SEQ_LEN=30, got {SEQ_LEN}")
    rows = read_manifest()
    cache: dict[tuple[str, str, str], dict[str, np.ndarray]] = {}
    outputs = {split: build_split(split, rows, cache) for split in SPLITS}

    participant_sets = {
        split: set(outputs[split]["participants"].tolist()) for split in SPLITS
    }
    overlaps = {
        "train_val": participant_sets["train"] & participant_sets["val"],
        "train_test": participant_sets["train"] & participant_sets["test"],
        "val_test": participant_sets["val"] & participant_sets["test"],
    }
    if any(overlaps.values()):
        raise AssertionError(f"Participant overlap across splits: {overlaps}")

    print("=== Windowed dataset ===")
    for split in SPLITS:
        result = outputs[split]
        x = result["X"]
        mask = result["frame_mask"]
        y = result["y"]
        if x.shape[1:] != (30, 111):
            raise AssertionError(f"{split} X shape is {x.shape}, expected (N, 30, 111)")
        if np.isnan(x[mask]).any() or not np.isfinite(x[mask]).all():
            raise AssertionError(f"{split} contains NaN or infinite X values at unpadded frames")
        if not np.isin(y, (0.0, 1.0)).all():
            raise AssertionError(f"{split} contains non-binary labels")
        print(f"{split}: X={x.shape} mask={mask.shape} y={y.shape}  "
              f"FG+ {int(y[:, 0].sum())}  HM+ {int(y[:, 1].sum())}  "
              f"participants {len(participant_sets[split])}")
        print(f"  saved: {result['path']}")
    print("Feature channels: 52 blendshapes + 3 head pose + 1 face_present + 55 velocity = 111")
    print("All assertions passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
