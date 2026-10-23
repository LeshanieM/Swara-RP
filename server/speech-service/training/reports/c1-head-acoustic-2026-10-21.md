# c1-head-acoustic-2026-10-21

Acoustic-only model trained on locally available SEP-28k episodes; test split is speaker-separated SEP-28k-E. XLS-R embeddings were not extracted.

Chosen on dev: acoustic / mlp.

## Test split (SEP-28k-E)

| label            |   precision |   recall |    f1 |   positives |   rule-based F1 |
|:-----------------|------------:|---------:|------:|------------:|----------------:|
| block            |       0.155 |    0.48  | 0.234 |         327 |           0.048 |
| prolongation     |       0.278 |    0.41  | 0.331 |         266 |           0.174 |
| sound_repetition |       0.117 |    0.564 | 0.194 |         236 |           0.112 |
| word_repetition  |       0.18  |    0.583 | 0.275 |         391 |           0.145 |
| interjection     |       0.333 |    0.545 | 0.413 |         670 |           0.296 |
| macro-F1         |     nan     |  nan     | 0.289 |         nan |           0.155 |

## Head comparison

| inputs   | head   |   dev macro-F1 |   test macro-F1 |
|:---------|:-------|---------------:|----------------:|
| acoustic | logreg |          0.318 |           0.299 |
| acoustic | mlp    |          0.319 |           0.289 |
