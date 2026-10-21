# Swara server, Component 1: implementation notes

*2026-10-14. Paths are relative to `Swara-RP/server/`; the C1 API code is in `api/src/modules/c1/`. Records the design decisions, the deviations from the C1 plan, the changes made during verification, and the known limits.*

## 1. What the C1 plan asked for, and where it lives

| Requirement | Implementation |
|---|---|
| Task by age: 5–10 picture description, 11–14 reading | `modules/c1/services/taskService.js` and `taskCatalog.json`; `GET /tasks`; `task_age_mismatch` check on upload |
| Encode once, 3 s windows with 1.5 s hop, multi-label head (5 labels) | `speech-service/app/detection/windows.py`, `base.py` (shared by all detectors) |
| Merge positive windows into events (start, end, type) | `detection/events.py` (`build_events`, `stutter_moments`) |
| %SS = stuttered ÷ total syllables × 100 | `severity/scoring.py` |
| Duration term = mean of the 3 longest events | `severity/scoring.py` (`duration_term`) |
| Syllables exact from the passage (reading); from C4's transcript or an energy-peak estimate (picture) | `severity/syllables.py`; `pipeline._syllables` |
| Age enters through the task (readers and non-readers scored separately) | `severity/config.py` (`FREQUENCY_BANDS` per task) |
| Pauses as features only, not in the formula | `audio/features.py` (`speech_features`); not used by `scoring.py` |
| Optional physical term from C2 | `concomitant_score` → `PHYSICAL_MAX_POINTS` |
| %SS below the lowest cut-off reported as "no / very mild stuttering detected" | `scoring.score` (`belowFrequencyFloor`) |
| MiMi chunk-ratio severity as the baseline | `severity/baselines.py`, using MiMi's published cut-offs (10 / 40 / 75 %) |
| Calibration against hand-counted %SS and SLP ratings | `POST /assessments/:id/reviews` stores the reference values next to each result |
| Async job + polling (the C2 pattern), save to SpeechAssessment, add Interjection, `events[]` and the severity method | `api/` job queue and the `SpeechAssessment` model (collection `c1_speech_assessments`) |
| Sync `def` endpoint in the speech service | `app/api/routes.py` |
| Lazy model loading behind env flags | `detection/registry.py`, `detection/xlsr.py` |
| Severity named an "SSI-4-inspired audio-based estimate"; SSI-4 tables not copied | `severity/config.py`: original, versioned tables (`c1-severity-0.1-provisional`) |

## 2. Deviations, and why

| # | Deviation | Why |
|---|---|---|
| D1 | New self-contained folder `server/` instead of rebuilding `backend/routes/speech.js` | The legacy `backend/api.js` payload and appended `backend/src/routes/auth.js` payload were removed. `backend/src/security/integrityGuard.js` now blocks backend startup if either pattern returns, and CI checks the guard on pushes and pull requests. |
| D2 | API on **5001**, speech service on **8010** | On macOS, 5000 is taken by AirPlay (ControlCenter); 8000 is the existing ai-service. Both ports are configurable |
| D3 | **No authentication** | The user decided this for this stage. `childId` is a free string ID, so a later auth layer (child login + parent mode) can wrap the routes without changing the data model |
| D4 | Default detector is an **acoustic rule-based detector** until the trained head exists | The training pipeline is now in `speech-service/notebooks/` (SEP-28k with the SEP-28k-E speaker splits). It exports `models/c1_head.joblib`, which `C1_DETECTOR=xlsr` loads (verified on a smoke set, log V-21). Until it is trained on SEP-28k, the rule-based detector stays the default and the comparison row |
| D11 | The trained head can read XLS-R embeddings, acoustic features, or both; per-label thresholds are tuned on dev | The plan names wav2vec 2.0 plus MFCC / pitch / energy. `app/audio/prosody.py` computes the acoustic part for both training and the detector, so the same numbers are used in both places. Notebook 3 picks the layer and the inputs on dev, and reports test once. Thresholds are stored with the head, and the detector re-centres each label's probability, so events are built the same way for every detector |
| D12 | SEP-28k is decoded with PyAV, not wget and ffmpeg | No system ffmpeg is needed; downloads resume and dead links are logged. FluencyBank episodes need a TalkBank login, so they are skipped |
| D5 | **Interjections are reported but excluded from %SS** | As in SSI-4 practice, interjections ("um") are typical of fluent speech too, not stuttering-like disfluencies. They still appear in `events` and `counts` |
| D6 | **Overlapping events count once** ("stutter moments") | %SS counts stuttered syllables. A block and a repetition on the same word are one stuttered syllable, not two |
| D7 | Reviews are an **append-only list** (`POST /:id/reviews`) instead of one `PATCH /:id/review` | Found during verification (log V-14): a parent note overwrote an SLP's hand-counted %SS, which is the calibration data. Appending keeps every entry |
| D8 | MiMi's chunks are our 3 s windows, not its word chunks | It keeps the comparison about the severity *method* only; MiMi's word segmentation isn't available. Note that on very short clips (1–2 windows) the chunk ratio jumps to 100%; the event-based %SS doesn't, which is part of what H1b tests |
| D9 | Task catalog content is placeholder | One Sinhala and one English passage, and two picture prompts, so the flow can run. They must be replaced with SLP-checked material |
| D10 | The folder is `server/` for all components, not a C1-only backend | Later components are added as modules of the same API (`api/src/modules/<name>/`) and as sibling ML services. C1 owns only its module, its collection (`c1_speech_assessments`), its upload folder (`uploads/c1/`) and `speech-service/`. The database is named `swara`, and server-wide health moved to `GET /api/health` (log V-20) |

## 3. Design decisions

- **Split by concern:** shared plumbing (config, MongoDB, error envelope, validation middleware, `ApiError`, the generic job queue) lives at the top of `api/src/`, and each component lives in `api/src/modules/<name>/`. `app.js` mounts every module at `/api/<name>`; `server.js` calls each module's `recover()` at startup; `/api/health` collects each module's `health()`.
- **Two processes split by language:** Node owns HTTP, validation, persistence and job orchestration; Python owns the signal processing and scoring. This matches the planned split, so the vision service (C2) and C4's `/analyze-language` can later sit beside the speech service, each called by its own API module.
- **One contract:** the speech service's response is a pydantic model (`app/schemas.py`). The API checks every response against a zod mirror before saving it (`validation/schemas.js`, `speechResult`), and `contracts/` holds a real example. Extra fields are allowed, so the service can grow without breaking the API.
- **Job state lives in MongoDB, not memory:** the queue is an in-process FIFO with a concurrency cap (`C1_JOB_CONCURRENCY`), but each job's status is in the database.
  - A job is claimed atomically (`findOneAndUpdate` on `status: queued`), so it can't run twice.
  - On startup, `recover()` re-queues unfinished jobs whose audio still exists and fails the rest with `audio_missing_after_restart`. It also deletes audio still held by a finished job (the server stopped between saving the result and deleting the file); C2 and C4 do the same. This fixes the C2 "lost jobs" weakness.
- **Retries:** transient speech-service failures (`unavailable`, `timeout`, `busy`) are retried up to 3 times with 2 s / 4 s back-off. Permanent ones (bad audio, contract errors) fail at once with the service's own error code.
- **Privacy:**
  - Audio is deleted after every job, successful or not. Requests rejected after upload remove their file in the error handler.
  - `storedPath` is never returned.
  - `DELETE` removes the record and the file.
- **Severity is versioned:** every result stores `severity.version` and `detector.version`, so results stay traceable to the tables and detector that produced them after recalibration.
- **Front-end readiness:**
  - The `summary` block reproduces the old mock's shape (`stutterDetected`, `stutterType`, `severity`, `confidence`), so the existing result card can bind with minimal change.
  - `events[]` drives the planned `fl_chart` timeline.
  - `GET /children/:id/summary` gives C3 its context: a severity ordinal 0–3 and a trend.
- **Concurrency inside the speech service:** the endpoint is a plain `def` (run in the thread pool, so the event loop never blocks), with a semaphore capping analyses at 2.

## 4. The acoustic detector (provisional)

All thresholds are in `speech-service/app/detection/acoustic.py` (`AcousticThresholds`) and were set on spliced TTS clips (see the verification log). They are **not** tuned on children's speech.

| Type | Cue | Main threshold |
|---|---|---|
| Sound / word repetition | Adjacent syllable-sized units are near-identical (DTW over MFCCs); a single short unit is a sound repetition, a longer or multi-syllable unit a word repetition | similarity ≥ 0.80; **≥ 0.92 for a single repeat with no break** (V-6) |
| Prolongation | A run of active frames whose spectrum barely changes | ≥ 0.45 s; repetitions mostly inside a prolongation are dropped (V-5) |
| Block | A silent gap where the speech before it stops abruptly instead of decaying | 0.25–3 s gap; offset drop ≥ −3 dB counts as fully abrupt |
| Interjection | A short, isolated unit bounded by pauses with almost no energy above 2.5 kHz | 0.15–0.9 s; 95th-percentile HF ratio < 0.1 |

Syllable nuclei are intensity peaks (de Jong & Wempe style), used for the picture-task estimate and for repetition units.

## 5. Changes made because of verification

Full details are in `VERIFICATION_LOG.md`.

| Log | Problem seen | Change |
|---|---|---|
| V-3 | The activity threshold split a continuous sentence into fragments | The threshold is now noise floor + 25 % of range, clamped to 20–40 dB below the peak |
| V-4 | A word repetition was found as a 2-syllable unit starting one word early | Repetition search runs one pass per unit size, smallest first |
| V-5 | A held vowel's energy ripple was read as a sound repetition | Prolongations are found first, and repetitions mostly inside one are dropped |
| V-6 | Fluent passage: 2–3 false repetitions (look-alike adjacent syllables) | Similarity 0.75 → 0.80, plus 0.92 for a single repeat with no break; minimum prolongation 0.40 → 0.45 s |
| V-10 | Fluent result (`primaryType: null`) failed the API's contract check, so the job was marked failed | The service no longer drops null fields (`exclude_unset` instead of `exclude_none`) |
| V-11 | A transcript covering only part of the recording silently inflated %SS (36 % instead of 13.6 %) | New `transcript_mismatch` warning when transcript and audio syllables disagree by more than 0.6–1.6× |
| V-12 | Age `7.5` and a missing age both said "must be a number" | Separate messages: "is required", "must be a number", "must be a whole number" |
| V-14 | A parent note overwrote the SLP reference %SS | Reviews became an append-only list (D7) |
| V-16 | A short speech-service outage failed jobs permanently | Bounded retries with back-off for transient errors |
| V-17 | MongoDB down gave a generic 500 | Mapped to `503 database_unavailable` |
| V-20 | Folder renamed and C1 moved into a module | Re-ran the health checks, the full lifecycle, the validation errors and crash recovery; behaviour unchanged |
| V-13 | Two assessments created in the same millisecond had an unstable order | History and summary sort by `createdAt` then `_id` |

## 6. Known limitations

- **No real stuttered speech was available.** The detector was checked on English TTS with stutter-like events spliced in at known times. These are cleaner than real stuttering: spliced repeats are almost identical, and real ones are not. Expect lower recall on real children until the thresholds are re-tuned or the XLS-R head replaces them.
- **Noise:** at 20 dB SNR the results were unchanged; at **10 dB SNR only 2 of 5 events** were found (blocks and prolongations were lost).
- **Expressive TTS samples:** 9 of 27 produced events, mostly at the start of "apologetic" clips. No transcripts exist for them, so it is unknown whether these are real "Oh…"/"Hmm" elongations or false positives.
- **Interjection cue:** "no high-frequency energy" also matches short isolated vowel-only words.
- **Not exercised:** MP3 decoding (no encoder on the test machine; WAV, FLAC, OGG and 44.1 kHz stereo WAV were verified) and the XLS-R head (D4).
- **Severity tables and cut-offs are provisional and original.** They need calibration against `reviews` data (hand-counted %SS, SLP ratings) before any clinical reading.
- **Reading syllables:** %SS uses the passage's syllable count even if the child stopped early. The `passage_possibly_incomplete` warning flags this (heard < 60 % of the passage) but doesn't correct it.
- **Short samples:** clinical %SS uses 200+ syllables. Samples under 100 syllables get a `short_sample` warning.
- **Single-instance queue:** jobs survive restarts, but two API instances would each run their own queue. The atomic claim prevents double processing, but there's no work-sharing between instances.

## 7. Next steps (outside this task)

1. Run `speech-service/notebooks/` (run guide: `notebooks/README.md`): SEP-28k download, features, training. Then switch `C1_DETECTOR=xlsr` if the trained head beats the rule-based detector on test. Keep `acoustic` as the B0 row.
2. Children:
   - label about 300 UCLASS clips with two raters (`tools/label_clips.py`);
   - run notebook 4 for κ and the child scores;
   - do the same for the Sinhala pilot once it is recorded.
3. Severity: compare C1's %SS with FluencyBank Voices-CWS (`training/chat_ss.py`) or SLP hand counts (notebook 4, part B), then calibrate `severity/config.py` and bump `SEVERITY_VERSION`.
4. Done since: the Flutter flow, and login with parent mode.

## Changes after the team's feedback (2026-10-20)

| # | Decision | Reason |
|---|---|---|
| D13 | The app can analyse a recording chosen from the phone ("Or choose a recording from this device") as well as a live one | Parents asked to analyse recordings made earlier. The API already took files; it now also takes `.m4a` / `.aac`, which most phone voice recorders save. libsndfile can't read them, so the speech service decodes them with PyAV (now in `requirements.txt`). The recording is scored as the child's age-band task, and the app never deletes a file the parent picked |
| D14 | The stutter type shown is chosen by group (Block / Prolongation / Repetition = sound + word), and ties say "Mixed" | `primaryType` used to be the single largest label in label order, so 2 blocks beat 2 sound repetitions plus 1 word repetition, and every tie went to "Block". The pipeline now picks the largest group (ties broken by total duration), `primaryType` is the larger label inside it, and the API's child list and the app show `summary.stutterType` |
| D15 | A block needs the speech to stop while still loud: the last 30 ms before the gap must stand at least 10 dB, and half the speech-to-floor range, above the gap's floor (`block_min_cliff_*`; detector 0.1.1) | With background noise, the soft tail of an ordinary pause sits flat on the noise floor, so the old "abrupt offset" test called most pauses blocks (V-22: 30 false blocks in 10.9 min of fluent speech at 20 dB SNR). Recall on spliced blocks did not change. Real child recordings are still needed to tune it |
