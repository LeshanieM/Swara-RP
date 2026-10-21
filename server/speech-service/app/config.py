"""Runtime settings for the C1 speech service.

Every value can be overridden with an environment variable prefixed ``C1_``
(for example ``C1_DETECTOR=xlsr``) or in a local ``.env`` file.
"""
from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

SERVICE_VERSION = "0.1.0"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="C1_", env_file=".env", extra="ignore")

    # Detector selection: "acoustic" (default, no training needed) or "xlsr".
    detector: str = "acoustic"
    model_dir: Path = Path(__file__).resolve().parent.parent / "models"
    xlsr_model_name: str = "facebook/wav2vec2-xls-r-300m"

    # Audio constraints.
    sample_rate: int = 16000
    min_duration_sec: float = 1.0
    max_duration_sec: float = 180.0
    max_upload_mb: int = 50

    # Windowing used by every detector (3 s windows, 1.5 s hop).
    window_sec: float = 3.0
    hop_sec: float = 1.5
    window_threshold: float = 0.5

    # At most this many analyses run at once; others wait.
    max_concurrent_analyses: int = 2


@lru_cache
def get_settings() -> Settings:
    return Settings()
