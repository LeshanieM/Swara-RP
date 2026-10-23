# Swara server, Component 3: verification log

*2026-10-15 · macOS 27.0.1 · Node 24.19.0 · Python 3.11 (C1 speech service) · MongoDB 7.0.45 (`docker compose`), database `swara_c3_verify`.*

Everything below was run against the live API (`node src/server.js`, port 5001) by sending real HTTP requests and reading the responses. The requests were sent with `curl` and with short Python scripts that only send requests and print what comes back. No automated tests were written. Responses are shortened to the fields that matter. A separate database (`swara_c3_verify`) was used so other work on the shared `swara` database was not touched. Its C3 collections were cleared before V-11 and between the two runs in V-14, so those comparisons start from the same state.

**Hand checks.** Engagement, performance, rewards and TSS values were recomputed by hand from the formulas in `C3_IMPLEMENTATION_NOTES.md` and compared with the responses.

**C1 audio.** V-9 used two clips made with macOS `say` (voice Daniel, 16 kHz): one fluent reading, and a copy with sound repetitions, 1 s blocks and prolongations spliced in at word onsets.

---

### V-1 Startup and health
- `GET /api/health` → 503 `degraded` while the C1 speech service was not running. `components.c3.status: ok` with `catalog.eligibleArmsByBand {"5-10": 18, "11-14": 18}`, 72 items, engagement model `c3-engagement-provisional-0.1`. `components.c1.status: degraded` (`speechService ECONNREFUSED`).
- After starting the speech service, both components report `ok`.
- C3 works without the speech service: it needs only MongoDB.

### V-2 Activity pool and age band
| Request | Response |
|---|---|
| `GET /activities?age=7` | 200, band `5-10`, 18 arms: breathing, easy_onset, picture_description, picture_naming, storytelling, syllable_practice × 3 difficulties |
| `GET /activities?age=12` | 200, band `11-14`, 18 arms: easy_onset, guided_conversation, passage_reading, slow_speech, storytelling, syllable_practice |
| `age=4`, `age=15` | 422 `age_out_of_range` "Swara supports ages 5–14" |
| `age=abc`, `age=7.5`, no age | 422 `validation_error`: "age must be a number" / "must be a whole number" / "age is required" |
| `GET /activities/items?armId=5-10:picture_description:easy` | 200, items `PD-E-01` ("A child flying a kite" / "සරුංගලයක් යවන ළමයෙක්"), `PD-E-02` |
| `armId=nope` | 404 `arm_not_found` |

### V-3 Questionnaire
- `GET /questionnaire?language=si` → 200: 6 items (`interest`, `willing_participation`, `enthusiasm`, `staying_involved`, `comfort`, `confidence`), scale 1–5 with Sinhala labels, plus the PRIME-O adaptation note.
- `language=fr` → 422.

### V-4 First session: pick, result, double requests
- `POST /sessions {childId: CH-101, age: 7}` → 201, band `5-10`, `c2Flag: missing`. Context at start: `c1Missing 1`, `c2Missing 1`, `engagementTrend 0.5` (prior), `sessionElapsed 0`.
- `POST /next-activity` → 201: `5-10:picture_naming:easy`, item `PN-E-01` ("cat", 5 targets), advice `continue`, 18 candidates, propensity 1. All 18 UCB scores equal (1.6971 = 0.6·√8).
- A second `next-activity` with the first still open → 409 `activity_pending`, with the open `attemptId`.
- Result `{targets 4, successes 3, attempts 5, responseLatencyMs 2500, taps 18, durationSec 180, parentHelp 1, parentFeedback just_right}` → 200:
  - `performance 0.75` (3/4 × 1);
  - E `0.8834` in mode `logs`, with features `zAttemptsPerTarget −0.1` ((1.25 − 1.3)/0.5), `zResponseLatency 0`, `zTapsPerMin 0` (6/min); E = σ(−1 + 3 + 0.025) = σ(2.025) = 0.8834;
  - `rewards {fused 0.8034, performance 0.75, engagement 0.8834, tap 1}`, where 0.6·0.75 + 0.4·0.8834 = 0.8034;
  - `bandit {updated true, n 1}`.
  
  All hand checks match.
- The same result again → 409 `result_already_recorded`.

### V-5 Issue: every new child got the same first activity
- **Observed:** in V-4 all UCB scores tied, and the pick was the first arm in catalog order. Every new child would start with picture naming (easy) and then sweep the catalog in file order.
- **Fix:** ties (within 1e-9) are broken at random. The logged propensity is `ε/K + (1 − ε)/(number tied)` for a tied arm.
- **After:** the next pick for CH-101 came from 5 tied easy arms (the population had learned from the one good "easy" result), with propensity 0.2. Later new children started on different arms (V-10, V-14).

### V-6 Skip, camera mode, face absent, on-device estimate (session CH-101 continued)
| Result sent | Response (hand check) |
|---|---|
| `skipped: true, durationSec 30` | `status skipped`, P 0, E 0.0759 = σ(−1 − 1.5), fused 0.0304, tap 0.5 (no feedback) |
| camera `{facePresentRatio .95, yaw 6°, pitch 6°, eyeOpen .85, smile .3}`, 2/4 successes, half completed, latency 4900 ms, 4 taps in 4 min | mode `camera_logs`, `headMovement 0.3`, `zResponseLatency 2`, `zTapsPerMin −1.25`, E 0.3635 = σ(−0.56); P 0.25 |
| camera `{facePresentRatio 0.1}`, 4/4 | mode `logs`, `faceMissing true`, E 0.8957: an absent face is treated as missing data, not as disengagement |
| `engagementEstimate {score .42, mode camera_logs, modelVersion ondevice-lr-0.1}` | used as sent, `source client`; fused 0.6·0.5 + 0.4·0.42 = 0.468 |

Norms were `population` for every signal, because the child had fewer than 3 earlier activities.

### V-7 Result validation
| Body | Response |
|---|---|
| `{durationSec: 60}` | 422: "targets is required unless the activity was skipped", same for successes |
| `successes 5 > targets 3` | 422 "successes cannot exceed targets" |
| extra key `mood` | 422 "Unrecognized key(s) in object: 'mood'" |
| `parentHelp 7` | 422 "less than or equal to 3" |
| unknown attempt id in the session | 404 `activity_not_found` |
| `GET /sessions/123` / unknown valid id | 422 "must be a 24-character hex id" / 404 `session_not_found` |

### V-8 Completion, TSS and questionnaire
- With one activity still open, `POST /complete` → 200. Activity 6 → `abandoned`, `banditUpdated false`.
- Outcome:
  - `activitiesCompleted 4`, `activitiesSkipped 1`, `activitiesAbandoned 1`;
  - P̄ 0.5 = (0.75 + 0 + 0.25 + 1 + 0.5)/5;
  - Ē 0.5277;
  - no questionnaire, so the weights are re-normalised to `{performance 0.625, engagement 0.375}`, giving **TSS 51** = 100·(0.625·0.5 + 0.375·0.5277);
  - `engagementModes {logs 3, camera_logs 2}`;
  - `fluency.available false`.
- `complete` again → 409 `session_already_completed`; `next-activity` → 409 `session_not_active`.
- Questionnaire:
  - with only 2 answers → 422 `invalid_questionnaire`, listing the 4 missing items;
  - complete answers (mean 3.833) → 201, `q 0.7083`, `engaged true`. The TSS was recomputed to **55**, which is 100·(0.5·0.5 + 0.3·0.5277 + 0.2·0.7083);
  - a second submission → 409 `questionnaire_already_submitted`.

### V-9 C1 link
- **Fluent clip:** uploaded to `/api/c1/assessments` for CH-201 (age 12, passage text) → C1 `completed`, `none_very_mild`, %SS 0.
  - `GET /api/c3/children/CH-201/context?age=12` → `c1Missing 0`, `c1Severity 0`, with `sources.c1.status: available` and the assessment id.
  - A child with no C1 data (CH-999) → `c1Missing 1`, `status missing`.
- **Session flags:** a session started with `c2Flag: yes, cameraOn: true` → context `c2Yes 1`, `c2Missing 0`, `cameraOn 1`.
  - That session's result had no camera features, so engagement used the logs mode.
  - E 0.9025 and TSS 96.3 both match hand checks.
- **Stuttered clip:** for the same child → C1 `severe`, %SS 33.33 (2 blocks, 2 prolongations, 6 sound repetitions).
  - The C3 context then showed `c1Severity 1` (ordinal 3 ÷ 3), `engagementTrend 0.9025` (the previous session's Ē) and `sessionsCompleted 0.05` (1/20).
  - The completed session's `outcome.fluency` was `{percentSS 33.33, previousPercentSS 0, changePP 33.33, trend needs_attention, includedInTss false}`.

### V-10 Learning for one child
CH-301 (age 8) was driven through 8 sessions of 6 activities. Picture description (any difficulty) gets 4/4 successes; every other type gets 0/4. Engagement logs were the same throughout, so the fused reward was 0.95 against 0.35.

| Session | Good picks (λ = 1) |
|---|---|
| 1–3 | 3, 0, 1 of 6: exploring all 18 arms |
| 4 | 5 of 6 |
| 5–8 | 6 of 6, rotating easy/moderate/difficult because the last arm isn't repeated |

A pick plus its result takes about 40 ms.

### V-11 Issue: the pooled prior helped a new child for only 3 picks
- **Observed:** a new child CH-302 in the same band got picture description for its first 3 picks, which is the population's knowledge working. It then explored the other arms (session 2: 1 of 6). With the per-child prior A = I, each untried arm's per-child bonus (0.6·√(xᵀx) ≈ 1.14) outweighed the population's reward gap (≈ 0.6).
- **Fix:** a per-child prior strength λ (A = λI, `C3_CHILD_PRIOR`, default 5). The discounted variant now shrinks towards λI, and migration fills new dimensions with λ.
- **After** (C3 collections cleared, same scenario):
  - CH-301 found the good type in session 2 (5 of 6), then 4–6 of 6 while still exploring now and then;
  - **new child CH-302: 6 of 6 good picks in sessions 1, 2 and 3.**

### V-12 Personalisation against the population
- CH-303 (age 8) likes storytelling, and picture description goes badly for them.
- Session 1: the first 3 picks followed the population (picture description, all bad). From the 4th pick it moved to storytelling.
- Sessions 2–6: 6 of 6 storytelling.
- The per-child part took over from the shared part.

### V-13 Persistence and export
- The API was restarted (process killed and started again).
- `GET /children/CH-303/bandit` → `updates 36`, storytelling arms n = 12/11/10 with mean reward 0.952, `stored true`.
  - The population had 102 updates, and β type terms were `picture_description +0.262`, `storytelling +0.192`, the others ≈ −0.05.
- `?matrices=1` → A 12×12, B 12×45, A0 45×45.
- After the restart, CH-303 was offered storytelling again.
- CH-302 (who had only ever tried picture description) was offered storytelling. That is ordinary UCB exploration: untried by this child, and good for another child according to the population.
- Errors: a fresh child → 200 with an empty arm list; `childId "bad id"` → 422.

### V-14 Discounted policy and shared-matrix bookkeeping
Scenario: a child whose best activity changes from storytelling (sessions 1–4) to breathing (sessions 5–10). C3 state was cleared before each run.

| Policy | Good picks in sessions 5–10 |
|---|---|
| `hybrid` | 29 / 36 |
| `discounted` (γ 0.95) | 31 / 36 |

This is one run each with random tie-breaks, so it shows that the discounted path works, not that it is better. Comparing the policies belongs to the simulator.

After the discounted run, the stored state was dumped from MongoDB and checked offline against Li et al.'s identity, A0 = I + Σzzᵀ − Σ_arms BᵀA⁻¹B and b0 = Σrz − Σ BᵀA⁻¹b. Over 60 updates: max error 1.4e-14 (A0) and 2.1e-14 (b0); A0 smallest eigenvalue 1.0 (positive definite).

### V-15 Within-session advice
Child CH-501 (age 6), planned 25 min, activities of 200 s each.

| Step | Advice after it |
|---|---|
| Low result 1 (E 0.038) | `continue` (low streak 1 activity, 3.33 min) |
| Low result 2 | `offer_break`: "Engagement has been below 0.4 for 2 activities (6.7 min)." |
| `POST /breaks {reason: low_engagement, 120 s}` | 201, `continue` |
| Low result 3 | `parent_led`: "Engagement stayed low after a break; switch to an easy, parent-led activity." |
| Next pick | `5-10:breathing:easy`, `parentLed: true` |
| Good results | `continue` … then `end_session` at 25.33 min |
| `next-activity` | 200 `activity: null`, "The planned 25 minutes have been used." |
| `next-activity {force: true}` | 201, a pick |
| `POST /breaks` with that pick open | 409 `activity_pending` |
| `reason: nap` | 422 |

### V-16 Feature-schema migration
- The stored names were rewritten in MongoDB to imitate an older schema: CH-402 and the population had `legacyTheme` instead of `sessionElapsed`, and `type:legacy` instead of `type:breathing`.
- `GET /children/CH-402/bandit` → 200, `featureVersion 1`, with `migrations [{featureVersion 0, added [sessionElapsed, …, type:breathing], removed [legacyTheme, …, type:legacy]}]`.
- Picks and updates continued, and CH-402's learned breathing preference was kept (n 11 → 13).

**Issue: the migration re-ran on every read.**
- **Observed:** the API log showed `[c3-bandit] migrated population state` and `migrated child CH-402` three times each. Reads (`GET /bandit`, `next-activity`) migrated in memory without saving, until the first bandit update saved.
- **Fix:** `banditStore` saves a migrated document as soon as it is loaded.
- **After:** repeating the same rewrite gave exactly one migration line for the population and one for the child, and the second migration record was stored.

### V-17 Engagement calibration
- With no labelled sessions → 422 `insufficient_calibration_data`, details `{sessions 0, engaged 0, notEngaged 0, minSessions 10}`.
- 16 sessions were driven across 4 children (CAL-1…4), 4 activities each.
  - "Engaged" sessions had good logs and parent ratings 4–5; "not engaged" sessions had poor logs and ratings 1–3.
  - In 2 sessions the parent's rating disagreed with the logs on purpose.
  - TSS ranged from 12.1 to 89.6 and followed the logs and the ratings.
- `{minSessions: 100}` → 422, with `sessions 16`.
- `{minSessions: 10}` → 201, version `c3-engagement-calibrated-…`, `active false`:
  - in-sample: balanced accuracy 0.875, macro-F1 0.875, confusion `{tp 7, tn 7, fp 1, fn 1}`. The two errors are the two mismatched ratings;
  - leave-one-child-out (4 children): balanced accuracy 0.75;
  - the provisional model on the same rows: 0.875.
- The weights were stable between 4,000 and 20,000 epochs (`zResponseLatency −1.38`, `zTapsPerMin +0.75`, `zAttemptsPerTarget +0.52`), so gradient descent had converged.
- Activation: `POST /engagement/model/activate {version}` → 200, `source calibrated`, and the next result was scored with that version. `{version: nope}` → 404; `{version: provisional}` → back to the provisional model.

**Issue: two calibrations in one second collided.**
- **Observed:** two back-to-back calls → 500 `internal_error`. The log showed `E11000 duplicate key … version: "c3-engagement-calibrated-20261015T052625"`.
- **Fix:** the version is now a millisecond timestamp plus a 4-hex random suffix.
- **After:** three back-to-back calls → three 201s with distinct versions.

### V-18 Reports, history and child summary
- **Engagement over time:** `GET /reports/engagement-over-time` covered 139 activities, split by band into 5-minute buckets. For example, 5–10 minute 0–5 had mean E 0.769 (83 activities, 26 sessions). `?ageBand=11-14&bucketMinutes=10` gave one 0–10 bucket (16 activities); `ageBand=4-6` → 422.
- **Replay log:** `GET /reports/replay-log?childId=CH-501&limit=3` → total 8. Each row has the policy, ε, `explored`, the propensity, 18 candidates, 12 feature names with a 12-value x, and all four rewards.
- **History:** `GET /children/CAL-1/sessions?limit=2&offset=1` → `total 5`, 2 items, newest first. `limit=0` and `status=paused` → 422.
- **Summary:** `GET /children/CAL-1/summary` → TSS latest 78.3 against previous 26.4 → `improving` (a change of 5 points or more); engagement over the last 3 sessions `[0.838, 0.168, 0.938]`, mean 0.648; last questionnaire mean 4.5.

### V-19 Double tap on next-activity
- Four `next-activity` requests were sent at the same time on a fresh session.
- Result: one 201 and three 409 `activity_pending`. The session has exactly one open activity.

### V-20 ε-random logging, tap reward, configuration checks
- With `C3_EXPLORE_EPSILON=0.3 C3_REWARD_MODE=tap`, `/health` showed the settings. Over 20 picks:
  - **exploration:** 6 explored;
  - **propensities:** 0.717647 = 0.3/17 + 0.7 for the greedy arm (13 times), 0.017647 = 0.3/17 for a random non-greedy arm (6 times), and 0.716667 = 0.3/18 + 0.7 on the first pick (18 candidates);
  - **tap rewards:** the rewards that updated the bandit were the tap values (`too_hard 0.2`, `just_right 1`, `too_easy 0.55`), with `rewardMode tap`.
- **Configuration checks:** `C3_POLICY=bogus` stops startup with "C3_POLICY must be one of hybrid, discounted (got "bogus")". `C3_ALPHA=-1` stops it with the range message.

### V-21 Contract fixtures and unknown routes
- One realistic session (CH-201, age 12, camera on, `c2Flag: no`, one completed and one skipped activity, then the questionnaire) was run, and its real requests and responses were saved to `contracts/c3/`.
- Final TSS 54.2 = 100·(0.5·0.5 + 0.3·0.4722 + 0.2·0.75).
- `GET /api/c3/nothing-here` → 404 `route_not_found`.

**State at the end:**
- All C3 endpoints in the README were called against the running server, and every formula was hand-checked.
- Four issues were found and fixed (V-5, V-11, V-16, V-17).
- A final run on the finished code, with the default settings (`hybrid`, α 0.6, λ 5, ε 0, `fused`), gave `/api/health` 200 with c1 and c3 `ok`, and a full session to TSS 95.5.
- The verification data stays in the `swara_c3_verify` database. The shared `swara` database was not used.

## Word check (did the child say the word?)

Added after the supervisor asked C3 to detect, for example, a child saying අක්කා when the activity asks for අම්මා.

**Test data:** no child recordings were available, and no Sinhala TTS voice. One shard of OpenSLR SLR52 (adult Sinhala read speech, CC BY-SA 4.0, 11,550 utterances) was used:

- **Word clips:** 516 clips from 250 utterances by 184 speakers, cut halfway to the neighbouring words. Only words the CTC decoded exactly as the reference transcript says were kept, so each clip's true word is known.
- **Catalog words:** 41 clips of the catalog's own words and confusables (අම්මා, මල, තාත්තා, අක්කා, මාළු, ගෙදර, …).
- **Splicing:** stutters were spliced in the same way as for C1 and C4:
  - part-word: the first 130 ms × 2 with 90 ms gaps;
  - prolonged onset: 40 ms tiled to 0.6 s;
  - word repetition: the word, 120 ms, the word.

All of this stayed in a scratch folder outside the repository.

### V-22 First evaluation (300 clips, 2,273 checks)
Each clip was checked as:
- the right word with ordinary alternatives;
- the right word with a near-identical alternative;
- a near-identical wrong word, with and without the true word listed as a confusable;
- an unrelated wrong word;
- the three stuttered forms.

Thresholds were tuned on 76 speakers and reported on the other 77. On the held-out speakers, the right word was never called wrong. Stutters were rarely called wrong, but part-word stutters came back `unclear` 60 of 163 times.

### V-23 Issue: fused stutters; listed confusables passing on the transcript
- **Observed:** for a part-word stutter the ASR writes the repetition and the word as one ("පරපපරපුර", "බවටබවට", "අපිඅපිඅපිඩ"). Maze removal only sees separate tokens, so text similarity fell and the expected word's acoustic fit got worse.
- **Fix 1 (stutter-aware matching):** a heard word may match on its ending when what precedes it is repeats of an opening piece of the word. "කමල" for "මල" still doesn't match, because "ක" is not a piece of "මල". Every candidate is also scored in its stuttered forms (piece + word, piece × 2 + word, word × 2), and each keeps its best.
- **Fix 2:** the transcript alone accepts the word only when no alternative reads at least as well; otherwise the acoustics decide.
- **After (same clips, same speaker split; held-out speakers, calibrated thresholds):**

| Case (held-out speakers) | n | match | mismatch | unclear |
|---|---|---|---|---|
| Right word | 163 | 160 | 0 | 3 |
| Right word, near-identical alternative listed | 141 | 136 | 2 | 3 |
| Part-word stutter of the right word | 163 | 153 | 1 | 9 |
| Prolonged onset of the right word | 163 | 156 | 0 | 7 |
| Word repeated | 163 | 157 | 0 | 6 |
| Wrong word, near-identical, listed as a confusable | 141 | 2 | 139 | 0 |
| Wrong word, near-identical, not listed | 141 | 5 | 103 | 33 |
| Wrong word, unrelated | 163 | 0 | 163 | 0 |
| Noise / near silence | 2 | 0 | 0 | 2 |

- **Thresholds chosen (tune half):** text match 0.8, text mismatch 0.6, margin 0, GOP match 0.4, GOP mismatch 0.8, minimum confidence 0.3. These are now the `C4_VERIFY_*` defaults.
- **Cost used:** calling a right word wrong cost 1.5, the other wrong decision 1, and `unclear` 0.3.
- **Remaining errors:** most are words that differ only by a suffix (ඉන්න / ඉන්නේ, ලංකාව / ලංකාවෙන්, සම්බන්ධයෙන් / සම්බන්ධයෙනුත්), plus two clips the ASR heard badly.

### V-24 The supervisor's case and the API end to end
**Service directly** (`/verify-word`, alternatives මල, අක්කා, තාත්තා), on real clips:

| Said | Expected | Decision | Reason |
|---|---|---|---|
| අම්මා (clip 1) | අම්මා | match | acoustic fit (the ASR wrote "වම්ම") |
| අම්මා (clip 2) | අම්මා | match | transcript matches |
| අක්කා | අම්මා | **mismatch** | අක්කා fits better |
| තාත්තා ×2 | අම්මා | mismatch | තාත්තා fits better |
| මල | අම්මා | mismatch | මල fits better |
| මල ×2 | මල | match | |
| මාළු | මල | mismatch | මාළු fits better |

The first check after a model load took 4.1 s; after that each check took about 0.15 s.

**Through the API** (SP-E-01: අම්මා, මල; age 8):
- **Re-recording:** word 0 said අක්කා gave mismatch. It was re-recorded as අම්මා and gave match, and the latest check counts. Word 1 said මල gave match.
- **Result:** the app reported 1 of 4, but P = 1 (2 of 2 checked words matched), with `verification.source: word_check`. The bandit was updated with reward 0.9523.
- **After the result:** a further check gave 409 `activity_not_pending`. An SLP review gave `affectsScore: false` (kept as ground truth, not re-scored).
- **Review before the result:** අක්කා gave mismatch and noise gave unclear (`no_speech_decoded`). An SLP then reviewed word 0 as match, so P = 1 (1 judged, 1 unclear left out).
- **Mismatch + unclear, no review:** P = 0 (0 of 1 judged).
- **Every word unclear:** fell back to the app's 3 of 4, giving P = 0.75, `source: reported`.
- **No checks:** P = 0.75, as before the change.
- **Skipped:** P = 0 even with a matched check.

**Errors:**

| Request | Response |
|---|---|
| 0.2 s clip | 422 `audio_too_short` |
| `wordIndex` missing | 422 with "wordIndex is required…" |
| `wordIndex` 9 | 422 `unknown_word` with the target words |
| no audio | 422 `audio_required` |
| a text file | 422 `unsupported_audio` |
| a breathing activity | 422 `not_a_word_activity` |
| an `en` session | 422 `language_not_supported` |
| language service stopped | 503 `word_check_unavailable` (results still post, `/api/c3/health` stays `ok` with `wordCheck.languageService: unreachable`) |

- **Fix during the run:** a word check had no id in the session view, so a review couldn't name it. Checks now carry `checkId`.

**Privacy:** `uploads/c3/` was empty after every check, including the failed ones. A file left there was deleted at startup (`c3: … cleaned: 1`).

The contract example, `contracts/c3/word-check.response.example.json`, is the අක්කා-for-අම්මා response.

### V-25 Regressions
- **ASR refactor:** transcribing 12 SLR52 utterances with C4's original code and with the refactored CTC engine gave identical text, word timings and confidences (12 / 12).
- **C4 sample:** a Sinhala recording completed with ASR, measures and C1's %SS.
- **C3:** a full session matched its contract values (P 1, reward 0.9474, TSS 95.1, questionnaire q 0.75).
- `/api/health`: c1, c3 and c4 `ok`. c2 was degraded only because its vision service was not started for this run.

**Limits:**
- Adult read speech, not children.
- Wrong words that are not listed as confusables are often `unclear` rather than `mismatch`, which is safe but means a re-recording.
- The thresholds stay provisional until tuned on reviewed child recordings.


## Engagement camera model (C3 plan, part 1)

*2026-10-20 · Node 24.19.0 · Python 3.11 (vision service, scikit-learn 1.5.2, MediaPipe 0.10.21) · MongoDB 7 · Flutter 3.44.9. Run against the shared `swara` database with new test accounts. The helper scripts (clip cutter, synthetic dataset, request driver) were kept outside the repo.*

**DAiSEE was not available.** It has to be requested through the dataset's Google Form, so the training pipeline was run on stand-ins. The numbers below check the code, not the model.

### V-26 Training pipeline
- **Feature definition:** `app/engagement/features.py` produced the three cases in `contracts/c3/engagement-camera-features.example.json`. One case was checked by hand: absolute-yaw mean 47.5 / 7 = 6.786, look-away 2 of 7 face frames.
- **Extraction:** `build_engagement` ran on a DAiSEE-shaped folder: 8 clips of 10 s, 4 subjects, Train / Validation / Test, label CSVs with DAiSEE's header including its trailing space. The clips were cut from "WikipediansSpeak – Gautam John" (Wikimedia Commons, CC BY-SA 3.0).
  - 8 / 8 clips extracted, 50 frames each at 5 fps, `facePresentRatio` 1.0.
  - 11.6 s with 2 workers.
  - A rerun read all 8 from the cache and extracted none.
- **Training:** `train_engagement` ran on a synthetic set: 1,500 rows, 80 subjects, 7.4 % not engaged, 20 rows without a face.
  - The 20 no-face rows were dropped.
  - 5 subject-grouped folds; 10 Test subjects kept, 0 removed for overlap.
  - Both `--export logistic` and `--export gbdt` wrote a JSON model and a report. (On synthetic data the scores are near 1 and mean nothing.)

### V-27 The API's evaluator and the fused estimate
- **Self-check:** `cameraModel.load()` reproduced scikit-learn's log-odds on all 8 self-check rows, for both the logistic and the gradient-boosting export (150 trees).
- **Issue found:** the first version compared probabilities. A gradient-boosting file with every leaf of tree 0 shifted still passed, because the check rows sat near p = 0.9997. The check now compares log-odds. A shift of 0.01 per leaf is refused: "self-check failed (8.133500 vs 8.133)".
- **Live requests** (provisional camera model, child aged 8, `cameraOn: true`):

| Activity `camera` | Response |
|---|---|
| 3 attentive windows | E 0.9162, `camera_logs`, cameraScore 0.8213, cameraLogit 1.525, windows 3 / 3 |
| 2 looking-away windows (look-away 0.6–0.7, yaw 30–35°) | E 0.628, `camera_logs`, cameraScore 0.4151 |
| 2 windows with a face under 30 % | E 0.8972, `logs`, `faceMissing: true`, windows 0 / 2 |
| older aggregate only (the earlier contract's numbers) | E 0.8621, `camera_logs` (the earlier model gave 0.8685 for the same request) |
| `camera: {}` | 422 "camera needs windows or facePresentRatio" |
| a window with an extra `pixels` field | 422 "Unrecognized key(s) in object: 'pixels'" |

- **Gradient-boosting model, live:** the API restarted with the synthetic gbdt export loaded and scored the same requests: attentive 0.9997, looking away 0.0007, no face → logs. The provisional file was then restored.
- **Session outcome:** complete → `meanEngagement` 0.8259, `engagementModes {camera_logs: 3, logs: 1}`. After the questionnaire, `GET /reports/engagement-pilot-check` gave 1 session with only engaged labels, with the note that the metrics are not meaningful yet. `GET /engagement/model` lists the camera model (`provisional: true`).
- **Fixtures:** `contracts/c3/activity-result.*` and `session.complete.response.example.json` were regenerated from a live request with camera windows.

### V-28 App
- `flutter test test/camera_features_test.dart test/api_adapters_test.dart test/video_analysis_models_test.dart`: 8 / 8 passed.
  - The Dart features match the shared fixture to 1e-6.
  - Windowing: 23.6 s gives 10 s + 10 s + a 3.6 s tail; a 0.8 s tail joins the window before it.
- `flutter analyze`: no new issues in the changed files.
- `flutter build web`: builds. On the web the camera setting is hidden and engagement is scored from the logs.
- **Not run on a phone.** No Android or iOS device was attached. The Android emulator build stopped before compiling any code: `android/settings.gradle` still applies Flutter's Gradle plugin the old way, which Flutter 3.44 rejects. That is a problem in the existing project setup, not in this change. So the ML Kit frame conversion, the camera permission prompt and the "Camera on" badge have not been seen working.

### V-29 On an Android emulator (Pixel-class, API 36, arm64)
- **Build:** `flutter build apk` failed on the old Gradle setup. After migrating to the declarative plugins block (AGP 8.13, Kotlin 2.2.20, Gradle 8.14.3) and moving `record` to 6.2, debug and profile builds both succeed.
- **Setting:** the camera toggle appears on the therapy home, asks for the PIN, and the session is created with `cameraOn: true`.
- **Activity:** starting an activity raises Android's camera permission prompt, and the **Camera on** badge shows during it.
- **What reached the server:** after about 64 s, the result carried `camera.windows` with 7 windows (6 × 10 s + 3.8 s). The emulator's synthetic front camera shows no face, so every window had `facePresentRatio: 0` and null features. The server scored the activity on logs only (`faceMissing: true`, windows 0 / 7). Frames reached ML Kit (a sample is only added after `processImage` returns).
- **Not checked:** detection of a real face. The emulator has none, and the webcam was not used. That still needs a phone.
- **Bug found:** a dark band showed under the activity screens. The badge's `Stack` passed loose constraints to the screen; with `StackFit.expand` the screens fill the page again.

### V-30 App gaps (same emulator, a new 9-year-old account)
| Step | Result |
|---|---|
| C3 feedback card: "A lot" + "Just right" | stored `parentHelp: 2`, `parentFeedback: just_right`; the next pick's context had `parentHelp 0.6667` (2 ÷ 3) |
| Demo mode | no Dart LinUCB left; it walks a fixed activity order |
| C4 first onboarding | the checklist came after the interests; Yes, Yes, Not yet + PIN → `startingLevel: developing` (2 yes) |
| C4 transcript correction (silent recording, empty ASR) | version 2 `corrected` saved and re-measured: 8 words typed, 7 counted (the repeated "mama" removed as a maze); the screen shows "Corrected by parent" |
| C4 band review (after baseline samples added through the API) | "today looks: Gaining"; choosing Stable stored an override, and the band shows "Stable" everywhere |
| C4 personalised / fixed | with 8 earlier sessions the next was `personalised`; the one after was `fixed` (`selection.method: fixed-sequence`) |

### V-31 Replay log with candidate sets
- The API was run with `C3_EXPLORE_EPSILON=0.3` for 3 sessions (18 decisions, 5 explored).
- Each replay-log row now carries `candidateArms`: 18 arms on the first pick, then 17, because the arm just done is left out.
- `node src/modules/c3/evaluation/ope.js replay.json` rebuilt every candidate's context and returned IPS, SNIPS and DR estimates for random and easy-only. With 18 rows these numbers are meaningless; the run only checks the data path.

### V-32 Simulator and evaluation runs
- **Determinism:** the same seed gives identical results (two runs of Hybrid LinUCB, 20 children × 4 sessions, seed 7: reward 0.671813 both times). So the comparisons are paired: every recommender meets the same children.
- **Sanity checks:**
  - the oracle's regret is 0;
  - random is the worst policy on reward;
  - the session-1 regret of the per-child model (0.195) is about twice that of the shared one (0.101), as expected when it starts from nothing.
- **Full run:** `run.js all --seeds 10 --children 80 --sessions 10` took about 9 minutes on 9 worker threads (M2 Pro). The stress test was rerun with harsher conditions, after the first grid found no condition where Hybrid LinUCB lost. It loses to the tap-only LinUCB only when the engagement model is wrong 70 % of the time. Results are in `C3_EVALUATION.md` and `api/src/modules/c3/evaluation/results/`.
- **Smoke run:** 2 seeds, 16 children, 3 sessions; all four experiments and the report ran end to end.

### V-33 Feedback changes: 5-activity sessions, the six-type pool, answer checks, resume, streak and stars (2026-10-20)
- **Session flow through the API** (one child per band, catalog 0.2):
  - both sessions ended after exactly 5 activities (`end_session`, "All 5 activities of today's session are done.", `activitiesDone 5 / maxActivities 5`);
  - no type repeated: 5–10 got word and phrase, reading, picture description, breathing, syllable practice; 11–14 got word and phrase, reading, breathing, syllable practice, picture naming;
  - items carried their new fields: `image` for picture items, `text` for passages, `keywords` for descriptions, `targetWords` for word items;
  - the third activity was posted as skipped: status `skipped`, P 0, counted in the summary (`activitiesSkipped 1`).
- **Resume and expiry:**
  - a second session with an open activity: `GET /children/:id/sessions/active` returned it, with the same pending attempt and item (`activitiesDone 0`);
  - after moving its `createdAt` back 13 hours, the same call returned no session; the history showed it `abandoned`, with `activitiesAbandoned 1`.
- **Summary:** `streakDays 1`, `stars 4` (4 completed activities), `sessionsAbandoned 1`. The context had the new features `c1PercentSS`, `c1Repetition`, `c1BlockProlong`, `c2FG`, `c2HM`.
- **Reading and picture checks on real Sinhala speech** (`POST :8012/check-speech`, 20 SLR52 shard-0 utterances, adult read speech):
  - reading, the clip against its own sentence: share of words read 0.2–1.0 (mean 0.68), against another sentence: 0–0.11 (mean 0.01);
  - keywords, 3 words of the clip's own sentence: found share 0.33–1.0 (mean 0.80); 3 words of another sentence: 0 in every case;
  - the first thresholds (0.7 / 0.4) called 10 correct readings "partial" because of ASR word errors; they were set to **pass 0.5, partial 0.25**: then 18/20 correct readings and 19/20 correct keyword sets match, and every wrong one is a mismatch.
- **API path:** an unrelated clip posted to `speech-check` for a reading item and a picture-description item: 201, `mismatch`, share 0; the result then had P = 0 (`verification.source: speech_check`) although the app claimed full success. A breathing activity refused the check (422 `not_a_speech_check_activity`).
- **Simulator:** `run.js main --seeds 2 --children 40 --sessions 6` ran end to end with the new pool, the 5-activity cap and the type rule. The full `run.js all` was started but stopped part-way (the machine ran low on memory), so `C3_EVALUATION.md` still shows the results of the earlier pool.
- **Contracts:** `contracts/c3/` (session, next activity, result, completion, questionnaire, child summary) were saved again from a real 11–14 session.
- **App:** `flutter analyze` (no errors) and the unit tests passed. The new screens were not driven on the emulator: it was starved of CPU and memory by the parallel runs.
