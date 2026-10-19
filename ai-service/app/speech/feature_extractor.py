"""
Feature extraction module for speech representation comparison.
Extracts contextual embeddings from 3-second audio windows using:
  1. facebook/wav2vec2-xls-r-300m (multilingual 128-language representation)
  2. facebook/wav2vec2-base (monolingual English baseline)

Pretrained models provide acoustic/phonetic contextual embeddings;
they do NOT detect stuttering directly. A dedicated classifier head is required.
"""

import logging
from typing import Optional, Tuple, Dict, Any
import numpy as np
import torch

from app.config.speech_settings import (
    EXTRACTOR_XLS_R_300M,
    EXTRACTOR_WAV2VEC2_BASE,
    SUPPORTED_EXTRACTORS,
    DEFAULT_EXTRACTOR,
    TARGET_SAMPLE_RATE,
)

logger = logging.getLogger(__name__)

# Global in-memory cache for loaded transformer models to prevent repeated disk/network loading
_LOADED_MODELS: Dict[str, Any] = {}


class SpeechFeatureExtractor:
    """
    Extracts representations from 3.0s audio windows using Wav2Vec2 / XLS-R models.
    """

    def __init__(self, extractor_name: str = DEFAULT_EXTRACTOR, device: Optional[str] = None):
        if extractor_name not in SUPPORTED_EXTRACTORS:
            # Allow fallback if valid HF model identifier, otherwise enforce supported list
            if not extractor_name.startswith("facebook/"):
                raise ValueError(
                    f"Unsupported feature extractor '{extractor_name}'. Supported options: {SUPPORTED_EXTRACTORS}"
                )

        self.extractor_name = extractor_name
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        self.model = None
        self.feature_extractor = None
        self.is_loaded = False
        self.load_error: Optional[str] = None

        self._load_model()

    def _load_model(self) -> bool:
        """Loads or retrieves cached Wav2Vec2/XLS-R model."""
        global _LOADED_MODELS

        if self.extractor_name in _LOADED_MODELS:
            cached = _LOADED_MODELS[self.extractor_name]
            self.model = cached["model"]
            self.feature_extractor = cached["feature_extractor"]
            self.is_loaded = True
            return True

        try:
            from transformers import AutoModel, AutoFeatureExtractor

            logger.info(f"Loading speech feature extractor: {self.extractor_name} on {self.device}")
            # Load feature extractor and base model (without classification head)
            feature_extractor = AutoFeatureExtractor.from_pretrained(self.extractor_name)
            model = AutoModel.from_pretrained(self.extractor_name)
            model.eval()
            model.to(self.device)

            _LOADED_MODELS[self.extractor_name] = {
                "model": model,
                "feature_extractor": feature_extractor,
            }
            self.model = model
            self.feature_extractor = feature_extractor
            self.is_loaded = True
            return True

        except Exception as err:
            self.load_error = str(err)
            self.is_loaded = False
            logger.warning(
                f"Could not load Hugging Face model '{self.extractor_name}' ({err}). "
                f"Falling back to high-dimensional acoustic feature representations if needed."
            )
            return False

    def extract_window_embedding(self, audio_window: np.ndarray) -> np.ndarray:
        """
        Extracts a fixed-length embedding vector from a 3.0-second 16 kHz audio chunk.

        Returns:
            1D numpy array of shape (embedding_dim,).
            For wav2vec2-base: 768 dims (mean-pooled).
            For xls-r-300m: 1024 dims (mean-pooled).
        """
        if self.is_loaded and self.model is not None:
            try:
                # Ensure audio is float32 and 1D
                chunk = audio_window.astype(np.float32)
                tensor_input = torch.from_numpy(chunk).unsqueeze(0).to(self.device)

                with torch.no_grad():
                    outputs = self.model(tensor_input)
                    hidden_states = outputs.last_hidden_state  # shape: (1, time_steps, hidden_size)
                    # Mean pooling over temporal dimension
                    mean_pooled = torch.mean(hidden_states, dim=1).squeeze(0)
                    embedding = mean_pooled.cpu().numpy()

                return embedding.astype(np.float32)
            except Exception as e:
                logger.warning(f"Transformer inference failed: {e}. Using acoustic fallback representation.")

        # Fallback to acoustic feature vector when transformer is unavailable
        return self._extract_acoustic_fallback(audio_window)

    def _extract_acoustic_fallback(self, audio_window: np.ndarray) -> np.ndarray:
        """
        Fallback acoustic feature extractor using Librosa (MFCC + Delta + Spectral features).
        Produces a stable 128-dimensional embedding.
        """
        import librosa

        sr = TARGET_SAMPLE_RATE
        chunk = audio_window.astype(np.float32)

        # 40 MFCCs
        mfcc = librosa.feature.mfcc(y=chunk, sr=sr, n_mfcc=40)
        mfcc_mean = np.mean(mfcc, axis=1)
        mfcc_std = np.std(mfcc, axis=1)

        # Delta MFCCs
        delta_mfcc = librosa.feature.delta(mfcc)
        delta_mean = np.mean(delta_mfcc, axis=1)

        # Spectral contrast (7 bands)
        spectral_contrast = librosa.feature.spectral_contrast(y=chunk, sr=sr, n_bands=6)
        sc_mean = np.mean(spectral_contrast, axis=1)

        # Zero crossing rate
        zcr = librosa.feature.zero_crossing_rate(chunk)
        zcr_val = np.array([np.mean(zcr)])

        features = np.concatenate([mfcc_mean, mfcc_std, delta_mean, sc_mean, zcr_val])
        # Pad or trim to exactly 128 dimensions
        if len(features) < 128:
            features = np.pad(features, (0, 128 - len(features)))
        else:
            features = features[:128]

        return features.astype(np.float32)
