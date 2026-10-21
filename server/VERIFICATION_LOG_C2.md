# Swara server, Component 2: verification log

*2026-10-15, macOS (Apple M2 Pro, CPU only), Node 24.19, Python 3.11, MongoDB 7 (Docker), MediaPipe 0.10.21, PyAV 14.1, torch 2.5.1.*

Everything below was run against the live services with `curl`. Responses are excerpts. **No automated tests were written.** The helper scripts (clip builder, request runners, the comparison printer) were kept outside the repo.

**Ports used.** Another work session was already using :5001 (API), :8010 (speech service) and the `swara` database on the shared MongoDB. To avoid touching its data, this run used:

- the API on **:5002**, with `MONGODB_URI=…/swara_c2dev`;
- the speech service on **:8012**;
- the vision service on its default **:8011**.

These are environment settings only, not code changes.

## Test material

No stuttering videos and no recordings of children were available. FluencyBank and CASA aren't on this machine.

**Source clips.** Three adult interview videos from Wikimedia Commons:

- two NASA "Interview Opportunity" clips (public domain; speakers "Jamie" and "Wes", 1920×1080, 29.97 fps);
- "WikipediansSpeak – Gautam John" (CC BY-SA 3.0, 1280×720, 25 fps).

Segments with a frontal talking head were cut and scaled to 640 px wide.

**Controlled clips** (`*_ctrl`). Stutter-like events were spliced into the *real* audio and video at known times:

- **block:** 1.0 s of silence over a held frame;
- **sound repetition:** the first 120 ms repeated 3×, with 80 ms gaps, video repeated in sync;
- **prolongation:** 40 ms of audio tiled to 0.8 s over a held frame.

On chosen events a movement was warped in, ramping in and out:

| Category | Movement | How |
|---|---|---|
| HM | head turn / tilt | 14° rotation plus a sideways shift |
| HM | nod | downward shift plus 10 % zoom |
| FG | jaw drop | stretch of the lower face |
| FG | lip press | vertical squeeze of the mouth |
| FG | eye squeeze | vertical squeeze of both eyes |

Each clip also has one stutter with no movement, and one head movement during fluent speech, which must not count. The frames were checked visually; the movements are visible and plausible.

| Clip | Length | Stutters with FG | Stutters with HM | Stutters with no movement |
|---|---|---|---|---|
| gautam_ctrl | 45.8 s | 3 (jaw, lip press, eye squeeze) | 2 (turn, nod) | 2 |
| jamie_ctrl | 43.8 s | 3 | 2 | 2 (one falls on a question card, no face) |
| wes_ctrl | 36.2 s | 3 | 1 | 1 |

**Other clips:**

- `*_plain`: the same segments with no edits. All speech is fluent, so every flag is a false positive.
- `silent.mp4`: no audio track.
- `noface.mp4`: a moving gradient with a tone.
- `fake.mp4`: text.
- `corrupt.mp4`: random bytes.
- `jamie.webm`: the full 224 s source.

---

### V-1 Setup and startup

- **Dependencies:** `uv pip install -r requirements-learned.txt` (MediaPipe 0.10.21 needs numpy < 2).
- **Face model:** `scripts/fetch_face_model.py` downloaded `face_landmarker.task` (3.8 MB).
- **`GET :8011/health`:**
  - `faceModel: available`, `activeDetector: srcd`;
  - `srcd` and `rules` available;
  - `gru` and `transformer` unavailable with `model_not_found: c2_srcd.pt`. The service still started.
- **First API start on :5001:** failed with `EADDRINUSE` (the other session's API). Moved to :5002, see above.
- **`GET :5002/api/health`:** `200 {"status":"ok", … "components":{"c2":{"status":"ok","visionService":{"status":"ok","faceModel":"available",…},"speechService":{"status":"ok"},"queue":{…"concurrency":1}},"c1":{"status":"ok",…}}}`.

### V-2 First run (vision service direct)

`POST /analyze-video` on `gautam_plain.mp4` with two arbitrary 1 s spans:

- `200`, `analysedFps 12.5` (every 2nd frame of 25 fps), 500 frames, `faceDetectedRatio 1.0`;
- baseline `fluent_spans`, 35.9 s;
- 5.2 s processing for 40 s of video.

The pipeline ran end to end.

### V-3 Speed

| Video | Frames analysed | Processing time |
|---|---|---|
| 36 s | 543 at 15 fps | 4.2 s |
| 46 s | 573 at 12.5 fps | 4.7–6.1 s |
| 44 s | 657 at 15 fps | 5.0 s |

That is well inside the ≤ 30 s per 60 s target. A full path-B job through the API, including C1, takes 6–23 s.

### V-4 Issue: a fixed "beyond the child's normal" rule flagged fluent speech

- **Observed:** the plain clip (no behaviours), first scoring version (robust z beyond the 1st–99th percentile of fluent frames). The span at 6–7 s gave `lip +10.0 SD (lip puckering)` and `head +3.8 SD`, so FG and HM were flagged on fluent speech.
- **Cause:** with 30 features × ~19 windows per moment, *something* almost always crosses a fixed per-frame bar; this is multiple comparisons. Natural blinks also set a very low eye bar.
- **Fix:** test each moment against the same statistic on equally long stretches of the child's own fluent speech (empirical null), with the false-positive rate controlled per category.

### V-5 Issue: ties at the clip, and blinks passing as held closures

- **Observed:** after V-4, plain-clip moments were flagged at `lip 10.0 / bar 10.0, as large in 67 % of fluent stretches`.
- **Cause 1:** scores clipped at 10 SD tie with the null's maximum, and `≥` counted the tie as present.
- **Cause 2:** a 2-frame (0.16 s) hold is shorter than a blink.
- **Fix:**
  - the decision uses the p-value, and ties count against the moment;
  - the scoring clip is raised to 50 SD;
  - the minimum hold is 0.3 s, rounded up to frames (4 frames at 12.5 fps, 5 at 15 fps).
- **After:** the plain clip had 1 flag out of 6 spans; the rules baseline had 6.

### V-6 Issue: one sparse feature set the bar for the whole signal

- **Observed:** gautam_ctrl, the lip press during a block at 22.4–23.4 s was missed (`lip 11.1 / bar 16.9`).
- **Cause:** the lip signal's null was the maximum over all lip features, so the heavy-tailed lip-puckering feature (often 10+ SD in normal speech) raised the bar for lip pressing too.
- **Fix:** each feature has its own null.
- **After:** the lip press was found (`lip +5.9 SD (lower lip roll)`).

### V-7 Issue: too few independent fluent stretches

- **Observed:** after V-6, the plain clip had 2 of 6 spans flagged, all reading "larger than any fluent stretch".
- **Cause:** about 30 s of fluent speech holds only ~20 *independent* 1 s stretches (the overlapping ones repeat each other). A new fluent span exceeds that empirical maximum on some feature quite often, and rank p-values can't tell "slightly above" from "far above".
- **Fix:**
  - model each feature's null tail as exponential above its 80th percentile, which gives a smooth p-value;
  - Bonferroni over the category's features (FG 23, HM 7).

### V-8 Issue: an overconfident p-value on a short clip

- **Observed:** `silent.mp4` (17 s), one arbitrary fluent span: `eye +4.5 SD (sideways gaze), p = 0.0002`, flagged. The speaker was glancing at the interviewer.
- **Cause:** with ~15 s of fluent speech the fitted tail is too thin.
- **Fix:** shrink the tail scale towards a prior (5 pseudo-excesses), weighted by the number of independent stretches.

### V-9 Issue: sparse features got a collapsed spread

- **Observed:** a false-positive scan on the three plain clips (3 requests × 5 one-second spans each; 44 spans assessed, every flag false):

  | | False FG | False HM |
  |---|---|---|
  | SRCD | 6 (14 %) | 3 (7 %) |
  | Rules | 38 (86 %) | 23 (52 %) |

  The SRCD flags were mostly `lip +17.1 SD (lip puckering)` and `lip +12.4 SD (lip funnelling)`.
- **Cause:** for features that are near 0 most of the time, MAD collapses to the floor (0.03), so an ordinary pucker reads as 17 "SD".
- **Fix:** spread = max(MAD × 1.4826, (p90 − p10) / 2.563, floor). Both terms equal σ for Gaussian data.
- **After:** the pucker on the same span read +13.1 SD; the false-positive rate was unchanged at prior 1.0 (V-10).

### V-10 Calibrating the tail prior on fluent speech

The vision service was restarted with each `C2_TAIL_PRIOR_SD` value, and two sets of runs were made:

- the same 44 fluent spans;
- the three controlled clips with their true stutter spans (`manual` source).

| Prior (SD per e-fold) | False FG (44 fluent spans) | False HM | Inserted behaviours found (right category, 14) | Extra categories on behaviour moments | Movement-free stutters flagged (4) |
|---|---|---|---|---|---|
| 1.0 | 14 % | 5 % | 10 | 6 | 0 |
| **1.5 (chosen)** | **5 %** | **0 %** | **7** | **4** | **0** |
| 2.0 | 2 % | 0 % | 6 | 1 | 0 |
| Rules baseline | 86 % | 52 % | 12 | 7 | 4 |

- **Decision:** 1.5, the value at which the observed false-positive rate matches the stated α = 0.05. The criterion uses fluent speech only.
- **What it costs:** about half of the inserted movements are missed. The missed ones are mostly head movements by speakers whose fluent head movement is large (for example Gautam turns his head often), and the subtler warps (lip press at 4.0 SD, eye squeeze during a prolongation).
- **The extra categories:** they are almost all HM flags on FG insertions (jaw drop → "vertical head shift", eye squeeze → "head turn"). The 2D warps move landmarks in a way MediaPipe partly reads as 3D head pose; this is probably an artefact of the test material.

Per-moment result at 1.5 (gautam_ctrl, true spans), which is also `contracts/c2/analyze-video.response.example.json`:

```
#0  6.00- 7.00 block         truth=HM  srcd=-     rules=FG,HM  head 6.1 / bar 6.9
#1 11.48-12.08 sound_rep     truth=-   srcd=-     rules=FG
#2 16.60-17.40 prolongation  truth=FG  srcd=FG    rules=FG,HM  jaw +15.5 SD (jaw opening); rarer than 1 in 1,000 fluent stretches
#3 22.40-23.40 block         truth=FG  srcd=FG    rules=FG,HM  lip +5.9 SD (lower lip roll); rarer than 1 in 1,000 fluent stretches
#4 28.40-29.00 sound_rep     truth=FG  srcd=HM    rules=HM     head -7.2 SD (head turn); about 1 in 227 fluent stretches move this much
#5 34.00-35.00 block         truth=-   srcd=-     rules=FG
#6 39.00-39.80 prolongation  truth=HM  srcd=FG,HM rules=FG,HM  head -12.4 SD (vertical head shift); eye +10.1 SD (inner brow raise)
hasSecondaryBehaviors true, concomitantScore 0.571; rules flag all 7 moments
```

### V-11 Vision service: edge cases

| Request | Result |
|---|---|
| `/extract-audio` on gautam_ctrl.mp4 | `200 audio/wav`, `x-audio-duration-sec: 45.803`; the WAV is 16000 Hz, 1 channel, 45.8 s |
| `/extract-audio` on silent.mp4 | `422 no_audio_track` "The video has no audio track, so C1 cannot find stutter moments in it." |
| fake.mp4 (text) / corrupt.mp4 (random bytes) | `422 unreadable_video` (InvalidDataError) |
| jamie.webm, 224 s | `422 video_too_long` "Video is 224.3 s; the limit is 180 s." |
| A file named `.txt` | `422 unsupported_video_type` |
| `stutter_moments` not valid JSON / end before start | `422 invalid_stutter_moments` |
| `target_fps=60` | `422 validation_error` (≤ 30) |
| No moments | `200`, `hasSecondaryBehaviors false`, `concomitantScore 0`, warning `no_stutter_moments` |
| One moment at 40 s in a 17 s video, plus one inside | `200`, 1 moment examined, warning `moment_outside_video` |
| `target_fps=10`, `include_frames=true` | 8.33 fps analysed (every 3rd frame of 25 fps), 142 frames, 52 blendshapes per frame, pose `yaw, pitch, roll, x, y, z`, geometry `ear, lipOpening, mouthWidth, jawOpening, faceWidthRatio` |
| jamie_ctrl, a moment on a question card (no face) | moment `assessed: false`, `faceRatio 0.0`, warning `moment_face_missing`; not counted as "no behaviour" |

- **Issue (test material):** the first "no-face" clip, cut from Jamie's question-card section, still had a face in 85 % of frames. It was replaced by a generated face-free video, which gave `no_face_detected` (V-15, F5).
- **Issue (code):** the response still carried `baseline.envelope: "p1-p99 …"` from the first version. It was replaced by `holdFrames`.

### V-12 API: validation (synchronous, `POST /api/c2/analyses` unless noted)

| Request | Result |
|---|---|
| No video | `422 video_required` |
| `videoConsent` missing / `false` | `422` "videoConsent is required" / "videoConsent must be true: video is analysed only with parental consent" |
| age missing / 7.5 / 4 / 15 | `422` "age is required" / "age must be a whole number" / `age_out_of_range` "Swara supports ages 5-14; got 4." / same for 15 |
| `inputPath` missing / `audio_only` | `422`; `audio_only` is reserved for path C |
| `childId` with a space | `422` "childId may contain letters, digits, "_" and "-" only" |
| A `.txt` upload | `422 unsupported_video_type` |
| `c1AssessmentId` + `stutterSpans` together | `422` "Send c1AssessmentId or stutterSpans, not both" |
| `stutterSpans` not JSON / end before start | `422` with the field named (`stutterSpans.0`) |
| `stutterSource=manual` without spans | `422` "stutterSource manual needs stutterSpans" |
| `c1AssessmentId` not hex / unknown | `422` validation / `c1_assessment_not_found` |
| `c1AssessmentId` belonging to another child | `422 c1_assessment_child_mismatch` |
| Age 12 with no passage | `422 passage_required` (C1's rule, checked before the video is accepted) |
| Age 12 with `passageId=nope` | `422 unknown_passage` |
| Age 8 with `taskType=reading` | `422 task_age_mismatch` |
| `targetFps=60` | `422` |
| not-assessed: bad reason / age 15 / unknown field / malformed JSON | `422` enum / `422 age_out_of_range` / `422` "Unrecognized key(s)" / `400 invalid_json` |
| `GET /analyses/xyz`, `/analyses/000…0`, `/nothing` | `422` / `404 analysis_not_found` / `404 route_not_found` |

After all 29 rejected requests, `api/uploads/c2/` was empty: rejected uploads are removed.

### V-13 API: path B end to end (audio-track source)

`POST /api/c2/analyses` with gautam_ctrl.mp4, `childId=CH-201 age=8 inputPath=parent_upload videoConsent=true language=en`, no spans:

```
202 {"analysisId":"6ad06547…2ec4","status":"queued","stutterSource":"c1_audio_track","ageBand":"5-10",…}
11:01:51 queued
11:01:52 awaiting_stutter_events   c1AssessmentId 6ad06547…2ec8
11:02:10 processing
11:02:14 completed
```

**C1 side.** `GET /api/c1/assessments/6ad06547…2ec8`:

- `completed`, `picture_description`, audio `video-audio-track.wav` (1.47 MB), deleted after scoring;
- events: block 6.02–6.99, sound_repetition 11.29–12.28, block 22.42–23.39, sound_repetition 28.55–29.14, block 34.02–34.99;
- %SS 3.21, "mild".

**C2 side:**

- the 5 C1 moments were analysed;
- `video.deleted: true`;
- `links.c1Assessment` is set.

**Findings:**

- C1 found all 3 blocks and both sound repetitions at the inserted times, but **neither prolongation**. The two missed moments carried the jaw drop and the nod, so they were not examined, and their movement entered the "fluent" baseline.
- That raised the eye bar for the eye-squeeze moment to 11.3 SD (observed 7.0), so it was missed. C1's recall directly limits C2; this is recorded as a limitation.

### V-14 API: final path B with the reading task

`wes_ctrl.mp4`, `childId=CH-501 age=12 passageText=… language=en`:

- the job completed in 6 s;
- C1 moments: block 9.83, word_repetition 15.90, block 21.41;
- FG at 9.83 (`lip +25.6 SD (lip puckering)`, `jaw +7.0 SD`), HM at 21.41 (`head +8.7 SD (head tilt)`), nothing at the movement-free repetition. The rules baseline flagged the movement-free one and missed the head tilt.
- `GET /children/CH-501/summary` → `c2Flag "yes"`, `hasVideo true`, `concomitantScore 0.667`, `behavioursPerStutter {FG 0.333, HM 0.333, any 0.667}`.

### V-15 API: other stutter sources and path C

| Run | Request | Status changes | Result |
|---|---|---|---|
| F1 | gautam_ctrl, `c1AssessmentId` from V-13 (same child) | processing → completed | 5 moments taken from C1, no audio extracted; `links.c1Assessment` set |
| F2 | wes_ctrl, `stutterSpans` = the true spans, age 12 | processing → completed | `hasSecondaryBehaviors true`, `concomitantScore 0.6` |
| F3 | silent.mp4, audio-track source | → failed | `no_audio_track`, video deleted |
| F4 | silent.mp4, 2 manual spans | → completed | `hasSecondaryBehaviors false`, `concomitantScore 0` |
| F5 | noface.mp4, manual span | → failed | `no_face_detected` |
| F6 | gautam_plain.mp4 (fluent), audio-track source | queued → processing → completed | C1 found **no** stutters, so `hasSecondaryBehaviors false`, warning `no_stutter_moments` |
| F7 | `POST /analyses/not-assessed` `{CH-203, 9, camera_declined, notes}` | — | `201`, `status not_assessed`, `inputPath audio_only` |
| F8 | not-assessed linked to CH-201's C1 assessment | — | `201`, `links.c1Assessment` set |

### V-16 API: summary, history, reviews, delete

**Summaries (the C3 context):**

| Child | c2Flag | Why |
|---|---|---|
| CH-202 | `yes` | Behaviours found |
| CH-204 | `no` | Video assessed, no behaviours |
| CH-205 | `no` | No stutters in a good video |
| CH-203 | `missing` | Path C |
| CH-999 | `missing` | No records |
| CH-201 | `missing` | Latest session was path C (camera unavailable), even though earlier analyses had video; `latestWithVideo` still shows the last video result |

**History.** `GET /children/CH-204/analyses`:

- 3 items, newest first, without per-moment detail;
- `?status=failed` → 2;
- `?limit=1&offset=1` → 1 of 3;
- `?limit=500` → `422`.

**Reviews:**

- an SLP review with labels for moments 0 and 3, then a parent review with `hasSecondaryBehaviors: true` → both `201`, and **both kept**;
- `momentIndex 9` → `422 unknown_moment` "out of range (this analysis has 5 moments)";
- an empty review → `422`;
- a review on a `not_assessed` record → `422 analysis_not_completed`.

**Delete.** `DELETE` on the failed F5 record → `200 {"deleted":true}`; then `GET` → `404`.

- **Issue:** path C records were returned with `video: {deleted: false}` and `stutterSource.spans: []`, which suggested a video.
- **Fix:** path C has no video block, and spans are omitted when absent. A fresh record (`CH-404`, `no_video_consent`) now carries neither.

### V-17 Robustness

- **Vision service stopped:**
  - `GET /api/c2/health` → `503 degraded`, `visionService: unreachable (ECONNREFUSED)`;
  - a job logged `retry 1/2 in 2000 ms`, `retry 2/2 in 4000 ms`, then `failed vision_service_unavailable`, video deleted.
- **Speech service stopped** (C1 fails underneath C2):
  - `queued → awaiting_stutter_events → failed` in 9 s, `stutter_events_unavailable`;
  - message: "C1 could not analyse the audio (speech_service_unavailable): …";
  - `details.c1Error` and `details.c1AssessmentId` are filled in.
- **API killed mid-job:**
  - jamie_ctrl, audio-track source, killed while `awaiting_stutter_events`; the video was still in `uploads/c2/`;
  - on restart: `[api] c2: recovered unfinished jobs: { requeued: 1, failed: 0 }`;
  - the job resumed with the C1 id it had saved (no second C1 assessment) → `completed`, `attempts: 2`, video deleted.
- **Upload limit** (restarted with `MAX_VIDEO_UPLOAD_MB=1`):
  - a 2.6 MB video → `413 file_too_large` "Video exceeds 1 MB.";
  - no partial file left.
  - C1 has no `req.uploadLimit`, so it keeps its "Audio exceeds 50 MB" wording; that path was not re-run.
- **Not tested: MongoDB stopped during requests.** The container was shared with another session. The shared error handler's 503 path is unchanged from C1 (C1 log V-17).

### V-18 Learned detectors (GRU / transformer)

**Dataset.** `training.build_dataset --manifest smoke_manifest.json`, built from the 3 controlled clips (labels from the inserted movements) plus 5 fluent spans per plain clip:

- 33 moments, 3 participants, FG+ 9, HM+ 5;
- the moment on the question card was skipped (not assessed).

**Training** (smoke run, `--folds 3`):

```
gru          params  11858 | F1 FG 0.48±0.14 HM 0.38±0.33 macro 0.43±0.16 (3 folds)
transformer  params  19266 | F1 FG 0.30±0.22 HM 0.61±0.08 macro 0.46±0.15 (3 folds)
saved models/c2_srcd.pt (gru)
```

**These numbers are not a result:** 33 synthetic moments from 3 adults.

**Serving** (`C2_DETECTOR=gru`):

- health → `gru available, version srcd-gru-2026-10-15`;
- `transformer unavailable: model_arch_mismatch: file is 'gru', detector is 'transformer'`;
- responses carry `scoreType: probability` (for example `HM 0.995`).

**Issues and fixes:**

- A GRU flag could come with no explanation and no event, because the GRU decided FG while no single SRCD signal crossed its bar. Now the strongest signal of that category is explained ("…; flagged by the gru model") and an event is added.
- An explanation listed an HM signal although the GRU had decided HM was absent. Now only categories the detector decided are explained.
- A weak signal read "about 1 in 1 fluent stretches move this much". Now p ≥ 0.2 reads "within this child's usual fluent range".
- `build_dataset` printed numpy's "All-NaN slice" warning when the face was gone for a whole smoothing window. It is now silenced where it is expected.

**Fallback.** `C2_DETECTOR=gru C2_LEARNED_MODEL_FILE=missing.pt`:

- health → `model_not_found: missing.pt`;
- response `detector {name: srcd, requested: gru, fallback: true, fallbackReason: "model_not_found: missing.pt"}`, warning `detector_fallback`.

The smoke checkpoint was then deleted, so that nobody mistakes it for a trained model.

### V-19 Final state

- **Services:** the vision service on the default `srcd` detector (prior 1.5).
- **Health:** `/api/health` → `ok`, with `c1: ok` and `c2: ok`.
- **Uploads:** `api/uploads/c1/` and `api/uploads/c2/` were empty after all runs.
- **C1 regression:** after the shared changes, a direct C1 upload (`POST /api/c1/assessments`, the WAV extracted in V-11, age 8) still completed: `picture_description`, %SS 3.21, "mild". That is the same result as the C1 assessment C2 created from the same audio in V-13.
- **Contract:** `contracts/c2/analyze-video.response.example.json` was saved from a real request (gautam_ctrl, true spans, default detector).

### V-20 Five-way comparison notebook and path A from the app (2026-10-20)
- **Smoke set:** 4 "participants" cut from "WikipediansSpeak – Gautam John" (CC BY-SA 3.0), 40 s each, with 12 moments per video and **random** FG/HM labels. It checks the code path only.
- **Builder:**
  - `training/build_dataset.py --manifest` gave 48 moments with `X` (32×31), `X_raw` (32×31), `W` (121 window statistics), `rules_pred` and `srcd_pred` for each.
  - `W` had no NaN, because the face was visible throughout.
- **Notebook:**
  - `notebooks/c2_srcd_comparison.ipynb` ran end to end with 4 participant-grouped folds (no participant in both train and test, asserted).
  - It produced the table (rules, label-free SRCD, RF, GRU without self-comparison, SRCD + GRU, CASA reference) and the report.
  - It saved `c2_srcd.pt` through `train_srcd.save_checkpoint`; `LearnedSRCD("gru", path).available()` returned `(True, None)`.
  - On random labels the F1 values mean nothing.
- **Path A through the API, with the app's fields:**
  - A 30 s C1 assessment, then the face video with `inputPath=in_task_camera` and `c1AssessmentId`.
  - It was accepted with `stutterSource: c1_assessment`, waited for C1, took its 5 stutter spans, completed, and deleted the video.
- **Path A from the app (Android emulator):**
  - The C1 task shows **Film the face during this task** (parent PIN). With it on, starting the task asked for camera and microphone permission and showed a small face preview.
  - Stopping uploaded the WAV to C1 (202), then the video to C2 (202, `in_task_camera`, the new C1 assessment id). The video was deleted after the job.
  - The analysis ended `no_face_detected`, because the emulator's camera shows a synthetic scene. A real face needs a phone.

### V-21 Majority baseline, full metrics, tuned thresholds and "not assessed" classes (2026-10-20)
- **Notebook** on the V-20 smoke set (48 moments, 4 participants, random labels; 4 grouped folds, 5 epochs): ran end to end. For every approach the report has FG / HM accuracy, majority-class accuracy, precision, recall, F1 and PR-AUC (n/a for rules and label-free SRCD), plus the macro F1, and a table of which classes each trained model may decide. On random labels no trained class passed the bar (precision ≥ 0.5 and accuracy above the majority class), except FG for the Random Forest.
- **Thresholds:** tuned per fold on a held-out participant of the training fold; the saved checkpoint has the median (0.05 / 0.05 on this smoke set) and `assessed: {FG: false, HM: false}`.
- **Service:**
  - with that checkpoint and `C2_DETECTOR=gru`, a smoke video was analysed with `fallback: false`, both classes decided by label-free SRCD (`scoreType: deviation_sd`) and the warning `model_class_not_assessed` ("… for FG, HM; label-free SRCD decided them");
  - with a copy marked `{FG: true, HM: false}`, FG came from the model (`probability`) and HM from SRCD, with the warning naming HM only.
- **CLI:** `training.train_srcd --archs gru,transformer` printed the same per-class metrics with the majority accuracy and the tuned threshold for each architecture, and saved the checkpoint with its `assessed` classes.
