"""Two people label the same clips independently (tools/label_clips.py); this measures how far they agree
(Cohen's κ per label) and builds the agreed test labels. Clips where they disagree go to a third person or a
discussion; until then they are left out of the child test set."""
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.metrics import cohen_kappa_score

LABELS = ("block", "prolongation", "sound_repetition", "word_repetition", "interjection")


def read_labels(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    return df[~df.get("unusable", 0).astype(bool)].set_index("clip")


def kappa(a: pd.DataFrame, b: pd.DataFrame) -> pd.DataFrame:
    """Cohen's κ per label on the clips both raters labelled (and called usable). κ above 0.6 is usually read as
    substantial agreement, 0.4–0.6 moderate; report it next to every child result."""
    common = a.index.intersection(b.index)
    rows = {}
    for lab in LABELS:
        x, y = a.loc[common, lab].astype(int), b.loc[common, lab].astype(int)
        rows[lab] = {"clips": len(common), "positivesA": int(x.sum()), "positivesB": int(y.sum()),
                     "agreement": float((x == y).mean()) if len(common) else np.nan,
                     "kappa": float(cohen_kappa_score(x, y)) if len(set(x) | set(y)) > 1 else np.nan}
    return pd.DataFrame(rows).T


def consensus(a: pd.DataFrame, b: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """(agreed labels, clips to resolve). A clip is agreed only when both raters gave the same answer on every
    label."""
    common = a.index.intersection(b.index)
    A, B = a.loc[common, list(LABELS)].astype(int), b.loc[common, list(LABELS)].astype(int)
    same = (A == B).all(axis=1)
    return A[same], pd.concat({"raterA": A[~same], "raterB": B[~same]}, axis=1)
