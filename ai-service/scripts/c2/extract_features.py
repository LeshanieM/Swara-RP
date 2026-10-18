"""Extract frame-level MediaPipe Face Landmarker features for CASA videos."""

from __future__ import annotations

import argparse
import csv
import json
import math
import time
from collections import defaultdict
from pathlib import Path
from typing import Any

import cv2
import mediapipe as mp
import numpy as np


SERVICE_ROOT = Path(__file__).resolve().parents[2]
CASA_ROOT = SERVICE_ROOT / "data" / "casa"
PROCESSED_ROOT = CASA_ROOT / "processed"
MANIFEST_PATH = PROCESSED_ROOT / "manifest.csv"
FEATURE_ROOT = PROCESSED_ROOT / "features"
MODEL_PATH = SERVICE_ROOT / "models" / "mediapipe" / "face_landmarker.task"
BLENDSHAPE_NAMES_PATH = FEATURE_ROOT / "blendshape_names.json"
FAILED_PATH = FEATURE_ROOT / "failed_videos.json"
SAMPLE_FPS = 15
VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv"}


def load_manifest() -> list[dict[str, str]]:
    with MANIFEST_PATH.open("r", newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    required = {"task", "media_file", "split", "mask"}
    missing = required - set(rows[0] if rows else ())
    if missing:
        raise ValueError(f"Manifest is missing required columns: {sorted(missing)}")
    return rows


def video_for(task: str, media_file: str) -> Path:
    video_dir = CASA_ROOT / task / "videos"
    if not video_dir.is_dir():
        raise FileNotFoundError(f"Video directory does not exist: {video_dir}")
    matches = [path for path in video_dir.iterdir()
               if path.is_file() and path.stem.casefold() == media_file.casefold()
               and path.suffix.casefold() in VIDEO_EXTENSIONS]
    if len(matches) != 1:
        raise FileNotFoundError(f"Expected one video for {task}/{media_file}; found {len(matches)} in {video_dir}")
    return matches[0]


def euler_pitch_yaw_roll(matrix: Any) -> np.ndarray:
    transform = np.asarray(matrix, dtype=np.float64)
    if transform.size != 16:
        raise ValueError(f"Expected a 4x4 facial transform, got shape {transform.shape}")
    rotation = transform.reshape(4, 4)[:3, :3]
    # Euler decomposition for R = Rz(roll) * Ry(yaw) * Rx(pitch).
    sy = math.sqrt(rotation[0, 0] ** 2 + rotation[1, 0] ** 2)
    singular = sy < 1e-8
    if not singular:
        pitch = math.atan2(rotation[2, 1], rotation[2, 2])
        yaw = math.atan2(-rotation[2, 0], sy)
        roll = math.atan2(rotation[1, 0], rotation[0, 0])
    else:
        pitch = math.atan2(-rotation[1, 2], rotation[1, 1])
        yaw = math.atan2(-rotation[2, 0], sy)
        roll = 0.0
    return np.asarray([pitch, yaw, roll], dtype=np.float32)


def make_landmarker() -> tuple[Any, Any]:
    if not MODEL_PATH.is_file():
        raise FileNotFoundError(f"Required MediaPipe model is missing: {MODEL_PATH}")
    options = mp.tasks.vision.FaceLandmarkerOptions(
        base_options=mp.tasks.BaseOptions(model_asset_path=str(MODEL_PATH)),
        running_mode=mp.tasks.vision.RunningMode.VIDEO,
        num_faces=1,
        output_face_blendshapes=True,
        output_facial_transformation_matrixes=True,
    )
    return mp.tasks.vision.FaceLandmarker.create_from_options(options), mp


def extract_video(video_path: Path, landmarker: Any) -> tuple[dict[str, np.ndarray], list[str]]:
    capture = cv2.VideoCapture(str(video_path))
    try:
        if not capture.isOpened():
            raise RuntimeError("OpenCV could not open the video")
        source_fps = float(capture.get(cv2.CAP_PROP_FPS))
        frame_count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT))
        if source_fps <= 0 or frame_count <= 0:
            raise RuntimeError(f"Invalid source video metadata: fps={source_fps}, frames={frame_count}")
        duration_ms = frame_count / source_fps * 1000.0
        timestamps = np.arange(0.0, duration_ms, 1000.0 / SAMPLE_FPS)
        timestamps_ms = np.rint(timestamps).astype(np.int32)
        target_frame_indices = np.rint(timestamps * source_fps / 1000.0).astype(np.int64)
        in_video = target_frame_indices < frame_count
        timestamps_ms = timestamps_ms[in_video]
        target_frame_indices = target_frame_indices[in_video]
        if not len(timestamps_ms):
            raise RuntimeError("Video is too short to produce any 15 FPS samples")

        blendshape_rows: list[np.ndarray] = []
        pose_rows: list[np.ndarray] = []
        face_rows: list[int] = []
        landmark_rows: list[int] = []
        confidence_rows: list[float] = []
        blendshape_names: list[str] = []

        current_frame_index = -1
        current_bgr = None
        for timestamp, target_frame_index in zip(timestamps_ms, target_frame_indices):
            while current_frame_index < int(target_frame_index):
                ok, next_bgr = capture.read()
                if not ok:
                    raise RuntimeError(f"Could not read sampled frame at {int(timestamp)} ms")
                current_bgr = next_bgr
                current_frame_index += 1
            if current_bgr is None:
                raise RuntimeError(f"Could not decode sampled frame at {int(timestamp)} ms")
            bgr = current_bgr
            rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
            image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
            result = landmarker.detect_for_video(image, int(timestamp))

            faces = getattr(result, "face_landmarks", None) or []
            has_face = bool(faces)
            face_rows.append(int(has_face))
            landmark_rows.append(int(has_face and len(faces[0]) == 478))

            categories_for_face = []
            all_blendshapes = getattr(result, "face_blendshapes", None) or []
            if has_face and all_blendshapes:
                categories_for_face = list(all_blendshapes[0])
            if categories_for_face:
                names = [str(category.category_name) for category in categories_for_face]
                if not blendshape_names:
                    blendshape_names = names
                elif names != blendshape_names:
                    raise RuntimeError("MediaPipe blendshape category order changed during video")
                scores = np.asarray([category.score for category in categories_for_face], dtype=np.float32)
                if scores.shape != (52,):
                    raise RuntimeError(f"Expected 52 blendshape scores; received {scores.shape}")
                blendshape_rows.append(scores)
            else:
                blendshape_rows.append(np.full(52, np.nan, dtype=np.float32))

            matrices = getattr(result, "facial_transformation_matrixes", None) or []
            if matrices:
                pose_rows.append(euler_pitch_yaw_roll(matrices[0]))
            else:
                pose_rows.append(np.full(3, np.nan, dtype=np.float32))
            # The Tasks result does not expose a numeric detection confidence.
            confidence_rows.append(float("nan"))

        if len(blendshape_names) != 52:
            raise RuntimeError(f"Expected 52 canonical blendshape names; received {len(blendshape_names)}")
        arrays = {
            "blendshapes": np.asarray(blendshape_rows, dtype=np.float32).reshape(-1, 52),
            "head_pose": np.asarray(pose_rows, dtype=np.float32).reshape(-1, 3),
            "face_present": np.asarray(face_rows, dtype=np.uint8),
            "landmarks_present": np.asarray(landmark_rows, dtype=np.uint8),
            "confidence": np.asarray(confidence_rows, dtype=np.float32),
            "timestamps_ms": timestamps_ms,
        }
        return arrays, blendshape_names
    finally:
        capture.release()


def cache_is_current(out_path: Path, video_path: Path) -> bool:
    return out_path.is_file() and out_path.stat().st_mtime > video_path.stat().st_mtime


def save_names(names: list[str]) -> None:
    FEATURE_ROOT.mkdir(parents=True, exist_ok=True)
    if BLENDSHAPE_NAMES_PATH.is_file():
        existing = json.loads(BLENDSHAPE_NAMES_PATH.read_text(encoding="utf-8"))
        if existing != names:
            raise ValueError("Saved blendshape_names.json differs from MediaPipe's canonical output order")
    else:
        BLENDSHAPE_NAMES_PATH.write_text(json.dumps(names, indent=2), encoding="utf-8")


def save_npz(out_path: Path, arrays: dict[str, np.ndarray]) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(out_path, **arrays, fps=np.asarray(SAMPLE_FPS, dtype=np.int32))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--smoke", action="store_true", help="Extract interview video 24fc only")
    mode.add_argument("--all", action="store_true", help="Extract every manifest video")
    parser.add_argument("--force", action="store_true", help="Ignore newer-output cache files")
    args = parser.parse_args()

    rows = load_manifest()
    usable_rows = [row for row in rows if row.get("mask", "").strip() == "1"]
    video_keys = sorted({(row["split"].strip(), row["task"].strip(), row["media_file"].strip())
                         for row in usable_rows})
    if args.smoke:
        candidates = [key for key in video_keys if key[1].casefold() == "interview"
                      and key[2].casefold() == "24fc"]
        if not candidates:
            raise SystemExit("No usable interview/24fc row found in manifest")
        video_keys = candidates[:1]

    FEATURE_ROOT.mkdir(parents=True, exist_ok=True)
    started_all = time.perf_counter()
    failures: list[dict[str, str]] = []
    totals: dict[str, dict[str, float]] = defaultdict(lambda: {"videos": 0, "frames": 0, "valid": 0})
    smoke_details: tuple[Path, dict[str, np.ndarray], list[str]] | None = None

    for split, task, media_file in video_keys:
        item_started = time.perf_counter()
        landmarker = None
        video_path = CASA_ROOT / task / "videos" / media_file
        try:
            video_path = video_for(task, media_file)
            out_path = FEATURE_ROOT / split / task / f"{media_file}.npz"
            if not args.force and cache_is_current(out_path, video_path):
                with np.load(out_path, allow_pickle=False) as cached:
                    arrays = {key: cached[key] for key in (
                        "blendshapes", "head_pose", "face_present", "landmarks_present",
                        "confidence", "timestamps_ms")}
                    fps = int(cached["fps"])
                names = json.loads(BLENDSHAPE_NAMES_PATH.read_text(encoding="utf-8"))
                if fps != SAMPLE_FPS or arrays["blendshapes"].shape[1] != 52:
                    raise ValueError(f"Cached feature schema is invalid: fps={fps}, shape={arrays['blendshapes'].shape}")
            else:
                # Create a fresh VIDEO-mode task for each file so the video's
                # timestamp sequence can correctly begin at zero.
                landmarker, _ = make_landmarker()
                arrays, names = extract_video(video_path, landmarker)
                save_names(names)
                save_npz(out_path, arrays)
            frames = len(arrays["timestamps_ms"])
            valid = int(np.sum((arrays["face_present"] == 1) & np.isfinite(arrays["head_pose"]).all(axis=1)))
            valid_pct = 100.0 * valid / frames if frames else 0.0
            group = f"{split}/{task}"
            totals[group]["videos"] += 1
            totals[group]["frames"] += frames
            totals[group]["valid"] += valid
            print(f"[{split}/{task}] {media_file}: {frames} frames, {valid_pct:.1f}% valid, "
                  f"{time.perf_counter() - item_started:.1f}s")
            if args.smoke:
                smoke_details = (out_path, arrays, names)
        except Exception as error:
            path_text = str(video_path)
            print(f"FAILED: {path_text}: {error}")
            failures.append({"task": task, "split": split, "media_file": media_file,
                             "path": path_text, "error": str(error)})
        finally:
            if landmarker is not None:
                landmarker.close()

    FAILED_PATH.write_text(json.dumps(failures, indent=2), encoding="utf-8")

    if args.smoke and smoke_details:
        out_path, arrays, names = smoke_details
        present = arrays["face_present"] == 1
        present_pct = 100.0 * float(present.mean()) if len(present) else 0.0
        nan_present = int(np.isnan(arrays["blendshapes"][present]).sum()) if present.any() else 0
        print("=== Smoke test ===")
        print(f"Number of frames: {len(arrays['timestamps_ms'])}")
        print(f"Frame rate confirmed: {SAMPLE_FPS}")
        print(f"Blendshape names ({len(names)}): {names[:10]}")
        print(f"Blendshape array shape: {arrays['blendshapes'].shape}")
        print(f"Head-pose array shape: {arrays['head_pose'].shape}")
        print(f"Frames with face_present == 1: {present_pct:.1f}%")
        print(f"NaN blendshape values where face_present == 1: {nan_present}")
        print(f"Saved .npz: {out_path}")
        print(f"Failed videos: {len(failures)}")
    else:
        print("=== Extraction summary ===")
        for split in ("train", "val", "test"):
            for task in ("interview", "reading"):
                group = f"{split}/{task}"
                values = totals[group]
                pct = 100.0 * values["valid"] / values["frames"] if values["frames"] else 0.0
                print(f"{group}: {int(values['videos'])} videos, {int(values['frames'])} frames, {pct:.1f}% valid")
        total_videos = sum(value["videos"] for value in totals.values())
        total_frames = sum(value["frames"] for value in totals.values())
        valid_count = sum(value["valid"] for value in totals.values())
        valid_pct = 100.0 * valid_count / total_frames if total_frames else 0.0
        print(f"Total: {int(total_videos)} videos, {int(total_frames)} frames, {valid_pct:.1f}% valid in {time.perf_counter()-started_all:.0f}s")
        print(f"Failed videos: {len(failures)} (details: {FAILED_PATH})")

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
