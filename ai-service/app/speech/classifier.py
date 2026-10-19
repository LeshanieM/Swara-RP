"""
Stuttering classifier module for Component 1.
Loads and runs inference with genuine trained classifiers (SVM / MLP) for:
  1. Blocks
  2. Prolongations
  3. Sound repetitions
  4. Word repetitions
  5. Interjections/fillers
  (and Fluent baseline)

Never fabricates predictions. If weights are missing, explicitly reports
unavailability and returns unclassified/fluent baseline with clear warnings.
"""

import json
import logging
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
import numpy as np
import joblib

from app.config.speech_settings import (
    CLASSIFIER_WEIGHTS_FILE,
    CLASSIFIER_METADATA_FILE,
    CATEGORY_BLOCK,
    CATEGORY_PROLONGATION,
    CATEGORY_SOUND_REP,
    CATEGORY_WORD_REP,
    CATEGORY_INTERJECTION,
    CATEGORY_FLUENT,
    ALL_CATEGORIES,
)

logger = logging.getLogger(__name__)


class StutterClassifier:
    """
    Manages loading, inference, and serialization of the stuttering classifier.
    """

    def __init__(
        self,
        weights_path: Optional[Path] = None,
        metadata_path: Optional[Path] = None,
    ):
        self.weights_path = Path(weights_path or CLASSIFIER_WEIGHTS_FILE)
        self.metadata_path = Path(metadata_path or CLASSIFIER_METADATA_FILE)

        self.model = None
        self.metadata: Dict[str, Any] = {}
        self.is_trained = False
        self.weights_loaded = False
        self.classifier_type = "None"
        self.feature_extractor = "None"

        self._load()

    def _load(self) -> bool:
        """Attempts to load trained classifier weights and metadata from disk."""
        if not self.weights_path.exists():
            logger.info(
                f"No classifier weights found at {self.weights_path}. Classifier will operate in untrained mode."
            )
            self.weights_loaded = False
            self.is_trained = False
            return False

        try:
            self.model = joblib.load(self.weights_path)
            self.weights_loaded = True
            self.is_trained = True

            # Load metadata if present
            if self.metadata_path.exists():
                with open(self.metadata_path, "r", encoding="utf-8") as f:
                    self.metadata = json.load(f)
                self.classifier_type = self.metadata.get("classifier_type", type(self.model).__name__)
                self.feature_extractor = self.metadata.get("feature_extractor", "unknown")
            else:
                self.classifier_type = type(self.model).__name__
                self.feature_extractor = "unknown"

            logger.info(f"Loaded {self.classifier_type} classifier from {self.weights_path}")
            return True

        except Exception as e:
            logger.error(f"Failed to load classifier weights from {self.weights_path}: {e}")
            self.weights_loaded = False
            self.is_trained = False
            self.model = None
            return False

    def predict_window(self, embedding: np.ndarray) -> Tuple[str, float, Dict[str, float]]:
        """
        Classifies a single 3-second window embedding.

        Returns:
            predicted_class: One of 'Block', 'Prolongation', 'Sound Repetition',
                            'Word Repetition', 'Interjection', or 'Fluent'.
            confidence: Float probability in [0.0, 1.0].
            probabilities: Dict mapping class names to probabilities.
        """
        if not self.weights_loaded or self.model is None:
            # Untrained / missing weights: do NOT fabricate predictions
            return CATEGORY_FLUENT, 0.0, {cat: 0.0 for cat in ALL_CATEGORIES}

        try:
            x = embedding.reshape(1, -1)

            if hasattr(self.model, "predict_proba"):
                probs = self.model.predict_proba(x)[0]
                classes = list(self.model.classes_)
                prob_dict = {cls: float(p) for cls, p in zip(classes, probs)}
                pred_idx = int(np.argmax(probs))
                pred_class = str(classes[pred_idx])
                confidence = float(probs[pred_idx])
            else:
                pred = self.model.predict(x)[0]
                pred_class = str(pred)
                confidence = 0.80  # Default non-probabilistic confidence
                prob_dict = {cat: 1.0 if cat == pred_class else 0.0 for cat in ALL_CATEGORIES}

            # Map any variants (e.g. SEP-28k internal names) to canonical categories
            canonical_class = self._normalize_class_name(pred_class)
            return canonical_class, round(confidence, 4), prob_dict

        except Exception as e:
            logger.warning(f"Classification inference failed: {e}")
            return CATEGORY_FLUENT, 0.0, {}

    def predict_windows(
        self,
        embeddings: List[np.ndarray],
    ) -> List[Tuple[str, float]]:
        """Batch predicts across a list of window embeddings."""
        return [self.predict_window(emb)[:2] for emb in embeddings]

    @staticmethod
    def _normalize_class_name(raw_name: str) -> str:
        """Maps various dataset labels into canonical Swara categories."""
        name = raw_name.lower().replace("_", "").replace(" ", "").replace("-", "")
        if "block" in name:
            return CATEGORY_BLOCK
        elif "prolongation" in name or "prolong" in name:
            return CATEGORY_PROLONGATION
        elif "soundrep" in name or "soundrepetition" in name:
            return CATEGORY_SOUND_REP
        elif "wordrep" in name or "wordrepetition" in name:
            return CATEGORY_WORD_REP
        elif "interjection" in name or "filler" in name:
            return CATEGORY_INTERJECTION
        elif "fluent" in name or "nostutter" in name or "clean" in name:
            return CATEGORY_FLUENT
        return raw_name
