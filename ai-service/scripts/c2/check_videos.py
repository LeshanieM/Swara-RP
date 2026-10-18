"""Verify CASA annotation IDs against the video files on disk."""

from __future__ import annotations

import csv
from collections import Counter
from contextlib import redirect_stdout
from pathlib import Path
import sys
from io import StringIO


SERVICE_ROOT = Path(__file__).resolve().parents[2]
DATA_ROOT = SERVICE_ROOT / "data" / "casa"
ALLOWED_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv"}
CHECK_STEMS = {
    "interview": ["24fc", "24ma", "29mb", "507", "50fb", "50fa", "32m", "34m"],
    "reading": ["24fc", "25m", "34m", "50fb", "08f", "09f"],
}


def emit_task(task: str) -> None:
    task_root = DATA_ROOT / task
    video_dir = task_root / "videos"
    csv_path = task_root / "total_dataset.csv"

    print(f"===== {task.upper()} =====")
    print(f"Video directory: {video_dir.resolve()}")
    print(f"Video directory exists: {video_dir.is_dir()}")

    files = []
    if video_dir.is_dir():
        files = sorted(
            (path for path in video_dir.iterdir()
             if path.is_file() and path.suffix.casefold() in ALLOWED_EXTENSIONS),
            key=lambda path: (path.name.casefold(), path.name),
        )
    print("Files in video directory:")
    if files:
        for path in files:
            print(f"  {path.name} | {path.stat().st_size} bytes | {path.suffix}")
    else:
        print("  (none)")

    extension_counts = Counter(path.suffix.casefold() for path in files)
    print(f"Total files on disk by extension: {dict(sorted(extension_counts.items()))}")

    annotated_ids: set[str] = set()
    if not csv_path.is_file():
        print(f"Annotation CSV: MISSING ({csv_path.resolve()})")
    else:
        print(f"Annotation CSV: {csv_path.resolve()}")
        try:
            with csv_path.open("r", newline="", encoding="utf-8-sig") as handle:
                reader = csv.DictReader(handle)
                if "media_file" not in (reader.fieldnames or []):
                    print("Annotation CSV is missing the 'media_file' column.")
                else:
                    annotated_ids = {
                        str(row.get("media_file", "")).strip()
                        for row in reader
                        if str(row.get("media_file", "")).strip()
                    }
        except (OSError, csv.Error, UnicodeError) as error:
            print(f"Could not read annotation CSV: {error}")

    print(f"Total unique annotated media_file values: {len(annotated_ids)}")
    disk_by_stem = {path.stem.casefold(): path for path in files}
    annotated_by_fold = {value.casefold(): value for value in annotated_ids}

    usable_keys = sorted(disk_by_stem.keys() & annotated_by_fold.keys())
    missing_keys = sorted(annotated_by_fold.keys() - disk_by_stem.keys())
    orphan_keys = sorted(disk_by_stem.keys() - annotated_by_fold.keys())
    usable = [disk_by_stem[key].stem for key in usable_keys]
    missing = [annotated_by_fold[key] for key in missing_keys]
    orphan = [disk_by_stem[key].stem for key in orphan_keys]
    print(f"Usable ({len(usable)}): {usable}")
    print(f"Annotated but missing on disk ({len(missing)}): {missing}")
    print(f"On disk but unannotated ({len(orphan)}): {orphan}")

    print("Requested stem checks:")
    for stem in CHECK_STEMS[task]:
        match = disk_by_stem.get(stem.casefold())
        if match is None:
            print(f"  {stem}: MISSING")
        else:
            print(f"  {stem}: FOUND {match.name}")
    print()


def main() -> None:
    captured = StringIO()
    with redirect_stdout(captured):
        print(f"Script: {Path(__file__).resolve()}")
        print(f"Service root: {SERVICE_ROOT}")
        print(f"Allowed extensions (case-insensitive): {sorted(ALLOWED_EXTENSIONS)}")
        print()
        for task_name in ("interview", "reading"):
            emit_task(task_name)
    output = captured.getvalue()
    sys.stdout.write(output)
    audit_path = DATA_ROOT / "audit_videos.txt"
    audit_path.parent.mkdir(parents=True, exist_ok=True)
    audit_path.write_text(output, encoding="utf-8")
    print(f"Full output saved to: {audit_path.resolve()}")


if __name__ == "__main__":
    main()
