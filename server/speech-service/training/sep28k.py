"""SEP-28k: metadata, audio download, 3-second clips, labels and the speaker-separated SEP-28k-E splits.

Replaces Apple's download_audio.py / extract_clips.py with the same layout but no system wget or ffmpeg
(audio is decoded with PyAV), resumable downloads and a log of dead links.

Layout under DATA_DIR:
    meta/SEP-28k_labels.csv, meta/SEP-28k_episodes.csv, meta/SEP-28k-Extended_clips.csv
    wavs/{Show}/{EpId}.wav            16 kHz mono episodes (about 32 GB for all of SEP-28k)
    clips/{Show}/{EpId}/{Show}_{EpId}_{ClipId}.wav   3 s clips (about 2.6 GB)
    download_log.csv                  one row per episode: ok / failed + reason

Sources: Lea et al., ICASSP 2021 (CC BY-NC 4.0); Bayerl et al., TSD 2022 (SEP-28k-E). Cite both.
FluencyBank episodes need a TalkBank login, so they are skipped here (see the C1 run guide).
"""
import csv
import shutil
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import numpy as np
import pandas as pd
import soundfile as sf

SR = 16000
APPLE = "https://raw.githubusercontent.com/apple/ml-stuttering-events-dataset/main"
EXTENDED = "https://raw.githubusercontent.com/th-nuernberg/ml-stuttering-events-dataset-extended/main"
META_FILES = {
    "SEP-28k_labels.csv": f"{APPLE}/SEP-28k_labels.csv",
    "SEP-28k_episodes.csv": f"{APPLE}/SEP-28k_episodes.csv",
    "SEP-28k-Extended_clips.csv": f"{EXTENDED}/SEP-28k-Extended_clips.csv",
}
# SEP-28k column → the service's label (app/detection/base.py LABELS order).
LABEL_COLUMNS = {
    "Block": "block",
    "Prolongation": "prolongation",
    "SoundRep": "sound_repetition",
    "WordRep": "word_repetition",
    "Interjection": "interjection",
}
LABELS = tuple(LABEL_COLUMNS.values())
# Clips where at least this many annotators flagged a problem are left out (common practice on SEP-28k).
EXCLUDE_COLUMNS = ("PoorAudioQuality", "Music", "NoSpeech", "DifficultToUnderstand", "Unsure")
USER_AGENT = "Mozilla/5.0 (research download; SEP-28k)"


def fetch_metadata(data_dir: Path, sources: dict | None = None) -> dict[str, Path]:
    """Downloads the small label / episode / split CSVs (kept if already there)."""
    meta = Path(data_dir) / "meta"
    meta.mkdir(parents=True, exist_ok=True)
    out = {}
    for name, url in (sources or META_FILES).items():
        path = meta / name
        if not path.exists():
            _fetch(url, path)
        out[name] = path
    return out


def read_episodes(path: Path) -> pd.DataFrame:
    """Apple's episodes file: no header, ", " separated: show name, episode name, URL, Show code, EpId."""
    rows = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            parts = [p.strip() for p in line.rstrip("\n").split(", ")]
            if len(parts) >= 5:
                rows.append({"url": parts[2], "Show": parts[-2], "EpId": parts[-1]})
    return pd.DataFrame(rows)


def read_clips(path: Path) -> pd.DataFrame:
    """SEP-28k-E clips file (labels + split columns). Keys are stripped strings so they match file names."""
    df = pd.read_csv(path, dtype={"EpId": str, "ClipId": str})
    df.columns = [c.strip() for c in df.columns]
    for c in ("Show", "EpId", "ClipId"):
        df[c] = df[c].astype(str).str.strip()
    df["key"] = df["Show"] + "_" + df["EpId"] + "_" + df["ClipId"]
    return df


def _fetch(url: str, dest: Path, timeout: int = 60) -> str:
    """Downloads url (or copies a local path / file:// URL) to dest; returns the content type."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    if url.startswith("file://") or Path(url).exists():
        shutil.copyfile(url.removeprefix("file://"), dest)
        return "local"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    tmp = dest.with_suffix(dest.suffix + ".part")
    with urllib.request.urlopen(req, timeout=timeout) as resp, open(tmp, "wb") as fh:
        ctype = resp.headers.get("Content-Type", "")
        shutil.copyfileobj(resp, fh, length=1 << 20)
    tmp.replace(dest)
    return ctype


def decode_to_wav(src: Path, dest: Path) -> float:
    """Any audio/video file → 16 kHz mono 16-bit WAV with PyAV (no system ffmpeg). Returns the duration in s."""
    import av

    chunks = []
    with av.open(str(src)) as container:
        stream = next(s for s in container.streams if s.type == "audio")
        resampler = av.AudioResampler(format="s16", layout="mono", rate=SR)
        for frame in container.decode(stream):
            for out in resampler.resample(frame):
                chunks.append(out.to_ndarray().reshape(-1))
        for out in resampler.resample(None):
            chunks.append(out.to_ndarray().reshape(-1))
    audio = np.concatenate(chunks) if chunks else np.zeros(0, dtype=np.int16)
    dest.parent.mkdir(parents=True, exist_ok=True)
    sf.write(dest, audio, SR, subtype="PCM_16")
    return len(audio) / SR


def _download_one(row: dict, wav_dir: Path) -> dict:
    wav = wav_dir / row["Show"] / f"{row['EpId']}.wav"
    if wav.exists():
        return {**row, "status": "ok", "reason": "already downloaded"}
    raw = wav.with_suffix(".download")
    try:
        ctype = _fetch(row["url"], raw)
        if "text/html" in ctype:
            return {**row, "status": "failed", "reason": "got a web page, not audio (dead link or login)"}
        seconds = decode_to_wav(raw, wav)
        return {**row, "status": "ok", "reason": f"{seconds:.0f} s"}
    except Exception as exc:  # dead links are expected (about 25 % on 11 Oct 2026)
        return {**row, "status": "failed", "reason": f"{type(exc).__name__}: {exc}"[:200]}
    finally:
        raw.unlink(missing_ok=True)


def download_episodes(episodes: pd.DataFrame, data_dir: Path, workers: int = 4, progress=print) -> pd.DataFrame:
    """Downloads and converts every episode; resumable (finished WAVs are skipped). Writes download_log.csv."""
    wav_dir = Path(data_dir) / "wavs"
    results = []
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = [pool.submit(_download_one, r, wav_dir) for r in episodes.to_dict("records")]
        for i, fut in enumerate(as_completed(futures), 1):
            results.append(fut.result())
            if progress and (i % 10 == 0 or i == len(futures)):
                ok = sum(r["status"] == "ok" for r in results)
                progress(f"  {i}/{len(futures)} episodes, {ok} ok")
    log = pd.DataFrame(results)
    log.to_csv(Path(data_dir) / "download_log.csv", index=False)
    return log


def extract_clips(clips: pd.DataFrame, data_dir: Path, progress=print) -> pd.DataFrame:
    """Cuts each labelled 3 s clip from its episode (Start/Stop are 16 kHz sample indices). Adds a `path` column;
    clips whose episode is missing get path None."""
    data_dir = Path(data_dir)
    paths = []
    for (show, ep), group in clips.groupby(["Show", "EpId"], sort=False):
        wav = data_dir / "wavs" / show / f"{ep}.wav"
        if not wav.exists():
            paths += [(i, None) for i in group.index]
            continue
        audio, sr = sf.read(wav, dtype="int16")
        assert sr == SR, f"{wav} is {sr} Hz"
        for i, row in group.iterrows():
            out = data_dir / "clips" / show / ep / f"{show}_{ep}_{row['ClipId']}.wav"
            if not out.exists():
                seg = audio[int(row["Start"]): int(row["Stop"])]
                if len(seg) == 0:
                    paths.append((i, None))
                    continue
                out.parent.mkdir(parents=True, exist_ok=True)
                sf.write(out, seg, SR, subtype="PCM_16")
            paths.append((i, str(out)))
    clips = clips.copy()
    clips["path"] = pd.Series(dict(paths))
    if progress:
        progress(f"{clips['path'].notna().sum()} of {len(clips)} clips available")
    return clips


def targets(clips: pd.DataFrame, min_votes: int = 2) -> np.ndarray:
    """Multi-label targets in LABELS order: a label is present when at least `min_votes` of 3 annotators chose it."""
    return np.stack([(clips[c].astype(int) >= min_votes).astype(int) for c in LABEL_COLUMNS], axis=1)


def usable(clips: pd.DataFrame, max_votes: int = 1) -> np.ndarray:
    """Leaves out clips that more than `max_votes` annotators marked as poor audio, music, no speech, hard to
    understand or unsure."""
    mask = np.ones(len(clips), dtype=bool)
    for c in EXCLUDE_COLUMNS:
        if c in clips:
            mask &= clips[c].astype(int).to_numpy() <= max_votes
    return mask


def summary(clips: pd.DataFrame, split_column: str = "SEP28k-E", min_votes: int = 2) -> pd.DataFrame:
    y = targets(clips, min_votes)
    rows = {}
    for split in ("train", "dev", "test"):
        m = (clips[split_column] == split).to_numpy()
        rows[split] = {"clips": int(m.sum()), **{lab: int(y[m, i].sum()) for i, lab in enumerate(LABELS)}}
    return pd.DataFrame(rows).T


def write_csv(rows: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)


__all__ = ["fetch_metadata", "read_episodes", "read_clips", "download_episodes", "extract_clips", "targets",
           "usable", "summary", "LABELS", "LABEL_COLUMNS", "SR", "decode_to_wav"]
