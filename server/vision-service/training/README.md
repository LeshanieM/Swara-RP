# DAiSEE camera-engagement training

The local DAiSEE archive and extracted dataset belong here:

- `training/data/DAiSEE.zip` - original archive.
- `training/data/daisee/` - extracted `DataSet/`, `Labels/`, generated features, and resumable per-clip cache.
- `training/artifacts/engagementCameraModel.candidate.json` - model candidate from the most recent training run.
- `training/reports/` - Markdown and JSON evaluation reports.

`training/data/` is excluded by the repository `.gitignore`. DAiSEE is research-use material; do not commit the archive, clips, feature arrays, or local cache.

## Run from Command Prompt (cmd.exe)

```bat
cd /d D:\Research\Swara-RP\server\vision-service
call .venv\Scripts\activate.bat
where python
python -c "import sys; print(sys.executable)"
```

Check that the printed Python path is `D:\Research\Swara-RP\server\vision-service\.venv\Scripts\python.exe`. If the project environment is missing packages, install them into this activated environment:

```bat
python -m pip install -r requirements.txt
python -m pip install scikit-learn==1.5.2
```

Then run the feature build, training, and report display. These are single-line CMD commands; CMD does not use PowerShell backticks for line continuation.

```bat
python -m training.build_engagement --daisee ".\training\data\daisee" --out ".\training\data\daisee\daisee_engagement.npz" --workers 6
python -m training.train_engagement --data ".\training\data\daisee\daisee_engagement.npz" --out ".\training\artifacts\engagementCameraModel.candidate.json" --report ".\training\reports\DAiSEE_panel_report.md" --note "DAiSEE research candidate; validate on the target SWARA population before deployment."
type .\training\reports\DAiSEE_panel_report.md
```
## Run from PowerShell

```powershell
Set-Location "D:\Research\Swara-RP\server\vision-service"
.\.venv\Scripts\Activate.ps1

# Optional if the environment does not already have scikit-learn:
python -m pip install scikit-learn==1.5.2

# Extract face features and labels. The clips JSONL cache allows this to resume.
python -m training.build_engagement `
  --daisee ".\training\data\daisee" `
  --out ".\training\data\daisee\daisee_engagement.npz" `
  --workers 6

# Compare models with subject-grouped CV and the official DAiSEE Test split.
# The default output is a provisional candidate under training/artifacts/;
# it does not replace the API model.
python -m training.train_engagement `
  --data ".\training\data\daisee\daisee_engagement.npz" `
  --note "DAiSEE research candidate; validate on the target SWARA population before deployment."
```

The report includes plain accuracy, the majority-class baseline, balanced accuracy, macro-F1, ROC-AUC, and confusion counts. Plain accuracy alone can be misleading because DAiSEE engagement classes are imbalanced.

The DAiSEE-trained GBDT candidate is currently copied to `server/api/src/modules/c3/data/engagementCameraModel.json` and is loaded by the API at startup. Restart the API after replacing the model file. It remains provisional: DAiSEE lecture-video results do not establish validity for SWARA's intended users or activities. Validate on consented, representative SWARA sessions before relying on its scores.

To use camera + activity-log scoring in the app, start/restart the API, then enable **Measure engagement with the camera** in the parent settings. Use the Android/iOS app for camera feature extraction; the web build can show preview but does not produce the native ML Kit feature windows. The phone computes numeric facial features locally in 10-second windows; video frames are not uploaded. At activity completion, the API combines the camera probability with activity-log features and returns one engagement estimate for that activity. The session summary shows the average over completed activities.
