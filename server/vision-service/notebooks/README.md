# C2 model training: run guide

`c2_srcd_comparison.ipynb` runs the C2 plan's evaluation and trains the model the service uses with `C2_DETECTOR=gru`. On the same labelled stutter moments, with participant-grouped folds, it compares:
1. the earlier fixed-threshold rules;
2. a Random Forest on 2-second window statistics;
3. a GRU **without** the "compare with yourself" step;
4. SRCD: (a) label-free, (b) with the GRU;
5. CASA's published video model (reference numbers only).

## 1. Data (needs the supervisor)

- **Videos:**
  - FluencyBank Voices-AWS (adults who stutter, filmed).
  - <https://fluency.talkbank.org/>. The supervisor needs TalkBank / FluencyBank membership: set up a TalkBank account, then the faculty advisor emails talkbank@cmu.edu with their affiliation and intended use. This is the same request as for C1.
- **Labels:**
  - The CASA annotations (Interspeech 2025; <https://github.com/mbzuai-nlp/CASA>, paper <https://arxiv.org/abs/2506.00644>): when facial grimacing (FG) and head movement (HM) happen in those videos.
  - Email the authors to confirm the labels may be used, because the licence is not stated.
- **Children:** filming children needs the ethics approval changed (the current letter says audio only). Once it is, the team's own labelled child videos go in the same way (see the manifest format below).

## 2. Setup (once)

```bash
cd Swara-RP/server/vision-service
uv pip install --python .venv/bin/python -r requirements-learned.txt   # torch, scikit-learn, pandas, jupyter
.venv/bin/python scripts/fetch_face_model.py                            # MediaPipe face model, if models/ is empty
```

## 3. Build the dataset

The builder runs every video through the service's own pipeline: face tracking, the speaker's fluent baseline and the deviations. For every labelled stutter moment it stores:
- the SRCD sequence;
- the raw sequence (for the ablation);
- 2-s window statistics (for the Random Forest);
- the rules and label-free SRCD decisions.

```bash
# CASA: timed annotations CSV + the FluencyBank videos (matched by file name to media_file)
.venv/bin/python -m training.build_dataset --casa-csv casa.csv --video-dir /path/to/voices-aws --out data/casa.npz
# or the team's own labelled videos:
.venv/bin/python -m training.build_dataset --manifest data/manifest.json --out data/children.npz
```

The manifest format is `[{"video": "clips/child01.mp4", "participant": "child01", "moments": [{"start": 4.0, "end": 4.8, "FG": 1, "HM": 0}, ...]}]`, with paths relative to the manifest file.

Check the CASA participant ids: `--participant-regex` (default: leading digits of `media_file`) decides which videos belong to the same person, and therefore that no person is in both training and test.

## 4. Run the notebook

```bash
.venv/bin/jupyter lab notebooks/c2_srcd_comparison.ipynb
```

Settings (environment variables):

| Variable | Default | Use |
|---|---|---|
| `SWARA_C2_DATA` | `data/casa.npz` | the dataset from step 3 |
| `SWARA_C2_FOLDS` | 5 | participant-grouped folds |
| `SWARA_C2_EPOCHS` | 60 | GRU training epochs |
| `SWARA_C2_SAVE_MODEL` | 1 | train the final GRU on all data and write `models/c2_srcd.pt` |
| `SWARA_C2_REPORT_DIR` | `training/reports` | where the comparison table goes (`c2-comparison-<date>.md` / `.json`) |
| `SWARA_C2_NOTE` | | free text stored with the model and the report |

**Reading the result:** the plan's claim holds if two things are true:
- SRCD (4a or 4b) beats the rules and the Random Forest;
- the GRU without self-comparison (3) is clearly below the one with it (4b).

CASA's published F1 (0.63 FG, 0.28 HM) comes from a different split, so it is only a scale.

**Use the model in the service:**

```bash
C2_DETECTOR=gru .venv/bin/uvicorn app.main:app --port 8011
curl -s localhost:8011/health      # detectors.gru.status should be "available"
```

If the file is missing or broken, the service falls back to label-free SRCD and says so in every response.

## Smoke test

On 2026-10-20 the builder and the notebook were run end to end on 4 short public interview clips with random labels (`VERIFICATION_LOG_C2.md`, V-20). That checks the code path only; it is not a result.
