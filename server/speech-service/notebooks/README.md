# C1 model training: run guide

These notebooks train and check C1's stutter-type model on this Mac (or any machine with Python 3.11), following the C1 dataset plan:

| Notebook | What it does | Time on an M2 Pro (all of SEP-28k) |
|---|---|---|
| `c1_01_data.ipynb` | Downloads SEP-28k, cuts the 3 s clips, attaches the speaker-separated SEP-28k-E splits | Download-bound: 32 GB of podcasts, a few hours |
| `c1_02_features.ipynb` | Acoustic features (MFCC, pitch, energy) and XLS-R embeddings for every clip | About 5 min acoustic, about 1 h XLS-R on the GPU (`mps`) |
| `c1_03_train.ipynb` | Picks the XLS-R layer, compares heads, reports macro-F1 on the test split against the rule-based detector, exports `models/c1_head.joblib` | Minutes |
| `c1_04_children.ipynb` | Checks the model on children's clips (rater agreement, Cohen's κ) and C1's %SS against a reference (FluencyBank or SLP counts) | Minutes, once the labels exist |

The notebooks only call code in `training/` and `app/`. The service's detector reads the exported head unchanged, so what you evaluate is what runs.

## 1. Setup (once)

```bash
cd Swara-RP/server/speech-service
uv venv --python 3.11 .venv            # skip if the service's .venv already exists
uv pip install --python .venv/bin/python -r requirements-training.txt
.venv/bin/jupyter lab notebooks/        # or open the notebooks in VS Code with this .venv as the kernel
```

- **Disk:** about 40 GB, under `data/sep28k/` by default (git-ignored). On this Mac, point it at the external drive: `export SWARA_C1_DATA=/Volumes/CORSAIR/data/sep28k` before starting Jupyter.
- **Model download:** the XLS-R model (`facebook/wav2vec2-xls-r-300m`, about 1.2 GB) downloads on first use to `~/.cache/huggingface`.

## 2. Train on SEP-28k (notebooks 1–3)

Run notebooks 1, 2 and 3 in order (Run All). Every step can be re-run: downloads, clips and feature chunks that already exist are skipped. So after an interruption, just run the notebook again.

**Settings** are environment variables, set before starting Jupyter or at the top of a notebook with `os.environ[...]`:

| Variable | Default | Use |
|---|---|---|
| `SWARA_C1_DATA` | `data/sep28k` | where the dataset, clips and features go |
| `SWARA_C1_SHOWS` | all | e.g. `HeStutters,StutterTalk` to try a few shows first |
| `SWARA_C1_WORKERS` | 4 | parallel downloads / feature processes |
| `SWARA_C1_ENCODER` | `facebook/wav2vec2-xls-r-300m` | the frozen encoder (the service uses the same one) |
| `SWARA_C1_LAYERS` | `6,9,12,15,18,21,24` | XLS-R layers to try; notebook 3 picks one on dev |
| `SWARA_C1_DEVICE` | auto (`mps` on a Mac) | `cuda`, `mps` or `cpu` |
| `SWARA_C1_MIN_VOTES` | 2 | a label counts when at least this many of the 3 annotators chose it |
| `SWARA_C1_HEAD_OUT` | `models/c1_head.joblib` | the exported head |
| `SWARA_C1_NOTE` | | free text stored with the head and report |

**What to expect:**
- About a quarter of the podcast links are dead (checked 11 October 2026). They are listed in `data/sep28k/download_log.csv`, and their clips are skipped. The rest still gives roughly 20,000 clips.
- SEP-28k's FluencyBank part needs a TalkBank login and is not downloaded.
- Notebook 3 writes a report to `training/reports/<version>.md` and `.json`: per-label F1, precision and recall, macro-F1, and every input/head combination. The model is chosen on dev; test is only reported. The dataset plan quotes about 0.45 macro-F1 for published systems on these splits; check the paper's setting before comparing.

After notebook 3 finishes, print the latest test report in a readable terminal table (PowerShell):

```powershell
cd D:\Swara-RP\server\speech-service
.\.venv\Scripts\python.exe show_accuracy.py
```

**Use the model in the service:**

```bash
cd Swara-RP/server/speech-service
C1_DETECTOR=xlsr .venv/bin/uvicorn app.main:app --port 8010
curl -s localhost:8010/health        # detectors.xlsr.status should be "available"
```

The head file says which inputs it needs (`xlsr`, `acoustic` or both). A head on acoustic features alone runs without torch.

**Sources:** SEP-28k <https://github.com/apple/ml-stuttering-events-dataset>, SEP-28k-E <https://github.com/th-nuernberg/ml-stuttering-events-dataset-extended> (notebook 1 downloads both).

**Licence:** SEP-28k is CC BY-NC 4.0 (research only, no redistribution of the audio). Cite Lea et al. (ICASSP 2021) and Bayerl et al. (TSD 2022, SEP-28k-E).

## 3. Children: UCLASS clips and rater agreement (notebook 4, part A)

SEP-28k is adults, so the model must be checked on children. UCLASS is free for research and needs no registration.

1. **Download:**
   - From <https://www.uclass.psychol.ucl.ac.uk/>, take the WAV zips:
     - Release One: `Audio/wav/AllAudioWav.zip`, spontaneous monologue, ages 5–47;
     - Release Two: `Release2/Monologue/AudioOnly/wav/AllMonoWavAudioOnly.zip` (about 700 MB), and optionally the Reading and Conversation zips (ages 5–20).
   - Unzip everything into one folder, for example `/Volumes/CORSAIR/data/uclass/`.
   - Terms: acknowledge UCLASS as the source and state that data collection was supported by the Wellcome Trust.
2. **Pick the clips to label:** about 300 clips of 3 s, children aged 5–14 only (read from the file names), spread evenly over speakers.

   ```bash
   .venv/bin/python -c "
   from pathlib import Path
   from training import uclass
   recs = uclass.recordings(Path('/Volumes/CORSAIR/data/uclass'))
   print(len(recs), 'recordings,', recs.speaker.nunique(), 'children')
   uclass.prepare_label_set(recs, Path('/Volumes/CORSAIR/data/uclass_label_set'), n_clips=300)"
   ```

3. **Label: two people, separately.** Each runs the labelling page on their own computer or port, so neither sees the other's answers:

   ```bash
   .venv/bin/python tools/label_clips.py --clips /Volumes/CORSAIR/data/uclass_label_set --rater A              # http://localhost:8090
   .venv/bin/python tools/label_clips.py --clips /Volumes/CORSAIR/data/uclass_label_set --rater B --port 8091
   ```

   - **Labels:** the same 5 as SEP-28k, or "fluent", or "unusable" (no child speech, noise, or an adult speaking).
   - **Keys:** 1–5 toggle the labels, F fluent, U unusable, space replays, Enter saves and moves on.
   - **Saving:** answers are saved after every clip in `labels_A.csv` / `labels_B.csv`, so a session can stop and resume. About 300 clips take roughly 1–2 hours per person.
4. **Run notebook 4** with `SWARA_C1_LABEL_SET=/Volumes/CORSAIR/data/uclass_label_set`. It reports:
   - Cohen's κ per label (above 0.6 is substantial agreement; report it with the results);
   - the clips the raters disagree on, to settle with a third person;
   - the model and the rule-based detector scored on the agreed clips, next to the adult SEP-28k test score.

The same tool and notebook work for the team's **Sinhala pilot recordings**:
- Put 16 kHz WAVs in a folder.
- Run `uclass.prepare_label_set` on a table with `path`, `speaker` and `ageYears` columns, or put the clips in `clips/` with your own `manifest.csv`.
- Then label them the same way.
- The pilot needs the ethics approval for children's audio, and ideally an SLP checks the labels.

## 4. Severity: C1's %SS against a reference (notebook 4, part B)

Notebook 4 runs each recording through the **service's own pipeline** and compares its %SS with a reference:
- Pearson and Spearman correlation;
- mean difference with 95 % limits of agreement (Bland–Altman);
- ICC(2,1).

Two kinds of reference:
- **FluencyBank Voices-CWS:**
  - <https://fluency.talkbank.org/>. Needs the supervisor's TalkBank membership. The faculty advisor must email talkbank@cmu.edu; requests from students alone get no reply.
  - Put each transcript `.cha` next to a 16 kHz WAV of the same name in one folder, and set `SWARA_C1_CHAT_DIR`.
  - `training/chat_ss.py` counts stuttered syllables from the CHAT codes as FluCalc does (`↫r-r↫rabbit`, `s:o`, `spa^ghetti`, `≠big`, monosyllabic `dog [/] dog`). Only the child's own utterances (`*CHI`, by their time stamps) go into C1.
  - Cite Bernstein Ratner & MacWhinney (2018).
- **SLP hand counts:** a CSV with `audio`, `referencePercentSS` and optionally `transcript`, `taskType`, `passageText`, `language`. Set `SWARA_C1_SS_CSV`. Hand counts stored through the API (`POST /api/c1/assessments/:id/reviews`) can be exported to this format.

Set `C1_DETECTOR=xlsr` before starting Jupyter to check the trained model; leave it unset to check the rule-based detector.

## Smoke test

To check the notebooks without downloading anything, run them on a tiny SEP-28k-shaped set: synthetic speech with stutters spliced in, in the same file formats. Point `SWARA_C1_DATA` at it. This was done on 2026-10-20 (`server/VERIFICATION_LOG.md`, V-21); numbers from a smoke set are not results.
