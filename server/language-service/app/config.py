"""Runtime settings for the C4 language service.

Every value can be overridden with an environment variable prefixed ``C4_``
(for example ``C4_ASR_ENGINE=whisper``) or in a local ``.env`` file.
"""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict

SERVICE_VERSION = "0.1.0"
# Bumped whenever normalisation, maze rules, segmentation or a measure changes,
# so stored results stay traceable to the method that produced them.
METHOD_VERSION = "c4-language-0.1"
VERIFY_METHOD_VERSION = "c3-word-check-0.1"
SPEECH_CHECK_METHOD_VERSION = "c3-speech-check-0.1"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="C4_", env_file=".env", extra="ignore")

    # ASR engine: "ctc" (default, keeps repetitions), "whisper" (baseline) or "none".
    asr_engine: str = "ctc"
    # Interim public XLS-R-300m Sinhala CTC fine-tune; replace with the team's MMS adapter / XLS-R model.
    ctc_model: str = "SpideyDLK/wav2vec2-large-xls-r-300m-sinhala-low-LR-part1"
    whisper_model: str = "SinhaSpeech/whisper-small-sinhala-run11"
    device: str = "cpu"
    # Load the active engine in the background at startup instead of on the first request.
    preload: bool = False
    # CTC inference is chunked so memory stays flat on long samples.
    ctc_chunk_sec: float = 20.0

    # Audio constraints (a sample is about 3 minutes; allow some margin).
    sample_rate: int = 16000
    min_duration_sec: float = 1.0
    max_duration_sec: float = 300.0
    max_upload_mb: int = 50

    # A silent gap at least this long ends an utterance (timed transcripts).
    utterance_pause_sec: float = 1.0

    max_concurrent_jobs: int = 1

    # Word check for C3 (/verify-word): one short word per clip.
    verify_min_sec: float = 0.3
    verify_max_sec: float = 10.0
    # Provisional thresholds (app/verify/word.py), calibrated on adult read Sinhala word clips (C3 verification log).
    verify_text_match: float = 0.8  # transcript similarity at which the word counts as said
    verify_text_mismatch: float = 0.6  # below this, with a poor acoustic fit, it was a different word
    verify_margin: float = 0.0  # an alternative that fits better (lower per-frame NLL) than the expected word wins
    verify_gop_match: float = 0.4  # expected word's NLL above the free path, per frame, still a match
    verify_gop_mismatch: float = 0.8  # at or above this, the expected word doesn't fit the audio
    verify_min_confidence: float = 0.3  # mean CTC confidence below which a clip is unclear
    # C3 reading / picture-description check (/check-speech): share of passage words read or keywords mentioned.
    speech_check_pass: float = 0.5  # at or above: match (calibrated on SLR52, C3 log V-33: ASR errors cost correct readings ~1/3 of words)
    speech_check_partial: float = 0.25  # at or above: partial; below: mismatch (a wrong passage scored at most 0.11)


@lru_cache
def get_settings() -> Settings:
    return Settings()
