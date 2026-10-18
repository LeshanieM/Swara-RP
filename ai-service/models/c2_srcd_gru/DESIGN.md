# Component 2: video-based annotation support

## What this component does

Component 2 is an experimental video model that looks for the CASA annotation labels **FG** and **HM** in short video windows. It turns sampled video frames into facial movement and head-pose features, then uses a recurrent neural network to estimate the two labels. It is intended to support research and review of video, not to diagnose a person or make decisions about a child.

The current evaluation supports using the ordinary feature model for FG experiments. HM did not meet the validation precision requirement and is marked **not assessed**. Its reported scores are retained to show the limitation, not as a dependable HM detector. The speaker-relative (SRCD) variant did not improve the FG results, so ordinary is the selected mode.

## Data and labels

The source collection contains 66 videos—36 interview and 30 reading—from 29 participants. After the video and participant quality exclusions, the processed set contains 18,208 usable windows.

Annotations from A1, A2, and A3 are combined for each window, separately for each label. The implemented rule is deliberately simple: a window is positive when any rater with an overlapping annotation marks it positive; it is negative only when all raters with overlapping annotations mark it negative. Windows with no covering rater, an unknown label, or an overlap with an exclusion are masked and do not train or score the model. Exclusion times are converted from seconds to milliseconds before comparing them with video timestamps.

Four videos were excluded after decoder failures: `interview/29mc`, `reading/29mc`, `interview/503`, and `reading/503`. Participant `508` was excluded for low face-detection validity and a very small number of windows.

## Keeping participants separate

All windows from a participant stay in one split so the model is evaluated on people it did not see during training. With seed 42, the final split has 17 training participants, 5 validation participants, and 5 test participants. It contains 11,758, 3,363, and 3,087 usable windows respectively. The participant IDs are listed in `split_manifest_final.json`.

The split aims for approximately 70/15/15 while balancing task and FG-positive rates. The realized window proportions differ from those targets because participants have different numbers of usable windows. The final manifest and split file reflect post-pruning counts; older split summaries were created before pruning and should not be used as the final count.

## What the model sees

Video is sampled at 15 frames per second and arranged into 30-frame windows, which span 2 seconds. The ordinary feature set has 111 channels:

- 52 MediaPipe facial blendshape scores;
- 3 head-pose angles;
- 1 face-present indicator;
- 52 blendshape movement values over time; and
- 3 head-pose movement values over time.

Normalization is fit using training data only and valid frames. The face-present indicator is left as a flag rather than treated as a continuous measurement.

### Speaker-relative experiment

The SRCD version adds 111 channels that describe how each window differs from a participant baseline, for 222 input channels total. A participant’s baseline is estimated from their negative training windows using a median and a robust scale for each feature. Deviations are clipped to limit extreme values. When a participant baseline is unavailable, the training-population baseline is used. Validation and test data use training-derived fallback statistics, so their labels do not define their baselines.

This experiment did not improve results over the ordinary features in the saved evaluation. It is recorded as a negative result rather than a model contribution.

## Model and training

Both variants use the same two-layer bidirectional GRU. Each direction has 64 hidden units, dropout is 0.2, and masked mean pooling combines the valid frame representations into a window representation. The network produces one score for FG and one for HM.

Training uses weighted binary cross-entropy (`BCEWithLogitsLoss`) and AdamW. The saved settings include a learning rate of 0.001, weight decay of 0.0001, batch size 32, and gradient clipping at 1.0. The model is trained on the training participants; validation is used for checkpoint selection and threshold selection. The test set is held back until those choices are made.

## Thresholds and how to read the results

For each label, thresholds are searched on validation data only. The pipeline records the threshold with the best F1 and, when possible, a threshold that also achieves precision of at least 0.5. Test evaluation uses the precision-constrained threshold when it exists; otherwise it uses the validation F1-max threshold and marks the result accordingly.

FG met the precision constraint in both modes and is marked **assessed**. HM did not meet it in either mode, so HM is **not_assessed**. HM metrics are diagnostic only and should not be presented as reliable detections.

Checkpoint and mode selection use validation macro-F1 at a fixed 0.5 threshold on usable windows. On that criterion, ordinary scored 0.591 and SRCD scored 0.492, so ordinary was selected. With validation-selected class thresholds, ordinary test FG F1 was 0.840 and PR-AUC was 0.861; SRCD test FG F1 was 0.837 and PR-AUC was 0.792. These results do not show an improvement from SRCD. Accuracy is secondary and should always be interpreted next to the class base rate and majority-class baseline; the complete values and confusion matrices are in `evaluation_report.md` and the `results_*.json` files.

## Important limitations

- The 2-second windows overlap by 1.5 seconds. The same underlying event can therefore appear in as many as four windows, making window-level rates and scores look stronger than event-level performance. Event-level metrics were not calculated.
- HM is not assessed as a reliable detection task. Its test positive rate is 15.9%, compared with 30.9% in training, so the split also has a substantial label-rate difference.
- Validation and test each contain only five participants. Results and participant-level confidence intervals are uncertain and may change with additional participants.
- The CASA data used here are from adults. The model has not been validated on children, who are the intended users of Swara.
- The model is not clinically validated and should be treated as research support only. A high model score is not a diagnosis or a substitute for review by a qualified professional.
- SRCD did not improve the evaluated FG results. No conclusion that it generalizes better should be drawn from this experiment.

## Files for review and reproducibility

- `evaluation_report.md` gives the split-level results, confusion matrices, participant-level FG results, and limitations.
- `config_final.json` records the selected mode and decision rules. `config_ordinary.json` and `config_srcd.json` contain the settings for each run.
- `results_ordinary.json` and `results_srcd.json` contain saved metrics; `thresholds_ordinary.json` and `thresholds_srcd.json` record validation-selected thresholds and feasibility.
- `split_manifest_final.json` records final participant membership, usable-window counts, and exclusions.
- `best_ordinary.pt` and `best_srcd.pt` are the saved model checkpoints. Normalization statistics are saved in the corresponding `norm_stats_*.npz` files.

All reported results use seed 42. No new training or threshold tuning is performed by this design document.
