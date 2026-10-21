# C4 ASR training: run guide

`c4_01_asr_finetune.ipynb` trains the team's own Sinhala speech-recognition model for C4, as the C4 plan asks, and compares it with the public model the service uses now.

| Step | What it does | Time |
|---|---|---|
| 1. Data | Downloads OpenSLR SLR52 shards and makes speaker-disjoint, sentence-disjoint train / dev / test splits | About 900 MB and a few minutes per shard |
| 2. Baseline | WER / CER of the service's current model on the test split | Minutes |
| 3. Training | Continues training the current model, or trains XLS-R-300m with a new head, or an MMS-1B Sinhala adapter | Hours on a GPU; see below |
| 4. Export | The same WER / CER on the same test utterances, a report in `training/reports/`, and a model folder for the service | Minutes |

## 1. Setup (once)

```bash
cd Swara-RP/server/language-service
uv pip install --python .venv/bin/python -r requirements-training.txt   # pandas, jupyter on top of the service's packages
.venv/bin/jupyter lab notebooks/
```

**Data location:** keep the corpus on the external drive, for example `export SWARA_C4_DATA=/Volumes/CORSAIR/data/slr52`. Each shard is about 900 MB zipped, about 1 GB unzipped.

## 2. Settings

| Variable | Default | Use |
|---|---|---|
| `SWARA_C4_DATA` | `data/slr52` | where the corpus goes |
| `SWARA_C4_SHARDS` | `0` | which of the 16 shards to use (`0123456789abcdef` = all 185k utterances); each shard is about 11.5k utterances from about 30 speakers |
| `SWARA_C4_BASE` | the service's current model | starting point: the current model (continue training), `facebook/wav2vec2-xls-r-300m` (new head) or `facebook/mms-1b-all` (MMS adapter) |
| `SWARA_C4_STEPS` | 2000 | optimiser steps |
| `SWARA_C4_BATCH` / `SWARA_C4_ACCUMULATE` | 8 / 2 | utterances per step = batch × accumulate |
| `SWARA_C4_LR` | 1e-4 (1e-3 for MMS adapters) | learning rate |
| `SWARA_C4_MAX_TRAIN` / `SWARA_C4_MAX_EVAL` | 0 (all) | limit the utterances, for a quick test |
| `SWARA_C4_DEVICE` | auto (`cuda`, `mps`, `cpu`) | |
| `SWARA_C4_OUT` | `models/c4_asr` | the model folder |
| `SWARA_C4_NOTE` | | free text in the report |

**Hardware:**
- XLS-R-300m trains on the Mac's GPU (`mps`), slowly: CTC loss runs on the CPU there.
- MMS-1B needs a GPU with about 24 GB, or Google Colab; on a laptop use it only with a small `SWARA_C4_MAX_TRAIN`.
- A real run (several shards, a few thousand steps) is best done on a CUDA GPU.

## 3. Use the model in the service

```bash
C4_CTC_MODEL=models/c4_asr C4_PRELOAD=1 .venv/bin/uvicorn app.main:app --port 8012
curl -s localhost:8012/health      # engines.ctc should be "available"
```

The model also does C3's word, reading and picture checks, so check those after switching.

## 4. Reading the result

- Print the latest recorded CTC / Whisper benchmark table in the terminal from `language-service/` with `.venv\\Scripts\\python.exe show_accuracy.py`. To compare a new reference transcript with an ASR transcript, pass `--reference reference.txt --hypothesis asr.txt`; both files should be UTF-8.
- The notebook reports WER and CER for the current model and for the new one on the same test speakers, who are never seen in training.
- Sentences read in dev or test are removed from train, so the model is not tested on text it learned.
- SLR52 is adult read speech. Before relying on the model for children, check it on the team's own child recordings: put their transcripts through `POST /evaluate-asr`.

**Source:** <https://www.openslr.org/52/> (the notebook downloads the shards). **Licence:** SLR52 is CC BY-SA 4.0. Cite Kjartansson et al., "Crowd-Sourced Speech Corpora for Javanese, Sundanese, Sinhala, Nepali, and Bangladeshi Bengali", SLTU 2018.

## Smoke test

On 2026-10-20 the data step was checked on shard 0: speaker- and sentence-disjoint splits of 8,896 / 647 / 614 utterances (`server/VERIFICATION_LOG_C4.md`, V-24). A short training run (10 steps) was started but stopped by the system for low memory, so training and export have **not** been verified yet. Run it on its own, with nothing else heavy running: `SWARA_C4_MAX_TRAIN=64 SWARA_C4_MAX_EVAL=24 SWARA_C4_STEPS=10`.
