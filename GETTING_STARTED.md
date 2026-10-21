# Getting started: set up, train and test Swara from scratch

This guide starts from a fresh clone and has two parts:

- **Part A, backend:** install the services, train the models, start the stack.
- **Part B, app:** run the Flutter app and test each component end to end, once with the real server and once in Demo Mode.

```
Flutter app ──► Swara API (Node, :5001) ──► MongoDB (:27017)
                   ├─► C1 speech service   (FastAPI, :8010)
                   ├─► C2 vision service   (FastAPI, :8011)
                   └─► C4 language service (FastAPI, :8012, also does C3's word check)
```

The full reference for the API and the services is [`server/README.md`](server/README.md).

---

## 1. Prerequisites

| Tool | Version | Check |
|---|---|---|
| Docker Desktop | any recent | `docker --version` |
| Node.js | ≥ 20 | `node --version` |
| Python | 3.11 | `python3.11 --version` |
| uv | any | `uv --version` (or use plain `venv` + `pip`) |
| Flutter | **≥ 3.44** | `flutter --version` |
| Chrome, or an Android emulator / iOS simulator | | |

**Flutter version:** `mobile/pubspec.lock` needs Flutter 3.44 or newer (video_player 2.14 needs Dart 3.12). If your default Flutter is older, use a separate puro environment so other projects are not affected:

```bash
puro create swara 3.44.9
~/.puro/envs/swara/flutter/bin/flutter --version
```

To make plain `flutter` use it inside `mobile/`, pin the project once and route `flutter` through puro:

```bash
cd Swara-RP/mobile && puro use swara        # writes mobile/.puro.json (git-excluded locally)
# in ~/.zshrc (outside a pinned project, puro falls back to its default env):
alias flutter='puro flutter'
alias dart='puro dart'
```

`flutter` in the commands below then means Flutter 3.44+. If `flutter pub get` rewrites `pubspec.lock` or `ios/Flutter/*.xcconfig`, don't commit those changes.

**Disk and network:**
- **Running the stack:** the first run downloads about 3 GB: Python packages (torch and transformers are about 1 GB), MediaPipe's face model, and the C4 Sinhala ASR model (about 1.2 GB, from Hugging Face).
- **Training (section 3):** add about 40 GB for SEP-28k and its features, and the XLS-R encoder (about 1.2 GB). DAiSEE, FluencyBank and UCLASS come on top, once you have them. On this Mac, keep the datasets on the external drive (for example `/Volumes/CORSAIR/data/`).
- **GPU:** feature extraction uses the Mac's GPU (`mps`) automatically; CUDA works too, and CPU works but is slow.

---

# Part A: Backend

## 2. Install the backend (once)

### 2.1 MongoDB

```bash
cd Swara-RP/server
docker compose up -d
docker compose ps            # swara-mongo should be "healthy"
```

### 2.2 Python services

Each service has its own `.venv`. The training packages go into the same `.venv`, so the notebooks run the services' own code.

```bash
# C1 speech service (+ training: torch, transformers, scikit-learn, pandas, PyAV, jupyter)
cd Swara-RP/server/speech-service
uv venv --python 3.11 .venv
uv pip install --python .venv/bin/python -r requirements.txt -r requirements-training.txt 
or
 uv pip install --python .venv\Scripts\python.exe -r requirements.txt -r requirements-training.txt

# C2 vision service (+ training: torch, scikit-learn, pandas, jupyter; also used for C3's camera model)

cd ../vision-service
uv venv --python 3.11 .venv
uv pip install --python .venv/bin/python -r requirements.txt -r requirements-learned.txt
.venv/bin/python scripts/fetch_face_model.py     # downloads face_landmarker.task into models/

# C4 language service (nothing to train)
cd ../language-service
uv venv --python 3.11 .venv
uv pip install --python .venv/bin/python -r requirements.txt 
or 
uv pip install --python .venv\Scripts\python.exe -r requirements.txt
```

To only run the app with the default models, you can skip `requirements-training.txt` and `requirements-learned.txt`.

### 2.3 API

Create the API's settings file once. The API reads `server/api/.env`:

```bash
cd Swara-RP/server
cp .env.example api/.env
```

Then edit `api/.env` and set at least:

```ini
JWT_SECRET=pick-a-long-random-string
THERAPIST_SIGNUP_CODE=slp-2026        # the code a therapist types when registering; empty = therapist sign-up off
```

Install its packages:

```bash
cd Swara-RP/server/api
npm install
```

---

## 3. Train the models

The stack runs without any training: every component has a default that needs no trained model. Training replaces those defaults with models trained on public datasets, which you need for the research results:

| Component | Default (no training) | Trained model | Data | Where the model goes | How the service uses it |
|---|---|---|---|---|---|
| C1 stutter types | rule-based acoustic detector | head on XLS-R embeddings and acoustic features | SEP-28k (free); UCLASS (free) and FluencyBank for the child checks | `speech-service/models/c1_head.joblib` | start the speech service with `C1_DETECTOR=xlsr` |
| C2 secondary behaviours | label-free SRCD | GRU on SRCD sequences | FluencyBank Voices-AWS videos + CASA labels (supervisor) | `vision-service/models/c2_srcd.pt` | start the vision service with `C2_DETECTOR=gru` |
| C3 engagement (camera) | provisional hand-set weights | logistic regression or gradient boosting | DAiSEE (Google Form) | `api/src/modules/c3/data/engagementCameraModel.json` | restart the API |
| C3 recommender | Hybrid LinUCB (learns online, per child) | nothing to train; offline evaluation only | simulated children; pilot logs | `server/C3_EVALUATION.md` | — |
| C4 ASR | public Sinhala XLS-R CTC model (Hugging Face) | the team's fine-tune (continue that model, XLS-R-300m, or an MMS-1B adapter) | OpenSLR SLR52 (free, about 900 MB per shard) | `language-service/models/c4_asr/` | start the language service with `C4_CTC_MODEL=models/c4_asr` |

**Where to get each dataset and model** (all links checked on 2026-10-20):

| For | What | Link | How you get it |
|---|---|---|---|
| C1 | SEP-28k labels and podcast list | <https://github.com/apple/ml-stuttering-events-dataset> | Free (CC BY-NC 4.0). Notebook `c1_01` downloads the label files and the podcast audio itself; no manual download |
| C1 | SEP-28k-E speaker-separated splits | <https://github.com/th-nuernberg/ml-stuttering-events-dataset-extended> | Free; also fetched by `c1_01` |
| C1 | XLS-R-300m encoder | <https://huggingface.co/facebook/wav2vec2-xls-r-300m> | Free; downloads on first use (about 1.2 GB) |
| C1 | UCLASS (children who stutter) | <https://www.uclass.psychol.ucl.ac.uk/> | Free, no registration; download the WAV zips by hand (section 3.1) |
| C1, C2 | FluencyBank (Voices-CWS for C1's %SS check, Voices-AWS videos for C2) | <https://fluency.talkbank.org/> (TalkBank: <https://talkbank.org/>) | Membership: the supervisor creates a TalkBank account, then the faculty advisor emails talkbank@cmu.edu with their affiliation and intended use. Requests from students alone get no reply |
| C2 | CASA annotations (FG / HM at stutter moments) | <https://github.com/mbzuai-nlp/CASA> (paper: <https://arxiv.org/abs/2506.00644>) | Email the authors to confirm the annotations may be used (the licence is not stated). The videos themselves come from FluencyBank |
| C3 | DAiSEE (engagement videos) | <https://people.iith.ac.in/vineethnb/resources/daisee/index.html> | Submit the Google Form on that page. Terms: research use only, no sharing, cite Gupta et al. 2018 |
| C4 | OpenSLR SLR52 (Sinhala read speech) | <https://www.openslr.org/52/> | Free (CC BY-SA 4.0). The C4 notebook downloads the shards itself (about 900 MB each) |
| C4 | Current Sinhala ASR (the service's default) | <https://huggingface.co/SpideyDLK/wav2vec2-large-xls-r-300m-sinhala-low-LR-part1> | Free; the language service downloads it on first use |
| C4 | MMS-1B (for the adapter option) | <https://huggingface.co/facebook/mms-1b-all> | Free; downloads when chosen (about 4 GB) |
| C3 pictures | The team's activity pictures | The team's Google Drive folder | Save each image over the matching placeholder in `mobile/assets/images/component3/items/` (same file name) |
| C4 topics | The team's topic bank | The team's Google Doc | Paste into `server/api/src/modules/c4/data/topicBank.template.csv` and import (section 3.4 and `server/README.md`) |

**Request these now, because approval takes time:** FluencyBank membership, CASA permission and DAiSEE.

**Ethics:** the current approval covers audio only. Filming children (C2 path A, the C3 camera) needs the amendment first.

Numbers from the smoke tests in the verification logs (synthetic or public clips) check the code only; they are not results.

### 3.1 C1: stutter-type model (SEP-28k, notebooks)

Full run guide: [`server/speech-service/notebooks/README.md`](server/speech-service/notebooks/README.md).

```bash
cd Swara-RP/server/speech-service
export SWARA_C1_DATA=/Volumes/CORSAIR/data/sep28k     # keeps the ~40 GB off the main disk
.venv/bin/jupyter lab notebooks/                       # or VS Code with this .venv as the kernel
```

Run each notebook top to bottom (Run All). Every step can be re-run; finished downloads, clips and features are skipped, so after an interruption just run it again.

1. **`c1_01_data.ipynb`:** downloads SEP-28k (about 32 GB of podcasts, a few hours), cuts the 3 s clips and attaches the speaker-separated SEP-28k-E splits. About a quarter of the podcast links are dead; they are listed in `download_log.csv` and skipped. To try a few shows first: `SWARA_C1_SHOWS=HeStutters,StutterTalk`.
2. **`c1_02_features.ipynb`:** acoustic features (about 5 min) and XLS-R embeddings (about 1 h on an M2 Pro's GPU).
3. **`c1_03_train.ipynb`:** picks the XLS-R layer and the head on dev, reports macro-F1 on test against the rule-based detector, and exports `models/c1_head.joblib`. The report goes to `training/reports/`.
4. **`c1_04_children.ipynb`:** checks the model on children. It needs labelled child clips first:
   - **UCLASS** (free, no registration): download the WAV zips from <https://www.uclass.psychol.ucl.ac.uk/> and pick about 300 clips of children aged 5–14 with `training.uclass.prepare_label_set` (command in the run guide).
   - **Two raters label the clips separately**, each with the labelling page, about 1–2 hours each:

     ```bash
     .venv/bin/python tools/label_clips.py --clips /Volumes/CORSAIR/data/uclass_label_set --rater A              # http://localhost:8090
     .venv/bin/python tools/label_clips.py --clips /Volumes/CORSAIR/data/uclass_label_set --rater B --port 8091
     ```

   - Then run the notebook with `SWARA_C1_LABEL_SET=/Volumes/CORSAIR/data/uclass_label_set`. It reports Cohen's κ, the disagreements, and the model on the agreed clips.
   - **%SS check:** set `SWARA_C1_CHAT_DIR` (FluencyBank transcripts next to their WAVs) or `SWARA_C1_SS_CSV` (SLP hand counts) to compare C1's %SS with the reference (correlation, Bland–Altman, ICC).
   - The same tool and notebook work for the team's Sinhala pilot recordings, once the ethics approval covers them.

Check the model in the service:

```bash
C1_DETECTOR=xlsr .venv/bin/uvicorn app.main:app --port 8010
curl -s localhost:8010/health        # detectors.xlsr.status should be "available"
```

Licence: SEP-28k is CC BY-NC 4.0 (research only, no redistribution). Cite Lea et al. (ICASSP 2021) and Bayerl et al. (TSD 2022). For UCLASS, acknowledge UCLASS and the Wellcome Trust.

### 3.2 C2: secondary-behaviour model (FluencyBank + CASA, notebook)

Full run guide: [`server/vision-service/notebooks/README.md`](server/vision-service/notebooks/README.md). This needs the FluencyBank videos and the CASA labels.

```bash
cd Swara-RP/server/vision-service
# 1. Run every labelled video through the service's own pipeline (face tracking, fluent baseline, deviations)
.venv/bin/python -m training.build_dataset --casa-csv casa.csv --video-dir /path/to/voices-aws --out data/casa.npz
#    or the team's own labelled videos: --manifest data/manifest.json --out data/children.npz
# 2. The five-way comparison, then the final model
SWARA_C2_DATA=data/casa.npz .venv/bin/jupyter lab notebooks/c2_srcd_comparison.ipynb
```

The notebook compares the rules, a Random Forest on 2-second windows, a GRU without self-comparison, SRCD (label-free and with the GRU) and CASA's published numbers, all on the same moments, with no person in both training and test. It then trains the final GRU and writes `models/c2_srcd.pt`, plus a report in `training/reports/`.

Check the model in the service:

```bash
C2_DETECTOR=gru .venv/bin/uvicorn app.main:app --port 8011
curl -s localhost:8011/health        # detectors.gru.status should be "available"
```

If the file is missing or broken, the service falls back to label-free SRCD and says so in every response.

### 3.3 C3: engagement camera model (DAiSEE) and recommender evaluation

**Camera model**, once DAiSEE is downloaded. It runs in the vision service's `.venv`:

```bash
cd Swara-RP/server/vision-service
# One row of 10-second face features per clip (MediaPipe at 5 fps). Resumable; about 1.4 s per clip per worker on an M2 Pro.
.venv/bin/python -m training.build_engagement --daisee /Volumes/CORSAIR/data/DAiSEE --out data/daisee_engagement.npz --workers 6
# Logistic regression vs gradient boosting, subject-grouped CV + the official Test split
.venv/bin/python -m training.train_engagement --data data/daisee_engagement.npz
```

`train_engagement` writes `api/src/modules/c3/data/engagementCameraModel.json` and a report in `training/reports/`. Restart the API to load it; the API refuses a file whose self-check fails. Until then the API uses the provisional weights. On pilot sessions, `GET /api/c3/reports/engagement-pilot-check` compares the camera model with the parent questionnaire.

**Recommender evaluation:** there is nothing to train beforehand; the recommender learns online, per child. The offline evaluation runs the production bandit code on simulated children (results in `server/C3_EVALUATION.md`):

```bash
cd Swara-RP/server/api
node src/modules/c3/evaluation/run.js all     # or main | signals | stress | ope; --seeds 10 --children 80 --sessions 10
```

For the replay test on real sessions, run the API with `C3_EXPLORE_EPSILON=0.2`, then save `GET /api/c3/reports/replay-log?limit=500` to `replay-log.json` and run `node src/modules/c3/evaluation/ope.js replay-log.json` (see `server/README.md`).

### 3.4 C4: Sinhala ASR (OpenSLR SLR52, notebook)

The service starts with a public Sinhala XLS-R CTC model from Hugging Face. To train the team's own model, use the language service's notebook. Full run guide: [`server/language-service/notebooks/README.md`](server/language-service/notebooks/README.md).

```bash
cd Swara-RP/server/language-service
uv pip install --python .venv/bin/python -r requirements-training.txt
export SWARA_C4_DATA=/Volumes/CORSAIR/data/slr52     # about 900 MB per shard; SWARA_C4_SHARDS=0123456789abcdef for all 16
.venv/bin/jupyter lab notebooks/c4_01_asr_finetune.ipynb
```

- **What it does:** downloads SLR52 shards and makes speaker-disjoint, sentence-disjoint splits. It measures the current model's WER and CER on the test speakers, then trains: continuing the current model (default), or `SWARA_C4_BASE=facebook/wav2vec2-xls-r-300m`, or `facebook/mms-1b-all` (a Sinhala adapter). It reports both models on the same test utterances and saves `models/c4_asr/`.
- **Hardware:** a real run needs a CUDA GPU (or Colab); the Mac's GPU works for XLS-R but slowly, and MMS-1B needs about 24 GB.
- **Use it:** start the language service with `C4_CTC_MODEL=models/c4_asr`. This also changes C3's word, reading and picture checks.
- **Other options:** `C4_ASR_ENGINE=whisper` switches to the Whisper baseline. `POST /evaluate-asr` gives WER, CER and repetition retention for a reference and a transcript.

---

## 4. Start the stack

Use four terminals, plus one command for MongoDB. Add the `C1_DETECTOR` / `C2_DETECTOR` settings only once the trained models from section 3 exist.

```bash
# MongoDB
cd Swara-RP/server && docker compose up -d

# Terminal 1: C1 speech service        (trained model: prefix C1_DETECTOR=xlsr)
cd Swara-RP/server/speech-service && .venv/bin/uvicorn app.main:app --port 8010

# Terminal 2: C2 vision service        (trained model: prefix C2_DETECTOR=gru)
cd Swara-RP/server/vision-service && .venv/bin/uvicorn app.main:app --port 8011

# Terminal 3: C4 language service
cd Swara-RP/server/language-service && C4_PRELOAD=1 .venv/bin/uvicorn app.main:app --port 8012

# Terminal 4: API                      (loads the C3 camera model, if trained, at startup)
cd Swara-RP/server/api && npm start   # or: npm run dev (restarts on change)
```

`C4_PRELOAD=1` loads the ASR model at startup. Without it, the first C4 recording or C3 word check waits for the download and model load.

## 5. Check the stack

```bash
curl -s localhost:5001/api/health | python3 -m json.tool
curl -s localhost:8010/health | python3 -m json.tool      # C1: which detector is active
curl -s localhost:8011/health | python3 -m json.tool      # C2: which detector is active
```

You want `"status": "ok"`, with `mongo.status: connected` and `components.c1` … `components.c4` all `ok`.

- **C1 `degraded`:** the speech service isn't reachable. C3 still works, but treats C1 as missing.
- **C2 `degraded`:** the vision service or its face model is missing. Run `fetch_face_model.py` again.
- **C4 `degraded`:** the language service isn't reachable. This also turns off C3's word check.
- **Trained models:** the C1 and C2 health show `activeDetector` and each detector's `status`. If the trained file is missing or broken, the service uses its default and every analysis response says `detector.fallback: true`.

`/api/health` is the only API route that works without signing in.

---

# Part B: App

## 6. Run the app

```bash
cd Swara-RP/mobile
flutter pub get
```

Then pick a target:

| Target | Command | Notes |
|---|---|---|
| Chrome | `flutter run -d chrome` | Allow the microphone when asked. It works on `localhost`; from another device it needs HTTPS. The C2 video preview isn't shown in the browser, but the upload works |
| Android emulator | `flutter run` | Reaches the API at `10.0.2.2:5001` automatically. If the emulator is short of space, `flutter run --profile` installs a much smaller build |
| iOS simulator | `flutter run` | Reaches the API at `localhost:5001` |
| Physical phone | `flutter run --dart-define=API_HOST=192.168.x.y` | Use your computer's LAN address; the phone must be on the same Wi-Fi |
| Deployed API | `flutter run --dart-define=API_BASE_URL=https://host` | |

---

## 7. Create test accounts

There is one login per child, created by a parent. Make one child in each age band, because the tasks differ:

| Account | Child's age | What changes |
|---|---|---|
| Child A | 8 (band 5–10) | C1 picture description; C3 uses the 6 activity types with easier content (short sentences to read); C4 uses the younger topic bank |
| Child B | 12 (band 11–14) | C1 passage reading; C3 uses the same 6 types with harder content (paragraphs); C4 uses the older topic bank |

1. On the login screen, check that **Demo Mode is off**.
2. Tap **Register**, then choose **Parent/Caregiver**.
3. Fill in:
   - your name, email and password (at least 6 characters);
   - the child's first name and age;
   - a 4–6 digit **parent PIN**. Remember it: video uploads and the C3 questionnaire ask for it.
4. **Create Account** takes you to the child's home screen, which greets the child by name.

For a therapist account, register with **Speech Therapist** and the `THERAPIST_SIGNUP_CODE` from `api/.env`.

---

## 8. Test each component

Go through these with Child A, then repeat them with Child B.

### C1: Speech assessment

1. On the home screen, open the speech card (`/c1/record`).
2. Only the card for the child's age band can be tapped; the other one is dimmed. Tap it.
3. Check the task:
   - 5–10 shows a picture and a prompt from the task catalog;
   - 11–14 shows the catalog's Sinhala reading passage.
4. Tap **Start**, speak or read for 20–60 seconds, then tap **Stop Recording**. The button spins while the upload runs.
5. On "Great Job", tap **Continue to Analysis**. The steps animate while the server analyses the recording.
6. Check the results: stuttering type, severity (in English and Sinhala), syllables, stuttered syllables, stutter rate (%SS) and the event counts. Warnings such as "short sample" appear under the statistics. The type groups sound and word repetitions as "Repetition", and says "Mixed" when two types are tied.
7. **A recording made earlier:** on the task screen, **Or choose a recording from this device** picks a file (wav, flac, ogg, mp3, m4a, aac; up to 50 MB and 3 minutes). It is analysed as this age band's task, so it should be the child doing that task. The chosen file is not deleted from the phone.

**Expected:** short samples (under about 100 syllables) give a `short_sample` warning. That is correct, not a bug.

**Filming the face for C2 (path A, Android / iOS only):**
- Under the start button, **Film the face during this task** is a parent setting. It is off by default, and turning it on asks for the PIN.
- With it on, the task also records a silent face video, with a small preview while recording.
- After C1's upload the video goes to C2 with that C1 assessment, and C2 reuses its stutter moments. It appears under the C2 history.
- Leave it off unless the ethics approval covers filming children.
- To use the trained C1 model, start the speech service with `C1_DETECTOR=xlsr` (section 3.1).

### C2: Video analysis

C2 finds the stutter moments in the video's own audio, so the child must speak in the video.

1. Open the video card (`/c2/video/upload`).
2. Pick one front-facing video of the child talking: 2 seconds to 3 minutes, up to 200 MB, in mp4, mov, m4v, webm, avi or mkv.
   - For Child B (11–14), the child should be reading the C1 Sinhala passage in the video.
3. Tick **Parent consent** and enter the parent PIN.
4. Tap **Start Analysis**. You should see:
   - the processing screen moving through **Video received → Finding stutter moments in the audio → Face and head movement**;
   - then the results: FG/HM summary, eye, lip, jaw, cheek and head deviation cards, a stutter-moment list with explanations, and tracking details.
5. Go back to the upload screen. The analysis should be listed under **Previous analyses**.

**Expected:** a fluent video can return "No stutter moments were found." That is correct: C2 only looks at stutter moments.

### C3: Therapy session (the recommender)

1. Open the therapy card.
   - The home shows the child's **Current Streak** (days in a row with a finished session) and **Total Stars** (one per finished activity), from the server.
   - On Android or iOS, there is a parent setting, **Measure engagement with the camera**. It is off by default; turning it on asks for the parent PIN. Leave it off unless the ethics approval covers camera use in C3. On the web it is hidden.
   - Tap **අද දින ප්‍රතිකාර සැලැස්ම අරඹන්න** (start today's plan).
2. Go through welcome, character and adventure plan. On the journey map, tap the mascot (**ආරම්භය**).
3. The **Your next activity** card shows the server's choice and **Activity n of 5**. Tap **අරඹමු!**, do the activity, then finish it. The six activity types are breathing and relaxation, picture description, picture naming, syllable practice, word and phrase practice, and paragraph reading. A session has 5 activities and never repeats a type.
4. Answers are checked in every speaking activity. After each recording the sheet shows the result:
   - **picture naming** (the picture is shown, not the word), **syllable practice**, **word and phrase practice:** each word: ✅ matched / try again / say it again;
   - **paragraph reading:** the whole passage: read well, part of it read (with the share), or read it again;
   - **picture description:** the picture's keywords: described well, say a bit more, or talk about the picture.
   - The pictures are placeholders (a "?" card) until the team's pictures are added.
5. Every activity has **Skip this activity**. Back on the next-activity screen, optionally tap **How much did a parent help?** (none / a little / a lot / did most), then answer **How did it feel?**. The next activity appears only after the feedback is saved.
6. Repeat until the screen says the day's practice is done (after the 5th activity). A **break** dialog can appear if engagement stays low.
   - **Continue later:** close the app part-way, open the therapy home again: **Continue today's session** brings back the same session (and the open activity). After 12 hours an unfinished session is closed and shows as "Left unfinished" in the history.
7. Tap **Finish today's session**. Session complete should show:
   - activities completed, the **Therapy Success Score** out of 100, and the time;
   - an **Engagement** meter, with "Camera + activity" or "Activity only" under it.

   With the camera setting on, a **Camera on** badge shows during each activity. The phone keeps the video; only 10-second face numbers are sent with the result. Check them with `GET /api/c3/sessions/:id` (`result.camera.windows`).
8. Tap **සාරාංශය බලන්න**, answer the 6 parent questions, then **යවන්න** (enter the PIN if asked). A box shows the Therapy Success Score before and after the answers (they are 20 % of it).
9. Open **ප්‍රතිකාර ඉතිහාසය** (history) and **Therapy Progress**. The session should be listed with its TSS and any skipped activities, with the real streak and stars at the top.

**Expected:** if the language service is down, the checks are skipped quietly and the activity carries on. `node server/api/src/modules/c3/scripts/checkContent.js` lists the activity content that is still a placeholder.

### C4: Spontaneous speech

1. Open the C4 card and tap **Start**.
2. On a first visit, **interests**:
   - the grid shows the topic bank's categories for the child's band;
   - tap the 5 favourites, most favourite first. Each shows its place (1st … 5th); **Your ranking** below lets you drag them into another order. **Continue** stays disabled until 5 are picked.
3. **Personalization** saves the ranking and picks a topic. (There is no familiarity rating.)
   - On the first visit the **parent checklist** comes next: three yes / not-yet questions (with the PIN). The answers set the child's starting level. **Answer later** skips it for now; it is asked again next time.
   - Check the topic screen: title, category, age band, level and "Favourite no. n".
   - **වෙනත් මාතෘකාවක්** (another topic) should change the topic.
4. On the question screen, open **Research View** to see the category rank, the selection probability and the level.
5. On the **recording** screen:
   - it asks for at least 5 sentences; answer for 30–90 seconds (stopping before 30 s asks "keep going?");
   - use **Next question** to see the follow-ups; on a follow-up, **Skip this question** moves on when the child doesn't understand it (logged);
   - then stop.
6. **Processing** waits for the server's transcription and analysis. The first run is slow while the ASR model loads.
7. Check the screens that follow:
   - **transcription**: the Sinhala transcript and the duration. **Correct transcript (parent)** opens an editor (PIN); after saving, the label reads "Corrected by parent" and the analysis screens use the corrected text;
   - **Listen to Recording**: plays your answer back;
   - **analysis** and **results**: utterances (against the goal of 5), total words, NDW, MLU and **stuttered syllables (%SS)** from C1's model;
   - **comparison**: the previous session next to this one, including %SS (the first session shows "—" for the previous one);
   - **next session**: the previous topic, the language band and the question style. Once the child has a band (after the baseline), the parent can confirm it or pick another (PIN).
8. Start C4 again. Because the child is now onboarded, it should go straight to a new topic. **Change interests** on the intro screen redoes onboarding.
   - Every session is personalised. A topic is not repeated until all 25 of the child's topics were used.
   - The choice also follows C3's progress (a falling TSS prefers simple, concrete topics) and the stuttering rate (a rising %SS prefers the child's top favourites and concrete topics). `progressSignal` and `selection` in `GET /api/c4/sessions/:id` show every input.
   - The topic bank is a placeholder until the team's topics are imported: `node server/api/src/modules/c4/scripts/topicBank.js export topics.csv`, fill it in, then `import topics.csv`.

**Expected:** answers under 50 words show "these numbers are less reliable". The band stays "building the starting level" for the first 3 samples.

### Progress and therapist views

1. Open **Profile** (`/profile`).
   - **My Journey** shows the overall verdict from all four components (`GET /api/children/:childId/progress`): improved, no clear change, needs attention, or not enough sessions yet (it needs 4 %SS measurements from C1 assessments and C4 answers), with the reasons.
   - The three achievements are bright once earned (first activity, a 3-day streak, 5 speech samples) and greyed before.
   - The **Clinical Summary** shows one line per component: C1 severity and %SS; C2 secondary-behaviour flag; C3 TSS; C4 band and %SS.
2. Sign out, register or log in as a therapist, and open the therapist home. Both test children should be listed with C1's latest severity.
3. Open a child. **View Speech Assessments**, **Component 2 Movement Analysis**, **Therapy Recommendations** and **Progress Dashboard** should open that child's screens. A therapist doesn't need the parent PIN.
4. The **Knowledge Base** should list the C3 activity pool for both age bands.

---

## 9. Demo Mode

Demo Mode runs without the server, using built-in sample data.

1. Sign out. On the login screen, turn **Demo Mode** on.
2. Log in as `parent@demo.com` or `therapist@demo.com`, with any password (e.g. `demo123`).
3. Go through C1, C3, C4 and Progress. They should show the sample results and make no network calls. C3 walks a fixed activity order in Demo Mode; it does not learn (the recommender runs only on the server).
4. C2 shows a "needs a real signed-in account" message in Demo Mode; that is expected.

---

## 10. Checks without the app

```bash
# App: static analysis and unit tests (the tests parse the server's contract files)
cd Swara-RP/mobile
flutter analyze
flutter test test/api_adapters_test.dart test/video_analysis_models_test.dart

# API: sign up and call a route by hand
curl -s -X POST localhost:5001/api/auth/register -H 'content-type: application/json' \
  -d '{"role":"child","name":"Test Parent","email":"t@example.com","password":"secret1","child":{"firstName":"Nimal","age":8},"parentPin":"1234"}'
TOKEN=...   # the "token" from the response
curl -s localhost:5001/api/c1/tasks?age=8 -H "Authorization: Bearer $TOKEN"
```

`test/widget_test.dart` already failed before the server was connected ("No ProviderScope found"); it is not related to this setup.

To look at the stored data:

```bash
docker exec -it swara-mongo mongosh swara
> db.accounts.find({}, {email: 1, role: 1, child: 1})
> db.getCollectionNames()          // c1_…, c2_…, c3_…, c4_… collections per component
```

---

## 11. Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| "Could not reach Swara" on login | The API isn't running, or the app points at the wrong host. On a phone, pass `--dart-define=API_HOST=<LAN IP>` and check both devices are on the same Wi-Fi |
| `flutter pub get` fails with a Dart SDK error | Flutter is older than 3.44; use the puro env from step 1 |
| API exits with "cannot reach MongoDB" | Run `docker compose up -d` in `Swara-RP/server` |
| 401 "Sign in first" | The session expired (7 days) or the app was signed out; log in again |
| 403 `parent_mode_required` | Enter the parent PIN when asked. Parent mode lasts 15 minutes |
| 403 `other_child` | A child account tried to act for another child. That is expected, and is the API protecting the data |
| 403 `therapist_signup_disabled` | Set `THERAPIST_SIGNUP_CODE` in `server/api/.env` and restart the API |
| C1 result stuck on the animation, then "taking too long" | The speech service is down; check `curl localhost:8010/health` |
| C2 stuck on "Finding stutter moments" | C2 waits for the linked C1 assessment, so check the speech service |
| C4 processing very slow the first time | The ASR model is downloading or loading. Start the language service with `C4_PRELOAD=1` |
| Results say `detector.fallback: true`, or a detector's `status` in the service's `/health` is not `available` | The trained model file is missing or broken, or the training packages aren't installed; run the notebook's export step again, or start without `C1_DETECTOR` / `C2_DETECTOR` |
| A notebook stops part-way (download, features) | Run it again: finished files are skipped |
| XLS-R features very slow | The notebook fell back to the CPU; check `SWARA_C1_DEVICE` (`mps` on a Mac) |
| C3 camera model not used after training | Restart the API; check `GET /api/c3/engagement/model` (`camera`) |
| C3 "Start today's plan from the therapy home first" | The app was restarted mid-session; start a new session from the therapy home |
| C4 "onboarding_required" | Choose 5 interests (use **Change interests** on the C4 intro) |
| No microphone in Chrome | Allow the microphone for the site; outside `localhost` the page must be served over HTTPS |
| Android: requests fail on a real phone | Check the IP passed with `API_HOST`; the app already allows HTTP to the dev server |

## 12. Reset for a fresh run

```bash
cd Swara-RP/server
docker compose down -v      # deletes the MongoDB volume: every account, session and result
docker compose up -d
```

In the app, sign out (Profile → sign out). Uninstall the app, or clear the browser's site data for `localhost`, to forget the saved login.
