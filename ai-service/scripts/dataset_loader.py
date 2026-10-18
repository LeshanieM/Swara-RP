"""
Dataset loader and partitioning module for Stuttering Detection.

Datasets Supported:
1. SEP-28k (Stuttering Events in Podcasts, 28k clips)
   - License: Creative Commons Attribution 4.0 International (CC BY 4.0)
   - Labels: Block, Prolongation, SoundRep, WordRep, Interjection, NoStutteredWords
2. FluencyBank / Voices-CWS (Children Who Stutter)
   - License: TalkBank Research License / Ethics agreement (strictly non-commercial clinical research)
3. UCLASS (University College London Archive of Stuttered Speech)
   - License: UCL Academic Research License
4. Sinhala Child Speech Dataset (Consented Research Cohort)
   - Collected with institutional ethics review and parental informed consent.
   - Anonymized identifiers (e.g. SN-CH-001) used exclusively.

Prevents Train/Test Leakage:
- Enforces strict speaker-independent splitting (GroupShuffleSplit on Speaker/Show/Child ID).
"""

import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any
import numpy as np
import pandas as pd
from sklearn.model_selection import GroupShuffleSplit

from app.config.speech_settings import (
    CATEGORY_BLOCK,
    CATEGORY_PROLONGATION,
    CATEGORY_SOUND_REP,
    CATEGORY_WORD_REP,
    CATEGORY_INTERJECTION,
    CATEGORY_FLUENT,
)

DATASET_LICENSES = {
    "SEP-28k": "Creative Commons Attribution 4.0 International (CC BY 4.0)",
    "FluencyBank_Voices-CWS": "TalkBank Code of Conduct / Clinical Research License",
    "UCLASS": "University College London Academic Research License",
    "Sinhala_Child_Cohort": "Institutional Ethics Approved & Guardian Consented (Pseudonymized IDs)",
}


def load_sep28k_metadata(csv_path: Path, audio_dir: Optional[Path] = None) -> pd.DataFrame:
    """
    Parses SEP-28k annotation CSV and prepares clip records.
    Labels in SEP-28k: Block, Prolongation, SoundRep, WordRep, Interjection, NoStutteredWords.
    """
    if not csv_path.exists():
        raise FileNotFoundError(f"SEP-28k metadata not found at {csv_path}")

    df = pd.read_csv(csv_path)

    # Required columns
    col_map = {
        "Show": "speaker_group",
        "EpId": "episode_id",
        "ClipId": "clip_id",
    }
    for old_col, new_col in col_map.items():
        if old_col in df.columns:
            df[new_col] = df[old_col]

    if "speaker_group" not in df.columns:
        df["speaker_group"] = df.get("Show", "unknown_speaker")

    # Map dominant label
    def get_canonical_label(row):
        # Annotators threshold: >= 2 annotators agreed
        if row.get("Block", 0) >= 2:
            return CATEGORY_BLOCK
        elif row.get("Prolongation", 0) >= 2:
            return CATEGORY_PROLONGATION
        elif row.get("SoundRep", 0) >= 2:
            return CATEGORY_SOUND_REP
        elif row.get("WordRep", 0) >= 2:
            return CATEGORY_WORD_REP
        elif row.get("Interjection", 0) >= 2:
            return CATEGORY_INTERJECTION
        elif row.get("NoStutteredWords", 0) >= 2:
            return CATEGORY_FLUENT
        return None

    df["label"] = df.apply(get_canonical_label, axis=1)
    df = df.dropna(subset=["label"]).reset_index(drop=True)

    if audio_dir:
        # Construct audio file path
        def find_audio(row):
            show = str(row.get("Show", ""))
            ep = str(row.get("EpId", ""))
            clip = str(row.get("ClipId", ""))
            candidate = audio_dir / show / ep / f"{clip}.wav"
            return str(candidate) if candidate.exists() else None

        df["audio_path"] = df.apply(find_audio, axis=1)

    return df


def load_sinhala_cohort_metadata(csv_path: Path) -> pd.DataFrame:
    """
    Loads Sinhala child speech annotations.
    Schema expected:
        anonymous_id, age, gender, task_type, audio_path, label, start_s, end_s
    """
    if not csv_path.exists():
        raise FileNotFoundError(f"Sinhala cohort metadata not found at {csv_path}")

    df = pd.read_csv(csv_path)
    # Ensure speaker_group is anonymous child identifier to prevent leakage
    df["speaker_group"] = df["anonymous_id"]
    return df


def split_speaker_independent(
    df: pd.DataFrame,
    speaker_col: str = "speaker_group",
    test_size: float = 0.20,
    random_state: int = 42,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """
    Performs speaker-level disjoint partitioning.
    No speaker or recording session in the test set will ever appear in the train set.
    """
    groups = df[speaker_col].astype(str).values
    gss = GroupShuffleSplit(n_splits=1, test_size=test_size, random_state=random_state)
    train_idx, test_idx = next(gss.split(df, groups=groups))

    train_df = df.iloc[train_idx].reset_index(drop=True)
    test_df = df.iloc[test_idx].reset_index(drop=True)

    # Verify zero leakage
    train_speakers = set(train_df[speaker_col].unique())
    test_speakers = set(test_df[speaker_col].unique())
    overlap = train_speakers.intersection(test_speakers)
    assert len(overlap) == 0, f"Critical train/test speaker leakage detected: {overlap}"

    return train_df, test_df


def generate_synthetic_benchmark_dataset(
    num_speakers: int = 20,
    clips_per_speaker: int = 15,
    sample_rate: int = 16000,
    clip_duration_s: float = 3.0,
    random_state: int = 42,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Generates synthetic feature representations with distinct acoustic distributions
    per stuttering class for testing the training and evaluation pipeline without
    requiring the full multi-gigabyte audio corpus.

    Returns:
        X: Synthetic embeddings of shape (N, feature_dim).
        y: Labels (array of strings).
        groups: Speaker IDs (array of strings).
    """
    rng = np.random.RandomState(random_state)
    classes = [
        CATEGORY_BLOCK,
        CATEGORY_PROLONGATION,
        CATEGORY_SOUND_REP,
        CATEGORY_WORD_REP,
        CATEGORY_INTERJECTION,
        CATEGORY_FLUENT,
    ]
    feature_dim = 128  # Matches acoustic representation or projected transformer embedding

    X_list = []
    y_list = []
    groups_list = []

    # Create distinct class centroids
    class_centroids = {
        cls: rng.randn(feature_dim) * 1.5 + (i * 0.8)
        for i, cls in enumerate(classes)
    }

    for s_idx in range(num_speakers):
        speaker_id = f"SYNTH_SPK_{s_idx:03d}"
        # Speaker-specific acoustic bias (pitch, vocal tract length)
        speaker_bias = rng.randn(feature_dim) * 0.4

        for _ in range(clips_per_speaker):
            cls = rng.choice(classes)
            centroid = class_centroids[cls]
            noise = rng.randn(feature_dim) * 0.6
            sample = centroid + speaker_bias + noise

            X_list.append(sample.astype(np.float32))
            y_list.append(cls)
            groups_list.append(speaker_id)

    X = np.vstack(X_list)
    y = np.array(y_list)
    groups = np.array(groups_list)

    return X, y, groups
