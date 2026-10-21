"""Download MediaPipe's Face Landmarker model (with blendshapes) into models/.

    .venv/bin/python scripts/fetch_face_model.py
"""
import sys
import urllib.request
from pathlib import Path

URL = "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"
DEST = Path(__file__).resolve().parent.parent / "models" / "face_landmarker.task"


def main() -> int:
    DEST.parent.mkdir(parents=True, exist_ok=True)
    if DEST.is_file() and DEST.stat().st_size > 0:
        print(f"already present: {DEST}")
        return 0
    tmp = DEST.with_suffix(".part")
    print(f"downloading {URL}")
    urllib.request.urlretrieve(URL, tmp)
    tmp.rename(DEST)
    print(f"saved {DEST} ({DEST.stat().st_size / 1e6:.1f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
