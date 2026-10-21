"""Video files: temporary storage, probing and validation.

PyAV reads the container (duration, streams); OpenCV decodes frames in
``landmarks.py`` because it applies the phone's rotation flag automatically.
"""
import os
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass

ALLOWED_EXT = (".mp4", ".mov", ".m4v", ".webm", ".mkv", ".avi")


class VideoError(Exception):
    """A problem with the uploaded video itself (maps to HTTP 422)."""

    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code, self.message = code, message


@dataclass
class VideoInfo:
    duration_sec: float
    fps: float
    width: int
    height: int
    has_audio: bool
    container: str
    codec: str


@contextmanager
def temp_file(data: bytes, filename: str | None):
    """Write the upload to a private temp file and remove it afterwards."""
    ext = os.path.splitext(filename or "")[1].lower() or ".mp4"
    fd, path = tempfile.mkstemp(prefix="c2-", suffix=ext)
    try:
        with os.fdopen(fd, "wb") as fh:
            fh.write(data)
        yield path
    finally:
        try:
            os.remove(path)
        except FileNotFoundError:
            pass


def probe(path: str) -> VideoInfo:
    import av

    try:
        with av.open(path) as container:
            vstreams = [s for s in container.streams if s.type == "video"]
            if not vstreams:
                raise VideoError("no_video_stream", "The file has no video stream.")
            v = vstreams[0]
            has_audio = any(s.type == "audio" for s in container.streams)
            if container.duration:
                duration = container.duration / 1_000_000
            elif v.duration and v.time_base:
                duration = float(v.duration * v.time_base)
            else:
                duration = 0.0
            rate = v.average_rate or v.guessed_rate or 0
            ctx = v.codec_context
            # Rotation metadata is applied by OpenCV when decoding; report the displayed size.
            width, height = ctx.width, ctx.height
            rotation = abs(int(getattr(v, "metadata", {}).get("rotate", 0) or 0))
            if rotation in (90, 270):
                width, height = height, width
            return VideoInfo(
                duration_sec=round(float(duration), 3),
                fps=round(float(rate), 3) if rate else 0.0,
                width=int(width or 0),
                height=int(height or 0),
                has_audio=has_audio,
                container=container.format.name,
                codec=ctx.name,
            )
    except VideoError:
        raise
    except Exception as exc:  # av raises many error types for corrupt input
        raise VideoError("unreadable_video", f"The file could not be read as a video ({type(exc).__name__}).") from exc


def validate(info: VideoInfo, min_sec: float, max_sec: float) -> None:
    if info.duration_sec <= 0 or info.width <= 0 or info.height <= 0:
        raise VideoError("unreadable_video", "The video has no readable frames or duration.")
    if info.duration_sec < min_sec:
        raise VideoError("video_too_short", f"Video is {info.duration_sec:.1f} s; at least {min_sec:g} s is needed.")
    if info.duration_sec > max_sec:
        raise VideoError("video_too_long", f"Video is {info.duration_sec:.1f} s; the limit is {max_sec:g} s.")
