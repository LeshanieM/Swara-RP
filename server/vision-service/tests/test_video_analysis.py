"""Small smoke tests for the C2 video-analysis pipeline."""
from types import SimpleNamespace

import numpy as np

from app import pipeline
from app.features import catalog


def test_analysis_returns_basic_result_with_mocked_video_and_detectors(monkeypatch):
    tracks = SimpleNamespace(
        times=np.array([0.0, 0.2]),
        face=np.array([True, True]),
        analysed_fps=5.0,
        frames_read=2,
        raw=None,
    )
    prepared = SimpleNamespace(
        info=SimpleNamespace(
            duration_sec=5.0, fps=5.0, width=640, height=480,
            container="mp4", codec="h264", has_audio=False,
        ),
        tracks=tracks,
        series=np.zeros((2, len(catalog.SCORED))),
        base=SimpleNamespace(source="whole_recording", frames=2, duration_sec=0.4),
        dev=SimpleNamespace(z=np.zeros((2, len(catalog.SCORED)))),
        moments=[],
        min_frames=2,
        warnings=[],
    )

    class Detector:
        def __init__(self, name):
            self.name = name
            self.version = "test"

        def predict(self, _ctx):
            return []

        def thresholds(self):
            return {}

    srcd, rules = Detector("srcd"), Detector("rules")
    monkeypatch.setattr(pipeline, "prepare", lambda *_args, **_kwargs: prepared)
    monkeypatch.setattr(
        pipeline.registry,
        "resolve",
        lambda: (srcd, {"requested": "srcd", "fallback": False, "fallbackReason": None}),
    )
    monkeypatch.setattr(pipeline.registry, "get", lambda name: {"srcd": srcd, "rules": rules}[name])
    settings = SimpleNamespace(target_fps=5.0, deviation_threshold=3.0, baseline_guard_sec=0.5)

    result = pipeline.analyze(b"mock video", "sample.mp4", [], settings, None, False)

    assert result["detector"]["name"] == "srcd"
    assert result["video"]["framesAnalysed"] == 2
    assert result["counts"]["momentsTotal"] == 0
    assert result["summary"]["assessed"] is True


def test_analysis_merges_overlapping_stutter_moments():
    moments, warnings = pipeline.clean_moments(
        [
            {"start": 1.0, "end": 2.0, "types": ["block"]},
            {"start": 1.5, "end": 2.5, "types": ["prolongation"]},
        ],
        duration=5.0,
    )

    assert moments == [(1.0, 2.5, ["block", "prolongation"])]
    assert warnings == []
