# DAiSEE engagement-model training

This is an **offline training workspace**, not a therapy decision-maker and not
a clinical measure of a child’s engagement. It trains a research baseline from
DAiSEE’s adult e-learning videos. Before any use with children, the model needs
ethics approval, age-appropriate data, fairness testing and evaluation in the
actual therapy setting.

## Keep the dataset private

Download DAiSEE yourself from the official access page and comply with its
research-only licence. Do not upload the videos or distribute them to others.
The downloaded archive is already available at `D:\Research\DAiSEE.zip`.
Extract it into the `data` folder exactly as follows:

```text
D:\Research\Swara-RP\ai-service\c3_engagement_training\data\DAiSEE\
  Labels\
    TrainLabels.csv
    ValidationLabels.csv
    TestLabels.csv
  DataSet\
    Train\<participant>\<clip>\<clip>.avi
    Validation\<participant>\<clip>\<clip>.avi
    Test\<participant>\<clip>\<clip>.avi
```

This repository’s `.gitignore` also excludes `data/`, `manifests/`, `features/`
and `artifacts/` under this folder. These locations can contain licensed videos,
local paths, derived biometric features and trained model files. Never commit
them.

## Why the binary label is explicit

The official DAiSEE `Engagement` column is an **ordinal intensity level**, not
a yes/no label: `0 = very low`, `1 = low`, `2 = high`, `3 = very high`.
The initial research policy in these scripts is:

```text
not engaged: 0 or 1 (very low / low)
engaged:     2 or 3 (high / very high)
```

That decision is implemented with `--positive-min-level 2`, printed in the
manifest class counts, recorded in the model artifact and easy to change for a
separate experiment. Do not change it after looking at the test results.

## VS Code setup (Windows PowerShell)

Open `D:\Research\Swara-RP\ai-service\c3_engagement_training` in VS Code, then
choose the created `.venv` interpreter:

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install --only-binary=:all: -r requirements.txt
```

If PowerShell blocks activation, run
`Set-ExecutionPolicy -Scope Process Bypass` once in that terminal and activate
again. The training virtual environment is already ignored by the repository.

## Run the pipeline

Run these from `ai-service\c3_engagement_training`:

```powershell
# 1. Match official labels to your local videos and confirm no subject appears
#    in more than one official split. This writes private manifests/.
python -m src.build_manifest `
  --labels-root .\data\DAiSEE\Labels `
  --videos-root .\data\DAiSEE\DataSet `
  --positive-min-level 2

# 2. First smoke-test just 10 clips. It samples 12 frames per 10-second clip;
#    it writes aggregate numeric features only, never extracted frames.
python -m src.extract_features `
  --manifest manifests\all.csv `
  --output features\smoke.csv `
  --limit 10

# 3. Extract all clips. This is CPU-intensive and can take a long time.
python -m src.extract_features `
  --manifest manifests\all.csv `
  --output features\daisee_face_head.csv `
  --frames-per-video 12

# 4. Compare class-balanced logistic regression and histogram gradient boosting.
#    Select on Validation only, then report the official Test result once.
python -m src.train `
  --features features\daisee_face_head.csv `
  --artifacts-dir artifacts `
  --positive-min-level 2
```

The final report is `artifacts/metrics.json`; the reusable scikit-learn model is
`artifacts/engagement_model.joblib`. Read **balanced accuracy** and **macro-F1**,
not plain accuracy—the engagement target is imbalanced. The manifest builder
also stops if participant folders overlap across Train, Validation and Test, so
the evaluation cannot be described as subject-safe unless that check passes.

## Run the local inference API

The training workspace has its own `api.py`; it is separate from the
Component 2 service under `ai-service\app`. Run these commands from
`ai-service\c3_engagement_training`:

```powershell
python -m pip install --only-binary=:all: -r requirements-api.txt
python -m uvicorn api:app --host 127.0.0.1 --port 8001 --reload
```

Check `http://127.0.0.1:8001/health`. The `/predict` endpoint accepts numeric
features matching **all and only** the `feature_columns` in
`artifacts/metrics.json`. This PowerShell example builds a schema-matching
sample request from that file:

```powershell
$metrics = Get-Content artifacts\metrics.json | ConvertFrom-Json
$features = @{}
foreach ($name in $metrics.feature_columns) { $features[$name] = 0.1 }
$body = @{ features = $features } | ConvertTo-Json -Depth 4
Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8001/predict `
  -ContentType 'application/json' -Body $body
```

The API returns HTTP 503 if no trained artifact exists and HTTP 422 for a
feature-schema mismatch. It accepts numeric aggregates (or `null` for a value
handled by the trained imputer), not image or video data. Bind it to
`127.0.0.1`; do not expose it publicly. This serves the DAiSEE adult
e-learning baseline, not the Flutter camera-feature baseline, and is not
validated for children, therapy, or clinical decisions.

## What the feature extractor actually learns from

For sampled frames, `extract_features.py` uses OpenCV's local face and eye
detectors to aggregate face-visible rate, face size and position, face-centre
movement, and an eye-pair detection proxy. It does not save frames, infer
diagnosis, or make a reliable eye-gaze, head-pose, or emotion claim.

DAiSEE is video-only. It **cannot** teach a model how a child uses Swara—for
example response time, taps, retries, activity completion or early exits. Add
those app-log features only after collecting consented, therapy-specific data
with a defined human engagement annotation protocol. Keep their feature schema
versioned and evaluate that later model on children never seen during training.

## Bringing a result into therapy research

Treat the model output as a low-stakes signal for clinician review or to offer a
break—not an automatic treatment decision. Keep a session-level record of model
version, confidence, camera availability and user override. If no face is
available or the confidence is low, show “unable to assess” rather than
“disengaged.” A DAiSEE result should be reported as an adult e-learning baseline,
not as validated child speech-therapy performance.

Sources: [official DAiSEE page](https://people.iith.ac.in/vineethnb/resources/daisee/)
and [DAiSEE paper](https://arxiv.org/abs/1609.01885).
