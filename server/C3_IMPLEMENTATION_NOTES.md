# Swara server, Component 3: implementation notes

*2026-10-15. Paths are relative to `Swara-RP/server/`; the C3 code is in `api/src/modules/c3/`. Records what C3 must do and where it is implemented, the deviations, the design decisions, the changes made during verification (see `C3_VERIFICATION_LOG.md`), and the known limits.*

## 1. What C3 requires, and where it lives

| Requirement | Implementation |
|---|---|
| Two-level activity pool: Level 1 = activity type × difficulty (what the bandit picks), Level 2 = content items | `data/activityCatalog.json`: 36 arms (18 per band: 6 types × easy/moderate/difficult) and 72 items; `services/catalogService.js` |
| Fields `id, type, age_band, difficulty, target_skill, duration_min (3–5), content_ref, slp_approved` | Arms: `id, type, ageBand, difficulty, targetSkill, durationMin, appActivityId, slpApproved`; items: `id (PD-E-01…), contentRef, prompt {si, en}, targets, slpApproved` |
| Age band is a strict filter; only SLP-approved content is shown | `catalogService.eligibleArms`: same band, `slpApproved`, and at least one approved item |
| Draw an item the child hasn't seen recently | `catalogService.drawItem`: the least recently used approved item for that child |
| Verify that the child said the activity's word (supervisor request: target අම්මා, child says අක්කා → not the same word) | Word items carry `targetWords` and `confusables` (catalog); `POST /sessions/:id/activities/:attemptId/word-checks` sends each recording to the language service's `/verify-word` (`language-service/app/verify/word.py`), which decides match / mismatch / unclear; `services/wordCheckService.js` stores the checks and feeds P (D15, log V-22 to V-25) |
| Context: age band, C1 severity, C2 flag (yes / no / missing), camera on, parent-help level, engagement trend (last 3 sessions), recent score for the activity type, sessions completed | `bandit/features.js` (12 named features) and `services/contextService.js`. C1 and C2 are read in-process from their own `summaryForChild`. Session time used is a 12th feature for within-session adaptation |
| Versioned context with state migration | Every stored matrix keeps its feature names and `featureVersion`; `banditStore.migrate` remaps by name when the schema changes (log V-16) |
| Hybrid LinUCB with a shared population part, so a new child benefits from other children | `bandit/hybridLinUCB.js` (Li et al. 2010, Algorithm 2). The shared β over `z = x ⊗ difficulty one-hot ⊕ type one-hot` (k = 45) is one population document; the per-arm θ over x (d = 12) is kept per child (`c3_bandit_states`) |
| Discounted (sliding-window style) variant | `C3_POLICY=discounted`: `hybridLinUCB.discountChild` shrinks the child's per-arm matrices towards the prior before each update |
| Reward `r = 0.6·P + 0.4·E`, clipped to [0, 1]; P = successes ÷ targets × share completed; response time and attempts feed E only | `services/scoring.js` (`performance`, `rewards`) |
| TSS = 100·(0.5·P̄ + 0.3·Ē + 0.2·Q), weights re-normalised when Q is missing | `scoring.tss`; `sessionService.computeOutcome`; recomputed when a questionnaire arrives after completion |
| Parent help in the context, never in the score | `result.parentHelp` (0–3) → `parentHelp` context feature; not used by `scoring.js` |
| Engagement estimator in two modes: camera + logs, and logs only; logs compared with the child's own history; face absent = missing | `services/engagementService.js`; `data/engagementModel.json` (provisional coefficients). z-scores use the child's last 20 activities once there are at least 3, population norms before that |
| Logs-only weights fitted by logistic regression against the parent questionnaire; store which mode was used | `services/calibrationService.js` (`POST /engagement/calibrate`); `engagement.mode` and `modelVersion` on every activity |
| Parent questionnaire: 5–6 items, 1–5, adapted from PRIME-O, once per session; part of the TSS and the real-child engagement label | `data/questionnaire.json` (6 items, si/en); `POST /sessions/:id/questionnaire`; `engaged = mean ≥ 3.5` is the calibration label |
| 25-minute session in 3–5-minute blocks; offer a break or a parent-led activity when engagement stays low; end on time | `services/adviceService.js` → `continue / offer_break / parent_led / end_session` on every pick and result |
| Report engagement over session time by age band | `GET /reports/engagement-over-time` |
| Random-logged replay evaluation | `C3_EXPLORE_EPSILON` picks uniformly at random with probability ε; every decision stores its propensity, context and all reward variants (`GET /reports/replay-log`) |
| Reward ablation (taps vs engagement vs fused) | All four rewards (`fused`, `performance`, `engagement`, `tap`) are stored per activity; `C3_REWARD_MODE` chooses which one updates the bandit |
| Therapist eligibility constraints | The band filter, `slpApproved`, and the parent-led restriction to easy arms (`recommendationService.candidateArms`) |
| C3 history and progress for the integrated report | `GET /children/:childId/summary` (TSS trend, engagement trend, per-type scores, C1 link, bandit counts) |

## 2. Deviations, and why

| # | Deviation | Why |
|---|---|---|
| D1 | The bandit runs on the server, not in Dart on the phone | Decided with the user for this phase. The backend had to show recommendations working without the app. The state is plain JSON with named features, and `GET /children/:id/bandit?matrices=1` exports A, B, b, A0 and b0, so a phone copy could mirror it. The app's own Dart LinUCB has since been removed (demo mode walks a fixed activity order), so the server's Hybrid LinUCB is the only recommender, as the plan asks |
| D2 | No Python service for C3 | The maths is small: one 45×45 and up to eighteen 12×12 inversions per pick, about 40 ms per pick and result in total (log V-10). The engagement model is a set of logistic coefficients. A separate service would add a process and a contract with nothing to put in it. DAiSEE training runs offline in the vision service, which already has the MediaPipe tracker (`training/build_engagement.py`, `training/train_engagement.py`). Its output is the JSON file `data/engagementCameraModel.json`, which `services/cameraModel.js` evaluates |
| D3 | Engagement coefficients are hand-set (`provisional: true`); calibration fits only the logs-only mode | No pilot sessions exist yet. The calibration endpoint is real and was run (log V-17), but on driven sessions. The camera model's training pipeline is built and was run end to end (log V-26), but DAiSEE is not on this machine yet, so the shipped `engagementCameraModel.json` is a provisional hand-set logistic file until the training run replaces it |
| D16 | The camera model is scored on the server from the phone's numbers, not on the phone | The plan wants inputs computed on the phone and no video leaving it. The phone runs ML Kit and sends only 10-second window statistics, so that holds, and there is a single copy of the model (no Dart evaluator to keep in step). `engagementEstimate` still lets an on-device model send E directly |
| D17 | DAiSEE trains only the camera part; it joins the logs by late fusion (`cameraLogit` is one feature of `camera_logs`) | DAiSEE has video but no app-activity signals, so a joint camera + logs model can't be trained on it. The fusion weight is provisional, and the questionnaire calibration can refit it once pilot sessions have both |
| D18 | Training features come from MediaPipe, phone features from ML Kit | ML Kit runs only on Android and iOS, so DAiSEE can't be processed with it. The angle features match across the two trackers. The eye and smile probabilities may be scaled differently: ML Kit gives probabilities, MediaPipe gives blendshapes (eye open = 1 − eyeBlink, smile = mouthSmile). `GET /reports/engagement-pilot-check` measures the gap on real sessions |
| D4 | The C1 %SS change is reported next to the TSS (`outcome.fluency`) but not weighted into it | No weight for that term has been agreed. Adding it later is a change to `scoring.tss` |
| D5 | The C2 flag comes from the C2 module's latest result for the child (`c2FlagSource: c2`, with `c2AnalysisId`). The app's `c2Flag` is used only when C2 has no yes / no (no analysis yet, camera declined, or nothing assessable), with `c2FlagSource: client`; otherwise it is `missing` | C2's own analysis is the measured value, so it wins over the app. What the app sent is kept in `c2FlagClient`. A session keeps the flag it started with; the child-level context preview reads C2 live |
| D6 | Session time is the sum of reported activity durations plus breaks, not wall-clock time | This is deterministic, survives a paused app, and is what the child actually spent on activities. Wall-clock time can be added as a separate check |
| D7 | The per-child prior is `A = λI` with λ = 5 (`C3_CHILD_PRIOR`), not Li et al.'s λ = 1 | With λ = 1 a new child got only 3 of 6 good picks in session 1 and 1 of 6 in session 2, because the per-child uncertainty bonus outweighed what the population knew. With λ = 5 a new child got 6 of 6 from session 1, and a child with different preferences still moved away from the population's choice within 4 picks (logs V-11, V-12) |
| D8 | Ties in UCB are broken at random, and the propensity counts the tie | With "first best" every new child started on the first arm in catalog order and swept the catalog in file order (log V-5) |
| D9 | A parent-led activity is restricted to easy arms and flagged `parentLed: true` | No separate parent-led content exists yet. Easy arms done together with the parent are the simplest reading of the requirement |
| D10 | The discounted variant discounts only the per-child part | The population part describes children in general. Only one child's needs change as therapy goes on |
| D11 | "Recent TSS for this activity type" is the mean reward of the child's last 3 activities of that type | The TSS is per session, while a session mixes types. The per-activity reward is the same quantity at the right grain |
| D12 | The simulator is an offline script in the API module (`evaluation/`), not a service | It calls the production bandit code (`bandit/hybridLinUCB.js`, `bandit/features.js`) directly, with the same context, history windows and advice rules, so the algorithm that runs for children is the one evaluated. Results: `C3_EVALUATION.md` |
| D13 | Authentication came later, with the shared API | Login (JWT) and the parent-mode PIN are now in place (`server/README.md`, Auth); the questionnaire needs parent mode |
| D14 | The tap reward uses 0.5 when no tap was given | This matches the existing app's behaviour (`completePendingWithoutFeedback`), so the tap ablation row reproduces the current system |
| D15 | The word check runs in the C4 language service, not a C3 service; it checks content, not fluency; checked words drive P, unclear ones are left out | The Sinhala CTC model is already loaded there (a second copy would cost ~1.2 GB and a contract). A stutter must not be scored as a wrong word: repetitions, prolongations and fused repetitions ("පරපපරපුර") still match, since fluency is C1's job. Decided with the user: P = matched ÷ (matched + mismatched); an unclear clip is not the child's fault, so it is left out, and if every word is unclear the app's count is used. The item's `targets` is unchanged (it counts attempts in the app, not words), and a review after the result is kept as ground truth but does not re-score (the bandit was already updated) |

## 3. Design decisions

- **One module, the same conventions as C1:** CommonJS, Zod schemas through `validate()`, `ApiError` and the shared error envelope, `c3_` collections (`c3_therapy_sessions`, `c3_activity_attempts`, `c3_bandit_states`, `c3_engagement_models`), `id` instead of `_id` in responses, and `{items, total, limit, offset}` pagination. `childId` and `objectId` validation are reused from C1.
- **Pure bandit functions, persistence outside:** `bandit/` is plain functions over plain arrays (no Mongo, no Express), so the same code can be ported to Dart or used by a future simulator. `banditStore` does the loading, migration and saving.
- **Exact shared-matrix bookkeeping:** every update (and every discount) first adds the arm's `BᵀA⁻¹B` coupling back into A0 and then removes the new one, as in Li et al. Checking the stored state after 60 updates under the discounted policy gave `A0 = I + Σzzᵀ − ΣBᵀA⁻¹B` to 1e-14 (log V-14).
- **One open activity per session, enforced twice:** a check in the service and a partial unique index (`one_pending_per_session`) in MongoDB. Recording a result first claims the activity atomically (`status: pending` → done), so a repeated request can't update the bandit twice.
- **The bandit learns only from what was recommended:** the context x and z are stored with each recommendation, and the update uses those stored vectors, not a recomputed context. An activity left open at completion is marked `abandoned` and gets no update.
- **Every decision is replayable:** policy, α, ε, `explored`, propensity, the candidate arms with their type scores, the full context, and all UCB scores are saved with each activity. `evaluation/ope.js` rebuilds each candidate's context from these and estimates other recommenders from the log (IPS, self-normalised IPS, doubly robust).
- **The camera engagement model (C3 plan, part 1):**
  - **Features.** Per 10-second window, defined once in `vision-service/app/engagement/features.py` and mirrored in `mobile/lib/core/engagement/camera_features.dart`:
    - `facePresentRatio`;
    - yaw / pitch SD and mean absolute angle;
    - `lookAwayRatio` (|yaw| > 25° or |pitch| > 20°);
    - eye-open mean and eyes-closed share (eye open < 0.3);
    - smile mean.

    `contracts/c3/engagement-camera-features.example.json` checks that both sides agree (the Dart test reads it).
  - **Label.** DAiSEE Engagement level 0 or 1 = not engaged (about 6 % of clips).
  - **Models.** `train_engagement.py` compares a standardised logistic regression (`class_weight='balanced'`) with shallow gradient-boosted trees (150 trees, depth 3, balanced sample weights).
  - **Evaluation.** Subject-grouped 5-fold CV over Train + Validation, then the official Test split, keeping only Test subjects never seen in training. It reports balanced accuracy, macro-F1, ROC-AUC and the confusion matrix. Plain accuracy is not reported, because "always engaged" already scores about 94 %. The model with the higher CV macro-F1 is exported.
  - **Export check.** The export carries `selfCheck` rows (inputs and scikit-learn's log-odds). The API recomputes them at start-up and refuses the file if its evaluator disagrees by more than 1e-4.
  - **Scoring an activity.** The camera score is the duration-weighted mean P(engaged) over the windows where a face was visible at least 30 % of the time. With no such window, the activity is scored on logs only (`faceMissing: true`). Its log-odds, clipped to ±4, are `cameraLogit` in the fused `camera_logs` mode.
- **Engagement from the phone is accepted:** `engagementEstimate` lets an on-device model (the app's later camera + logs model) supply E directly, labelled `source: client`, so the server and on-device estimators can be compared on the same sessions.
- **Content is data:** the catalog and questionnaire are JSON files with `placeholder: true` and a version string. An SLP can change difficulty labels or `slpApproved` without code changes. The catalog generator keeps the arm × item structure consistent.
- **Configuration fails fast:** an unknown `C3_POLICY` or `C3_REWARD_MODE`, or an out-of-range `C3_ALPHA`, γ, λ or ε, stops the API at startup with the variable named (log V-20).

## 4. Changes made because of verification

| Log | Problem seen | Change |
|---|---|---|
| V-5 | Every new child got the first arm in catalog order, then swept the catalog in file order, because all UCB scores tie at the start | Random tie-breaking; the propensity accounts for ties (D8) |
| V-11 | A new child benefited from the population for only 3 picks, then explored every arm | Per-child prior strength λ (`C3_CHILD_PRIOR`, default 5) (D7) |
| V-16 | A migrated state was re-migrated on every read until the first bandit update saved it (the log showed the same migration three times) | `banditStore` saves a migrated document as soon as it is loaded |
| V-17 | Two calibrations in the same second produced the same version name → E11000 → 500 `internal_error` | Version = millisecond timestamp + random suffix |
| V-23 | Part-word stutters were `unclear` 60 of 163 times: the ASR fuses a repetition into the word ("පරපපරපුර", "බවටබවට"), which maze removal can't see | Stutter-aware matching: a heard word matches on its ending when the rest is repeats of the word's opening, and every candidate is also scored in its stuttered forms. Part-word stutters matched 102 → 153 of 163 |
| V-23 | A listed confusable said by the child could still pass on the transcript ("මතකයි" for expected "මේකයි") | The transcript alone accepts only when no alternative reads at least as well; otherwise the acoustic comparison decides. False matches on listed confusables 5 → 2 of 141 |
| V-24 | Word checks in the session view had no id, so a review couldn't name one | Each check is serialised with `checkId` |

## 5. Known limitations

- **Provisional numbers:**
  - The engagement coefficients and the low-engagement threshold (0.4 over 2 activities and 6 minutes) are hand-set. The catalog and questionnaire are placeholders, and the Sinhala wording needs review.
  - λ = 5 and α = 0.6 were chosen from the driven runs in the log, not tuned on real children.
  - Calibration has been run only on driven sessions.
- **One API process:** the bandit lock is in-process. Running several API instances would need a database-level lock or optimistic versioning on the population document.
- **Approximate migration when features are removed:** a migration that *removes* features keeps the population matrices only approximately consistent with each child's coupling terms. Children migrate lazily, one at a time. Adding features is exact.
- **Arms are stored once updated:** untried arms are not stored for a child; they are created at the prior when needed.
- **The population sees only C3's own data:** there is no cross-component outcome (for example C1 %SS change) in the reward yet.
- **Camera features are trusted as sent:** they are computed on the phone, and the server only range-checks them.
- **Domain gap:** DAiSEE is students aged roughly 18–30 watching lectures, not 5–14-year-olds in therapy games. Expect the camera model to be weaker on children, and report the pilot-check numbers rather than the DAiSEE ones as the result.
- **Word check on adult speech only:** the thresholds were calibrated on adult read Sinhala (SLR52), with stutters spliced in, not on children. Words that differ only by a suffix (ඉන්න / ඉන්නේ, ලංකාව / ලංකාවෙන්) are sometimes accepted for each other, and a wrong word that is not a listed confusable is more often `unclear` than `mismatch` (33 of 141). Sinhala only.
- **Evaluation is simulated:** the comparisons in `C3_EVALUATION.md` come from simulated children under stated assumptions. The replay test needs pilot sessions with `C3_EXPLORE_EPSILON` > 0, and only decisions logged with their candidate set can be used.
- **Reward vs learning:** in the simulator, a reward that is mostly successes ÷ targets steers towards activities the child already masters, which grows ability less than harder ones if children learn most just above their level. `C3_EVALUATION.md` section 2 shows the trade-off; the SLP should decide which reward to use.

## 6. Next steps

1. **App integration:**
   - The app's C3 flow maps onto the endpoints as follows: `startSession` → `POST /sessions`; the adaptive screen → `POST /next-activity` (use `activity.appActivityId` for the screen and `item` for the content); the feedback card → `POST …/result` (send `parentHelp`, and `parentFeedback` if kept); `session_complete` → `POST /complete`, then show `outcome.tss` and `meanEngagement`; parent mode → `GET /questionnaire` and `POST /questionnaire`.
   - Point `AppConstants.baseUrl` at this server.
2. **Bandit on the phone:** decided: the server is the only recommender; the Dart LinUCB was removed.
3. **On-device engagement:** done. The app sends ML Kit window features in `camera.windows`, plus `taps` and `responseLatencyMs`, when the parent turns the camera on.
4. **Engagement model:** request DAiSEE (Google Form on the dataset page, research use only). Then run `build_engagement` and `train_engagement` (server README, "Vision service"), restart the API, and check `GET /engagement/model` → `camera.provisional: false`. Then calibrate the logs-only mode and read `GET /reports/engagement-pilot-check` on pilot sessions with real parent questionnaires. Using the camera in C3 needs the same ethics amendment as C2.
5. **Evaluation:** the simulator, stress test and learning-signal comparison are done (`C3_EVALUATION.md`; rerun with `node src/modules/c3/evaluation/run.js`). Still to do: pilot sessions with `C3_EXPLORE_EPSILON` set (e.g. 0.2), then `node src/modules/c3/evaluation/ope.js <saved replay log>`.
6. **SLP review:** have an SLP review the activity pool, the difficulty labels and the questionnaire wording, and set `slpApproved`. Include the `targetWords` and `confusables` (likely substitutions per word).
7. **Word check on children:** collect child recordings with parent / SLP reviews (`PUT …/word-checks/:checkId/review`), then re-tune the `C4_VERIFY_*` thresholds on them, and add confusables the reviews show children actually say.

## Changes after the team's feedback (2026-10-20)

| # | Decision | Reason |
|---|---|---|
| D16 | A session has **5 activities** (`C3_MAX_ACTIVITIES`, 1–20; completed + skipped). After the 5th the server advises `end_session`; the 25-minute limit stays as a second stop | The team asked for a fixed, short session instead of "until the child stops". The app shows "Activity n of 5" |
| D17 | Each activity **type** at most once per session while other types remain (on top of "not the arm just done") | The same type at another difficulty looked like a repeat. With 6 types per band and 5 activities, a type never has to repeat. The filter runs before the propensities are computed, so the replay log and OPE stay valid; the simulator applies the same rule |
| D18 | The pool is the **six types** the team chose, in **both** age bands: breathing and relaxation, picture description, picture naming, syllable practice, word and phrase practice (replaces easy onset), paragraph reading (short sentences for 5–10). Catalog 0.2: 36 arms, 72 items | Storytelling, slow speech and guided conversation were removed, with their app screens. Items gained `image` (picture naming and description), `keywords` (what a description should mention) and `text` (the passage). The content is still a placeholder: the pictures are generated placeholders (`mobile/assets/images/component3/items/`, replace with the team's, same file names), and an SLP must check the words, passages and keywords |
| D19 | Answers are checked in every speaking activity: words (picture naming, syllable practice, word and phrase practice) by the existing word check; **reading** by the share of passage words read; **picture description** by the share of the picture's keywords mentioned (`POST /check-speech` in the language service; `POST .../speech-check` in the API) | Before, only word activities were checked and any recording of the others counted as full success. Both new checks run on the ASR transcript with stutter repetitions removed (content, not fluency). P = the share (× the item's targets); an unclear check is left out and the app's count is used. Thresholds (pass 0.5, partial 0.25; calibrated on adult SLR52 speech, V-33) are provisional for children. Breathing counts completion only |
| D20 | Skip on every activity screen; a skipped activity is posted with `skipped: true` (P = 0, low engagement), counted in the session outcome, history and summary | Only guided conversation had a skip button, so "skipping" was invisible to the recommender |
| D21 | A session left part-way can be **continued** for 12 hours (`config.resumeHours`): `GET /children/:id/sessions/active` returns it with its open activity, and the therapy home offers "Continue today's session". After 12 hours it is closed as **`abandoned`** (its open activity gets no reward), at startup and whenever the child's sessions are read | There was no resume, and unfinished sessions stayed "Active" for ever. A time window avoids phone/server time-zone ambiguity about "today" |
| D22 | **Streak** = consecutive days (to today or yesterday) with a completed session; **stars** = completed activities; both in the C3 summary and shown on the therapy home and history | They were hard-coded ("5 Days", "1.2k") |
| D23 | After the parent questionnaire the app shows the TSS before and after the answers; the score is called "Therapy Success Score (TSS)" everywhere; demo mode shows a demo TSS out of 100 instead of "Feedback x/10" | Reviewers read the session-complete score and the history score as two different scores |
| D24 | The bandit context also has C1's %SS (÷ 20), C1's main type (repetition / block-or-prolongation) and C2's FG and HM separately (feature schema 2) | C3 used only C1's severity and C2's yes/no. Stored bandit state is remapped by name (new dimensions start neutral), and the simulator generates the same features |
