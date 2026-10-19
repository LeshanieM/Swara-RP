# C2 SRCD-GRU evaluation report

## Executive summary

FG is reliably detected in this evaluation: the ordinary model reached test F1 **0.84** and PR-AUC **0.86** across five test participants. HM is **not learned reliably** (test F1 **0.27**, precision **0.18**) and is marked **not_assessed**; its scores are below the majority-class reference. SRCD does not improve over ordinary: validation macro-F1 at the checkpoint-selection threshold was **0.591** for ordinary and **0.492** for SRCD, while test FG F1 is effectively equal (**0.84** for both), SRCD has lower FG PR-AUC (**0.79** vs **0.86**), and SRCD FG accuracy is below its majority baseline. Ordinary FG accuracy is **0.736** (base rate **0.722**; Δ over majority baseline **+0.014**). That small accuracy margin alone is weak evidence; the FG signal is carried by F1 and PR-AUC, not accuracy. The saved artifacts select ordinary using validation threshold-0.5 macro-F1 only; test was evaluated once per mode after validation-only threshold selection.

## Data and evaluation protocol

- Source: **66 videos** (36 interview, 30 reading) from **29 participants**.
- After pruning: **18,208 usable windows**: 11,758 train, 3,363 validation, and 3,087 test.
- Participant split: 17 train, 5 validation, and 5 test participants; the groups are disjoint. Seed: **42**. The final participant lists and counts are in `split_manifest_final.json`.
- Labels were aggregated from A1/A2/A3 at the window level, after applying exclusions. The saved per-rater rule is positive if any covering rater votes positive, and negative only if all covering raters vote negative; this is not a strict majority vote. Windows overlapping exclusions or with no usable consensus label were masked.
- Four failed videos were excluded: interview/29mc, reading/29mc, interview/503, and reading/503. Participant 508 was excluded for low face-detection validity and only 25 windows.
- Thresholds were selected on validation only. The primary test threshold is the validation threshold satisfying precision ≥0.5 when feasible; otherwise the class uses its validation F1-max threshold. HM had no feasible precision-constrained threshold in either mode and is marked **not_assessed** throughout.
- Checkpoint selection and mode selection use validation macro-F1 at threshold 0.5, on usable windows. The reported validation metrics below use the final class thresholds and therefore are distinct from the checkpoint-selection metric.
- `n_total` is the window support; positive and negative supports are shown separately. Confusion matrices use `[[TN, FP], [FN, TP]]`. Confidence intervals are saved 95% participant-level bootstrap intervals for F1.

## Results

Accuracy is shown in every row with the actual positive base rate and delta from the majority-class baseline. F1 and PR-AUC are the primary interpretation metrics; accuracy is secondary. HM remains **not_assessed** in every summary row.

### Ordinary mode

| Split / class | Status | Threshold | Precision | Recall | F1 (95% participant bootstrap CI) | PR-AUC | ROC-AUC | Accuracy (base rate; Δ over majority baseline) | Majority baseline accuracy | Support (positive / negative) | Confusion matrix |
|---|---|---:|---:|---:|---:|---:|---:|---|---:|---:|---|
| Val FG | assessed | 0.05 | 0.697 | 0.919 | 0.792 (0.664–0.845) | 0.778 | 0.656 | 0.680 (0.665; +0.014) | 0.665 | 3,363 (2,238 / 1,125) | [[230, 895], [182, 2,056]] |
| Val HM | **not_assessed** | 0.35 | 0.385 | 0.658 | 0.486 (0.245–0.550) | 0.301 | 0.578 | 0.603 (0.285; −0.112) | 0.715 | 3,363 (959 / 2,404) | [[1,397, 1,007], [328, 631]] |
| Test FG | assessed | 0.05 | 0.745 | 0.963 | 0.840 (0.587–0.926) | 0.861 | 0.715 | 0.736 (0.722; +0.014) | 0.722 | 3,087 (2,228 / 859) | [[125, 734], [82, 2,146]] |
| Test HM | **not_assessed** | 0.35 | 0.182 | 0.488 | 0.265 (0.148–0.425) | 0.179 | 0.564 | 0.571 (0.159; −0.270) | 0.841 | 3,087 (490 / 2,597) | [[1,524, 1,073], [251, 239]] |

Ordinary validation macro-F1 at the selected per-class thresholds is **0.639**; its checkpoint-selection validation macro-F1 at threshold 0.5 is **0.591**. Test macro-F1 at the selected thresholds is **0.553**.

### SRCD mode

| Split / class | Status | Threshold | Precision | Recall | F1 (95% participant bootstrap CI) | PR-AUC | ROC-AUC | Accuracy (base rate; Δ over majority baseline) | Majority baseline accuracy | Support (positive / negative) | Confusion matrix |
|---|---|---:|---:|---:|---:|---:|---:|---|---:|---:|---|
| Val FG | assessed | 0.08 | 0.716 | 0.951 | 0.817 (0.700–0.847) | 0.723 | 0.631 | 0.717 (0.665; +0.051) | 0.665 | 3,363 (2,238 / 1,125) | [[283, 842], [110, 2,128]] |
| Val HM | **not_assessed** | 0.05 | 0.317 | 0.694 | 0.435 (0.246–0.494) | 0.302 | 0.564 | 0.485 (0.285; −0.230) | 0.715 | 3,363 (959 / 2,404) | [[966, 1,438], [293, 666]] |
| Test FG | assessed | 0.08 | 0.724 | 0.991 | 0.837 (0.611–0.925) | 0.792 | 0.623 | 0.720 (0.722; −0.001) | 0.722 | 3,087 (2,228 / 859) | [[16, 843], [20, 2,208]] |
| Test HM | **not_assessed** | 0.05 | 0.180 | 0.808 | 0.295 (0.162–0.518) | 0.233 | 0.612 | 0.387 (0.159; −0.454) | 0.841 | 3,087 (490 / 2,597) | [[798, 1,799], [94, 396]] |

SRCD validation macro-F1 at the selected per-class thresholds is **0.626**; its checkpoint-selection validation macro-F1 at threshold 0.5 is **0.492**. Test macro-F1 at the selected thresholds is **0.566**.

### Per-participant test FG F1

The table reports FG F1 for each test participant. HM is **not_assessed** and is omitted from this participant summary.

| Participant | Test windows | Ordinary FG F1 | SRCD FG F1 |
|---|---:|---:|---:|
| 26 | 334 | 0.693 | 0.707 |
| 27 | 1,478 | 0.949 | 0.947 |
| 33 | 400 | 0.876 | 0.873 |
| 42 | 359 | 0.797 | 0.795 |
| 64 | 516 | 0.358 | 0.463 |

Across these five participants, ordinary FG F1 ranges from **0.36 to 0.95** and SRCD FG F1 ranges from **0.46 to 0.95**. With only five test participants, the aggregate point estimates and participant-level confidence intervals are unstable.

### Ordinary vs SRCD ablation

| Comparison | Ordinary | SRCD | Interpretation |
|---|---:|---:|---|
| Checkpoint-selection validation macro-F1 (threshold 0.5) | 0.591 | 0.492 | Lower for SRCD; mode selection used validation only. |
| Test macro-F1 (validation-selected thresholds) | 0.553 | 0.566 | Slightly higher for SRCD, but this does not establish an overall improvement. |
| Test FG F1 | 0.840 | 0.837 | Effectively equal. |
| Test FG PR-AUC | 0.861 | 0.792 | Lower for SRCD. |
| Test FG ROC-AUC | 0.715 | 0.623 | Lower for SRCD. |
| Test FG accuracy (base rate; Δ over majority baseline) | 0.736 (0.722; +0.014) | 0.720 (0.722; −0.001) | SRCD is below the majority baseline; accuracy is secondary. |
| Test HM F1 | **0.265, not_assessed** | **0.295, not_assessed** | Neither mode establishes reliable HM detection. |

**Conclusion:** SRCD does not improve on any metric that matters for FG detection: FG F1 is essentially equal while PR-AUC, ROC-AUC, and checkpoint-selection validation macro-F1 are lower. SRCD is a negative result on this dataset, not a contribution. The slightly higher SRCD test macro-F1 does not override the validation-only selection criterion or the class-specific results.

## HM assessment

HM is not reported as a usable detection capability. The validation precision constraint (precision ≥0.5) was infeasible in both modes, so HM used its F1-max threshold only for transparent diagnostic metrics. The saved test results show low precision and performance below the majority-class accuracy baseline. HM metrics are included for transparency but have status **not_assessed**; do not interpret HM output as a reliable prediction. Conditional HM modeling on FG-positive windows is future work and was not implemented.

## Limitations

- Windows are 2 seconds long with a 0.5-second stride, so overlapping samples can repeat the same underlying event up to four times. The FG positive rate and per-window metrics are inflated by this overlap. Event-level metrics were not reported; they would likely be lower.
- HM positive rate is **15.9%** in test versus **30.9%** in train. This distribution shift likely worsens HM performance.
- There are only five test and five validation participants. Participant-level confidence intervals and point estimates are wide and unstable.
- CASA contains adult participant data. The intended users of Swara are children. This model has not been validated on children and should be treated as research support only.
- SRCD is a negative result: it did not improve the primary FG ranking/detection evidence over ordinary features.
- The report evaluates saved window-level results; it does not establish clinical validity or event-level performance.

## Reproducibility

- Random seed: **42**.
- Mode selection: validation macro-F1 at threshold 0.5, usable windows only; selected mode: **ordinary**.
- Threshold selection: validation only; constrained precision threshold when feasible, otherwise validation F1-max. Test was evaluated once per mode after threshold selection; saved results state that model weights were not changed during evaluation.
- Configurations: `config_ordinary.json`, `config_srcd.json`, and merged `config_final.json` in this directory.
- Checkpoints: `best_ordinary.pt` and `best_srcd.pt` in this directory.
- Saved evaluation sources: `results_ordinary.json`, `results_srcd.json`, `thresholds_ordinary.json`, and `thresholds_srcd.json`.
- Final split membership and counts: `split_manifest_final.json`. The earlier `split_manifest.json` and `manifest_summary.json` predate pruning and were not used for final split counts.

