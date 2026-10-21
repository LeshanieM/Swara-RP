"""OpenSLR SLR52 (Sinhala read speech, Google, CC BY-SA 4.0) for fine-tuning C4's CTC ASR.

The corpus is 185,293 utterances from 478 speakers in 16 zip shards (asr_sinhala_0.zip … asr_sinhala_f.zip, about
900 MB each) plus one transcript index, utt_spk_text.tsv (utterance id, speaker id, text). An utterance's audio is
asr_sinhala/data/<first two characters of the id>/<id>.flac; each shard holds the ids starting with its hex digit.

Splits are **speaker-disjoint** (no speaker in two splits) and **sentence-disjoint** (a sentence read in dev or test
is removed from train, so the model is not tested on text it was trained on). Cite Kjartansson et al., SLTU 2018.
"""
import random
import urllib.request
import zipfile
from pathlib import Path

import pandas as pd

from app.text.normalise import normalise_text

BASE_URL = "https://www.openslr.org/resources/52"
SHARDS = list("0123456789abcdef")
INDEX = "utt_spk_text.tsv"


def _download(url: str, dest: Path) -> None:
    """Resumable download (an interrupted file continues where it stopped)."""
    have = dest.stat().st_size if dest.exists() else 0
    req = urllib.request.Request(url, headers={"Range": f"bytes={have}-"} if have else {})
    try:
        with urllib.request.urlopen(req, timeout=60) as r, open(dest, "ab" if have else "wb") as fh:
            if have and r.status != 206:  # the server ignored the range: start again
                fh.truncate(0)
            while chunk := r.read(1 << 20):
                fh.write(chunk)
    except urllib.error.HTTPError as exc:
        if exc.code != 416:  # 416: the file is already complete
            raise


def fetch(root: Path, shards: list[str]) -> Path:
    """Downloads the index and the chosen shards into ``root`` and unzips them (skips what is already there)."""
    root.mkdir(parents=True, exist_ok=True)
    if not (root / INDEX).exists():
        _download(f"{BASE_URL}/{INDEX}", root / INDEX)
    for s in shards:
        if s not in SHARDS:
            raise ValueError(f"unknown shard {s!r}; use 0-9 or a-f")
        z = root / f"asr_sinhala_{s}.zip"
        marker = root / f".unzipped_{s}"
        if marker.exists():
            continue
        # A complete shard may have been copied from an external drive. Reuse
        # it directly; only resume a download when the local archive is absent
        # or incomplete.
        if not (z.is_file() and zipfile.is_zipfile(z)):
            _download(f"{BASE_URL}/{z.name}", z)
        with zipfile.ZipFile(z) as zf:
            zf.extractall(root)
        marker.touch()
    return root


def read_index(root: Path) -> pd.DataFrame:
    """All utterances (id, speaker, text, normalised text, audio path, whether the audio is on disk)."""
    df = pd.read_csv(root / INDEX, sep="\t", header=None, names=["utt", "speaker", "text"], dtype=str, quoting=3)
    df["norm"] = df["text"].map(normalise_text)
    df["path"] = [root / "asr_sinhala" / "data" / u[:2] / f"{u}.flac" for u in df["utt"]]
    df["available"] = [p.exists() for p in df["path"]]
    return df


def split(df: pd.DataFrame, dev_share: float = 0.05, test_share: float = 0.05, seed: int = 17) -> pd.DataFrame:
    """Adds a ``split`` column (train / dev / test): speakers are assigned whole, then any train utterance whose
    sentence also appears in dev or test is dropped (split = 'dropped')."""
    speakers = sorted(df["speaker"].unique())
    random.Random(seed).shuffle(speakers)
    n_dev, n_test = max(1, round(dev_share * len(speakers))), max(1, round(test_share * len(speakers)))
    role = {s: "test" for s in speakers[:n_test]}
    role.update({s: "dev" for s in speakers[n_test:n_test + n_dev]})
    out = df.copy()
    out["split"] = [role.get(s, "train") for s in out["speaker"]]
    held_out = set(out.loc[out["split"] != "train", "norm"])
    out.loc[(out["split"] == "train") & out["norm"].isin(held_out), "split"] = "dropped"
    return out


def summary(df: pd.DataFrame) -> pd.DataFrame:
    return df.groupby("split").agg(utterances=("utt", "size"), speakers=("speaker", "nunique"), sentences=("norm", "nunique"))
