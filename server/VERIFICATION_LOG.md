# Swara server, Component 1: verification log

*2026-10-14, macOS, Node 24.19, Python 3.11, MongoDB 7 (Docker).*

V-1 to V-19 were run when the folder was still named `c1-backend/` and the C1 code sat directly in `api/src/`. V-20 re-checks the same behaviour after the restructure. Paths such as `api/uploads/` now mean `api/uploads/c1/`, and `/api/c1/health` still exists next to the new `/api/health`.

Everything below was run against the live services (`speech-service` on :8010, `api` on :5001) with `curl`. Responses are excerpts. No automated tests were written.

**Test audio.** No recordings of stuttered speech were available, so clips were built with macOS `say` (voice Daniel, 16 kHz). Stutter-like events were spliced in at known times:
- *sound repetition:* 3 × the first 120 ms of a word, with 80 ms gaps;
- *word repetition:* the word said 3 times;
- *prolongation:* a 40 ms slice at the loudest point of a word tiled to ~0.8 s;
- *block:* 1 s of silence cut into a word 60 ms after its onset;
- *interjection:* TTS "um" with pauses around it.

The passage clips use the 5-sentence English passage (66 syllables) with 0, 2, 5 or 9 events inserted. Other inputs: a fluent single-utterance sentence, silence, 0.5 s and 200 s clips, a text file named `.wav`, 44.1 kHz stereo, FLAC, OGG, the passages with white noise at 20 and 10 dB SNR, and 27 expressive TTS clips from another project. The generator script was kept outside the repo.

---

### V-1 Startup

- `GET :8010/health` → `status: ok`, `activeDetector: acoustic`, `xlsr: unavailable (dependency_not_installed: torch, transformers)`.
- `GET :5001/api/c1/health` → `200 {"status":"ok","mongo":{"status":"connected"},"speechService":{"status":"ok",...},"queue":{"running":0,"waiting":0,"concurrency":2}}`.

### V-2 Calibration (speech service, frame features)

Frame features were printed for the fluent and spliced clips:
- adjacent-unit DTW similarity was 0.99–1.00 for spliced repeats and at most 0.64 in fluent speech;
- the stable-spectrum run was 0.85 s for the prolongation and at most 0.24 s in fluent speech;
- at a normal pause the level drops by 12–21 dB before the gap, but by 0 dB at a spliced block;
- the share of energy above 2.5 kHz was 0.04 for "um" vs 0.57 for the isolated word "park".

These set the starting thresholds.

### V-3 Issue: the activity threshold fragmented continuous speech

- **Observed:** `fluent_sentence` (one TTS utterance) had threshold −12.7 dB and was split into 6 segments.
- **Cause:** the threshold rule `max(p10 + 0.35·range, p95 − 30)` rises when a clip has little silence.
- **Fix:** `clip(noise + 0.25·range, peak − 40, peak − 20)`.
- **After:** threshold −21.3 dB, 3 segments, 14 syllable nuclei.

### V-4 Issue: a word repetition started one word early

- **Observed:** `word_rep` (truth 1.46–2.65) was detected as `word_repetition 1.14–3.11`.
- **Cause:** at position 1.14 the greedy search accepted a 2-chunk unit ("the park" ≈ "park park") before 1-chunk units were tried at the next position.
- **Fix:** one search pass per unit size, smallest first.
- **After:** `word_repetition 1.46–3.11, confidence 0.975`. The end includes the final fluent "park", which is the target word.

### V-5 Issue: prolongations mislabelled as repetitions

- **Observed:** in `passage_5_stutters` the prolongation (truth 8.43–9.27) came out as `word_repetition 8.31–9.97`.
- **Cause:** the tiled vowel's energy ripple created look-alike "syllables".
- **Fix:** prolongations are detected first, and repetition candidates mostly inside a prolongation are dropped.
- **After:** `prolongation 8.48–9.24`.

### V-6 Issue: false positives in fluent speech

- **Observed:** `passage_0_stutters` (no events) gave `prolongation 0.95–1.36`, `sound_repetition 2.40–2.86` (similarity 0.884) and `word_repetition 6.61–7.16` (0.849). So it reported %SS 4.55 and "mild" for fluent reading.
- **Cause:** every false repetition was exactly one repeat with no break; every true repetition had 3 or more units, similarity ≥ 0.95, or a silent break.
- **Fix:**
  - repetition similarity 0.75 → 0.80;
  - **0.92 required for a single contiguous repeat**;
  - minimum prolongation 0.40 → 0.45 s.
- **After:** zero events on both fluent passages and both fluent sentences, with all true events kept (V-7).

### V-7 Detection and scoring on the final thresholds (`POST :8010/analyze-speech`)

| Clip | Truth | Detected | %SS | Severity |
|---|---|---|---|---|
| fluent_sentence (picture) | – | none | 0 | none_very_mild |
| sound_rep | sound_rep 1.46–2.06 | sound_rep 1.46–1.99 (1.00) | 5.88 | mild (6+2) |
| word_rep | word_rep 1.46–2.65 | word_rep 1.46–3.11 (0.975) | 6.25 | mild (6+3) |
| prolongation | prolong 1.51–2.45 | prolong 1.56–2.42 (0.769) | 6.67 | mild (6+2) |
| block | block 1.52–2.52 | block 1.54–2.51 (1.00) | 6.67 | mild (6+2) |
| interjection | interj 1.66–2.00 | interj 1.66–2.01 (0.784) | **0** (excluded) | none_very_mild |
| passage_0 (reading) | 0 events | 0 | 0 | none_very_mild (0 pts) |
| passage_2 (reading) | 2 | 2, both at the right times | 3.03 | mild (6+3 = 9) |
| passage_5 (reading) | 5 | 5, all types and times right | 7.58 | moderate (8+3 = 11) |
| passage_9 (reading) | 9 | 9 at the right times; 1 prolongation labelled sound_rep | 13.64 | moderate (12+3 = 15) |

- **Monotonic:** severity points rise 0 → 9 → 11 → 15 with the number of stutters.
- **MiMi baseline on the same windows:** 0 % → 23 % → 64 % → 88 % (none → mild → moderate → severe). On the single-event clips it is 100 % = "severe", because they have only 1–2 windows. The event-based %SS doesn't have this short-clip problem (D8).
- **Hand check, passage_5:**
  - 5 moments ÷ 66 passage syllables = 7.576 % → 7.58 ✓ → reading band 5–8 % = 8 pts ✓;
  - the 3 longest moments are 1.30, 0.97 and 0.78 s, mean 1.017 ✓ → band 1–2 s = 3 pts ✓;
  - total 11 → moderate (10–15) ✓.
- **Hand check, passage_9:** 9 ÷ 66 = 13.64 % ✓ → 12 pts; mean of the top 3 (1.63, 1.00, 0.98) = 1.203 ✓ → 3 pts; total 15 → moderate ✓.
- **Processing time:** 5–30 ms for 3–26 s clips; the first request after a start takes about 0.6–1.1 s (library warm-up).

### V-8 Task-aware scoring, transcript, physical term, formats

- **Task-aware scoring:** passage_5 gives the same %SS 7.58 (using the transcript) in both tasks. As `reading` it scores 8 freq pts → moderate (11); as `picture_description` 6 pts → mild (9). Scoring differs by task as intended.
- **Syllable sources:** picture with no transcript: syllables `estimated` 73 → %SS 6.85. Picture with the full transcript: `transcript` 66 → %SS 7.58.
- **Physical term:** `concomitant_score=0.9` → physical 4 pts (round(0.9 × 4)); reading total 15 → moderate; `physicalTermUsed: true`.
- **Formats:**
  - 44.1 kHz stereo WAV → `originalSampleRate 44100, channels 2`, resampled to 16 kHz, same 5 events;
  - FLAC: identical result;
  - OGG: same 5 events (%SS 6.58 from the estimate, because lossy coding shifts the nucleus count).
- **Window scores:** `include_windows=true` returns `windowScores` (2 windows for a 4.35 s clip: 0–3 and 1.354–4.354, the last aligned to the end). Without the flag the field is absent.

### V-9 Speech-service errors, fallbacks, robustness

| Request | Response |
|---|---|
| silence.wav | 422 `silent_audio` |
| 0.5 s clip | 422 `audio_too_short` "Audio is 0.50 s; at least 1 s is required." |
| 200 s clip | 422 `audio_too_long` |
| text file named .wav | 422 `unsupported_audio` |
| reading with no passage_text | 422 `passage_required` |
| task_type=singing / language=fr / concomitant 1.5 / no audio | 422 `validation_error` with the field named |
| `C1_DETECTOR=xlsr` | analysis runs with `detector {name: acoustic-b0, requested: xlsr, fallback: true, fallbackReason: dependency_not_installed}` + warning `detector_fallback` |
| `C1_DETECTOR=bogus` | `fallbackReason: unknown_detector:bogus` |

- **Noise:** passage_0 + noise gave 0 events at both 20 and 10 dB SNR. passage_5 kept all 5 events at 20 dB but **only 2 of 5 at 10 dB** (listed as a limitation).
- **Expressive TTS (27 clips, no transcripts):** 18 had no events. The other 9 had 1–2 events each, mostly in the first second of "apologetic" clips: 4 prolongations, 2 blocks, 3 interjections and 1 word repetition. These are **unverified**: there's no ground truth, and they may be real drawn-out "Oh…"/"Hmm" sounds.

### V-10 Issue: fluent results failed in the API

- **Observed:** `POST /api/c1/assessments` with the fluent passage (age 6) ended as `failed {code: invalid_speech_response, message: "...broke the contract at: primaryType"}`.
- **Cause:** the service used `response_model_exclude_none`, so `primaryType: null` (no stutters) was dropped from the JSON, and the API's contract requires the key.
- **Fix:** use `exclude_unset`; only `windowScores` is omitted when not requested.
- **After:** the same upload completed: `events [] · %SS 0 · none_very_mild · primaryType None`.

### V-11 Issue: a partial transcript inflated %SS without warning

- **Observed:** picture task with a 2-sentence transcript (25 syllables) for a 5-sentence recording (about 87 heard): %SS **36 → severe**, no warning.
- **Fix:** warn with `transcript_mismatch` when transcript syllables ÷ audio estimate falls outside 0.6–1.6.
- **After:** the same request returns `warnings: [transcript_mismatch, short_sample]`. With the full transcript: %SS 13.64 → moderate, no mismatch warning.

### V-12 Tasks endpoint (`GET /api/c1/tasks`)

| Query | Response |
|---|---|
| age=4 / age=15 | 422 `age_out_of_range` "C1 supports ages 5-14" |
| age=5 / age=10 | 200 `ageBand 5-10, picture_description`, 2 pictures, no passages |
| age=11 / age=14 | 200 `ageBand 11-14, reading`, 2 passages |
| age=12&language=si | only `si-reading-village-01` |
| age=7.5 | first run: "age must be a number" (**wrong**) → fixed → "age must be a whole number" |
| (no age) | first run: "age must be a number" (**wrong**) → fixed → "age is required" |
| age=abc | "age must be a number" |

### V-13 Assessment lifecycle through the API

1. `POST /api/c1/assessments` with `passage_5_stutters.wav, childId=CH-001, age=12, passageId=en-reading-school-01` → **202**, `Location: /api/c1/assessments/6acfa581…`, `{"status":"queued","taskType":"reading","ageBand":"11-14"}`.
2. An immediate GET showed `processing`; after about 1.3 s it showed `completed`, `attempts: 1`, `language: en` (taken from the passage).
   - The result matches V-7: 5 events, syllables `{total 66, source passage}`, %SS 7.58, severity `moderate 11/20`, MiMi 64.29 % (9/14 windows), `summary {stutterDetected: true, stutterType: Repetition, severity: Moderate, confidence 0.876}`.
3. `audio.deleted: true`, `deletedAt` set; `api/uploads/` is empty.

**Other uploads**

| Upload | Result |
|---|---|
| Sinhala passage `si-reading-village-01`, age 13 (English audio, so only the syllable path is under test) | `syllables {total 96, source passage}`, %SS 2.08, mild |
| Reading with a free `passageText` (66 syllables) and the 4 s block clip | `warnings: [passage_possibly_incomplete, short_sample]` (15 heard vs 66 in the passage) |

**History, summary and sort order**

- **History:** `GET /children/CH-002/assessments` → `total 5`, newest first, without `events`, `transcript` or `passageText`.
  - `?status=failed&limit=1` → 1 item; `?limit=500` → 422.
- **Summary:**
  - `GET /children/CH-002/summary` → `picture_description {percentSS 13.64, previousPercentSS 36, trend improving, severity moderate, severityOrdinal 2}` and `reading {trend insufficient_data}`.
  - CH-001 reading: 7.58 → 2.08 → `improving`.
  - An unknown child returns `{completedAssessments: 0, latest: null, byTask: {}}`.
- **Change:** some test assessments were created in the same second. Sorting now breaks ties by `_id`, so the order is stable.

### V-14 Issue: reviews overwrote each other

- **Observed:** the SLP review `{referencePercentSS 8.0, slpSeverity moderate}` → 200; then a parent note → 200, and the stored review became `{reviewerRole: parent, notes}`. The SLP's %SS was lost.
- **Fix:** the endpoint is now `POST /:id/reviews` and appends entries.
- **After:** both entries kept (201 each). The old `PATCH …/review` → 404 `route_not_found`.

**Validation checks**

| Request | Response |
|---|---|
| `{reviewerRole: slp}` alone | 422 "Provide at least one of …" |
| unknown key | 422 "Unrecognized key(s)" |
| %SS 150 | 422 |
| malformed JSON | 400 `invalid_json` |
| review of a failed assessment | 422 `assessment_not_completed` |

**Delete:** 200 `{deleted: true}`; then GET → 404 `assessment_not_found`; a second DELETE → 404.

### V-15 API input validation

Every request below was rejected before queuing, and `api/uploads/` was still empty afterwards.

| Request | Response |
|---|---|
| no audio | 422 `audio_required` |
| `.py` file | 422 `unsupported_audio_type` |
| age 4 | 422 `age_out_of_range` |
| no childId / `childId="CH 001;drop"` | 422 `validation_error` (field childId) |
| age 8 + taskType=reading | 422 `task_age_mismatch` "Age 8 (band 5-10) uses the picture_description task" |
| age 12, no passage | 422 `passage_required` |
| unknown passageId | 422 `unknown_passage` |
| passageId + passageText | 422 `ambiguous_passage` |
| passage on the picture task | 422 `passage_not_applicable` |
| unknown pictureId | 422 `unknown_picture` |
| concomitantScore=2 / language=fr | 422 `validation_error` |
| two audio files | 400 `invalid_upload` "Too many files" |
| 6.4 MB with `MAX_UPLOAD_MB=1` | 413 `file_too_large` |
| `/assessments/123` | 422 (id format) · valid but unknown id → 404 · `/api/c1/nothing` → 404 `route_not_found` |

These were accepted (202) and then failed during analysis, each carrying the service's error code: a non-audio `.wav` (`unsupported_audio`), silence (`silent_audio`), 0.5 s (`audio_too_short`) and 200 s (`audio_too_long`). Their audio was deleted.

### V-16 Resilience

**Concurrency cap**
1. Paused the speech service (`kill -STOP`) and posted 5 jobs.
2. `/health` → `degraded`, `queue {running: 2, waiting: 3}`.
3. After `kill -CONT`, all 5 completed. Two started at 15:55:59; the other three started at 15:56:03.95, only after the first two finished.

**Crash recovery**
1. Paused the speech service, posted 3 jobs (2 `processing`, 1 `queued`), then `kill -9` on the API.
2. Deleted the queued job's audio file by hand and restarted the API.
3. Log: `recovered unfinished jobs: { requeued: 2, failed: 1 }`.
4. The 2 jobs completed with `attempts: 2` (%SS 7.58). The third failed with `audio_missing_after_restart`. Uploads were empty afterwards.

**Speech service down**
- First run: the job failed at once with `speech_service_unavailable` (**weak**: a brief outage loses the job).
- Fixed with 3 tries and 2 s / 4 s back-off for transient codes.
- **Outage of about 3 s:** the log shows `retry 1/2 in 2000 ms`, `retry 2/2 in 4000 ms`, and then the job **completed**.
- **Longer outage:** the job fails after the 3rd try with `speech_service_unavailable`.

### V-17 MongoDB down

- **First run:** `docker stop swara-c1-mongo` made `/health` return 503 `degraded`, mongo `disconnected`, but `GET /children/CH-001/summary` returned **500 `internal_error`** (unhelpful).
- **Fix:** connection errors are mapped to **503 `database_unavailable`**.
- **After:** summary → 503 `database_unavailable`; an upload → 503 with no file left in `uploads/`. After `docker start`, mongoose reconnected by itself (health `ok` within about 10 s) and the same requests returned 200.

### V-18 Sinhala syllable counting (hand check)

- **Examples:**

  | Word | Syllables | Count |
  |---|---|---|
  | අම්මා | am-mā | 2 |
  | ක්‍රීඩා | krī-ḍā | 2 |
  | මම පාසල් යනවා | 2 + 2 + 3 | 7 |
  | ආයුබෝවන් | ā-yu-bō-van | 4 |
  | ශ්‍රී ලංකාව | shrī + lan-kā-va | 4 |

  All match the counter.
- **Placeholder passage:** each of its 40 words was printed and checked (e.g. ගුරුතුමිය = 5, කුරුල්ලන් = 3, සෙල්ලම් = 2, දෙයි = 2). The total is 96, which matches the API result in V-13.

### V-19 Final regression via the API

After all the fixes, the six single-event clips were run again through `POST /api/c1/assessments` (child CH-007, age 8). The results were identical to V-7: fluent → none; each type found at its spliced time; the interjection was reported but %SS stayed 0.

**State at the end:** both services running and healthy, and `api/uploads/` empty. Leftover data from before the schema change (one old `review` field) was removed with `$unset`.

### V-20 Restructure into `server/` with a C1 module

**Change:**
- the folder was renamed `c1-backend/` → `server/`;
- the C1 API code moved to `api/src/modules/c1/`, and the generic job queue and `ApiError` moved to `api/src/lib/`;
- components are registered in `modules/index.js`;
- uploads now go to `uploads/c1/`;
- the database is renamed `swara_c1` → `swara` and the Docker container `swara-c1-mongo` → `swara-mongo`.

The Python venv was rebuilt, because venvs hard-code their path. Re-run against the live services:

- **Health:**
  - `GET /api/health` → 200 `{"status":"ok","mongo":{"status":"connected"},"components":{"c1":{"status":"ok","speechService":{...},"queue":{...}}}}`.
  - `GET /api/c1/health` → 200 with the C1 view.
  - `GET /api/c2/health` and `GET /api/c1/nope` → 404 `route_not_found`.
- **Lifecycle (CH-RENAME, age 12, `en-reading-school-01`, `passage_5_stutters.wav`):**
  - 202 with `Location: /api/c1/assessments/<id>`.
  - During the job the file sat in `api/uploads/c1/`.
  - Completed: block 1, prolongation 1, sound repetition 2, word repetition 1, %SS 7.58, `moderate`, `audio.deleted: true`, and `uploads/c1/` empty.
  - History, summary (`severityOrdinal` 2, trend `insufficient_data`), `POST /reviews` (201), `DELETE` (200), then `GET` → 404 `assessment_not_found`.
- **Validation:** age 8 with `taskType=reading` → 422 `task_age_mismatch`, with no file left behind.
- **Speech service stopped:** `/api/health` → 503, with `components.c1.status: "degraded"` and `speechService.error: "ECONNREFUSED"`.
- **Crash recovery:**
  - A picture-task job was queued while the speech service was down, and the API was killed with `kill -9` during its retries.
  - After the restart the log showed `[api] c1: recovered unfinished jobs: { requeued: 1, failed: 0 }`.
  - The job completed (`attempts: 2`, word repetition 1, `mild`), and its audio was deleted.

**State at the end:** both services running and healthy, container `swara-mongo` up, and `api/uploads/c1/` empty.

### V-21 Training notebooks and the trained detector (2026-10-20, smoke set)
SEP-28k was not downloaded, by decision. The notebooks were run on a stand-in with SEP-28k's exact file formats: 160 clips of 3 s in 4 "episodes" (4 macOS voices), with stutters spliced in at known places (sound and word repetitions, prolongations, blocks, "um"). The split is 2 episodes train, 1 dev, 1 test. **The numbers below check the code, not the model.**
- **Real metadata:**
  - `training/sep28k.py` read the real SEP-28k and SEP-28k-E CSVs (5.3 MB, no audio): 385 episodes and 28,177 clips, every clip matched to an episode.
  - Split sizes are train 15,213 / dev 6,402 / test 6,562, as published.
  - After the quality filter (no more than 1 of 3 annotators flagged poor audio, music, no speech, hard to understand or unsure), 14,092 / 5,932 / 6,191 remain.
- **Notebook 1:** 4/4 episodes "downloaded" (local files through the same code path), decoded with PyAV, and 160/160 clips cut.
- **Notebook 2:**
  - acoustic features (51 per clip) took 3 s;
  - XLS-R (`facebook/wav2vec2-xls-r-300m`, layers 6–24) took 42 s on `mps`, including the 1.27 GB model download;
  - a rerun read every chunk from the cache.
- **Notebook 3:**
  - Dev macro-F1 by layer was 0.68–0.86; layer 15 was chosen.
  - Inputs × heads: acoustic logreg 0.49, XLS-R logreg 0.86, both 0.86.
  - Test macro-F1 was 0.83 for the trained head vs 0.49 for the rule-based detector.
  - The head exported. `XlsrDetector.availability()` reported `available`, and `pipeline.analyze` on a test recording with `C1_DETECTOR=xlsr` used `xlsr-head` (`fallback: False`) and produced events and %SS.
- **Notebook 4 inputs:** the UCLASS-style recordings were the smoke episodes renamed `M_0000_06y0m_1.wav` etc., plus one 22-year-old, who was correctly left out by the age filter. `prepare_label_set` sampled 24 clips, 6 per child.
- **Labelling tool:** `tools/label_clips.py` served the page; clips played (`audio/x-wav`); 24 answers were posted and saved in manifest order in `labels_A.csv`. Rater B was made to disagree on 6 clips.
- **Notebook 4 results:**
  - κ per label 0.46–1.0; 18 clips agreed, 6 to resolve.
  - The head and the rule baseline were scored on the agreed clips.
  - The %SS comparison ran on 1 CHAT transcript (child segments from the time bullets) plus 3 CSV rows: correlations, limits of agreement and ICC were computed.
- **CHAT %SS counter:**
  - Checked by hand on the CHAT manual's examples (PWR `↫r-r-r↫`, `s:`, `spa^ghetti`, `≠`, `dog [/] dog`, `<that is a> [/]`, `[//]`, `&-um`, `&+sn`, `[x 3]`): 29 intended syllables, 7 SLDs, 1 phrase repetition and 2 revisions, all as expected.
  - Fixed during the check: phrase repetitions weren't counted (the `>` before `[/]` was skipped), and "laughed" counted as 2 syllables.

### V-22 Feedback fixes: chosen recordings, grouped type, block rule (2026-10-20)
- **Recording formats through the API** (`POST /api/c1/assessments`, child aged 8, picture description):
  - a WAV (8.3 s, macOS `say`) and the same speech saved by `afconvert` as AAC in an `.m4a` both completed (`audio.format` WAV / M4A, 8.36 s from the M4A, decoded by PyAV);
  - an `.aiff` was refused with 422 `unsupported_audio_type`, listing the allowed formats.
- **Grouped type:** a 120 s smoke episode with spliced stutters completed with `summary.stutterType` "Repetition" and `primaryType` `word_repetition`; `GET /api/children` showed "Repetition" for the child.
- **Block rule, before → after** (`acoustic-b0` 0.1.0 → 0.1.1, `block_min_cliff_db` 10, `block_min_cliff_share` 0.5):
  - smoke set (160 clips, 17 with a spliced block): blocks TP 9 / FP 0 / FN 8 before and after; the other labels did not change;
  - fluent TTS passages (36 clips, 6 voices, 5.9 min, no stutters): 0 false blocks before and after;
  - real fluent speech (a 15-minute Wikimedia interview, "WikipediansSpeak – Gautam John", CC BY-SA 3.0, in 30 s pieces): 0 false blocks before and after; 5 other false events (0.33 per minute);
  - **with background noise** (the TTS passages and 5 minutes of the interview, 10.9 min): false blocks **30 → 12** with white noise at 20 dB SNR and **29 → 12** with low-frequency room noise at 20 dB; at 10 dB and with clipping there were none before or after. The remaining 12 are crisp word endings before sentence pauses in TTS speech.
- **Reproduced cause:** at 20 dB SNR the soft tail of a word sits just above the activity threshold and is flat (it is mostly noise), so the last 30 ms looked as loud as the 300 ms before it ("abrupt"). The new rule asks for the speech to stop from near its full level (cliff above the gap's floor).
- **App:** `flutter analyze` clean for the changed files; the picker is the C2 video picker's pattern with audio extensions.
