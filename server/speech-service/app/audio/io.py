"""Audio loading: any libsndfile-readable file (WAV, FLAC, OGG, MP3), or AAC / M4A / MP4 audio through PyAV,
-> mono float32 at the target rate."""
import io
from dataclasses import dataclass

import numpy as np
import soundfile as sf
import soxr


class AudioError(ValueError):
    """Raised when an upload can't be analysed. ``code`` is machine-readable."""

    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


@dataclass
class LoadedAudio:
    signal: np.ndarray  # mono float32 at ``sample_rate``
    sample_rate: int
    original_sample_rate: int
    channels: int
    format: str
    duration_sec: float


def load_audio(data: bytes, target_sr: int, min_sec: float, max_sec: float) -> LoadedAudio:
    if not data:
        raise AudioError("empty_audio", "The uploaded audio file is empty.")
    try:
        info = sf.info(io.BytesIO(data))
        signal, sr = sf.read(io.BytesIO(data), dtype="float32", always_2d=True)
        fmt = info.format
    except Exception as exc:  # libsndfile raises RuntimeError/LibsndfileError
        try:
            signal, sr, fmt = _decode_av(data)
        except Exception:
            raise AudioError(
                "unsupported_audio",
                "Could not decode the audio. Send WAV (16 kHz mono preferred), FLAC, OGG, MP3 or M4A/AAC.",
            ) from exc

    channels = signal.shape[1]
    mono = signal.mean(axis=1)
    duration = len(mono) / sr
    if duration < min_sec:
        raise AudioError("audio_too_short", f"Audio is {duration:.2f} s; at least {min_sec:g} s is required.")
    if duration > max_sec:
        raise AudioError("audio_too_long", f"Audio is {duration:.1f} s; at most {max_sec:g} s is allowed.")
    if not np.isfinite(mono).all() or np.max(np.abs(mono)) < 1e-4:
        raise AudioError("silent_audio", "The recording is silent.")

    if sr != target_sr:
        mono = soxr.resample(mono, sr, target_sr)
    return LoadedAudio(
        signal=mono.astype(np.float32),
        sample_rate=target_sr,
        original_sample_rate=sr,
        channels=channels,
        format=fmt,
        duration_sec=len(mono) / target_sr,
    )


def _decode_av(data: bytes) -> tuple[np.ndarray, int, str]:
    """Decodes containers libsndfile can't read (phone recordings: M4A / AAC / MP4 audio) with PyAV.
    Returns (frames x channels float32, sample rate, container name)."""
    import av  # imported here: only needed for these formats

    with av.open(io.BytesIO(data)) as container:
        stream = next(s for s in container.streams if s.type == "audio")
        sr = stream.codec_context.sample_rate or stream.rate
        channels = stream.codec_context.channels or 1
        # Planar float out, one row per channel; keeps the original rate (resampled later with soxr).
        resampler = av.AudioResampler(format="fltp", layout="stereo" if channels > 1 else "mono", rate=sr)
        chunks = []
        for frame in container.decode(stream):
            for out in resampler.resample(frame):
                chunks.append(out.to_ndarray())
        for out in resampler.resample(None):
            chunks.append(out.to_ndarray())
        name = container.format.name
    if not chunks:
        raise ValueError("no audio frames")
    signal = np.concatenate(chunks, axis=1).T.astype(np.float32)
    return signal, int(sr), "M4A" if "m4a" in name.split(",") else name.split(",")[0].upper()
