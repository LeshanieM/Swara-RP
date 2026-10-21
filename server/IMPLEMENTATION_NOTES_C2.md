# Swara server, Component 2: implementation notes

*2026-10-15. Paths are relative to `Swara-RP/server/`; the C2 API code is in `api/src/modules/c2/` and the ML service in `vision-service/`. This file records what C2 had to do, where each part lives, the deviations from the plan, the changes made because of verification, and the known limits. What was run and seen is in `VERIFICATION_LOG_C2.md`.*

## 1. What C2 had to do, and where it lives

C2's method is **audio-visual Speaker-Relative Concomitant Deviation (SRCD)**. Movement is measured at each stutter moment against the person's *own* fluent movement, so it needs no labels.

| Requirement | Implementation |
|---|---|
| Input path A: the camera records during the C1 task; one recording gives audio for C1 and video for C2 | `inputPath=in_task_camera`; the job extracts the audio track (`vision-service /extract-audio`) and creates a **linked C1 assessment** (`services/c1Bridge.js`), or uses the `c1AssessmentId` the app already has |
| Input path B: a parent uploads a video; C1 runs on its audio track | `inputPath=parent_upload`, same mechanism |
| Input path C: audio only, stored as "not assessed" (never "0 behaviours"); C3's flag becomes "missing" | `POST /api/c2/analyses/not-assessed` → `status: not_assessed`; `GET /children/:id/summary` → `c2Flag: missing` |
| Baseline from the speaker's own fluent spans, no labels | `vision-service/app/srcd/baseline.py`: face-visible frames ≥ 0.5 s from any stutter moment; robust centre and spread per feature |
| Per-stutter-moment, per-signal deviation from that baseline | `app/srcd/deviation.py` (`score_moment`): eye, lip, jaw, cheek → FG; head → HM |
| Keep all 52 blendshapes plus pose; keep cheek and lip blendshapes (`cheekPuff`, `cheekSquint*`, `mouthPress*`, `mouthPucker`) | `app/video/landmarks.py` keeps all 52 per frame (returned with `include_frames=true`); `app/features/catalog.py` scores 30 features, including those named |
| Per-signal deviation shown as the explanation ("jaw +2.8 SD above this child's normal") | `explanation[]` on each moment, e.g. `jaw +15.5 SD above this child's normal (jaw opening); rarer than 1 in 1,000 fluent stretches` |
| Label-free mode: a per-child anomaly score that works on unlabelled children | The default detector `srcd` (`app/detection/srcd.py`) |
| Small GRU (≤ 30k parameters) vs small temporal transformer on baseline-normalised sequences, FG/HM output | `app/detection/nets.py` (GRU 11,858 parameters, transformer 19,266), `app/detection/learned.py`, `C2_DETECTOR=gru \| transformer` |
| Audio-visual fusion with C1's XLS-R features | The slot is reserved (`audio_dim` in `nets.py` and in the checkpoint); not active, see D2 |
| Rules baseline (reuse) | `app/detection/rules.py` (the prototype's thresholds), computed on every request as `baselines.rules` |
| Participant-grouped folds (fixing the `tmmf.py` leak); CASA loader; training script | `training/build_dataset.py` (manifest or CASA CSV, `--participant-regex`), `training/train_srcd.py` (`GroupKFold` by participant, F1 FG/HM and macro) |
| `/analyze-video` returns behaviour events and `hasSecondaryBehaviors`; the flag feeds C3 | `behaviourEvents[]`, `hasSecondaryBehaviors`, `concomitantScore`; `GET /children/:id/summary` gives `c2Flag`, `hasVideo` and the trend |
| MediaPipe at 10–15 fps | `C2_TARGET_FPS=15`; frames are sampled from the source (a 25 fps video is analysed at 12.5 fps) |
| Async job + polling, results saved | `api/src/modules/c2/services/analysisService.js` (collection `c2_video_analyses`), on the shared `JobQueue` |
| Behaviour timeline and counts for the results screen | `behaviourEvents[]` (start, end, signal, category), `counts`, `behavioursPerStutter` |
| Separate vision service, lazy model loading behind env flags | `vision-service/` on :8011; the face model and learned models load on first use; a missing model never stops startup |

## 2. How the label-free SRCD score works

1. **Face tracking.** MediaPipe Face Landmarker in VIDEO mode gives, per frame, the blendshapes, the head pose (yaw, pitch, roll and translation from the transformation matrix) and the EAR, lip opening, chin drop and mouth width (normalised by the inter-ocular distance).
   - Frames without a usable face are kept as missing, so the timing stays aligned with C1.
   - A 3-frame rolling median removes landmark jitter.
   - Head-position features have a 5 s rolling median subtracted, so slow posture drift doesn't count.
2. **The child's normal.** Frames ≥ 0.5 s away from every stutter moment form the fluent baseline. For each of the 30 scored features it keeps:
   - the median;
   - a spread equal to the larger of MAD × 1.4826 and (p90 − p10) / 2.563, floored per feature.

   With less than 4 s of fluent video, the baseline falls back to the whole recording and says so.
3. **Held deviation.** A deviation counts only at the level it *holds* for 0.3 s (the window minimum upwards, the maximum downwards). That is longer than an ordinary blink, so one jittery frame or a blink cannot become a behaviour. A feature's score for a moment (padded by 0.25 s) is its largest held deviation, in SDs.
4. **Is that unusual for this child?** The same score is computed for every equally long stretch of the child's fluent speech. The upper tail of those scores is modelled as exponential above their 80th percentile. The tail scale is shrunk towards a prior of 1.5 SD per e-fold, weighted by how many *independent* fluent stretches there are, so short recordings don't extrapolate from a handful of stretches.
5. **Decision.** A feature deviates when:
   - p ≤ α / (features in its category), with α = 0.05 per category (Bonferroni: FG has 23 features, HM 7), and
   - the deviation is at least 3 SD.

   A signal reports its most significant feature. A category is present if any of its signals deviates.

The outputs:

- `concomitantScore`: the share of assessed stutter moments with any behaviour.
- `hasSecondaryBehaviors`: `true` / `false`, or `null` if no moment had enough visible face.

## 3. Deviations from the plan, and why

| # | Deviation | Why |
|---|---|---|
| D1 | The default detector is the **label-free SRCD**, not the GRU. The GRU and the transformer are fully wired (dataset builder, training script, checkpoint format, inference, fallback), but **no real model is trained** | There are no CASA annotations or FluencyBank videos on the development machine. As agreed, the training script was only smoke-run, on synthetic clips (log V-18). The smoke checkpoint was deleted afterwards so nobody mistakes it for a model |
| D2 | **Audio-visual fusion is not active.** The nets take an optional `audio` vector (`audio_dim` in the checkpoint), but it is 0 | It needs C1's XLS-R span features, and C1's XLS-R path isn't available yet (C1 notes, D4). H2b (audio-visual beats video-only) cannot be tested until then |
| D3 | The label-free decision uses a **statistical test against the child's own fluent stretches**, not a fixed SD threshold | Verification showed that a fixed bar (or a fixed "normal envelope") flags something in almost every 1 s span of fluent speech, because 30 features × ~15 windows per moment are tested (V-4 to V-10). The test keeps the false-positive rate near the stated α on fluent speech |
| D4 | The tail prior (1.5 SD) was **calibrated on fluent speech** | It is the value at which the observed false-positive rate on 44 fluent spans matched α (5 % FG, 0 % HM). Only fluent speech is needed for this, so the calibration is label-free and can be redone on child videos |
| D5 | **RF on 2-s window statistics is evaluated offline, not served** | It needs labelled training data. `training/build_dataset.py` stores 2-s window statistics per moment, and `notebooks/c2_srcd_comparison.ipynb` trains and scores the Random Forest in the five-way comparison. The rules row is computed on every request too |
| D11 | "GRU without self-comparison" uses the same GRU on raw features standardised with the training fold's population statistics | This is the plan's ablation: everything is the same as SRCD + GRU except the speaker-relative step. The builder stores the raw sequence (`X_raw`) next to the SRCD one (`X`) for every moment |
| D6 | The optional **self-supervised pretraining** step is not implemented | It was optional, and it needs unlabelled child video, which ethics doesn't cover yet |
| D7 | C2's `concomitantScore` **is not written back into the linked C1 assessment's severity** | C1 scores the audio before C2 has its moments, and C1 deletes the audio after scoring. Rescoring would need a C1 change, which is outside this task. The score is exposed in the C2 result and summary; C1 already accepts `concomitantScore` on an upload |
| D8 | **If C1 fails, C2 fails** (`stutter_events_unavailable`, with C1's error attached) instead of analysing the whole video | Without stutter moments there is nothing stutter-locked to measure. The client can resend with `c1AssessmentId` or `stutterSpans` |
| D9 | Extra input **`stutterSpans`** (source `manual`) | Lets researchers use CASA spans and lets an SLP correct moments. It is also the only way to run C2 on a video with no usable audio |
| D10 | New code in `server/`; the prototype in `ai-service/` and the old `backend/` are **not imported** | The geometry (EAR, Euler angles), the rules thresholds, the MediaPipe setup and the CASA CSV loader were ported and adapted. `backend/` contains malware (see the C1 notes, D1) |
| D11 | **HM uses head position and speed** as well as yaw, pitch and roll | "Head movement" in CASA includes moving forward, backward and away. Translation and speed come from the same transformation matrix |
| D12 | A **cheek signal** (cheek puff, cheek squint, nose wrinkle) is scored as part of FG | The cheek and lip muscles were found the most predictive in adults (Das et al., 2020). FG covers eye, lip, jaw and cheek |
| D13 | Video limits: 2–180 s and ≤ 200 MB; one face | They match C1's 180 s limit, so the whole audio track can always go to C1 |

## 4. Design decisions

- **One module, C1 as the template:** atomic job claim, bounded retries for transient vision errors (2 s, then 4 s), the contract check against a zod mirror, file deletion in `finally`, and `recover()` at startup.
- **Resumable stages:** `queued` (extract audio, create the C1 assessment) → `awaiting_stutter_events` (wait for C1) → `processing` (vision) → `completed` / `failed`.
  - The C1 id is saved as soon as it exists, so a restart never creates a second C1 assessment once that step has finished.
  - A job is locked by `runningSince`, not by its status, because it passes through several unfinished statuses.
- **C1 stays the owner of %SS and stutter detection.** C2 reaches C1 only through `services/c1Bridge.js`:
  - it creates an assessment the way an app upload would, so C1 validates and stores it as usual;
  - it reads `stutterMoments`;
  - it checks that a linked assessment belongs to the same child.
- **Early validation:** C1's task rules (age band, passage for 11–14) run before the video is accepted (C1 now exports `resolveTask`), so a bad request fails at once instead of minutes later inside the job.
- **Never "0 behaviours" by accident:**
  - a moment without enough visible face is `assessed: false`;
  - if no moment could be assessed, the flag is `null` / `missing`;
  - path C is stored explicitly;
  - only "C1 found no stutters in a good video" gives `false` / `no`.
- **Every flag has a reason:** a moment flagged by a learned model also gets an explanation, from the signal of that category that moved most (V-18).
- **Front-end readiness:**
  - `behaviourEvents` drives the timeline;
  - `summary` gives the results card (`assessed`, `hasSecondaryBehaviors`, `behaviourTypes`);
  - `explanation[]` gives text; the structured `signals` allow Sinhala wording later;
  - `/children/:id/summary` is C3's context.
- **Privacy:**
  - the video is deleted after every job and every rejected upload;
  - the vision service uses a temporary copy and deletes it;
  - only numbers are stored;
  - `videoConsent=true` is required.
- **Versioning:** every result records `detector.version`, the thresholds used and the service version.

### Shared code touched (small)

- `config/env.js`: the C2 settings (vision URL and timeout, upload limit, queue size, keep-uploads flag, C1 wait).
- `middleware/errorHandler.js`: the "too large" message now names each module's own limit (`req.uploadLimit`) instead of always "Audio … 50 MB".
- `modules/index.js`: adds `c2`.
- C1: `services/assessmentService.js` exports `resolveTask`; `validation/schemas.js` exports `optional`, `wholeNumber` and `TASK` for reuse. C1's behaviour is unchanged.

## 5. Changes made because of verification

Details are in `VERIFICATION_LOG_C2.md`.

| Log | Problem seen | Change |
|---|---|---|
| V-4 | A fixed "beyond the child's normal range" rule flagged ordinary fluent spans (lip puckering +10 SD) | A per-moment test against the same-length fluent stretches (empirical null) |
| V-5 | Scores clipped at 10 SD tied with the null's maximum and counted as present (p = 0.67); 2-frame holds let blinks through | The decision uses the p-value (ties count against the moment); the scoring clip is 50 SD; the minimum hold is 0.3 s, rounded up to frames |
| V-6 | One sparse feature (lip puckering) set the bar for the whole lip signal, so a lip press was missed | Each feature has its own null |
| V-7 | About 30 s of fluent speech holds only ~20 independent stretches; "larger than any fluent stretch" happened to fluent spans | An exponential tail above p80 per feature, with a Bonferroni correction over the category's features |
| V-8 | A 17 s clip gave an overconfident p (0.0002) for an ordinary sideways glance | The tail scale is shrunk towards a prior, weighted by the number of independent stretches |
| V-9 | Sparse features had a collapsed MAD, so an ordinary pucker read as +17 SD | The spread is max(MAD × 1.4826, (p90 − p10) / 2.563, floor) |
| V-10 | The false-positive rate on fluent speech was 14 % for FG at prior 1.0 | Prior set to 1.5 (5 % FG, 0 % HM on 44 fluent spans); configurable as `C2_TAIL_PRIOR_SD` |
| V-11 | The response still described an "envelope" that no longer existed | Replaced by `baseline.holdFrames` |
| V-16 | Path C records showed `video: {deleted: false}` and empty `spans` | They now carry no video block; spans are omitted when absent |
| V-18 | A GRU flag could come with no explanation or event; an explanation could name a category the detector had rejected; weak signals read "1 in 1 fluent stretches"; an "All-NaN slice" warning appeared when the face was gone for a whole window | Flags from a learned model get an explanation and an event; only decided categories are explained; p ≥ 0.2 reads "within this child's usual fluent range"; the warning is silenced where NaN is expected |

## 6. Known limitations

- **No real stuttering video and no children were used.** Verification used three adult interviews (public domain / CC BY-SA). Stutter events were spliced into their real audio and video, and face or head movements were warped in at known times. Real concomitants are subtler and more varied than these warps.
- **Measured on that test material:**

  | | False positives on 44 fluent spans | Inserted behaviours found (14) | Movement-free stutters flagged (4) |
  |---|---|---|---|
  | SRCD (default) | FG 5 %, HM 0 % | 7 | 0 |
  | Rules baseline | FG 86 %, HM 52 % | 12 | 4 |

  SRCD trades recall for specificity. Speakers who move their head a lot when fluent get a high HM bar, which is intended. These numbers describe the synthetic material, not children who stutter.
- **2D warps disturb MediaPipe's 3D head pose,** so some inserted facial movements also produced an HM flag (log V-10). This is probably an artefact of the test material, but it is untested on real video.
- **C1's recall limits C2.** C1's acoustic detector missed the inserted prolongations. A missed stutter isn't examined, and its movement then enters the fluent baseline, which raises the bar for the other moments (log V-13).
- **Short recordings:** with less than ~4 s of fluent, face-visible video, the baseline uses the whole recording. With fewer than 20 fluent stretches, only the fixed 3 SD bar applies (`null_unavailable`).
- **The learned detectors are untrained.** The smoke-run F1 values (33 synthetic moments) mean nothing. Adult → child transfer is untested until the ethics amendment.
- **CASA:** the CASA participant regex (`^(\d+)` on `media_file`) is a guess until checked on the real file names. CASA's FG is broader than C2's scope (it includes tongue protrusion and jaw tension).
- **Timeouts:** a C2 job waits up to `C2_C1_WAIT_MS` (10 min) for C1. Both run in the same process, so very long C1 queues delay C2.
- **Not exercised:**
  - MongoDB going down during a request (the container was shared with another session; the shared handler's 503 is unchanged from C1);
  - `.mov`, `.mkv` and `.avi` files, and phone videos with rotation metadata (`.mp4` and `.webm` were verified);
  - more than one face in view (the tracker follows one face).

## 7. Next steps (outside this task)

1. When FluencyBank and CASA access is granted, build the CASA dataset (`training/build_dataset.py --casa-csv …`) and check the participant grouping. Then run `notebooks/c2_srcd_comparison.ipynb`, the five-way comparison (run guide: `notebooks/README.md`). Switch `C2_DETECTOR=gru` only if the learned model beats `srcd`.
2. When C1's XLS-R features exist, pass the pooled span features as `audio` (set `audio_dim`) for the audio-visual row (H2b).
3. Recalibrate `C2_TAIL_PRIOR_SD` on fluent spans of child videos once filming is approved, and collect SLP `reviews` on 10–15 child videos for the child test set.
4. Done since: the app films the face during the C1 task when a parent turns it on (path A, `c1AssessmentId`), path B uploads, and C3 reads the summary.

## Changes after the team's feedback (2026-10-20)

| # | Decision | Reason |
|---|---|---|
| D14 | The comparison reports, per class: accuracy next to the **majority-class** accuracy, precision, recall, F1 and PR-AUC; a "0 majority class" row is added | Accuracy alone hides "always no" (most moments have no behaviour): a teammate's run showed HM at 100 % accuracy with no positive found. PR-AUC needs scores, so it is reported for the RF and the GRUs, and "n/a" for the rules and label-free SRCD, which give 0/1 decisions |
| D15 | Each trained model's thresholds are tuned on a **participant-grouped validation split of its training fold** (never the test fold), and the saved checkpoint keeps the median of the folds' thresholds | A fixed 0.5 is wrong for imbalanced classes; tuning on test would inflate the score |
| D16 | A class whose cross-validated precision is below 0.5 (`SWARA_C2_MIN_PRECISION`, `--min-precision`), or whose accuracy does not beat the majority class, is **not assessed** by the model: the checkpoint records `assessed: {FG, HM}` and the service decides that class with label-free SRCD, with a `model_class_not_assessed` warning | The same rule the teammate applied to HM. A weak class must not reach the child's report as a learned decision; label-free SRCD stays a principled fallback |
