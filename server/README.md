# Swara server

The backend for all Swara components, split by concern:

- **one Node API** handles HTTP, validation, persistence and jobs, with one module per component;
- **separate Python services** do the ML work.

All four components are implemented:

- **Component 1** (stutter-event detection and severity): a child's recording goes in; stutter events, %SS and a task-aware severity estimate come out and are saved.
- **Component 2** (video-based secondary behaviours): a face video goes in; for every stutter moment it reports whether the face (FG: eye, lip, jaw, cheek) or head (HM) moved unusually *for this child*, with an explanation, a behaviour timeline and the yes / no / missing flag C3 reads.
- **Component 3** (engagement-aware therapy recommender): a Hybrid LinUCB picks the child's next activity from an age-banded, SLP-approved pool, using C1 severity, the C2 flag, parent help, engagement and therapy history as context. It learns from `0.6·performance + 0.4·engagement` and scores each session with a Therapy Success Score.
- **Component 4** (spontaneous speech and language-sample analysis): a topic is chosen from the child's ranked interests and the child's answer goes in. Out come and are saved:
  - a Sinhala transcript that keeps repetitions;
  - maze removal and utterances;
  - MLU / NDW / MATTR and new words;
  - a band relative to the child's own baseline;
  - spontaneous %SS (via C1).

```
 Flutter app ──Bearer JWT──► Swara API (Node/Express, :5001) ──► MongoDB (db "swara")
                                        ├─ /api/health    whole-server status
                                        ├─ /api/auth      child + therapist logins, parent-mode PIN
                                        ├─ /api/children  the children an account can see
                                        ├─ /api/c1/...    C1 module: async jobs, history, summary, reviews
                                        │     │
                                        │     ▼
                                        │  C1 speech service (FastAPI, :8010)
                                        │  audio → 3 s windows → events → %SS + duration → severity
                                        │     ▲ the video's audio track becomes a linked C1 assessment
                                        │     ▲ spontaneous %SS (C4 sends its recording + transcript)
                                        ├─ /api/c2/...    C2 module: async jobs, history, summary (C3 flag), reviews
                                        │     │
                                        │     ▼
                                        │  C2 vision service (FastAPI, :8011)
                                        │  video → MediaPipe (52 blendshapes + pose) → child's fluent baseline
                                        │  → deviation at each C1 stutter moment → FG / HM + explanation
                                        ├─ /api/c3/...    C3 module: activity pool, sessions, Hybrid LinUCB,
                                        │                 engagement, TSS, questionnaire (reads C1's summary)
                                        └─ /api/c4/...    C4 module: topic banks, onboarding, sessions,
                                              │           async sample job, corrections, vocabulary, bands
                                              ▼
                                           C4 language service (FastAPI, :8012)
                                           audio → CTC ASR (keeps repetitions) → mazes → utterances → measures
```

## Layout

| Path | What it is |
|---|---|
| `api/src/config`, `db`, `lib`, `middleware` | Shared by every component: env, the MongoDB connection, `ApiError`, the job queue, validation and the error envelope |
| `api/src/auth/` | Accounts, password / PIN hashing, session and parent-mode tokens, the `authenticate` / `requireParentMode` middleware, `/api/auth` routes |
| `api/src/routes/children.js` | `GET /api/children`: the child accounts a signed-in account can see, with C1's latest severity |
| `api/src/routes/health.js` | `GET /api/health`: MongoDB plus each component's own health |
| `api/src/modules/index.js` | The list of components; each is mounted at `/api/<name>` |
| `api/src/modules/c1/` | Component 1: routes, `SpeechAssessment` model, services, validation, task catalog, audio upload |
| `api/src/modules/c2/` | Component 2: routes, `VideoAnalysis` model, job service, vision client, the C1 bridge, validation, video upload |
| `speech-service/` | Python 3.11 FastAPI service for C1: detector, events, syllables, severity, MiMi baseline |
| `api/src/modules/c3/` | Component 3: routes, session/activity/bandit/engagement-model models, Hybrid LinUCB (`bandit/`), services, validation, activity pool and questionnaire (`data/`) |
| `api/src/modules/c4/` | Component 4: topic bank and checklist data, profile / session / sample models, topic selector, sample job, vocabulary, bands, research exports |
| `vision-service/` | Python 3.11 FastAPI service for C2: face tracking, speaker baseline, SRCD scoring, rules baseline, GRU / transformer hook, training scripts |
| `language-service/` | Python 3.11 FastAPI service for C4: Sinhala CTC ASR, normalisation, stemming, maze removal, utterances, measures, ASR evaluation |
| `contracts/c1/`, `contracts/c2/` | A real `/analyze-speech` and `/analyze-video` response: the frozen contracts between the API modules and the services |
| `contracts/c3/` | Real C3 requests and responses (session, next activity, result, completion, questionnaire, child summary), the contract for the app |
| `contracts/c4/` | Real `/transcribe` and `/measures` responses, the contract between the C4 module and the language service |
| `IMPLEMENTATION_NOTES.md`, `VERIFICATION_LOG.md` | C1: design decisions, deviations, limitations; what was run and fixed |
| `IMPLEMENTATION_NOTES_C2.md`, `VERIFICATION_LOG_C2.md` | The same for C2 |
| `C3_IMPLEMENTATION_NOTES.md`, `C3_VERIFICATION_LOG.md` | The same for C3 |
| `IMPLEMENTATION_NOTES_C4.md`, `VERIFICATION_LOG_C4.md` | The same for C4 |

This folder is self-contained: the API and the three services are the whole backend.

### Adding a component

1. Create `api/src/modules/<name>/index.js` exporting `{ name, title, router, health(), recover() }`. `health()` returns `{ ok, ...details }` for the component's own dependencies; `recover()` resumes unfinished jobs at startup and returns `{ requeued, failed }`.
2. Add it to `api/src/modules/index.js`.
3. Keep its models, collections (prefixed, e.g. `c2_…`), uploads (`uploads/<name>/`) and validation inside the module.
4. Put its ML work in its own service folder next to `speech-service/` (for example `vision-service/` for C2), with its contract under `contracts/<name>/`.

## Run it

Prerequisites: Docker, Node ≥ 20, Python 3.11 with [`uv`](https://docs.astral.sh/uv/) (or plain `venv` + `pip`).

```bash
cd Swara-RP/server

# 1. MongoDB
docker compose up -d

# 2. Speech service (terminal 1)
cd speech-service
uv venv --python 3.11 .venv && uv pip install --python .venv/bin/python -r requirements.txt
.venv/bin/uvicorn app.main:app --port 8010

# 3. Vision service (terminal 2)
cd vision-service
uv venv --python 3.11 .venv && uv pip install --python .venv/bin/python -r requirements.txt
.venv/bin/python scripts/fetch_face_model.py      # MediaPipe face_landmarker.task → models/
.venv/bin/uvicorn app.main:app --port 8011

# 4. C4 language service (terminal 3). torch + transformers are about 1 GB; the CTC
#    model (~1.2 GB) downloads from Hugging Face on first use (or at startup with C4_PRELOAD=1).
cd language-service
uv venv --python 3.11 .venv && uv pip install --python .venv/bin/python -r requirements.txt
.venv/bin/uvicorn app.main:app --port 8012

# 5. API (terminal 4)
cd api
npm install
npm start            # or: npm run dev (restarts on change)
```

Check: `curl localhost:5001/api/health` returns `"status":"ok"` with Mongo `connected` and `components.c1.status`, `components.c2.status`, `components.c3.status` and `components.c4.status` all `ok`. C3 needs only MongoDB; without the speech service, C1 reports `degraded` and C3 still works (it then treats C1 as missing for children with no saved result).

Configuration: see `.env.example`. The API reads `server/api/.env`; the speech service reads `C1_*` variables or `speech-service/.env`; the vision service reads `C2_*` variables or `vision-service/.env`; the language service reads `C4_*` variables or `language-service/.env`.

## Auth (`/api/auth`, `/api/children`)

There is one login per child, set up by a parent. The parent also sets a PIN for **parent mode**. Therapists have their own logins. Every `/api/c1`–`/api/c4` and `/api/children` route needs `Authorization: Bearer <token>`; only `/api/health` and `/api/auth/register|login` are open.

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/auth/register` | Child: `{role:"child", name, email, password, child:{firstName, age 5–14}, parentPin (4–6 digits)}`. Therapist: `{role:"therapist", name, email, password, signupCode}` (must equal `THERAPIST_SIGNUP_CODE`). → **201** `{token, user}`; a child account gets a generated `child.childId` (`CH-XXXXXX`) |
| POST | `/api/auth/login` | `{email, password}` → `{token, user}` |
| GET | `/api/auth/me` | The signed-in account |
| PATCH | `/api/auth/me/child` | `{firstName?, age?}` (e.g. a birthday) |
| POST | `/api/auth/parent-mode` | `{pin}` → `{parentToken, expiresInSec}`; send it as `X-Parent-Token` |
| GET | `/api/children` · `/api/children/:childId` | A therapist sees every child, a child account only itself: `{childId, firstName, age, severity, stutterType, percentSS, lastAssessedAt}` from C1's latest result (`stutterType`: Block / Prolongation / Repetition / Mixed) |
| GET | `/api/children/:childId/progress` | Overall progress across C1–C4: the %SS series (C1 assessments and C4 answers, by date), each component's evidence (C1 severity, C2 flag, C3 TSS trend, C4 band and trend), and a verdict `improved / no_clear_change / needs_attention / insufficient_data` with its reasons. Rule (provisional, `src/progress/overall.js`): ≥ 4 points; mean of the last 3 vs the earlier ones, ±1.5 %SS points; "improved" drops to "no clear change" when C3's TSS is falling or C4's band is below |

- **Child scope:** a child account may only send or read its own `childId` (path, query or body, multipart included); anything else is **403** `other_child`. Therapists may act for any child.
- **Parent mode** (**403** `parent_mode_required` without a valid `X-Parent-Token`; therapists don't need one): C2 `POST /analyses` with `inputPath=parent_upload`, C3 `POST /sessions/:id/questionnaire`, C4 checklist, known words, transcript edits and band confirmation.
- **Settings:** `JWT_SECRET` (required in production), `AUTH_REQUIRED` (`0` lets token-less requests through for research scripts and curl), `AUTH_TOKEN_DAYS` (7), `PARENT_MODE_MINUTES` (15), `THERAPIST_SIGNUP_CODE`.
- **Limit:** records fetched by their own id (`/assessments/:id`, `/sessions/:id`, `/samples/:id`, …) are not yet checked against the account's child; the ids are random ObjectIds that only the owner's app receives.

The curl examples below assume `AUTH_REQUIRED=0`, or add `-H "Authorization: Bearer $TOKEN"`.

## C1 API (`/api/c1`)

`GET /api/health` reports the whole server; the routes below belong to the C1 module.

All errors use one envelope: `{"error": {"code", "message", "details"}}`.

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | C1's view: MongoDB, speech service and queue status (503 + `degraded` when a dependency is down) |
| GET | `/tasks?age=&language=` | Age band and task: 5–10 → `picture_description` (pictures), 11–14 → `reading` (passages). Ages outside 5–14 → 422 |
| POST | `/assessments` | Multipart upload. Returns **202** `{assessmentId, status:"queued"}` and a `Location` header |
| GET | `/assessments/:id` | Status (`queued → processing → completed / failed`), result or error |
| POST | `/assessments/:id/reviews` | Append an SLP or parent reference (hand-counted %SS, severity, notes) |
| DELETE | `/assessments/:id` | Delete the record and any stored audio |
| GET | `/children/:childId/assessments?taskType=&status=&limit=&offset=` | History, newest first (no event lists) |
| GET | `/children/:childId/summary` | Latest severity per task: ordinal 0–3, %SS, trend. This is the context C3 will read |

### POST `/assessments` fields

| Field | Required | Notes |
|---|---|---|
| `audio` | yes | `.wav` (16 kHz mono preferred), `.flac`, `.ogg`, `.mp3`, `.m4a`, `.aac` (phone recordings, decoded with PyAV); ≤ 50 MB; 1–180 s |
| `childId` | yes | letters, digits, `_`, `-` |
| `age` | yes | whole number 5–14; it selects the task |
| `taskType` | no | must match the age band if sent |
| `passageId` / `passageText` | reading only, one of them | `passageId` from `/tasks`; the text gives the exact syllable count |
| `pictureId` | no | picture task; checked against the catalog |
| `transcript` | no | picture task: C4's transcript, which gives an exact syllable count instead of the audio estimate |
| `concomitantScore` | no | 0–1 from C2; adds the optional physical term |
| `language` | no | `si` (default) or `en`; for `passageId`, the passage's language is used |

```bash
curl -F audio=@reading.wav -F childId=CH-001 -F age=12 -F passageId=en-reading-school-01 \
     localhost:5001/api/c1/assessments
curl localhost:5001/api/c1/assessments/<assessmentId>
```

### Result (inside a completed assessment)

- `events[]`: `{type, start, end, duration, confidence}`, with type one of `block`, `prolongation`, `sound_repetition`, `word_repetition`, `interjection`. Use these for the timeline.
- `stutterMoments[]`: overlapping stuttering-like events merged; each moment counts as one stuttered syllable.
- `counts`, `primaryType`, `syllables {total, source: passage | transcript | estimated}`, `stutteredSyllables`, `percentSS`.
- `durationTerm.meanLongest3Sec`.
- `severity`: `{label: none_very_mild | mild | moderate | severe, score, components, taskType, version, provisional}`.
- `baselines.mimiChunkRatio`: MiMi's chunk-ratio severity on the same windows, for comparison.
- `features`: duration, pauses, speech and articulation rate.
- `summary`: the old app shape (`stutterDetected`, `stutterType`, `severity`, `confidence`), so the current result card can bind without changes.
- `warnings[]`: e.g. `short_sample`, `passage_possibly_incomplete`, `transcript_mismatch`, `detector_fallback`.

A full example: `contracts/c1/analyze-speech.response.example.json`.

## Speech service (`:8010`)

- `GET /health`: active detector, availability of each detector, and the severity table version.
- `POST /analyze-speech` (multipart): `audio`, `task_type`, `language`, `passage_text`, `transcript`, `concomitant_score`, `include_windows`. It is synchronous and can be called directly for experiments.

### Detectors

`C1_DETECTOR` selects the detector:

- `acoustic` (default): signal rules with provisional thresholds; needs no training.
- `xlsr`: a trained head on XLS-R embeddings and/or acoustic features (MFCC, pitch, energy), read from `speech-service/models/c1_head.joblib`; the head format is described in `app/detection/xlsr.py`. It needs `requirements-training.txt` (torch and transformers only when the head reads XLS-R).

Training: `speech-service/notebooks/` (SEP-28k with the speaker-separated SEP-28k-E splits, macro-F1, child clips with rater agreement, %SS against FluencyBank or SLP counts). The run guide is `speech-service/notebooks/README.md`; `tools/label_clips.py` is the clip-labelling page.

If the selected detector is unavailable, the service uses `acoustic` and reports `detector.fallback: true` in the response.

## C2 API (`/api/c2`)

C2 looks only at **stutter moments**. It needs them from C1, so a video can arrive three ways:

| Input path | How | Stutter moments come from |
|---|---|---|
| **A** `in_task_camera` | The camera records during the C1 task | The video's own audio track: C2 extracts it and creates a **linked C1 assessment** (`stutterSource: c1_audio_track`), or the app sends the `c1AssessmentId` it already has (`c1_assessment`) |
| **B** `parent_upload` | A parent uploads a pre-recorded video | Same as A |
| **C** no video | The child or parent declined the camera | Nothing is analysed. `POST /analyses/not-assessed` records it, so C2 reads **"not assessed"** (flag `missing`), never "0 behaviours" |

Researchers and SLPs can also give the spans by hand (`stutterSpans`, source `manual`), for example CASA spans.

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | C2's view: MongoDB, vision service (and its face model), speech service (needed for the audio-track source), queue |
| POST | `/analyses` | Multipart video upload. Returns **202** `{analysisId, status, stutterSource, links}` and a `Location` header |
| POST | `/analyses/not-assessed` | Path C, JSON `{childId, age, reason, notes?, c1AssessmentId?}` → **201** |
| GET | `/analyses/:id` | Status (`queued → awaiting_stutter_events → processing → completed / failed`, or `not_assessed`), result or error, `links.c1Assessment` |
| POST | `/analyses/:id/reviews` | Append an SLP or parent reference: per-moment FG/HM labels, overall yes/no, notes (the child test set) |
| DELETE | `/analyses/:id` | Delete the record and any stored video (refused while it is being analysed) |
| GET | `/children/:childId/analyses?status=&limit=&offset=` | History, newest first (no per-moment detail) |
| GET | `/children/:childId/summary` | **The context C3 reads:** `c2Flag` (`yes` / `no` / `missing`), `hasVideo`, latest `concomitantScore`, behaviours per stutter, trend |

### POST `/analyses` fields

| Field | Required | Notes |
|---|---|---|
| `video` | yes | `.mp4`, `.mov`, `.m4v`, `.webm`, `.mkv`, `.avi`; ≤ 200 MB; 2–180 s; one face, filmed from the front |
| `childId`, `age` | yes | as for C1; age 5–14 |
| `inputPath` | yes | `in_task_camera` (A) or `parent_upload` (B) |
| `videoConsent` | yes | must be `true` |
| `c1AssessmentId` | no | use this C1 assessment's stutter moments (same child); no audio is extracted |
| `stutterSpans` | no | JSON `[{start, end, types?}]` in seconds; not with `c1AssessmentId` |
| `taskType`, `language`, `passageId` / `passageText`, `pictureId`, `transcript` | audio-track source | passed to the linked C1 assessment and checked against C1's rules before the video is accepted (ages 11–14 need a passage) |
| `targetFps` | no | 5–30; default 15 |

```bash
# Path B: C2 extracts the audio, creates the linked C1 assessment, waits for it, then analyses the face
curl -F video=@session.mp4 -F childId=CH-001 -F age=8 -F inputPath=parent_upload -F videoConsent=true \
     localhost:5001/api/c2/analyses
curl localhost:5001/api/c2/analyses/<analysisId>
curl localhost:5001/api/c2/children/CH-001/summary
```

### Result (inside a completed analysis)

- `stutterMoments[]`: `{start, end, types, assessed, faceRatio, categories: {FG, HM: {present, score, scoreType}}, signals: {eye, lip, jaw, cheek, head: {deviation, direction, topFeature, threshold, pValue, exceeds}}, explanation[]}`. A moment with too little visible face is `assessed: false`, never "no behaviour".
- `explanation[]`, per moment: e.g. `"jaw +15.5 SD above this child's normal (jaw opening); rarer than 1 in 1,000 fluent stretches"`.
- `behaviourEvents[]`: `{category, signal, feature, start, end, peakDeviation, momentIndex}`. Use these for the behaviour timeline.
- `counts`, `behavioursPerStutter {FG, HM, any}`.
- `hasSecondaryBehaviors`: `true` / `false`, or `null` when no moment could be assessed. It feeds C3.
- `concomitantScore`: the share of assessed moments with a behaviour (0–1). It is the value for C1's optional physical term.
- `baselines.rules`: the old fixed-threshold rules on the same moments, for comparison.
- `baseline`: where the child's normal came from (`fluent_spans`, or `whole_recording` with a warning) and how much.
- `warnings[]`: e.g. `low_face_coverage`, `insufficient_fluent_baseline`, `no_stutter_moments`, `moment_face_missing`, `moment_outside_video`, `detector_fallback`.

A full example: `contracts/c2/analyze-video.response.example.json`.

## Vision service (`:8011`)

- `GET /health`: face-model presence, the active detector, and each detector's availability.
- `POST /analyze-video` (multipart): `video`, `stutter_moments` (JSON), `target_fps`, `include_frames` (per-frame record of all 52 blendshapes, pose and geometry, for research). It is synchronous and can be called directly for experiments.
- `POST /extract-audio` (multipart `video`): the audio track as 16 kHz mono WAV (no system ffmpeg needed).

### Detectors

`C2_DETECTOR` selects the detector:

- `srcd` (default): **label-free speaker-relative deviation**. The child's own fluent speech is the reference; no training data is needed.
- `rules`: the earlier prototype's fixed thresholds. It is always computed as `baselines.rules` too.
- `gru` / `transformer`: learned classifiers on the same baseline-normalised sequences, read from `vision-service/models/c2_srcd.pt`. They need `requirements-learned.txt` (torch, scikit-learn). Train them with:

  ```bash
  .venv/bin/python -m training.build_dataset --casa-csv casa.csv --video-dir videos/ --out data/casa.npz   # or --manifest
  .venv/bin/python -m training.train_srcd --data data/casa.npz --save-arch gru
  ```

  The five-way comparison (rules, Random Forest, GRU without self-comparison, SRCD, CASA reference) and the final model: `vision-service/notebooks/c2_srcd_comparison.ipynb`, run guide `vision-service/notebooks/README.md`.

If the selected detector is unavailable, the service uses `srcd` and reports `detector.fallback: true` in the response.

### C3 engagement camera model (training only)

The vision service also trains C3's camera engagement model on DAiSEE. DAiSEE is requested through the Google Form on its page (<https://people.iith.ac.in/vineethnb/resources/daisee/index.html>); the terms are research use only, no sharing, and citing Gupta et al. 2018. Steps:

```bash
uv pip install --python .venv/bin/python -r requirements-learned.txt     # scikit-learn (torch is not needed for this)
.venv/bin/python scripts/fetch_face_model.py                              # if models/face_landmarker.task is missing
# One row of 10-second face features per clip, via the service's MediaPipe tracker at 5 fps. Resumable (JSONL cache).
.venv/bin/python -m training.build_engagement --daisee ~/data/DAiSEE --out data/daisee_engagement.npz --workers 6
# Logistic regression vs gradient boosting, subject-grouped CV + official Test split; writes the model the API loads
.venv/bin/python -m training.train_engagement --data data/daisee_engagement.npz
```

`train_engagement` writes `api/src/modules/c3/data/engagementCameraModel.json` and a report under `training/reports/`. Restart the API to load the new model; it refuses a file whose self-check fails. Extraction runs at about 1.4 s per clip per worker on an M2 Pro (V-26).

## C3 API (`/api/c3`)

A session is a loop: start it, ask for the next activity, post the activity's result, and repeat until the advice says to stop; then complete it and (in parent mode) send the questionnaire. Real examples of every step are in `contracts/c3/`.

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Recommender settings, catalog counts per band, engagement-model version |
| GET | `/activities?age=` | The bandit's choices for the child's band (type × difficulty, SLP-approved). Ages outside 5–14 → 422 |
| GET | `/activities/items?armId=` | Content items for one choice |
| GET | `/questionnaire?language=` | The 6-item parent questionnaire (1–5 scale) |
| POST | `/sessions` | `{childId, age, cameraOn?, plannedMinutes? (25), maxActivities? (5), c2Flag? yes/no/missing, language?}` → 201 with the starting context. The C2 flag is read from the C2 module (`c2FlagSource: c2`); the sent `c2Flag` is used only when C2 has no yes / no for the child (`c2FlagSource: client`) |
| GET | `/sessions/:id` | The session, its activities and the current advice |
| POST | `/sessions/:id/next-activity` | `{excludeArmIds?, force?}` → 201 with the activity, the content item, the named context, every arm's UCB score and the logging propensity. 409 `activity_pending` while one is open; 200 with `activity: null` once the session's activities (5) are done or the planned time is used (unless `force`). A type is not repeated in a session while other types remain |
| POST | `/sessions/:id/activities/:attemptId/word-checks` | Word activities: multipart `audio` (one recording of one word) + `wordIndex` (position in `item.targetWords`) → **201** `{decision: match / mismatch / unclear, expected, heard, reasons, verification}`. Synchronous; the clip is deleted at once. Record again to replace a word's check |
| POST | `/sessions/:id/activities/:attemptId/speech-check` | Reading and picture description: multipart `audio` (the whole answer) → **201** `{mode: reading / keywords, decision: match / partial / mismatch / unclear, share, wordsRead / found, heard, verification}`. Synchronous; the clip is deleted at once |
| PUT | `/sessions/:id/activities/:attemptId/word-checks/:checkId/review` | `{decision: match / mismatch, by: parent / slp, notes?}`: a human correction that overrides the automatic decision (and calibration data) |
| POST | `/sessions/:id/activities/:attemptId/result` | The activity's logs (below) → engagement E, performance P, rewards, bandit update, advice. 409 if already recorded |
| POST | `/sessions/:id/breaks` | `{durationSec?, reason: low_engagement / requested / other}` |
| POST | `/sessions/:id/complete` | Closes the session; an open activity is marked `abandoned` (no reward). Returns the outcome with the TSS |
| POST | `/sessions/:id/questionnaire` | `{answers: {interest, willing_participation, enthusiasm, staying_involved, comfort, confidence}}` (1–5) → Q, TSS recomputed |
| GET | `/children/:childId/sessions?status=&limit=&offset=` | Session history, newest first (`status`: active / completed / abandoned) |
| GET | `/children/:childId/sessions/active` | `{session, activitiesDone, pending}`: the session that can still be continued (started within 12 h), with its open activity in the `next-activity` shape; `{session: null}` when there is none. Older unfinished sessions are closed as `abandoned` |
| GET | `/children/:childId/summary` | TSS trend, engagement over the last 3 sessions, recent score per activity type, C1 and C2 links, the bandit's counts, `streakDays` (consecutive days with a completed session), `stars` (completed activities), `activitiesSkipped`, `sessionsAbandoned` |
| GET | `/children/:childId/context?age=` | The context the bandit would use now |
| GET | `/children/:childId/bandit?matrices=1` | Per-arm counts, mean reward and θ, the shared β; with `matrices=1` the raw A, B, b, A0, b0 (for mirroring on the phone) |
| GET / POST | `/engagement/model` · `/engagement/calibrate` · `/engagement/model/activate` | Show the active engagement model (and `camera`: the camera model's version, type and training metrics); fit the logs-only weights against the questionnaire (`{minSessions?, activate?}`); activate a version (or `provisional`) |
| GET | `/reports/engagement-over-time?ageBand=&bucketMinutes=` | Mean engagement by session minute and age band |
| GET | `/reports/engagement-pilot-check?ageBand=` | The camera model on real sessions: per session, the mean camera score against the questionnaire's engaged label (balanced accuracy, macro-F1, confusion), by age band, with the fused E beside it |
| GET | `/reports/replay-log?childId=&limit=&offset=` | Every decided activity: context, chosen arm, propensity, the candidate arms (`candidateArms`, with their type scores), all reward variants |

### Activity result fields

| Field | Notes |
|---|---|
| `skipped` | `true` → P = 0; `targets`/`successes` not needed |
| `targets`, `successes` | Required unless skipped; `successes ≤ targets` |
| `completedShare` | 0–1, default 1 |
| `durationSec` | Required; it also measures session time |
| `attempts`, `responseLatencyMs`, `taps`, `earlyExit` | Feed engagement only, compared with the child's own history (never P: speaking slowly is a technique) |
| `parentHelp` | 0–3, the parent-help tap; goes into the context, never the reward |
| `parentFeedback` | `too_hard` / `just_right` / `too_easy`, the old tap; kept for the reward ablation |
| `camera` | Face numbers computed on the phone by ML Kit, never images. `windows`: up to 60 objects `{durationSec, facePresentRatio, yawStdDeg, pitchStdDeg, yawAbsMeanDeg, pitchAbsMeanDeg, lookAwayRatio, eyeOpenMean, eyesClosedRatio, smileMean}`, one per 10 s (null fields when no face). Older clients may send only the aggregate `{facePresentRatio, yawStdDeg, pitchStdDeg, eyeOpenMean, smileMean}`. Windows with a face under 30 % of the time are missing data; with none left, the logs-only mode is used |
| `engagementEstimate` | `{score, mode, modelVersion}` from an on-device model; used as is when sent |

### Word check (did the child say the word?)

Word activities (`picture_naming`, `syllable_practice` and `word_phrase_practice`) carry `item.targetWords` (`si`, `en`) in the `next-activity` response. The app records each word and posts it to `word-checks`; the language service (`POST :8012/verify-word`, the C4 CTC model) compares what was said with the expected word and with alternatives (the item's other words and its listed `confusables`, e.g. අක්කා for අම්මා):

- `match`: the right word. **A stutter is not a mismatch**: repetitions and fillers are removed first, so "අ අ අම්මා" or a prolonged onset still matches (fluency is C1's job).
- `mismatch`: a different word was said.
- `unclear`: the clip can't be judged (nothing decoded, low confidence, borderline); ask the child to say it again.

**Scoring:** when words were checked, P = matched ÷ (matched + mismatched) × `completedShare`, from the latest check of each word (a review wins); unclear words are left out, not counted as wrong. The app's `successes` is still stored for comparison, and is used when no word was checked or every word was unclear. `verification` on the result says which was used. Sinhala only (an `en` session gets 422 `language_not_supported`); activities without target words get 422 `not_a_word_activity`; without the language service the check returns 503 `word_check_unavailable` and the rest of C3 works.

### Reading and picture-description check

`passage_reading` items carry the passage in `item.text`, and `picture_description` items the words a description should mention in `item.keywords`. The app posts the whole answer to `speech-check`; the language service (`POST :8012/check-speech`) transcribes it, removes stutter repetitions and fillers (a stutter never counts against the child), and compares: the share of passage words read, or the share of keywords mentioned (by stem or close spelling). `match` ≥ 0.5, `partial` ≥ 0.25 (calibrated on adult read speech, C3 log V-33; provisional for children, `C4_SPEECH_CHECK_*`). P = that share × the item's targets; an `unclear` check is left out and the app's count is used. Breathing is scored on completion only.

### Settings (`api/.env`)

`C3_MAX_ACTIVITIES` (5; activities per session), `C3_POLICY` (`hybrid` or `discounted`), `C3_ALPHA` (0.6), `C3_CHILD_PRIOR` (5), `C3_DISCOUNT_GAMMA` (0.95), `C3_EXPLORE_EPSILON` (0; picks made at random for replay evaluation), `C3_REWARD_MODE` (`fused`, `performance`, `engagement` or `tap`, for the reward ablation), `C3_WORD_CHECK_TIMEOUT_MS` (60000; the first check may wait for the ASR model to load). Invalid values stop the API at startup. The word check also needs `LANGUAGE_SERVICE_URL` (shared with C4).

### Evaluation (offline)

The simulator, stress test and learning-signal comparison run on the production bandit code with simulated children; the results are in `C3_EVALUATION.md`.

```bash
cd api
node src/modules/c3/evaluation/run.js all          # or main | signals | stress | ope; --seeds 10 --children 80 --sessions 10
# Replay test on real sessions (run them with C3_EXPLORE_EPSILON=0.2 so some picks are random):
curl -s "localhost:5001/api/c3/reports/replay-log?limit=500" -H "Authorization: Bearer $TOKEN" > replay-log.json
node src/modules/c3/evaluation/ope.js replay-log.json   # IPS / SNIPS / doubly robust estimates for other recommenders
```

## C4 API (`/api/c4`)

Spontaneous speech: the child (with a parent for 5–10) ranks 5 favourite interest categories once, 1st to 5th. Each session picks **one topic** from them, the child answers out loud, and the recording is analysed in the background (ASR, language measures, and C1's %SS on the same recording). Same error envelope as C1.

**Topic selection** (priority order): age group (the bank per band) → ranked interests (category weights 5:4:3:2:1) → progress (C3's TSS trend, read from C3; the C4 band; the parent checklist: falling / below prefer concrete topics) → variety and stuttering rate (no topic repeats until all 25 of the child's topics were used; last session's category is blocked; a rise of ≥ 2 %SS points in C1 or C4 prefers concrete topics and weights the top-ranked categories more, 8:4:2:1:0.5). Every input is stored on the session (`progressSignal`, `selection`).

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Language service (active ASR engine, model loaded?), C1 speech service (optional for C4), topic bank counts, queue |
| GET | `/catalog` · `/catalog/categories?age=` · `/catalog/topics?age=&category=&level=` · `/catalog/checklist?age=` | Topic bank (2 bands × 20 categories × 5 topics, Sinhala + English) and the parent checklist for the child's band |
| PUT / GET | `/children/:childId/profile` | Onboarding: `{age, language, rankedCategories: [5 ids, favourite first]}`. 201 on create, 200 on update |
| POST | `/children/:childId/checklist` | Parent mode: `{respondent: parent\|slp, answers: [{itemId, answer}]}` → starting level `emerging / developing / established` |
| PUT | `/children/:childId/known-words` | Parent mode: words the child already uses; they never count as new |
| POST | `/sessions` | `{childId, c3TssTrend?, seed?}` → the topic, its prompts and the full selection breakdown. `mode: fixed` (the fixed-topic research arm) only with `C4_ALLOW_FIXED=1`, otherwise 422 `fixed_sessions_off` |
| GET | `/sessions/:id` | Session, current prompt, skip log |
| POST | `/sessions/:id/next-prompt` | The child answered: show the next follow-up |
| POST | `/sessions/:id/skips` | `{kind: follow_up\|main_prompt, reason?}`. A follow-up skip moves to the next follow-up; a main-prompt skip moves to another topic. All logged |
| POST | `/sessions/:id/recordings` | Multipart `audio` (+ optional `transcript` to skip ASR). **202** `{sampleId}`; one sample per session (a failed one may be retried) |
| GET / DELETE | `/samples/:id` | Status (`queued → processing → completed / failed`) and the full result |
| PUT | `/samples/:id/transcript` | `{text, kind: corrected\|manual, editedBy: parent\|slp}`. A new version; measures, %SS, new words and bands are recomputed |
| POST | `/samples/:id/band-confirmation` | `{by, decision: confirm\|override, band?, notes?}` |
| GET | `/children/:childId/samples` · `/sessions` · `/progress` · `/vocabulary` · `/summary` | History; the series for the comparison screens; new words; the latest band, trend and spontaneous %SS next to C1's task %SS (the context C3 and the progress report read) |
| GET | `/research/h4c` | Personalised vs fixed response length per child, with a paired Wilcoxon signed-rank test |
| GET | `/research/h4d?childId=&format=json\|csv` | One row per utterance (length, complexity, relative length, stutter) for H4d |

```bash
curl -X PUT localhost:5001/api/c4/children/CH-001/profile -H 'content-type: application/json' \
     -d '{"age":8,"rankedCategories":["animals","space-and-stars","food","games-and-toys","the-sea-and-beach"]}'
curl -X POST localhost:5001/api/c4/sessions -H 'content-type: application/json' -d '{"childId":"CH-001"}'
curl -F audio=@answer.wav localhost:5001/api/c4/sessions/<sessionId>/recordings
curl localhost:5001/api/c4/samples/<sampleId>
```

### A completed sample

- `asr`: engine and model, raw text, timed `words[]` (CTC frame timings).
- `transcripts[]`: every version (`asr`, `corrected`, `manual`), who made it and when; `measuresByVersion[]` keeps the measures of each, for the raw vs corrected vs manual comparison.
- `analysis`:
  - `tokens[]`: each with its stem, timing, maze flag and reason;
  - `utterances[]`: each with word count, complexity proxy and stutter yes / no;
  - `measures`: `mluWords`, `ndw50`, `ndwAll`, `mattr25`, `totalWords`, `utteranceCount`, `mazeRatio`;
  - `syllables`, `lexicon`;
  - `flags`: `short_sample`, `unreliable_sample` (< 50 words), `no_utterance_boundaries`.
- `stuttering`: C1's events and stutter moments on this recording; `percentSS` (as C1 computed it) and `percentSSCurrent` (after corrections); or `status: not_assessed` with the reason.
- `vocabulary`: `baseline_building` for the first 3 samples, then `newWords`, `newWordsPer100`, `pendingStems` (heard once in ASR, not yet counted) and `respelled`.
- `band`: `computed` and `effective` (`below / stable / gaining`, or `baseline_building` / `not_reliable`), the change against the baseline, and parent / SLP confirmations.

Real responses: `contracts/c4/`.

## Language service (`:8012`)

- `GET /health`: ASR engines and their state (`not_loaded / loading / loaded / unavailable`).
- `POST /transcribe` (multipart `audio`, optional `engine`): text plus timed words.
- `POST /measures` (JSON): timed `words` and/or a typed `text`, `source`, optional `c1Events` / `c1Moments`. Returns tokens, mazes, utterances, measures and lexicon. Text only, so it is fast.
- `POST /analyze-language` (multipart): audio and/or a transcript in, `{transcription, analysis}` out, for direct experiments.
- `POST /evaluate-asr` (JSON `{reference, hypothesis}`): WER, CER and repetition retention (H4a).
- `POST /verify-word` (multipart `audio`, `expected`, optional `alternatives` JSON list): C3's word check. Always uses the CTC engine (it needs frame scores); clips 0.3–10 s. Thresholds: `C4_VERIFY_*` (provisional).
- `POST /check-speech` (multipart `audio`, `mode: reading | keywords`, `reference` or `keywords` JSON list): C3's reading and picture-description check (see the C3 section). Thresholds: `C4_SPEECH_CHECK_PASS` (0.5), `C4_SPEECH_CHECK_PARTIAL` (0.25), provisional.

`C4_ASR_ENGINE` selects the engine:

- `ctc` (default): a public XLS-R-300m Sinhala CTC fine-tune (`C4_CTC_MODEL`). Replace it with the team's model by changing that variable: `notebooks/c4_01_asr_finetune.ipynb` trains one on OpenSLR SLR52 (speaker- and sentence-disjoint splits; continue this model, XLS-R-300m with a new head, or an MMS-1B adapter). Run guide: `language-service/notebooks/README.md`.
- `whisper`: a Sinhala Whisper fine-tune, the H4a baseline.
- `none`: typed transcripts only.

Models download from Hugging Face on first use; `C4_PRELOAD=1` loads at startup instead.

## Data and privacy

- **Audio deletion:** uploaded audio (in `api/uploads/c1/` and `api/uploads/c4/`) is deleted as soon as a job finishes, whether it succeeded or failed (`audio.deleted: true`). Set `C1_KEEP_UPLOADS=1` / `C4_KEEP_UPLOADS=1` to keep it. C4 transcripts are kept, because corrections and new-word history need them.
- **Video deletion:** uploaded video (in `api/uploads/c2/`) is deleted as soon as a job finishes, whether it succeeded or failed (`video.deleted: true`). Set `C2_KEEP_UPLOADS=1` to keep it. The vision service works on a temporary copy, which it removes after each request. Only numbers are stored, never frames.
- **Consent:** C2 refuses a video unless `videoConsent=true`. The current ethics approval covers audio only, so video must stay on team or pilot data until the amendment is approved.
- **Placeholder content:** the passages and pictures in `api/src/modules/c1/data/taskCatalog.json`, the C3 activity pool and questionnaire in `api/src/modules/c3/data/`, and C4's topic bank and parent checklist (`api/src/modules/c4/data/`, all marked `reviewed: false`) are placeholders. An SLP or teacher must check them (including the Sinhala wording and the difficulty labels) before use.
  - **C3 pictures:** `mobile/assets/images/component3/items/<itemId>.png` are generated placeholders; replace them with the team's pictures under the same names. `node api/src/modules/c3/scripts/checkContent.js` lists what is still a placeholder.
  - **C4 topic bank:** `node api/src/modules/c4/scripts/topicBank.js export topics.csv` writes the bank as a spreadsheet (template: `api/src/modules/c4/data/topicBank.template.csv`); fill it from the team's document and `import topics.csv` (it checks 20+ categories × 5 topics per band, 2–4 follow-ups, Sinhala and English).
- **After a restart:** an upload that a finished job still holds (the server stopped between saving the result and deleting the file) is deleted at startup, unless the module's `*_KEEP_UPLOADS=1`.
- **No video in C3:** C3 receives only numbers computed on the phone (face-present ratio, head-angle spread, eye-open and smile averages), never images.
- **Accounts:** passwords and PINs are stored as salted scrypt hashes, never in plain text. The "parent mode" routes need the parent-mode token (see Auth) and also record who acted (`respondent`, `editedBy`, `by`).
