"""
Syllable counting and %SS (Percentage of Syllables Stuttered) estimation module.

Documented Method:
------------------
Acoustic Syllable Nucleus Detection (de Jong & Wempe 2009; Pfitzinger 1996):
1. Bandpass filter the 16 kHz audio between 300 Hz and 3400 Hz (first and second vowel formant region).
2. Compute the smoothed Hilbert envelope / short-time intensity envelope (25 ms frame, 10 ms hop).
3. Detect local intensity peaks (vowel nuclei) with minimum peak separation (130 ms, corresponding to
   a maximum child speaking rate of ~7.7 syllables/sec) and minimum prominence drop (2.5 dB).
4. Cross-reference detected syllable nuclei against the temporal boundaries of detected stuttering events.
5. Derive %SS = (syllables_stuttered / total_syllables) * 100.
6. Provide an orthographic Sinhala syllable counter when reference passage text is available.
"""

from typing import List, Tuple, Dict, Any, Optional
import numpy as np
import scipy.signal

from app.config.speech_settings import (
    TARGET_SAMPLE_RATE,
    MIN_SYLLABLE_DISTANCE_S,
    MIN_TOTAL_SYLLABLES_FOR_SS,
)


def count_acoustic_syllables(
    audio: np.ndarray,
    sample_rate: int = TARGET_SAMPLE_RATE,
    min_distance_s: float = MIN_SYLLABLE_DISTANCE_S,
) -> Tuple[int, List[float], float]:
    """
    Detects vowel nuclei (syllables) in the speech audio using intensity envelope peak detection.

    Returns:
        total_syllables: Total number of detected syllable nuclei.
        syllable_timestamps: List of timestamp centers (in seconds) for each detected syllable.
        syllable_rate: Syllables per second over active duration.
    """
    if len(audio) < int(0.2 * sample_rate):
        return 0, [], 0.0

    # 1. Bandpass filter 300 - 3400 Hz (vowel formant resonance region)
    nyquist = sample_rate / 2.0
    low = 300.0 / nyquist
    high = min(3400.0 / nyquist, 0.99)
    try:
        b, a = scipy.signal.butter(4, [low, high], btype="band")
        filtered_audio = scipy.signal.filtfilt(b, a, audio)
    except Exception:
        filtered_audio = audio

    # 2. Compute smoothed energy envelope
    frame_len = int(0.025 * sample_rate)  # 25 ms
    hop_len = int(0.010 * sample_rate)    # 10 ms
    num_frames = (len(filtered_audio) - frame_len) // hop_len + 1

    if num_frames < 2:
        return 0, [], 0.0

    # Frame-wise root-mean-square energy in dB
    envelope = np.zeros(num_frames, dtype=np.float32)
    for i in range(num_frames):
        start = i * hop_len
        end = start + frame_len
        frame = filtered_audio[start:end]
        rms = np.sqrt(np.mean(frame ** 2) + 1e-12)
        envelope[i] = rms

    # Convert to dB relative to peak
    max_env = np.max(envelope)
    if max_env < 1e-5:
        return 0, [], 0.0

    envelope_db = 20.0 * np.log10(envelope / max_env + 1e-12)

    # 3. Peak detection
    # Minimum samples between peaks
    min_dist_frames = max(1, int(min_distance_s * (sample_rate / hop_len)))
    # Prominence: at least 2.5 dB drop into valley
    prominence_db = 2.5
    # Absolute height: peak must be within -30 dB of max peak to ignore background noise
    min_height_db = -32.0

    peaks, properties = scipy.signal.find_peaks(
        envelope_db,
        distance=min_dist_frames,
        prominence=prominence_db,
        height=min_height_db,
    )

    syllable_timestamps = [round((p * hop_len + frame_len // 2) / sample_rate, 3) for p in peaks]
    total_syllables = len(syllable_timestamps)

    total_duration = len(audio) / sample_rate
    syllable_rate = round(total_syllables / max(total_duration, 0.1), 2)

    return total_syllables, syllable_timestamps, syllable_rate


def count_sinhala_text_syllables(text: str) -> int:
    """
    Orthographic syllable counter for Sinhala script.
    In Sinhala:
    - Independent vowels (අ, ආ, ඇ, ඈ, ඉ, ඊ, උ, ඌ, ඍ, ඎ, එ, ඒ, ඔ, ඕ) start a syllable.
    - Base consonants without hal-kireema (්) have an inherent /a/ vowel and represent a syllable.
    - Consonants with vowel diacritics (පිල්ලම්) represent a syllable.
    - Consonants with hal-kireema (්) are coda consonants and do not increment syllable count.
    - Special signs (ං, ඃ) do not form independent syllables.
    """
    if not text:
        return 0

    # Unicode ranges for Sinhala
    # Independent vowels: 0x0D85 to 0x0D96
    # Consonants: 0x0D9A to 0x0DC6
    # Hal kireema (virama): 0x0DCA
    # Vowel signs (diacritics): 0x0DCF to 0x0DF3
    syllable_count = 0
    chars = list(text)
    n = len(chars)

    for i in range(n):
        code = ord(chars[i])
        # Independent vowel
        if 0x0D85 <= code <= 0x0D96:
            syllable_count += 1
        # Consonant
        elif 0x0D9A <= code <= 0x0DC6:
            # Check if followed by virama (hal kireema)
            if i + 1 < n and ord(chars[i + 1]) == 0x0DCA:
                # Coda consonant / consonant cluster part -> not a syllable nucleus
                pass
            else:
                syllable_count += 1

    return max(1, syllable_count)


DEFAULT_SINHALA_READING_PASSAGE = (
    "අද උදෑසන නදී සහ ඇගේ මිතුරන් පාසල් වත්තට ගියා. "
    "ඔවුන් එහි තිබූ ලස්සන මල් පැල නිරීක්ෂණය කළා. "
    "පසුව ඔවුන් ගුරුවරිය සමඟ එකතු වී වත්ත පිරිසිදු කළා. "
    "මෙම කාර්යය ඔවුන්ට ඉතා සතුටක් ගෙන දුන්නා."
)


def resolve_total_syllables(
    task_type: str,
    audio_duration_s: float,
    acoustic_syllables: int,
    transcript: Optional[str] = None,
    reference_text: Optional[str] = None,
) -> Tuple[int, str]:
    """
    Resolves total spoken syllables per Section 2 & Page 6 specifications:
    - Ages 11-14 (Passage reading): Text is known -> exact syllable count, adjusted if child stopped early.
    - Ages 5-10 (Picture description): Count syllables from C4 transcript if provided, else acoustic energy peaks.
    """
    norm_task = (task_type or "").lower()

    if "read" in norm_task or "passage" in norm_task:
        # Passage reading (ages 11–14)
        passage = reference_text or DEFAULT_SINHALA_READING_PASSAGE
        exact_syllables = count_sinhala_text_syllables(passage)
        # Expected normal pace duration for this ~35 syllable passage is ~20 seconds
        expected_full_duration = 20.0
        if audio_duration_s < 16.0:
            ratio = min(1.0, max(0.2, audio_duration_s / expected_full_duration))
            adjusted_syllables = int(round(exact_syllables * ratio))
            total = max(acoustic_syllables, max(MIN_TOTAL_SYLLABLES_FOR_SS, adjusted_syllables))
            source = "Sinhala Known Passage Text (Adjusted for Early Stop)"
        else:
            total = exact_syllables
            source = "Sinhala Known Passage Text (Exact Orthographic Count)"
        return total, source
    else:
        # Picture description (ages 5–10)
        if transcript and transcript.strip():
            transcript_syllables = count_sinhala_text_syllables(transcript)
            return transcript_syllables, "C4 Sinhala Transcript Syllable Count"
        else:
            return acoustic_syllables, "Acoustic Intensity Nucleus Peak Detection (de Jong & Wempe)"


def calculate_stuttered_syllables(
    syllable_timestamps: List[float],
    detected_events: List[Dict[str, Any]],
    total_duration_s: float,
    total_syllables_override: Optional[int] = None,
    event_based_counting: bool = False,
) -> Tuple[int, float, bool]:
    """
    Computes:
    - stuttered_syllables: Number of syllables affected by stuttering events.
      In clinical %SS counting (event_based_counting=True): each detected event counts once.
    - percent_ss: Percentage of syllables stuttered (%SS).
    - is_reliable: Whether the total syllable count is sufficient for reliable calculation.
    """
    total_syllables = total_syllables_override if total_syllables_override is not None else len(syllable_timestamps)

    if total_syllables < MIN_TOTAL_SYLLABLES_FOR_SS:
        # Insufficient speech or silence
        return 0, 0.0, False

    if event_based_counting:
        # Clinical %SS event-based definition: each detected event counts once
        stuttered_count = len(detected_events)
        percent_ss = round((stuttered_count / max(total_syllables, 1)) * 100.0, 2)
        percent_ss = min(100.0, percent_ss)
        return stuttered_count, percent_ss, True

    stuttered_indices = set()

    for event in detected_events:
        start = event.get("start_time", event.get("startTime", 0.0))
        end = event.get("end_time", event.get("endTime", 0.0))
        event_type = event.get("event_type", event.get("eventType", ""))

        # Check which acoustic syllables fall inside the event interval
        matched = [i for i, t in enumerate(syllable_timestamps) if start <= t <= end]

        if matched:
            for idx in matched:
                stuttered_indices.add(idx)
        else:
            # If the event is short or between detected peaks (e.g., tense block or quick repetition),
            # count at least one stuttered syllable for the event.
            if "Repetition" in event_type:
                dur = max(0.3, end - start)
                estimated_reps = max(1, int(round(dur / 0.25)))
                total_syllables += max(0, estimated_reps - 1)
                for k in range(estimated_reps):
                    stuttered_indices.add(len(syllable_timestamps) + k)
            else:
                stuttered_indices.add(f"event_{start}_{end}")

    stuttered_count = len(stuttered_indices)
    percent_ss = round((stuttered_count / max(total_syllables, 1)) * 100.0, 2)
    percent_ss = min(100.0, percent_ss)

    return stuttered_count, percent_ss, True
