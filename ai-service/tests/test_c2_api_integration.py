import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import numpy as np

from app import c2_inference


SERVICE_ROOT = Path(__file__).resolve().parents[1]
TEST_VIDEO = SERVICE_ROOT / "data" / "casa" / "interview" / "videos" / "24fc.mp4"
INTEGRATION_READY = c2_inference.C2_AVAILABLE and TEST_VIDEO.is_file()


@unittest.skipUnless(INTEGRATION_READY, "C2 model assets, PyTorch, or fixed CASA test video unavailable")
class C2ApiIntegrationTests(unittest.TestCase):
    def test_fixed_video_returns_assessed_c2_prediction_block(self):
        import cv2
        from app.analyzers.mediapipe_analyzer import MediaPipeAnalyzer

        print("[c2 smoke] preparing short clip", flush=True)
        with tempfile.TemporaryDirectory() as temp_dir:
            clip_path = Path(temp_dir) / "24fc_smoke.mp4"
            capture = cv2.VideoCapture(str(TEST_VIDEO))
            self.assertTrue(capture.isOpened(), f"Unable to open {TEST_VIDEO}")
            fps = float(capture.get(cv2.CAP_PROP_FPS)) or 30.0
            width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT))
            writer = cv2.VideoWriter(
                str(clip_path), cv2.VideoWriter_fourcc(*"mp4v"), fps, (width, height)
            )
            self.assertTrue(writer.isOpened(), "Unable to create temporary smoke clip")
            cutoff = 6.0 * fps
            frame_count = 0
            while frame_count < cutoff:
                ok, frame = capture.read()
                if not ok:
                    break
                writer.write(frame)
                frame_count += 1
            capture.release()
            writer.release()
            self.assertGreaterEqual(frame_count, int(4 * fps), "Source video is too short for inference")
            print(f"[c2 smoke] clip ready ({frame_count} frames); running MediaPipe analyzer", flush=True)

            analyzer = MediaPipeAnalyzer().analyze(str(clip_path))
            repeated = MediaPipeAnalyzer().analyze(str(clip_path))
        self.assertEqual(analyzer["status"], "completed", json.dumps(analyzer))
        c2 = analyzer["c2_predictions"]
        self.assertEqual(c2["status"], "assessed")
        self.assertEqual(c2["assessment_status"]["HM"], "not_assessed")
        self.assertIsNone(c2["hasSecondaryBehaviors"])
        self.assertGreater(len(c2["behaviours"]["FG"]["events"]), 0)
        self.assertGreater(analyzer["inference_ms"], 0)
        self.assertEqual(
            c2["behaviours"]["FG"]["events"],
            repeated["c2_predictions"]["behaviours"]["FG"]["events"],
        )
        self.assertEqual(
            c2["behaviours"]["FG"]["mean_probability"],
            repeated["c2_predictions"]["behaviours"]["FG"]["mean_probability"],
        )
        self.assertIn("tmmf", analyzer)
        fixture_path = Path(__file__).parent / "fixtures" / "mediapipe_24fc_smoke_tmmf.json"
        expected_tmmf = json.loads(fixture_path.read_text(encoding="utf-8"))
        self.assertEqual(analyzer["tmmf"], expected_tmmf)
        smoke_payload = {
            "analysis_status": analyzer["status"],
            "c2_status": analyzer["c2_status"],
            "tracking_quality": analyzer.get("tracking_quality"),
            "inference_ms": analyzer["inference_ms"],
            "c2_predictions": c2,
            "features_only": {
                "status": analyzer["tmmf"]["status"],
                "method": analyzer["tmmf"]["method"],
                "total_windows": len(analyzer["tmmf"]["windows"]),
                "pre_integration_snapshot_matched": True,
            },
        }
        print(json.dumps(smoke_payload, indent=2))

    def test_missing_c2_runtime_returns_unavailable_without_breaking_legacy_analysis(self):
        import cv2
        from app.analyzers.mediapipe_analyzer import MediaPipeAnalyzer

        with tempfile.TemporaryDirectory() as temp_dir:
            clip_path = Path(temp_dir) / "missing_c2_runtime.mp4"
            writer = cv2.VideoWriter(
                str(clip_path), cv2.VideoWriter_fourcc(*"mp4v"), 15.0, (320, 240)
            )
            self.assertTrue(writer.isOpened(), "Unable to create missing-model test clip")
            for _ in range(60):
                writer.write(np.zeros((240, 320, 3), dtype=np.uint8))
            writer.release()

            with patch.object(c2_inference, "C2_AVAILABLE", False), patch.object(
                c2_inference, "C2_UNAVAILABLE_REASON", "model_unavailable: test checkpoint missing"
            ):
                result = MediaPipeAnalyzer().analyze(str(clip_path))

        self.assertEqual(result["status"], "completed")
        self.assertEqual(result["c2_status"], "unavailable")
        self.assertIsNone(result["c2_predictions"])
        self.assertIn("checkpoint missing", result["c2_reason"])

    def test_no_face_clip_returns_insufficient_tracking_without_prediction(self):
        import cv2
        from app.analyzers.mediapipe_analyzer import MediaPipeAnalyzer

        with tempfile.TemporaryDirectory() as temp_dir:
            clip_path = Path(temp_dir) / "no_face.mp4"
            writer = cv2.VideoWriter(
                str(clip_path), cv2.VideoWriter_fourcc(*"mp4v"), 15.0, (320, 240)
            )
            self.assertTrue(writer.isOpened(), "Unable to create no-face test clip")
            for _ in range(60):
                writer.write(np.zeros((240, 320, 3), dtype=np.uint8))
            writer.release()

            result = MediaPipeAnalyzer().analyze(str(clip_path))

        self.assertEqual(result["status"], "completed")
        self.assertEqual(result["c2_status"], "insufficient_face_tracking")
        self.assertIsNone(result["c2_predictions"])
        self.assertTrue(result["tracking_quality"]["low"])


if __name__ == "__main__":
    unittest.main()
