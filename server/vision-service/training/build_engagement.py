"""Build the C3 engagement dataset from DAiSEE: one row of camera features per 10-second clip.

Each clip goes through the service's own MediaPipe tracker (app.video.landmarks.track) and the shared
window definition (app.engagement.features), so training sees the same numbers the phone sends.

DAiSEE layout (as downloaded): DataSet/{Train,Validation,Test}/<subject>/<clip>/<clip>.avi and
Labels/{TrainLabels,ValidationLabels,TestLabels}.csv (ClipID, Boredom, Engagement, Confusion, Frustration).
Label: engaged = 1, not engaged = 0 for Engagement level 0 or 1 (about 6 % of clips).

Extraction is slow (about 9,000 clips), so per-clip results go to a JSONL cache and a rerun skips them.

    python -m training.build_engagement --daisee training/data/daisee --out training/data/daisee/daisee_engagement.npz --workers 6
"""
import argparse
import csv
import json
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

import numpy as np

from app.config import get_settings
from app.engagement.features import FEATURES, WINDOW_SEC, sample_from_mediapipe, window_features
from app.video.io import VideoError
from app.video.landmarks import track

VIDEO_EXT = (".avi", ".mp4")
SPLITS = ("Train", "Validation", "Test")
NOT_ENGAGED_MAX_LEVEL = 1


def load_labels(labels_dir: Path) -> dict[str, int]:
    """ClipID stem → engagement level, from every label CSV in the folder."""
    levels = {}
    for path in sorted(labels_dir.glob("*.csv")):
        with open(path, newline="", encoding="utf-8-sig") as fh:
            reader = csv.DictReader(fh)
            reader.fieldnames = [f.strip() for f in reader.fieldnames or []]
            if "ClipID" not in reader.fieldnames or "Engagement" not in reader.fieldnames:
                continue
            for row in reader:
                try:
                    levels[Path(row["ClipID"].strip()).stem] = int(float(row["Engagement"]))
                except (TypeError, ValueError):
                    continue
    return levels


def find_clips(dataset_dir: Path) -> list[dict]:
    clips = []
    for split in SPLITS:
        root = dataset_dir / split
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*")):
            if path.suffix.lower() in VIDEO_EXT:
                # <split>/<subject>/<clip>/<clip>.avi: the subject is two folders up.
                subject = path.parent.parent.name if path.parent.parent != root else path.parent.name
                clips.append({"clip": path.stem, "path": str(path), "subject": subject, "split": split})
    return clips


def extract(clip: dict, target_fps: float) -> dict:
    s = get_settings()
    try:
        tracks = track(clip["path"], s.face_model_path, target_fps, 0.0, s.min_face_width_ratio, keep_raw=True)
    except VideoError as exc:
        return {**clip, "error": f"{exc.code}: {exc.message}"}
    # DAiSEE clips are one window long; a longer file is summarised over its first WINDOW_SEC.
    t0 = float(tracks.times[0])
    samples = [sample_from_mediapipe(r) for t, r in zip(tracks.times, tracks.raw) if t - t0 < WINDOW_SEC]
    return {**clip, "frames": len(samples), "features": window_features(samples)}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--daisee", type=Path, required=True, help="DAiSEE root (contains DataSet/ and Labels/)")
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--cache", type=Path, default=None, help="per-clip JSONL (default: <out>.clips.jsonl)")
    ap.add_argument("--target-fps", type=float, default=5.0, help="analysed frames per second (the phone uses about 5)")
    ap.add_argument("--workers", type=int, default=1)
    ap.add_argument("--limit", type=int, default=0, help="only the first N clips (smoke runs)")
    args = ap.parse_args()

    if not get_settings().face_model_path.is_file():
        raise SystemExit("MediaPipe model missing: run scripts/fetch_face_model.py first.")
    levels = load_labels(args.daisee / "Labels")
    clips = [c for c in find_clips(args.daisee / "DataSet") if c["clip"] in levels]
    if args.limit:
        clips = clips[:args.limit]
    if not clips:
        raise SystemExit(f"No labelled clips found under {args.daisee}/DataSet (labels read: {len(levels)}).")

    cache = args.cache or args.out.with_suffix(".clips.jsonl")
    cache.parent.mkdir(parents=True, exist_ok=True)
    done = {}
    if cache.is_file():
        for line in cache.read_text().splitlines():
            if line.strip():
                row = json.loads(line)
                done[row["clip"]] = row
    todo = [c for c in clips if c["clip"] not in done]
    print(f"{len(clips)} labelled clips, {len(done)} cached, {len(todo)} to extract", file=sys.stderr)

    with open(cache, "a", encoding="utf-8") as fh, ProcessPoolExecutor(max_workers=max(1, args.workers)) as pool:
        futures = [pool.submit(extract, c, args.target_fps) for c in todo]
        for i, fut in enumerate(as_completed(futures), 1):
            row = fut.result()
            done[row["clip"]] = row
            fh.write(json.dumps(row) + "\n")
            fh.flush()
            if i % 100 == 0 or i == len(futures):
                print(f"  {i}/{len(futures)}", file=sys.stderr)

    X, y, level, groups, split, ids = [], [], [], [], [], []
    errors = 0
    for c in clips:
        row = done[c["clip"]]
        if "error" in row:
            errors += 1
            continue
        f = row["features"]
        X.append([np.nan if f[name] is None else f[name] for name in FEATURES])
        level.append(levels[c["clip"]])
        y.append(0 if levels[c["clip"]] <= NOT_ENGAGED_MAX_LEVEL else 1)
        groups.append(c["subject"])
        split.append(c["split"])
        ids.append(c["clip"])
    args.out.parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(
        args.out,
        X=np.asarray(X, dtype=np.float32).reshape(-1, len(FEATURES)),
        y=np.asarray(y, dtype=np.int64),  # 1 = engaged, 0 = not engaged (the minority to catch)
        level=np.asarray(level, dtype=np.int64),
        groups=np.asarray(groups), split=np.asarray(split), clip=np.asarray(ids),
        features=np.asarray(FEATURES),
    )
    y = np.asarray(y)
    print(f"saved {args.out}: {len(y)} clips, {len(set(groups))} subjects, not engaged {int((y == 0).sum())} "
          f"({100 * (y == 0).mean() if len(y) else 0:.1f} %), {errors} unreadable")
    return 0


if __name__ == "__main__":
    sys.exit(main())
