# C3 engagement camera model: c3-engagement-camera-gbdt-2026-10-21

Trained 2026-10-21T15:46:37+00:00 on `daisee_engagement.npz`.

Rows (face visible ≥ 30% of frames): 8986, dropped for no face: 0.

| Model | CV balanced acc. | CV macro-F1 | Test accuracy | Majority baseline | Test balanced acc. | Test macro-F1 | Test ROC-AUC |
|---|---|---|---|---|---|---|---|
| logistic | 0.629 ± 0.066 | 0.503 ± 0.024 | 0.725 | 0.951 | 0.721 | 0.519 | 0.7968 |
| gbdt | 0.593 ± 0.073 | 0.510 ± 0.032 | 0.747 | 0.951 | 0.689 | 0.523 | 0.7472 |

Exported: **gbdt**. Test subjects kept: 21, removed for appearing in training: 0.
