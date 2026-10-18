"""Extract privacy-preserving, aggregate face/attention-proxy features from DAiSEE videos.

No frames are written to disk.  The resulting one-row-per-clip CSV contains
numeric aggregates only and remains ignored because it can still be sensitive.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import cv2
import numpy as np
import pandas as pd


def _summarize(values: list[float], prefix: str) -> dict[str, float]:
    if not values:
        return {f"{prefix}_mean": np.nan, f"{prefix}_std": np.nan}
    return {f"{prefix}_mean": float(np.mean(values)), f"{prefix}_std": float(np.std(values))}


def extract_clip(video_path: Path, frames_per_video: int) -> dict[str, float]:
    capture = cv2.VideoCapture(str(video_path))
    count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT))
    if count <= 0:
        capture.release()
        raise RuntimeError(f"Cannot read frames from {video_path}")
    target_frames = np.unique(np.linspace(0, count - 1, num=frames_per_video, dtype=int))
    target_set = set(target_frames.tolist())
    frame_index = 0
    face_detector = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
    eye_detector = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_eye.xml")
    if face_detector.empty() or eye_detector.empty():
        raise RuntimeError("OpenCV Haar cascade files are unavailable in this installation")

    attempted = faces = eye_pairs = 0
    face_area: list[float] = []
    center_offset: list[float] = []
    face_centers: list[tuple[float, float]] = []
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        if frame_index not in target_set:
            frame_index += 1
            continue
        frame_index += 1
        attempted += 1
        height, width = frame.shape[:2]
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        candidates = face_detector.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(40, 40))
        if len(candidates) == 0:
            continue
        # For a single-person webcam clip, use the largest detected face.
        x, y, face_width, face_height = max(candidates, key=lambda face: face[2] * face[3])
        faces += 1
        face_area.append((face_width * face_height) / (width * height))
        center_x, center_y = (x + face_width / 2) / width, (y + face_height / 2) / height
        face_centers.append((center_x, center_y))
        center_offset.append(float(np.hypot(center_x - 0.5, center_y - 0.5)))
        eye_region = gray[y:y + face_height // 2, x:x + face_width]
        eyes = eye_detector.detectMultiScale(eye_region, scaleFactor=1.1, minNeighbors=4, minSize=(12, 12))
        if len(eyes) >= 2:
            eye_pairs += 1
    capture.release()

    face_motion = [
        float(np.hypot(current[0] - previous[0], current[1] - previous[1]))
        for previous, current in zip(face_centers, face_centers[1:])
    ]

    result: dict[str, float] = {
        "frames_attempted": float(attempted),
        "face_detect_rate": faces / max(attempted, 1),
        "eye_pair_detect_rate": eye_pairs / max(faces, 1),
        "face_center_motion_mean": float(np.mean(face_motion)) if face_motion else np.nan,
    }
    result.update(_summarize(face_area, "face_area"))
    result.update(_summarize(center_offset, "face_center_offset"))
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract aggregate face/head features from a DAiSEE manifest.")
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--frames-per-video", type=int, default=12)
    parser.add_argument("--limit", type=int, default=None, help="Useful for a smoke test before the full dataset.")
    args = parser.parse_args()

    manifest = pd.read_csv(args.manifest)
    if args.limit:
        manifest = manifest.head(args.limit)
    rows = []
    for number, row in enumerate(manifest.itertuples(index=False), start=1):
        video_path = Path(row.video_path)
        try:
            features = extract_clip(video_path, args.frames_per_video)
            rows.append({**row._asdict(), **features})
            print(f"[{number}/{len(manifest)}] {row.clip_id}")
        except Exception as error:  # continue, but make missing/corrupt clips visible
            print(f"SKIPPED {row.clip_id}: {error}")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(rows).to_csv(args.output, index=False)
    print(f"Wrote {len(rows)} feature rows to {args.output}")


if __name__ == "__main__":
    main()
