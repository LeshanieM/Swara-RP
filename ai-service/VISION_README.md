# Component 2 – CV secondary-behavior experiment (ai-service)

Flow: Flutter → Node `/api/concomitant/video-analysis` → FastAPI `/analyze-video` → analyzers → JSON.

## Endpoints (FastAPI)
- `POST /analyze-video` (multipart: `video`, optional `technologies` = `all` | `mediapipe,openface,...`, `generate_overlay`, `generate_timeline`, `ground_truth` JSON)
- `GET /analyze-video/{id}/status`
- `GET /analyze-video/{id}/results`
- `POST /tmmf/windows` (technology-neutral frame features → labeled temporal windows)
- `POST /tmmf/casa-labels` (CASA timed labels → matching feature windows)
- `POST /tmmf/evaluate` (speaker-grouped RF/SVM/rule-baseline evaluation)

## TMMF research extension

The existing Component 2 analyzers and event format remain the baseline. The
MediaPipe analyzer now also returns `tmmf.status=features_only` and the
overlapping 2-second/50%-overlap temporal feature windows alongside its
existing event output. Eye/lip/jaw signals are derived from the existing
inter-ocular-normalized signals; head features use existing pose-angle
velocity. These are experimental defaults, not validated thresholds. No FG
or HM classifier prediction is returned until speaker-labeled expert data is
available.

`POST /tmmf/windows` accepts JSON `{frames:[{timestamp,eye,lip,jaw,head}],
annotations?:[{behavior,start_time,end_time}], window_s?:2, overlap?:0.5,
label_overlap_fraction?:0.5}`. Annotation labels are independent binary FG/HM
labels. Unsupported behaviors do not become positive labels.

`POST /tmmf/evaluate` accepts `{records:[{speaker_id,features:{...},
baseline_features:{...},labels:{FG:0|1,HM:0|1}}], n_splits?:5}`. `features`
contains TMMF window aggregates; `baseline_features` contains the matched
non-temporal movement feature vector (if omitted, `features` is used). It uses GroupKFold by speaker and
reports fold metrics and means/standard deviations for independent FG/HM
outputs, comparing rule-based, Random Forest, and SVM methods. Data must
contain multiple speakers and enough positive/negative examples in training
folds. The event-merging helper in `app/processing/tmmf.py` merges overlapping
window predictions independently by category. Existing `evaluation.py`
continues to provide event overlap matching against annotated events.

CASA annotations can be read locally with
`load_casa_annotations(csv_path, task="interview", annotator="Gold")` from
`app.processing.tmmf`. Its `start`/`end` millisecond fields are converted to
seconds. Pass the normalized rows and windows carrying `media_file` (and
`task`) to `label_casa_windows` or `/tmmf/casa-labels`; then map each returned
window's `features`, `speaker_id`, and `labels` into `/tmmf/evaluate`. The
importer omits windows with insufficient annotation coverage, so unannotated
time is never silently treated as a negative. Use one annotator/aggregation
policy consistently and keep the participant identifier as the CV group.

CASA's FG guideline includes jaw jerking, tongue protrusion, lip pressing, jaw
muscle tension, and eye movements; Swara's requested subset excludes tongue
protrusion and jaw muscle tension and is limited to eye/lip/jaw movement.
Therefore the published binary FG label is broader than the target label and
cannot validate the narrow FG scope by itself. HM's backward/forward/turning
away definition aligns with the requested category. CASA source instructions
require authenticated TalkBank access to download media; this repository does
not download or bundle that video. The timed annotation importer works with a
CSV the researcher is authorized to access.

### Local CASA pilot run

With the AI-service virtual environment installed and the MediaPipe `.task`
model configured, run from `ai-service/`:

```powershell
.\venv\Scripts\python.exe scripts\run_casa_tmmf.py --target-fps 10
```

The script processes exact video-stem/`media_file` matches (or a selected
subset with `--media-files 24fb,24fc`), uses the `bau` annotation aggregation,
reuses cached results at the same sampling rate, and writes feature windows and a summary under
`results/casa_tmmf/`. The pilot sampling rate and 10% positive/coverage
fractions are experimental settings. CASA data under `data/casa/` is ignored
by Git to keep downloaded clinical media and annotations out of commits.

### Existing-file integration map

- Reused: `app/analyzers/mediapipe_analyzer.py` video/frame timestamps,
  landmark-derived signals and head pose; `app/processing/feature_extraction.py`
  normalized geometry; `app/processing/temporal_detection.py` event logic;
  `app/processing/evaluation.py` annotation matching; existing `/analyze-video`
  API and response shape.
- Extended: MediaPipe analysis adds TMMF temporal windows without removing
  existing behavior events. `app/api/vision_routes.py` adds research endpoints.
- Added: `app/processing/tmmf.py` feature windows, annotation labels, event
  merging, and speaker-independent baseline/model comparison.
- Not yet supplied by this repository: a broad expert-labeled multi-child
  corpus run and trained production model. OpenFace continues to return its
  existing movement events; its frame features are not yet emitted as TMMF
  windows. Consequently, these endpoints support the research workflow but
  cannot establish performance or clinical validity without real data.

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
