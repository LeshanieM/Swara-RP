"""Extract a video's audio track as 16 kHz mono 16-bit WAV (C1's preferred input).

PyAV's wheels bundle the FFmpeg libraries, so no system ffmpeg is required.
"""
import io
import wave

import numpy as np

from app.video.io import VideoError

SAMPLE_RATE = 16000


def extract_wav(path: str) -> tuple[bytes, float]:
    """Return (wav_bytes, duration_sec) for the first audio stream."""
    import av

    try:
        with av.open(path) as container:
            streams = [s for s in container.streams if s.type == "audio"]
            if not streams:
                raise VideoError("no_audio_track", "The video has no audio track, so C1 cannot find stutter moments in it.")
            resampler = av.AudioResampler(format="s16", layout="mono", rate=SAMPLE_RATE)
            chunks = []
            for frame in container.decode(streams[0]):
                for out in resampler.resample(frame):
                    chunks.append(out.to_ndarray().reshape(-1))
            for out in resampler.resample(None):  # flush
                chunks.append(out.to_ndarray().reshape(-1))
    except VideoError:
        raise
    except Exception as exc:
        raise VideoError("audio_decode_failed", f"The audio track could not be decoded ({type(exc).__name__}).") from exc

    samples = np.concatenate(chunks).astype(np.int16) if chunks else np.zeros(0, dtype=np.int16)
    if samples.size == 0:
        raise VideoError("no_audio_track", "The audio track is empty.")
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(samples.tobytes())
    return buf.getvalue(), round(samples.size / SAMPLE_RATE, 3)
