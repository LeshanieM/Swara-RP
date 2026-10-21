"""Build the SRCD sequence dataset: one baseline-normalised sequence per labelled stutter moment.

Uses the service's own pipeline (``app.pipeline.prepare``), so training sees exactly
what inference sees: the same face tracking, speaker baseline and normalisation.

Two input formats:

1. A manifest (JSON list), e.g. hand-labelled child videos:
     [{"video": "clips/child01.mp4", "participant": "child01",
       "moments": [{"start": 4.0, "end": 4.8, "FG": 1, "HM": 0}, ...]}, ...]
   Paths are relative to the manifest file.

2. CASA (FluencyBank Voices-AWS): --casa-csv with the timed annotations and
   --video-dir with the videos, matched by file stem to ``media_file``. Each
   annotated row becomes a moment with its FG/HM label (annotator "Gold" by
   default). Group folds by participant, not media file.

    .venv/bin/python -m training.build_dataset --manifest data/manifest.json --out data/srcd_dataset.npz
    .venv/bin/python -m training.build_dataset --casa-csv casa.csv --video-dir videos/ --out data/casa.npz
"""
import argparse
import csv
import json
import re
import sys
from pathlib import Path

import numpy as np

from app.config import get_settings
from app.detection import registry
from app.detection.base import Context
from app.detection.sequences import N_INPUT, SEQ_LEN, moment_sequence, raw_sequence, window_names, window_stats
from app.features import catalog
from app.pipeline import prepare
from app.video.io import VideoError

VIDEO_EXT = (".mp4", ".mov", ".m4v", ".webm", ".mkv", ".avi")


def load_casa(csv_path: Path, video_dir: Path, task: str | None, annotator: str, participant_regex: str) -> list[dict]:
    """CASA timed annotations (start/end in ms) → manifest items. Ported from the earlier C2 prototype."""
    required = {"media_file", "start", "end", "annotator", "FG", "HM"}
    videos = {p.stem: p for p in video_dir.iterdir() if p.suffix.lower() in VIDEO_EXT}
    items: dict[str, dict] = {}
    with open(csv_path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise SystemExit(f"CASA CSV is missing columns: {sorted(missing)}")
        for row in reader:
            if annotator and row["annotator"].strip().casefold() != annotator.casefold():
                continue
            if task and row.get("task", "").strip() and row["task"].strip().casefold() != task.casefold():
                continue
            try:
                start, end = float(row["start"]) / 1000, float(row["end"]) / 1000
                fg, hm = int(float(row["FG"])), int(float(row["HM"]))
            except (TypeError, ValueError):
                continue
            media = row["media_file"].strip()
            if end <= start or media not in videos:
                continue
            # Folds must group by participant, not media file: use a participant column if the CSV
            # has one, else the --participant-regex match on the media name (check it on real CASA names).
            match = re.match(participant_regex, media)
            participant = row.get("participant", "").strip() or (match.group(1) if match else media)
            # Store an absolute path here: build() resolves relative paths against the
            # manifest/video base, and a relative video_dir would otherwise be joined twice.
            item = items.setdefault(media, {"video": str(videos[media].resolve()), "participant": participant, "moments": []})
            item["moments"].append({"start": start, "end": end, "FG": fg, "HM": hm})
    return list(items.values())


def _pair(decision) -> list[int]:
    return [int(decision["FG"].present), int(decision["HM"].present)] if decision else [-1, -1]


def build(items: list[dict], base: Path, target_fps: float) -> dict:
    """Per assessed moment: the SRCD sequence (X) and, for the five-way comparison, the same moment without the
    speaker-relative step (X_raw), 2-s window statistics (W, for the Random Forest), and the decisions of the
    fixed-threshold rules and the label-free SRCD detector, all on identical input."""
    s = get_settings()
    rules, srcd = registry.get("rules"), registry.get("srcd")
    X, X_raw, W, rules_pred, srcd_pred, y, groups, meta = [], [], [], [], [], [], [], []
    for item in items:
        path = Path(item["video"])
        path = path if path.is_absolute() else base / path
        moments = [{"start": m["start"], "end": m["end"]} for m in item["moments"]]
        try:
            p = prepare(str(path), moments, s, target_fps)
        except VideoError as exc:
            print(f"skip {path.name}: {exc.code} {exc.message}", file=sys.stderr)
            continue
        ctx = Context(p.tracks.times, p.tracks.face, p.series, p.dev.z, p.tracks.analysed_fps, p.moments, s.deviation_threshold)
        by_rules, by_srcd = rules.predict(ctx), srcd.predict(ctx)
        # prepare() sorts and merges moments; map labels back by overlap (a merged moment is positive if any part is).
        for m, r_dec, s_dec in zip(p.moments, by_rules, by_srcd):
            if not m.assessed:
                continue
            labels = [lab for lab in item["moments"] if lab["start"] < m.end and lab["end"] > m.start]
            X.append(moment_sequence(p.dev.z, p.tracks.face, m.span, SEQ_LEN))
            X_raw.append(raw_sequence(p.series, p.tracks.face, m.span, SEQ_LEN))
            W.append(window_stats(p.series, p.tracks.times, p.tracks.face, (m.start + m.end) / 2))
            rules_pred.append(_pair(r_dec))
            srcd_pred.append(_pair(s_dec))
            y.append([max(int(lab["FG"]) for lab in labels), max(int(lab["HM"]) for lab in labels)])
            groups.append(item["participant"])
            meta.append({"video": path.name, "start": m.start, "end": m.end})
        print(f"{path.name}: {sum(1 for g in meta if g['video'] == path.name)} moments", file=sys.stderr)
    if not X:
        raise SystemExit("No video moments were processed. Check the video paths, face model, and video readability.")
    return {
        "X": np.asarray(X, dtype=np.float32).reshape(-1, SEQ_LEN, N_INPUT),
        "X_raw": np.asarray(X_raw, dtype=np.float32).reshape(-1, SEQ_LEN, N_INPUT),
        "W": np.asarray(W, dtype=np.float32).reshape(len(W), -1),
        "window_names": np.asarray(window_names()),
        "rules_pred": np.asarray(rules_pred, dtype=np.int64).reshape(-1, 2),
        "srcd_pred": np.asarray(srcd_pred, dtype=np.int64).reshape(-1, 2),
        "y": np.asarray(y, dtype=np.int64).reshape(-1, 2),
        "groups": np.asarray(groups),
        "features": np.asarray(catalog.SCORED_NAMES),
        "meta": np.asarray([json.dumps(m) for m in meta]),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--manifest", type=Path)
    src.add_argument("--casa-csv", type=Path)
    ap.add_argument("--video-dir", type=Path, help="with --casa-csv")
    ap.add_argument("--task", default=None, help="CASA task filter, e.g. interview")
    ap.add_argument("--annotator", default="Gold")
    ap.add_argument("--participant-regex", default=r"^(\d+)",
                    help="CASA: regex whose group 1 is the participant id in media_file (default: leading digits)")
    ap.add_argument("--target-fps", type=float, default=get_settings().target_fps)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    if args.manifest:
        items, base = json.loads(args.manifest.read_text()), args.manifest.parent
    else:
        if not args.video_dir:
            ap.error("--casa-csv needs --video-dir")
        items = load_casa(args.casa_csv, args.video_dir, args.task, args.annotator, args.participant_regex)
        base = args.video_dir
    data = build(items, base, args.target_fps)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(args.out, **data)
    y = data["y"]
    print(f"saved {args.out}: {len(y)} moments, {len(set(data['groups']))} participants, "
          f"FG+ {int(y[:, 0].sum()) if len(y) else 0}, HM+ {int(y[:, 1].sum()) if len(y) else 0}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
