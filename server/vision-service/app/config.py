"""Runtime settings for the C2 vision service.

Every value can be overridden with an environment variable prefixed ``C2_``
(for example ``C2_DETECTOR=gru``) or in a local ``.env`` file.
"""
from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

SERVICE_VERSION = "0.1.0"
SERVICE_ROOT = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="C2_", env_file=".env", extra="ignore")

    # Detector: "srcd" (label-free, default), "rules" (baseline), "gru" or "transformer" (trained file).
    detector: str = "srcd"
    model_dir: Path = SERVICE_ROOT / "models"
    face_model_file: str = "face_landmarker.task"
    learned_model_file: str = "c2_srcd.pt"

    # Video constraints.
    min_duration_sec: float = 2.0
    max_duration_sec: float = 180.0
    max_upload_mb: int = 200
    # Frames are analysed at this rate (the source rate if lower).
    target_fps: float = 15.0
    # Faces narrower than this share of the frame width are too small to track reliably.
    min_face_width_ratio: float = 0.08

    # Speaker-relative baseline.
    # Frames this close to a stutter moment are not used as "fluent" baseline.
    baseline_guard_sec: float = 0.5
    # Below this much fluent, face-visible time the baseline falls back to the whole recording.
    min_baseline_sec: float = 4.0
    # (Each feature's smallest allowed spread is set in features/catalog.py.)

    # Moment scoring.
    # Each stutter moment is examined with this padding on both sides.
    moment_pad_sec: float = 0.25
    # A signal deviates when its held deviation beats the child's own fluent stretches
    # (empirical null) at this family-wise false-positive rate per category ...
    null_alpha: float = 0.05
    # ... and is at least this many baseline SDs (also the only bar when the null is too small) ...
    deviation_threshold: float = 3.0
    # ... held for at least this long (seconds, rounded up to frames at the analysed rate).
    # 0.3 s is longer than an ordinary blink, so blinks cannot pass as held eye closure.
    min_deviation_sec: float = 0.3
    # Fewer fluent stretches than this and the null is not used.
    min_null_spans: int = 20
    # Prior for how heavy a child's fluent-movement tail is (SD per e-fold), used when the
    # recording has little fluent speech. 1.5 is the value at which the false-positive rate
    # on 44 fluent spans matched null_alpha (5 % FG, 0 % HM); chosen on fluent speech only.
    tail_prior_sd: float = 1.5
    # A moment is "assessed" only if the face is visible in at least this share of its frames.
    min_moment_face_ratio: float = 0.5
    # Below this share of frames with a face, the whole video gets a low_face_coverage warning.
    low_face_coverage_ratio: float = 0.7

    # At most this many analyses run at once; others wait.
    max_concurrent_analyses: int = 2

    @property
    def face_model_path(self) -> Path:
        return self.model_dir / self.face_model_file

    @property
    def learned_model_path(self) -> Path:
        return self.model_dir / self.learned_model_file


@lru_cache
def get_settings() -> Settings:
    return Settings()
