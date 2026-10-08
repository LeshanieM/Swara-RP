# Component 2 – CV secondary-behavior experiment (ai-service)

Flow: Flutter → Node `/api/concomitant/video-analysis` → FastAPI `/analyze-video` → analyzers → JSON.

## Endpoints (FastAPI)
- `POST /analyze-video` (multipart: `video`, optional `technologies` = `all` | `mediapipe,openface,...`, `generate_overlay`, `generate_timeline`, `ground_truth` JSON)
- `GET /analyze-video/{id}/status`
- `GET /analyze-video/{id}/results`

## Technology setup (each is optional; missing ones report `unavailable` + reason)
| Technology | Requirement | Env var |
|---|---|---|
| MediaPipe | `pip install mediapipe opencv-python` + download `face_landmarker.task` into `models/` | `MEDIAPIPE_FACE_MODEL_PATH` |
| OpenFace | built `FeatureExtraction` executable | `OPENFACE_BIN` |
| OpenSeeFace | cloned repo (contains `tracker.py`, models) | `OPENSEEFACE_DIR` |
| 3DDFA-V2 | cloned + built repo | `DDFA_V2_DIR` |
| MMPose | `mmpose`, `mmdet`, `mmcv` installed | `MMPOSE_CONFIG`, `MMPOSE_CHECKPOINT` (optional) |

Status meanings: `supported` / `unsupported` (technology lacks the feature) / `unavailable` (cannot run now) / `error` (failed at runtime).

## Reproducibility
Thresholds live only in `app/config/settings.py` (env-overridable) and are written into every result (`thresholds_used`) and into `results/<analysis_id>_reproducibility_log.json`. Per-technology events: `results/<analysis_id>/<tech>/events.json`; `comparison.json`, `evaluation.json` alongside. Uploaded video is deleted after processing (`VISION_KEEP_UPLOADS=1` to keep for debugging).

## Not tested / known limitations
- OpenFace, OpenSeeFace, 3DDFA-V2 and MMPose adapters were written against those tools' documented interfaces but could not be run in the development sandbox; verify them once installed.
- MediaPipe was verified only to load and to report `model_unavailable` without the model file; the frame loop needs a real face video.
- Job state is in memory (lost on restart); Node caches completed results in MongoDB.
- Overlay videos are written to `results/` but not yet served to the app; ground-truth input has no Flutter UI (API-only).
- Thresholds are literature-style defaults, untuned.
