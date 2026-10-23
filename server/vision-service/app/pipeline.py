"""C2 analysis: video → face tracks → speaker baseline → per-moment deviation → FG/HM.

``prepare`` holds every step up to the moment scores and is shared with the
training-set builder, so training and serving see identical inputs.
"""
import time
from dataclasses import dataclass

import numpy as np

from app.config import SERVICE_VERSION, Settings
from app.detection import registry
from app.detection.base import Context
from app.features import catalog
from app.srcd import baseline as bl
from app.srcd.deviation import Deviation, MomentScore, NullModel, explanation, normalise, score_moment
from app.video import io as vio
from app.video.landmarks import Tracks, track


@dataclass
class Prepared:
    info: vio.VideoInfo
    tracks: Tracks
    series: np.ndarray
    base: bl.Baseline
    dev: Deviation
    moments: list[MomentScore]
    min_frames: int
    warnings: list[dict]


def clean_moments(raw: list[dict], duration: float) -> tuple[list[tuple[float, float, list]], list[dict]]:
    """Clip to the video, drop moments outside it, sort and merge overlaps."""
    warnings, kept, outside = [], [], 0
    for m in raw:
        start, end = float(m["start"]), float(m["end"])
        if start >= duration or end <= 0:
            outside += 1
            continue
        kept.append([max(0.0, start), min(duration, end), list(m.get("types") or [])])
    if outside:
        warnings.append({"code": "moment_outside_video", "message": f"{outside} stutter moment(s) lie outside the video and were ignored."})
    kept.sort(key=lambda x: x[0])
    merged = []
    for start, end, types in kept:
        if merged and start <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], end)
            merged[-1][2] = sorted(set(merged[-1][2]) | set(types))
        else:
            merged.append([start, end, types])
    return [tuple(m) for m in merged], warnings


def prepare(path: str, moments_in: list[dict], s: Settings, target_fps: float, keep_raw: bool = False) -> Prepared:
    info = vio.probe(path)
    vio.validate(info, s.min_duration_sec, s.max_duration_sec)
    tracks = track(path, s.face_model_path, target_fps, info.fps, s.min_face_width_ratio, keep_raw)
    if not tracks.face.any():
        code = "face_too_small" if tracks.small_face_frames else "no_face_detected"
        raise vio.VideoError(code, "No usable face was found in the video." if code == "no_face_detected"
                             else "The face is too small in the frame to track; record closer to the camera.")

    warnings = []
    face_ratio = float(tracks.face.mean())
    if face_ratio < s.low_face_coverage_ratio:
        warnings.append({"code": "low_face_coverage",
                         "message": f"A face was tracked in {face_ratio:.0%} of frames; moments without a visible face are not assessed."})

    fps = tracks.analysed_fps
    series = catalog.derive_series(tracks.scored, tracks.times, fps)
    moments, w = clean_moments(moments_in, info.duration_sec)
    warnings += w
    min_frames = max(2, int(np.ceil(s.min_deviation_sec * fps - 1e-6)))
    base, w = bl.build(series, tracks.times, tracks.face, [(a, b) for a, b, _ in moments], fps,
                       s.baseline_guard_sec, s.min_baseline_sec, min_frames)
    warnings += w
    dev = normalise(series, base, min_frames)
    null = NullModel(dev, base, s.null_alpha, s.deviation_threshold, s.min_null_spans, s.tail_prior_sd)
    scores = [score_moment(i, a, b, tracks.times, tracks.face, dev, null, s.moment_pad_sec, s.min_moment_face_ratio)
              for i, (a, b, _) in enumerate(moments)]
    if moments and all(sc.assessed and sc.signals["head"].p_value is None for sc in scores):
        warnings.append({"code": "null_unavailable",
                         "message": f"Too little fluent speech to compare against (fewer than {s.min_null_spans} fluent stretches); "
                                    f"only the fixed {s.deviation_threshold:g} SD bar was applied."})
    for sc, (_, _, types) in zip(scores, moments):
        sc.types = types
    return Prepared(info, tracks, series, base, dev, scores, min_frames, warnings)


def _event(cat: str, sig: str, sc, run: tuple[int, int], times: np.ndarray, moment: int) -> dict:
    lo, hi = run
    return {
        "category": cat, "signal": sig, "feature": sc.top_feature,
        "start": round(float(times[lo]), 3), "end": round(float(times[hi]), 3), "duration": round(float(times[hi] - times[lo]), 3),
        "peakDeviation": sc.deviation, "direction": sc.direction, "momentIndex": moment,
    }


def _rate(n: int, d: int) -> float | None:
    return round(n / d, 3) if d else None


def analyze(data: bytes, filename: str | None, moments_in: list[dict], s: Settings,
            target_fps: float | None, include_frames: bool) -> dict:
    t0 = time.perf_counter()
    fps_target = target_fps or s.target_fps
    with vio.temp_file(data, filename) as path:
        p = prepare(path, moments_in, s, fps_target, keep_raw=include_frames)

    detector, det_info = registry.resolve()
    ctx = Context(p.tracks.times, p.tracks.face, p.series, p.dev.z, p.tracks.analysed_fps, p.moments, s.deviation_threshold)
    decisions = detector.predict(ctx)
    rules = registry.get("rules")
    rule_decisions = decisions if detector is rules else rules.predict(ctx)
    warnings = list(p.warnings)
    if det_info["fallback"]:
        warnings.append({"code": "detector_fallback",
                         "message": f"Detector '{det_info['requested']}' is unavailable ({det_info['fallbackReason']}); used label-free SRCD."})
    elif hasattr(detector, "assessed"):
        skipped = [c for c, ok in detector.assessed().items() if not ok]
        if skipped:
            warnings.append({"code": "model_class_not_assessed",
                             "message": f"The {detector.name} model did not meet the validation precision requirement for "
                                        f"{', '.join(skipped)}; label-free SRCD decided {'it' if len(skipped) == 1 else 'them'}."})

    times = p.tracks.times
    moments_out, events = [], []
    for m, dec in zip(p.moments, decisions):
        item = {
            "index": m.index, "start": round(m.start, 3), "end": round(m.end, 3),
            "duration": round(m.end - m.start, 3), "types": m.types,
            "faceRatio": m.face_ratio, "assessed": m.assessed,
            "categories": None, "signals": None, "explanation": [], "behaviourPresent": None,
        }
        if m.assessed:
            item["categories"] = {c: {"present": d.present, "score": d.score, "scoreType": d.score_type} for c, d in dec.items()}
            item["behaviourPresent"] = any(d.present for d in dec.values())
            item["signals"] = {
                sig: {"deviation": sc.deviation, "direction": sc.direction, "topFeature": sc.top_feature,
                      "threshold": sc.threshold, "pValue": sc.p_value, "nullSpans": sc.null_spans, "exceeds": sc.present}
                for sig, sc in m.signals.items()
            }
            explained = set()
            for sig, sc in sorted(m.signals.items(), key=lambda kv: -kv[1].deviation):
                cat = catalog.CATEGORY_OF_SIGNAL[sig]
                if not sc.present or not dec[cat].present:  # explain only what the detector decided
                    continue
                item["explanation"].append(explanation(sig, sc))
                if sc.run:
                    events.append(_event(cat, sig, sc, sc.run, times, m.index))
                    explained.add(cat)
            # A learned detector can flag a category no single signal explains on its own; still say
            # which signal moved most, so the app never shows a behaviour without a reason.
            for cat, d in dec.items():
                if d.present and cat not in explained:
                    sig, sc = max(((g, s) for g, s in m.signals.items() if catalog.CATEGORY_OF_SIGNAL[g] == cat),
                                  key=lambda kv: kv[1].deviation)
                    item["explanation"].append(f"{explanation(sig, sc)}; flagged by the {detector.name} model")
                    run = (sc.window, min(sc.window + p.min_frames - 1, len(times) - 1))
                    events.append(_event(cat, sig, sc, run, times, m.index))
        else:
            warnings.append({"code": "moment_face_missing",
                             "message": f"Stutter moment {m.index} ({m.start:.2f}–{m.end:.2f} s) has a visible face in only "
                                        f"{m.face_ratio:.0%} of frames and was not assessed."})
        moments_out.append(item)
    events.sort(key=lambda e: (e["start"], e["category"]))

    assessed = [d for d in decisions if d is not None]
    n_fg = sum(d["FG"].present for d in assessed)
    n_hm = sum(d["HM"].present for d in assessed)
    n_any = sum(d["FG"].present or d["HM"].present for d in assessed)
    if not p.moments:
        warnings.append({"code": "no_stutter_moments",
                         "message": "No stutter moments were given, so there is nothing to examine for secondary behaviours."})
        has_sb, score = False, 0.0
    elif not assessed:
        has_sb, score = None, None
    else:
        has_sb, score = n_any > 0, round(n_any / len(assessed), 3)

    rule_assessed = [d for d in rule_decisions if d is not None]
    behaviour_types = [c for c, n in (("FG", n_fg), ("HM", n_hm)) if n]
    return {
        "video": {
            "durationSec": p.info.duration_sec, "fps": p.info.fps, "width": p.info.width, "height": p.info.height,
            "container": p.info.container, "codec": p.info.codec, "hasAudio": p.info.has_audio,
            "analysedFps": p.tracks.analysed_fps, "framesRead": p.tracks.frames_read,
            "framesAnalysed": int(p.tracks.times.size), "faceDetectedRatio": round(float(p.tracks.face.mean()), 3),
        },
        "detector": {"name": detector.name, "version": detector.version, **det_info, "thresholds": detector.thresholds()},
        "baseline": {
            "source": p.base.source, "frames": p.base.frames, "durationSec": p.base.duration_sec,
            "guardSec": s.baseline_guard_sec, "holdFrames": p.min_frames,
        },
        "stutterMoments": moments_out,
        "behaviourEvents": events,
        "counts": {
            "momentsTotal": len(p.moments), "momentsAssessed": len(assessed), "momentsWithBehaviour": n_any,
            "FG": n_fg, "HM": n_hm, "behaviourEvents": len(events),
        },
        "behavioursPerStutter": {"FG": _rate(n_fg, len(assessed)), "HM": _rate(n_hm, len(assessed)), "any": _rate(n_any, len(assessed))},
        "hasSecondaryBehaviors": has_sb,
        "concomitantScore": score,
        "baselines": {
            "rules": {
                "version": rules.version,
                "momentsWithBehaviour": sum(d["FG"].present or d["HM"].present for d in rule_assessed),
                "FG": sum(d["FG"].present for d in rule_assessed),
                "HM": sum(d["HM"].present for d in rule_assessed),
                "perMoment": [None if d is None else {"FG": d["FG"].present, "HM": d["HM"].present} for d in rule_decisions],
            },
        },
        "summary": {
            "assessed": has_sb is not None,
            "hasSecondaryBehaviors": has_sb,
            "behaviourTypes": behaviour_types,
            "momentsWithBehaviour": n_any,
            "momentsAssessed": len(assessed),
        },
        "frames": _frames(p) if include_frames else None,
        "warnings": warnings,
        "processingMs": int((time.perf_counter() - t0) * 1000),
        "serviceVersion": SERVICE_VERSION,
    }


def _frames(p: Prepared) -> dict:
    """Per-frame record for research and dataset building: all blendshapes, pose and geometry."""
    return {
        "times": [round(float(t), 3) for t in p.tracks.times],
        "face": [bool(f) for f in p.tracks.face],
        "raw": p.tracks.raw,
    }
