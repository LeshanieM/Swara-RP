# DAiSEE camera engagement training results

## Dataset and method

- 8,986 labeled 10-second clips from DAiSEE, spanning 113 subjects.
- Labels: Engagement levels 0-1 = not engaged; levels 2-3 = engaged.
- Train + Validation development data: 7,202 clips. Official Test: 1,784 clips from 21 subjects, with no subject overlap with development data.
- 0 clips were unreadable; no clips were dropped by the face-visibility filter.
- Features were extracted with the same MediaPipe tracker and camera-window feature definitions used by SWARA. The trainer compared class-balanced logistic regression and gradient-boosted trees using five subject-grouped CV folds.

## Official held-out Test results

| Model | Accuracy | Always-engaged baseline | Balanced accuracy | Macro-F1 | ROC-AUC |
|---|---:|---:|---:|---:|---:|
| Logistic regression | 72.5% | 95.1% | 0.721 | 0.519 | 0.7968 |
| Gradient boosting (selected by CV macro-F1) | 74.7% | 95.1% | 0.689 | 0.523 | 0.7472 |

The selected GBDT model's confusion counts were: 1,277 engaged correctly identified, 55 not-engaged correctly identified, 33 not-engaged clips predicted engaged, and 419 engaged clips predicted not-engaged. There were 88 not-engaged and 1,696 engaged clips in the Test set.

Plain accuracy is strongly affected by class imbalance: always predicting "engaged" gives 95.1% on this Test set. The trained model's 74.7% plain accuracy is below that baseline. Its balanced accuracy and ROC-AUC indicate some class-discriminating signal, but performance is modest. This candidate should not replace SWARA's current model or be described as production-ready based on these results alone.

## Cross-validation

| Model | Mean balanced accuracy (5 subject folds) | Mean macro-F1 (5 subject folds) |
|---|---:|---:|
| Logistic regression | 0.629 +/- 0.066 | 0.503 +/- 0.024 |
| Gradient boosting | 0.593 +/- 0.073 | 0.510 +/- 0.032 |

GBDT was exported because its cross-validation macro-F1 was slightly higher; the held-out Test metrics were not used to choose the model.

## Interpretation and next step

This is a DAiSEE research-dataset result, not evidence that the camera model validly measures engagement for SWARA's intended users or therapy activities. Validate the candidate on consented, representative SWARA data and revisit the decision threshold and labels before deployment. No trained-model claim is made for other populations.

Candidate model: `DAiSEE_candidate_engagementCameraModel.json` (marked provisional). The source feature dataset and extracted-video cache remain under `D:\Research\DAiSEE` and are not included here.
