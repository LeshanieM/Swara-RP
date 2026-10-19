import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import numpy as np

from app import c2_inference


class DeterministicRuntime:
    mean = np.zeros(c2_inference.FEATURE_DIM, dtype=np.float32)
    std = np.ones(c2_inference.FEATURE_DIM, dtype=np.float32)
    thresholds = {"FG": 0.05, "HM": 0.35}

    def predict_proba(self, batch):
        # Fixed probabilities make the inference-path tests independent of
        # whether the optional PyTorch package is installed in this checkout.
        return np.tile(np.asarray([[0.8, 0.2]], dtype=np.float32), (len(batch), 1))


def sample_video(face_rate=1.0):
    timestamps = np.rint(np.arange(90) * c2_inference.FRAME_MS).astype(np.int32)
    frames = np.zeros((len(timestamps), c2_inference.BASE_FEATURE_DIM), dtype=np.float32)
    frames[:, :52] = np.linspace(0.0, 1.0, 52, dtype=np.float32)
    faces = np.ones(len(timestamps), dtype=np.uint8)
    if face_rate < 1.0:
        faces[int(len(faces) * face_rate):] = 0
    frames[:, 55] = faces
    return frames, timestamps, faces


class C2InferenceTests(unittest.TestCase):
    def test_saved_checkpoint_and_assets_load_when_installed(self):
        if all(path.is_file() for path in (
            c2_inference.CHECKPOINT_PATH,
            c2_inference.NORMALIZATION_PATH,
            c2_inference.THRESHOLDS_PATH,
            c2_inference.BLENDSHAPE_NAMES_PATH,
        )):
            self.assertTrue(c2_inference.C2_AVAILABLE, c2_inference.C2_UNAVAILABLE_REASON)

    def test_happy_path_returns_assessed_fg_and_unassessed_hm(self):
        frames, timestamps, faces = sample_video()
        result = c2_inference.predict_c2(frames, timestamps, faces, DeterministicRuntime())

        self.assertEqual(result["status"], "assessed")
        self.assertEqual(result["assessment_status"]["FG"], "assessed")
        self.assertEqual(result["assessment_status"]["HM"], "not_assessed")
        self.assertGreater(len(result["behaviours"]["FG"]["events"]), 0)
        self.assertIsNone(result["behaviours"]["HM"]["detected"])
        self.assertIsNone(result["hasSecondaryBehaviors"])
        self.assertGreater(result["inference_ms"], 0)

    def test_no_face_majority_is_insufficient_tracking(self):
        _, _, faces = sample_video(face_rate=0.49)
        quality = c2_inference.face_tracking_quality(faces)
        self.assertTrue(quality["low"])
        self.assertEqual(c2_inference.status_for_tracking(faces), "insufficient_face_tracking")

    def test_exactly_half_face_frames_is_not_over_the_skip_limit(self):
        frames, timestamps, faces = sample_video()
        frames, timestamps, faces = frames[:30], timestamps[:30], faces[:30].copy()
        faces[:15] = 0
        frames[:, 55] = faces
        windows, metadata = c2_inference._window_batch(frames, timestamps, faces)
        self.assertEqual(windows.shape, (1, 30, 111))
        self.assertEqual(len(metadata), 1)

    def test_missing_model_asset_returns_unavailable_without_raising(self):
        with tempfile.TemporaryDirectory() as directory:
            missing_checkpoint = Path(directory) / "missing.pt"
            with patch.object(c2_inference, "CHECKPOINT_PATH", missing_checkpoint):
                runtime, reason, _names = c2_inference._load_runtime()
        self.assertIsNone(runtime)
        self.assertIn("model_unavailable", reason)
        self.assertIn("missing.pt", reason)

    def test_analyzer_unavailable_response_is_additive_and_explicit(self):
        from app.analyzers.mediapipe_analyzer import MediaPipeAnalyzer

        result = MediaPipeAnalyzer().unavailable_result({}, "model_unavailable: checkpoint missing")
        self.assertEqual(result["c2_status"], "unavailable")
        self.assertIsNone(result["c2_predictions"])
        self.assertEqual(result["c2_reason"], "model_unavailable: checkpoint missing")

    def test_same_input_produces_identical_events_and_probabilities(self):
        frames, timestamps, faces = sample_video()
        first = c2_inference.predict_c2(frames, timestamps, faces, DeterministicRuntime())
        second = c2_inference.predict_c2(frames, timestamps, faces, DeterministicRuntime())
        self.assertEqual(first["behaviours"]["FG"]["events"], second["behaviours"]["FG"]["events"])
        self.assertEqual(first["behaviours"]["FG"]["mean_probability"],
                         second["behaviours"]["FG"]["mean_probability"])

if __name__ == "__main__":
    unittest.main()
