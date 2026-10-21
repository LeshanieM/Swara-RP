"""UCLASS (University College London Archive of Stuttered Speech) → a set of 3-second child clips to label.

UCLASS recordings are not labelled clip by clip, so the team labels a sample themselves (about 300 clips, two
people independently; see tools/label_clips.py and agreement.py). File names carry the speaker and the age at
recording, e.g. F_0050_10y9m_1.wav; a few break the pattern (M_0016_1_08y7m_1, M_0061_16y9m-1), so the parser is
lenient. Acknowledge UCLASS as the source and that data collection was supported by the Wellcome Trust.
"""
import re
from pathlib import Path

import numpy as np
import pandas as pd
import soundfile as sf

SR = 16000
NAME = re.compile(r"^(?P<sex>[MF])_(?P<speaker>\d{4})(?:_\d+)?_(?P<years>\d{1,2})y(?P<months>\d{1,2})m(?:[_-](?P<session>\d+))?", re.I)


def parse_name(path: str | Path) -> dict | None:
    m = NAME.match(Path(path).stem)
    if not m:
        return None
    return {"sex": m["sex"].upper(), "speaker": m["speaker"], "ageYears": int(m["years"]),
            "ageMonths": int(m["months"]), "session": m["session"] or "1"}


def recordings(root: Path, min_age: int = 5, max_age: int = 14) -> pd.DataFrame:
    """Every WAV under root whose speaker was 5–14 at recording (the app's age range)."""
    rows = []
    for path in sorted(Path(root).rglob("*.wav")):
        info = parse_name(path)
        if info and min_age <= info["ageYears"] <= max_age:
            rows.append({"path": str(path), "release": path.parent.name, **info})
    return pd.DataFrame(rows)


def _load_16k(path: str) -> np.ndarray:
    audio, sr = sf.read(path, dtype="float32")
    if audio.ndim > 1:
        audio = audio.mean(axis=1)
    if sr != SR:
        import librosa
        audio = librosa.resample(audio, orig_sr=sr, target_sr=SR)
    return audio


def prepare_label_set(recs: pd.DataFrame, out_dir: Path, n_clips: int = 300, clip_sec: float = 3.0,
                      seed: int = 7, min_level_db: float = -35.0) -> pd.DataFrame:
    """Cuts non-overlapping 3 s clips with speech in them and samples `n_clips` spread evenly over speakers
    (so a few long recordings don't dominate). Writes clips/*.wav and manifest.csv; the clip order is shuffled
    once, so both raters see the same order."""
    rng = np.random.default_rng(seed)
    out_dir = Path(out_dir)
    (out_dir / "clips").mkdir(parents=True, exist_ok=True)
    pool = []
    for rec in recs.to_dict("records"):
        audio = _load_16k(rec["path"])
        n = int(clip_sec * SR)
        peak = np.abs(audio).max() + 1e-9
        for k in range(len(audio) // n):
            seg = audio[k * n:(k + 1) * n]
            rms_db = 20 * np.log10(np.sqrt(np.mean(seg ** 2)) / peak + 1e-9)
            if rms_db > min_level_db:  # skip near-silent stretches
                pool.append({**rec, "startSec": k * clip_sec, "segment": seg})
    if not pool:
        raise SystemExit("No usable clips: check the UCLASS folder and the age filter.")
    by_speaker = {}
    for c in pool:
        by_speaker.setdefault(c["speaker"], []).append(c)
    for clips in by_speaker.values():
        rng.shuffle(clips)
    chosen = []
    while len(chosen) < min(n_clips, len(pool)):  # round-robin over speakers
        for clips in by_speaker.values():
            if clips and len(chosen) < n_clips:
                chosen.append(clips.pop())
    rng.shuffle(chosen)
    rows = []
    for i, c in enumerate(chosen):
        name = f"uclass_{i:04d}.wav"
        sf.write(out_dir / "clips" / name, c["segment"], SR, subtype="PCM_16")
        rows.append({"clip": name, "speaker": c["speaker"], "sex": c["sex"], "ageYears": c["ageYears"],
                     "ageMonths": c["ageMonths"], "source": Path(c["path"]).name, "startSec": c["startSec"]})
    manifest = pd.DataFrame(rows)
    manifest.to_csv(out_dir / "manifest.csv", index=False)
    return manifest
