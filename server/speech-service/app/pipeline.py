"""C1 pipeline: audio -> frames -> windows -> events -> syllables -> severity."""
import time
from collections import Counter

import numpy as np

from app.audio.features import analyse_frames, speech_features
from app.audio.io import AudioError, load_audio
from app.config import SERVICE_VERSION, get_settings
from app.detection import registry
from app.detection.base import LABELS, STUTTER_LABELS
from app.detection.events import build_events, stutter_moments
from app.schemas import AnalysisResponse
from app.severity.baselines import mimi_chunk_ratio
from app.severity.scoring import duration_term, percent_ss, score
from app.severity.syllables import count_syllables

COUNT_KEYS = {
    "block": "block",
    "prolongation": "prolongation",
    "sound_repetition": "soundRepetition",
    "word_repetition": "wordRepetition",
    "interjection": "interjection",
}
LEGACY_TYPE = {"block": "Block", "prolongation": "Prolongation", "sound_repetition": "Repetition", "word_repetition": "Repetition"}
LEGACY_SEVERITY = {"none_very_mild": "None", "mild": "Mild", "moderate": "Moderate", "severe": "Severe"}

# Reading: warn when the audio holds far fewer syllables than the passage.
PASSAGE_INCOMPLETE_RATIO = 0.6
MIN_RELIABLE_SYLLABLES = 100
# Transcript syllables / audio estimate outside this range -> warn.
TRANSCRIPT_RATIO_RANGE = (0.6, 1.6)


def _syllables(task_type: str, passage_text: str | None, transcript: str | None, estimated: int, warnings: list) -> dict:
    if task_type == "reading" and passage_text:
        from_text = count_syllables(passage_text)["total"]
        if from_text and estimated < PASSAGE_INCOMPLETE_RATIO * from_text:
            warnings.append({
                "code": "passage_possibly_incomplete",
                "message": f"About {estimated} syllables were heard but the passage has {from_text}; "
                "%SS uses the passage count, so it may be underestimated if the child stopped early.",
            })
        return {"total": from_text, "source": "passage", "estimatedFromAudio": estimated, "fromText": from_text}
    if transcript and transcript.strip():
        from_text = count_syllables(transcript)["total"]
        if from_text:
            ratio = from_text / max(estimated, 1)
            if not TRANSCRIPT_RATIO_RANGE[0] <= ratio <= TRANSCRIPT_RATIO_RANGE[1]:
                warnings.append({
                    "code": "transcript_mismatch",
                    "message": f"The transcript has {from_text} syllables but about {estimated} were heard; "
                    "check that it covers the whole recording, since %SS uses the transcript count.",
                })
            return {"total": from_text, "source": "transcript", "estimatedFromAudio": estimated, "fromText": from_text}
        warnings.append({"code": "transcript_unusable", "message": "No syllables found in the transcript; using the audio estimate."})
    return {"total": estimated, "source": "estimated", "estimatedFromAudio": estimated, "fromText": None}


def _legacy_summary(counts: Counter, moments: list, events: list, max_stutter_prob: float, severity_label: str) -> dict:
    grouped = Counter()
    for label in STUTTER_LABELS:
        grouped[LEGACY_TYPE[label]] += counts[label]
    ranked = grouped.most_common()
    if not moments:
        stutter_type = "None"
    elif len(ranked) > 1 and ranked[0][1] == ranked[1][1]:
        stutter_type = "Mixed"
    else:
        stutter_type = ranked[0][0]
    stutter_conf = [e.confidence for e in events if e.type in STUTTER_LABELS]
    confidence = float(np.mean(stutter_conf)) if stutter_conf else 1.0 - max_stutter_prob
    return {
        "stutterDetected": bool(moments),
        "stutterType": stutter_type,
        "severity": LEGACY_SEVERITY[severity_label],
        "confidence": round(confidence, 3),
    }


def _primary_type(stutter_counts: dict, events: list) -> str | None:
    """The most frequent stutter label, chosen by group first: sound and word repetitions count together
    (as in summary.stutterType), so two kinds of repetition are not outvoted by one block. Ties go to the
    longer total duration, not to label order."""
    if not stutter_counts:
        return None
    seconds = Counter()
    for e in events:
        seconds[e.type] += e.duration
    groups = Counter()
    for label, n in stutter_counts.items():
        groups[LEGACY_TYPE[label]] += n
    group_seconds = Counter()
    for label in stutter_counts:
        group_seconds[LEGACY_TYPE[label]] += seconds[label]
    best = max(groups, key=lambda g: (groups[g], group_seconds[g]))
    members = [label for label in stutter_counts if LEGACY_TYPE[label] == best]
    return max(members, key=lambda label: (stutter_counts[label], seconds[label]))


def analyze(
    data: bytes,
    task_type: str,
    language: str,
    passage_text: str | None = None,
    transcript: str | None = None,
    concomitant_score: float | None = None,
    include_windows: bool = False,
) -> AnalysisResponse:
    started = time.perf_counter()
    settings = get_settings()
    audio = load_audio(data, settings.sample_rate, settings.min_duration_sec, settings.max_duration_sec)
    frames = analyse_frames(audio.signal, audio.sample_rate)
    if not frames.active.any() or len(frames.nuclei) == 0:
        raise AudioError("no_speech_detected", "No speech was found in the recording.")

    detector, chosen = registry.resolve(settings.detector)
    output = detector.detect(audio.signal, audio.sample_rate, frames)
    threshold = settings.window_threshold
    events = build_events(output, frames, threshold)
    moments = stutter_moments(events)
    counts = Counter(e.type for e in events)

    warnings: list[dict] = []
    if chosen["fallback"]:
        warnings.append({"code": "detector_fallback", "message": f"Detector '{chosen['requested']}' unavailable ({chosen['fallbackReason']}); used '{detector.name}'."})
    syllables = _syllables(task_type, passage_text, transcript, len(frames.nuclei), warnings)
    if syllables["total"] < MIN_RELIABLE_SYLLABLES:
        warnings.append({
            "code": "short_sample",
            "message": f"Only {syllables['total']} syllables; %SS is unstable below {MIN_RELIABLE_SYLLABLES} "
            "(clinical samples usually have 200+).",
        })

    pss = percent_ss(len(moments), syllables["total"])
    dur = duration_term(moments)
    severity = score(task_type, pss, dur, concomitant_score)
    stutter_cols = [LABELS.index(label) for label in STUTTER_LABELS]
    max_stutter_prob = float(output.probs[:, stutter_cols].max()) if output.probs.size else 0.0
    stutter_counts = {label: counts[label] for label in STUTTER_LABELS if counts[label]}

    result = {
        "taskType": task_type,
        "language": language,
        "audio": {
            "durationSec": round(audio.duration_sec, 3),
            "sampleRate": audio.sample_rate,
            "originalSampleRate": audio.original_sample_rate,
            "channels": audio.channels,
            "format": audio.format,
        },
        "detector": {"name": detector.name, "version": detector.version, **chosen},
        "windows": {"sizeSec": settings.window_sec, "hopSec": settings.hop_sec, "threshold": threshold, "count": len(output.windows)},
        "events": [
            {"type": e.type, "start": round(e.start, 2), "end": round(e.end, 2), "duration": round(e.duration, 2), "confidence": round(e.confidence, 3)}
            for e in events
        ],
        "stutterMoments": [
            {"start": round(m.start, 2), "end": round(m.end, 2), "duration": round(m.duration, 2), "types": m.types} for m in moments
        ],
        "counts": {COUNT_KEYS[label]: counts[label] for label in LABELS},
        "primaryType": _primary_type(stutter_counts, events),
        "syllables": syllables,
        "stutteredSyllables": len(moments),
        "percentSS": pss,
        "durationTerm": dur,
        "severity": severity,
        "baselines": {"mimiChunkRatio": mimi_chunk_ratio(output, threshold)},
        "features": speech_features(frames, syllables["total"]),
        "summary": _legacy_summary(counts, moments, events, max_stutter_prob, severity["label"]),
        "warnings": warnings,
        "processingMs": int((time.perf_counter() - started) * 1000),
        "serviceVersion": SERVICE_VERSION,
    }
    if include_windows:
        result["windowScores"] = [
            {"start": s, "end": e, "scores": {label: round(float(p), 3) for label, p in zip(LABELS, row)}}
            for (s, e), row in zip(output.windows, output.probs)
        ]
    return AnalysisResponse.model_validate(result)
