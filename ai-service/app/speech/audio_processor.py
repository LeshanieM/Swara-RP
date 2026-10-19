"""
Audio processing and validation module for Component 1.
Handles audio ingestion, validation, resampling to 16 kHz mono float32,
sliding window segmentation (3.0s window, 1.5s step), and pause/acoustic feature analysis.
"""

import io
import math
from pathlib import Path
from typing import List, Tuple, Union
import numpy as np
import soundfile as sf
import librosa

from app.config.speech_settings import (
    TARGET_SAMPLE_RATE,
    TARGET_CHANNELS,
    MIN_AUDIO_DURATION_S,
    MAX_AUDIO_DURATION_S,
    MAX_FILE_SIZE_BYTES,
    WINDOW_DURATION_S,
    STEP_DURATION_S,
    TASK_AGE_RANGES,
    TASK_PICTURE_DESCRIPTION,
    TASK_PASSAGE_READING,
    ALLOWED_TASK_TYPES,
    OVERALL_MIN_AGE,
    OVERALL_MAX_AGE,
)


class AudioValidationError(Exception):
    """Raised when an audio input file fails validation."""
    pass


class TaskAgeValidationError(Exception):
    """Raised when the child's age is incompatible with the selected task type."""
    pass


def validate_task_and_age(task_type: str, age: float) -> None:
    """
    Validates task type and child age per Section 2 requirements:
    - Picture-description task: Ages 5–10
    - Passage-reading task: Ages 11–14
    """
    if task_type not in ALLOWED_TASK_TYPES:
        raise TaskAgeValidationError(
            f"Invalid task_type '{task_type}'. Allowed tasks are: {ALLOWED_TASK_TYPES}."
        )

    if age < OVERALL_MIN_AGE or age > OVERALL_MAX_AGE:
        raise TaskAgeValidationError(
            f"Child age {age} is outside the supported range ({OVERALL_MIN_AGE}–{OVERALL_MAX_AGE} years)."
        )

    expected_range = TASK_AGE_RANGES[task_type]
    min_a = expected_range["min_age"]
    max_a = expected_range["max_age"]

    if age < min_a or age > max_a:
        raise TaskAgeValidationError(
            f"Task '{task_type}' is designated for ages {min_a}–{max_a}, but child age is {age}. "
            f"For ages 5–10, please select '{TASK_PICTURE_DESCRIPTION}'. "
            f"For ages 11–14, please select '{TASK_PASSAGE_READING}'."
        )


def load_and_preprocess_audio(
    file_bytes_or_path: Union[bytes, str, Path],
    filename: str = "audio.wav",
) -> Tuple[np.ndarray, float]:
    """
    Ingests an audio recording, validates file size, format, and duration,
    and converts to 16 kHz mono float32 normalized in [-1.0, 1.0].

    Returns:
        audio_16k: 1D numpy array of float32 samples at 16000 Hz.
        duration_s: Audio duration in seconds.
    """
    # 1. File size validation if raw bytes
    if isinstance(file_bytes_or_path, bytes):
        if len(file_bytes_or_path) > MAX_FILE_SIZE_BYTES:
            raise AudioValidationError(
                f"File size exceeds maximum permitted limit ({MAX_FILE_SIZE_BYTES // (1024 * 1024)} MB)."
            )
        if len(file_bytes_or_path) < 44:
            raise AudioValidationError("Audio file is too small or truncated (invalid header).")
        audio_source = io.BytesIO(file_bytes_or_path)
    else:
        path = Path(file_bytes_or_path)
        if not path.exists():
            raise AudioValidationError(f"Audio file not found: {path}")
        if path.stat().st_size > MAX_FILE_SIZE_BYTES:
            raise AudioValidationError(
                f"File size exceeds maximum permitted limit ({MAX_FILE_SIZE_BYTES // (1024 * 1024)} MB)."
            )
        audio_source = str(path)

    # 2. Decode audio with soundfile / librosa
    try:
        data, sample_rate = sf.read(audio_source, dtype="float32")
    except Exception as sf_err:
        # Fall back to librosa if soundfile direct read encounters container issues
        try:
            if isinstance(audio_source, io.BytesIO):
                audio_source.seek(0)
            data, sample_rate = librosa.load(audio_source, sr=None, mono=False)
            data = data.T if data.ndim > 1 else data
        except Exception as lib_err:
            raise AudioValidationError(
                f"Could not decode audio file '{filename}'. Ensure it is a valid WAV or supported audio format. "
                f"Errors: {str(sf_err)}; {str(lib_err)}"
            )

    if data is None or len(data) == 0:
        raise AudioValidationError("Audio file contains no readable samples.")

    # 3. Convert multi-channel to mono
    if data.ndim > 1:
        data = np.mean(data, axis=1)

    # 4. Resample to 16000 Hz if necessary
    if sample_rate != TARGET_SAMPLE_RATE:
        data = librosa.resample(data, orig_sr=sample_rate, target_sr=TARGET_SAMPLE_RATE)
        sample_rate = TARGET_SAMPLE_RATE

    data = data.astype(np.float32)

    # 5. Check amplitude and normalize
    max_amp = np.max(np.abs(data))
    if max_amp == 0.0 or np.isnan(max_amp):
        raise AudioValidationError("Audio signal is entirely silent or contains invalid NaN values.")

    # Prevent clipping and normalize to standard [-1.0, 1.0] range
    if max_amp > 1.0:
        data = data / max_amp
    elif max_amp > 0.01:
        # Mild peak normalization with headroom
        data = data / (max_amp + 1e-6) * 0.95

    # 6. Duration checks
    duration_s = float(len(data)) / float(TARGET_SAMPLE_RATE)
    if duration_s < MIN_AUDIO_DURATION_S:
        raise AudioValidationError(
            f"Audio duration ({duration_s:.2f}s) is shorter than the minimum required ({MIN_AUDIO_DURATION_S:.1f}s)."
        )
    if duration_s > MAX_AUDIO_DURATION_S:
        raise AudioValidationError(
            f"Audio duration ({duration_s:.2f}s) exceeds the maximum allowed ({MAX_AUDIO_DURATION_S:.1f}s)."
        )

    return data, duration_s


def segment_into_windows(
    audio: np.ndarray,
    sample_rate: int = TARGET_SAMPLE_RATE,
    window_duration_s: float = WINDOW_DURATION_S,
    step_duration_s: float = STEP_DURATION_S,
) -> List[Tuple[np.ndarray, float, float]]:
    """
    Segments 16 kHz audio into overlapping windows per Section 3:
    3-second windows with a 1.5-second step.

    Returns:
        List of tuples: (window_samples, start_time_s, end_time_s)
    """
    window_samples = int(window_duration_s * sample_rate)
    step_samples = int(step_duration_s * sample_rate)
    total_samples = len(audio)

    windows = []
    start_sample = 0

    while start_sample < total_samples:
        end_sample = start_sample + window_samples
        start_time_s = start_sample / sample_rate

        if end_sample <= total_samples:
            chunk = audio[start_sample:end_sample]
            end_time_s = end_sample / sample_rate
        else:
            # Last window: pad with zeros to maintain exact 3-second window for transformer model
            chunk = np.zeros(window_samples, dtype=np.float32)
            remaining = total_samples - start_sample
            chunk[:remaining] = audio[start_sample:]
            end_time_s = total_samples / sample_rate

        windows.append((chunk, round(start_time_s, 3), round(end_time_s, 3)))
        start_sample += step_samples

        # Break if the remaining signal is less than 0.5s to avoid duplicate padding
        if (total_samples - start_sample) < int(0.5 * sample_rate):
            break

    return windows


def extract_acoustic_features(
    audio: np.ndarray,
    sample_rate: int = TARGET_SAMPLE_RATE,
) -> dict:
    """
    Computes duration, silent pause count, average pause duration,
    and speech rate for C1/C2/C3 compatibility.
    """
    duration = float(len(audio)) / float(sample_rate)

    # Short-time energy / RMS envelope for silence / pause detection
    frame_length = int(0.025 * sample_rate)  # 25 ms
    hop_length = int(0.010 * sample_rate)    # 10 ms
    rms = librosa.feature.rms(y=audio, frame_length=frame_length, hop_length=hop_length)[0]

    # Dynamic silence threshold (-35 dB below maximum RMS)
    max_rms = np.max(rms) if len(rms) > 0 else 1e-4
    silence_thresh = max(max_rms * 0.03, 1e-4)

    is_silent = rms < silence_thresh
    silent_runs = []
    current_run = 0

    for silent in is_silent:
        if silent:
            current_run += 1
        else:
            if current_run > 0:
                duration_run_s = (current_run * hop_length) / sample_rate
                # Pauses are defined as silence > 250 ms (0.25s)
                if duration_run_s >= 0.25:
                    silent_runs.append(duration_run_s)
                current_run = 0

    if current_run > 0:
        duration_run_s = (current_run * hop_length) / sample_rate
        if duration_run_s >= 0.25:
            silent_runs.append(duration_run_s)

    pause_count = len(silent_runs)
    avg_pause_duration = float(np.mean(silent_runs)) if pause_count > 0 else 0.0

    # Total speech duration (active phonation)
    active_speech_duration = max(0.1, duration - sum(silent_runs))
    
    # Heuristic word count estimation based on Sinhala average speaking rate
    # (~2.2 words per second of active speech for children)
    estimated_word_count = max(1, int(round(active_speech_duration * 2.2)))
    speech_rate = round(float(estimated_word_count) / max(duration / 60.0, 0.01), 2)  # words per minute

    return {
        "duration": round(duration, 2),
        "pauseCount": pause_count,
        "averagePauseDuration": round(avg_pause_duration, 2),
        "speechRate": speech_rate,
        "estimatedWordCount": estimated_word_count,
        "activeSpeechDuration": round(active_speech_duration, 2),
    }
