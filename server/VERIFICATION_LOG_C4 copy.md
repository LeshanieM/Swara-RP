# Swara server, Component 4: verification log

*2026-10-17, macOS (16 GB, CPU only), Node 24.19, Python 3.11, MongoDB 7 (Docker), torch 2.5.1, transformers 4.47.1.*

Everything below was run against the live services:

- `language-service` on :8012;
- the C1 `speech-service` on :8010 (acoustic detector);
- `api` on :5001.

Requests were sent with small Python `urllib` scripts and `curl`. The scripts and test audio stayed in a scratch folder outside the repo. Responses are excerpts. **No automated tests were written.** Each issue found is logged as observed → cause → fix → result after the fix.

## Test data

- **Hand transcripts.** Small Sinhala transcripts written for this log, with known content:
  - **T1, typed:** whole-word, part-word and phrase repetitions, a filler, Sinhala reduplication, a SALT-style marked maze in round brackets, an ellipsis and ෴.
  - **T2:** the ZWJ/ZWNJ/NFC cases: a proper yansaya, a stray ZWJ, a ZWNJ and a decomposed vowel sign.
  - **T3, timed ASR words:** pauses, a misspelt repetition and C1 events.
  - **T4:** T3 corrected by hand, with one word inserted.
- **Real Sinhala speech.** One shard of OpenSLR SLR52 (`asr_sinhala_0.zip`, 11,550 utterances, 477 speakers, adult read speech, CC BY-SA 4.0), with its reference transcripts.
  - **Samples:** each one-minute sample is 10 (later 14) utterances from one speaker, joined with 1.2–1.8 s pauses into a multi-utterance "monologue" with an exact reference transcript. Six speakers gave samples of 58–104 s.
  - **Stuttered copies:** the clean sample was transcribed once and the CTC words aligned to the reference. At six reference words the ASR got exactly right, the audio was spliced: three whole-word repetitions (word, 120 ms gap, word) and three part-word repetitions (first 130 ms of the word ×2 with 90 ms gaps). The repeated piece was inserted into the reference transcript too.
  - These are **adults reading**, not children speaking freely. They test the pipeline, not clinical accuracy.
- **Other audio.** An English TTS sentence (macOS `say`) for engine loading and the lifecycle, a text file renamed `.wav`, and a `.txt` upload.

---

### V-1 Startup and health

- `GET :8012/health` → `status: ok`, `activeEngine: ctc`, both engines `not_loaded` (lazy).
- `GET :5001/api/health` → `200 status: ok`, Mongo `connected`, `components.c1.status: ok`, `components.c4.status: ok`.
- `c4.topicBank` reports `{5-10: 20 categories / 100 topics, 11-14: 20 / 100}` and 8 fixed topics per band; the bank is checked when the module loads.
- CTC model load took 17 s the first time (7.9 s once cached).

### V-2 Measures on hand transcript T1 (`POST :8012/measures`)

T1: `මම ම ම මම ඊයේ පාසලට ගියා. අ ... මගේ යාළුවා එක්ක සෙල්ලම් කළා! බ බ බල්ලෙක් හෙමින් හෙමින් ආවා. (ඒ ඒ) ඒ බල්ලා ලොකු ලොකු ගල් උඩ පැන්නා ෴ අපි ගෙදර ගියා ගෙදර ගියා.`

Expected by hand: 5 utterances of 4 / 5 / 4 / 7 / 3 words, so MLU 4.6.

| | First run | Cause | Fix |
|---|---|---|---|
| Issue A | "මම" (the word "I") marked as a filler; utterance 1 counted "ම ඊයේ පාසලට ගියා" | The "held sound" rule (one letter repeated) fired on two letters | It now needs 3+ copies ("අඅඅ", "mmm") |
| Issue B | The utterance with "බල්ලා" got complexity 2 | The clause-chaining ending "-ලා" (කරලා, "having done") also ends nouns like බල්ලා (dog) | "-ල්ලා" is excluded |
| Issue C | "මගේ" (my) stemmed to "මග" (road) | Suffix stripping with no pronoun handling | A pronoun lemma table maps the inflected pronoun forms to their base (මගේ / මට / මාව → මම, etc.) |

**After:** utterances 4 / 5 / 4 / 7 / 3, MLU 4.6, NDW (all) 18, all checked by hand. Mazes:

- the whole-word repetition "මම";
- the fragments "ම ම" and "බ බ";
- the filler "අ";
- the marked maze "(ඒ ඒ)";
- the phrase repetition "ගෙදර ගියා".

"හෙමින් හෙමින්" and "ලොකු ලොකු" were kept as grammatical reduplication. The ellipsis did not split the utterance; ෴ did. `unreliable_sample` and `short_sample` were flagged, correctly (23 words).

### V-3 Normalisation (T2)

- The yansaya ZWJ in විද්‍යාව was kept.
- The stray ZWJ in "ගි‍යා" was removed, so it equals "ගියා" (and was caught as a repetition of it).
- The ZWNJ in "පො‌ත" was removed.
- The decomposed "ක + ෙ + ා + ළ" became the composed "කොළ".
- **Issue:** "පොත්" (books) counted as a clause link because it ends like the conditional "-ොත්" (ගියොත්). **Fix:** clause endings only count on words of 5+ code points. After: complexity 1.

### V-4 Timed words with C1 events (T3)

- **Segmentation:** gaps of 1.3 s and 1.7 s gave 3 utterances (method `pause`).
- **Mazes:**
  - "මම ම මම" became 1 word (the part-word fragment plus the word said before it);
  - the misspelt ASR repetition "බලල් බල්ලා" was removed **only** because C1 reported a word repetition over it (`c1_repetition`).
- **Stutter flags:** C1 stutter moments marked utterances 1 and 2 as stuttered and 3 as fluent.
- MLU 3.0 (9 words / 3).

### V-5 Corrected transcript aligned to ASR timings (T4)

- 84.6 % of the typed tokens matched an ASR token and took its timing.
- **Issue:** the inserted word "ලස්සන" was stretched over the whole 1.7 s pause (5.30–7.00 s), so the timing lost the pause.
- **Fix:** an inserted word gets at most 0.4 s after its left neighbour.
- **After:** utterance 2 ends at 5.7 s; the pause survives; method `pause+punctuation`.

### V-6 `/evaluate-asr` by hand

- **Input:**
  - reference "මම ම ම මම … බ බ බල්ලා දැක්කා දැක්කා …";
  - hypothesis "මම ම මම … බල්ලා දැක්කා …".
- **Expected:** 6 repetition tokens in the reference, 3 kept by the hypothesis. **Got:** `referenceRepetitionTokens 6, retained 3, retention 0.5`, WER 0.357, CER 0.246.
- Invalid bodies gave `422 validation_error` with the reason.

### V-7 Catalog and onboarding validation

| Request | Result |
|---|---|
| `GET /catalog/categories?age=8` / `?age=12` | 200, band 5-10 / 11-14, 20 categories each |
| `?age=4`, `?age=15` | 422 `age_out_of_range` |
| `?age=7.5`, `?age=` | 422 "age must be a whole number" / "age is required" |
| `GET /catalog/topics?age=8&category=animals&level=open` | 2 topics (animals.04, .05) |
| Unknown category | 422 `unknown_category` |
| Profile with 5 valid categories | 201, then 200 on update |
| 4 categories / a duplicate / an 11-14 category for age 8 / an extra field (`pin`) / bad `childId` | 422 with the reason (list of allowed ids for the wrong band) |
| Session or profile for an unknown child | 422 `onboarding_required` / 404 `profile_not_found` |
| Checklist: missing item, other band's item, `respondent: child` | 422 `checklist_mismatch` (expected / missing / unknown listed) or `validation_error` |
| Checklist, 1 "yes" of 3 | 201, `startingLevel: emerging` |

- **Issue:** a profile with no checklist showed `"checklist": {"answers": []}`. **Fix:** no default for that array. **After:** `checklist: null` until answered.

### V-8 Topic selection

**First session for ranking [animals, space-and-stars, food, games-and-toys, the-sea-and-beach]:** category probabilities were 0.333 / 0.267 / 0.200 / 0.133 / 0.067, which is exactly 5:4:3:2:1.

**Issue A (100 sessions):** the favourite category fell to 25 %. 18 distinct topics appeared in the first 25 sessions, and one topic came back after 2 sessions.
- **Cause:** one combined draw over 25 topics let recency penalties on the favourite's topics flatten the category weights.
- **Fix:** two seeded draws: category by rank weight, then topic inside it.

**Issue B (400 sessions, fixed seeds):** 93 of 400 draws repeated a topic before all 5 topics of its category had been used.
- **Cause:** linear recency (sessionsSince / 15) was too soft.
- **Fix:** least-recently-used rank weights 1, 0.1, 0.01, ….
- **After:** 3 of 400.

**Issue C:** with the LRU weights, the "concrete" policy (falling C3 TSS) still gave open topics 48 %, because an unused open topic (0.2) outweighed a used concrete one (0.1).
- **Fix:** when concrete topics are preferred, LRU ranks are computed within each level.
- **After:** open share 0.16 with the policy vs 0.26 without.

**Long-run shares (400 sessions):** observed 29.2 / 25.5 / 23.2 / 14.5 / 7.5 %.
- The theory for "never the same category twice in a row" with weights 5:4:3:2:1 is π ∝ w·(15−w) = 29.4 / 25.9 / 21.2 / 15.3 / 8.2 %.
- The same category never came twice in a row.

**Fixed mode:** the 8-topic sequence in order, then it wraps around.

### V-9 Prompts and skips

- `skips {kind: follow_up}` while the main prompt shows → 422 `main_prompt_showing`.
- `next-prompt` → follow-up 0.
- Skipping a follow-up → follow-up 1, then `exhausted`, then 422 `no_follow_up_left`.
- `skips {kind: main_prompt}` → a different topic, `offeredTopicIds` grew, and the prompt reset to the main prompt. `lastCategory` stayed the previous **session's** category, not the skipped topic's.
- After 25 main-prompt skips: 422 `no_topics_left` (all 25 offered).
- The skip log kept the kind, topic, follow-up index, replacement and reason.
- A skip after a recording → 422 `session_already_recorded`.

### V-10 Recording lifecycle with a typed transcript

- **Upload:** T1 typed with the audio → `202 {sampleId, status: queued, transcriptSource: manual}`.
- **Job:** `queued → processing → completed` in 16 s (the C1 model was cold). ASR was skipped (`asr: null`); the measures were identical to V-2; C1 assessed the audio; the audio was deleted and the upload folder emptied.
- **Errors:**
  - no audio → 422 `audio_required`;
  - `.txt` → 422 `unsupported_audio_type`;
  - a text file named `.wav` → 202, then the job `failed` with `unsupported_audio` (the language service's decoder);
  - unknown session → 404.
- **Issue:** a session that already had a completed sample accepted a second recording, so it would count twice in progress and H4c. **Fix:** one sample per session; a retry is allowed only after a failed one. **After:** 422 `session_already_recorded`; the retry after failure → completed.

### V-11 Whisper baseline engine

| Problem seen | Cause | Fix |
|---|---|---|
| 500 on the first call; the retry without language forcing also failed ("dict needs a raw key") | The pipeline pops keys from the audio dict; the retry reused the emptied dict | A fresh dict per call |
| `TypeError: slice indices must be integers` in Whisper's timestamp processor | This checkpoint stores `eos_token_id` as a list (transformers 4.47 needs an int). The first fix changed only the model's config; the pipeline keeps its own copy | Both configs set to the model's `config.eos_token_id` (50257) |

- **After:** both engines work. The checkpoint has alignment heads, so Whisper now returns real **word** timestamps (`wordTimings: "word"`).
- The CTC engine on the English clip gives a Sinhala-script transliteration, as expected for a Sinhala-only model.

### V-12 C1 speech service down

- C4 health stayed `ok` (C1 is optional for C4); the whole-server health is `degraded` through the C1 component.
- A sample completed with `stuttering: {status: not_assessed, reason: {code: speech_service_unavailable}}`; the language measures were unaffected.

### V-13 ASR on real Sinhala speech (H4a check)

Six 10-utterance samples (58–77 s) were each transcribed clean and stuttered, then compared with the reference via `/evaluate-asr`.

| Engine | Clean WER / CER | Stuttered WER / CER | Repetition retention (exact) | Real-time factor |
|---|---|---|---|---|
| CTC (first run) | 0.575 / 0.124 | 0.643 / 0.155 | 0.76 (0.28) | 0.07 |
| Whisper | 0.284 / 0.081 | 0.358 / 0.124 | 0.70 (0.32) | 0.27 |

**Issue:** the CTC word error rate was far above what its character error rate implied. The hypotheses showed words fused across sentence pauses ("වුවාටනමුත්", "දෙකමදෙවැනි").
- **Cause:** the model was trained on single sentences and never emits the word delimiter at a sentence end.
- **Fix:** more than 0.3 s of blank frames between two symbols forces a word boundary.
- **After:**

| Engine | Clean WER / CER | Stuttered WER / CER | Retention |
|---|---|---|---|
| CTC | 0.411 / 0.103 | 0.512 / 0.135 | 0.90 |

**Checkpoint choice:** the second public candidate (`IAmNotAnanth/wav2vec2-large-xls-r-300m-sinhala`) gave clean WER 0.752 / CER 0.230, much worse, so the default stays `SpideyDLK/wav2vec2-large-xls-r-300m-sinhala-low-LR-part1`.

**Final run (V-23, 14-utterance samples, 63–104 s, 54 repetition tokens):**

| Engine | Clean WER / CER | Stuttered WER / CER | Retention (exact) | Real-time factor |
|---|---|---|---|---|
| CTC | 0.500 / 0.124 | 0.537 / 0.138 | **0.889** (0.204) | 0.07–0.09 |
| Whisper | 0.306 / 0.071 | 0.373 / 0.095 | 0.741 (0.259) | 0.29 |

**Reading:** CTC keeps more repetitions (the direction H4a predicts), and the Whisper fine-tune has the lower error rate. Most repetitions are kept but misspelt (exact match 0.2–0.26). That is why C1's timestamps and the human correction step matter.

### V-14 Full pipeline on real audio (`POST /sessions/:id/recordings`)

**Child R-1:** six sessions with the 10-utterance samples: 3 baseline, then counted, mixing stuttered and clean speakers.
- 4–10 s per job for 58–81 s of audio (ASR, C1, measures, vocabulary, bands).
- 10 utterances found in every sample, which is the true count.
- All 6 splices in the stuttered sample became mazes; two of them ("දව", "කටු") only through C1's events.
- **Issue A:** on clean read speech, the C1-aided rule removed 6 real words in one sample ("තිබුණ", "පැෑයිකේන්", "විතර", "හා" …).
  - **Cause:** C1's provisional detector fires on clean read speech, and the rule trusted it alone.
  - **Fix:** C1 says where; the text must agree. A covered word is removed only if it resembles a word after it (prefix, contained, or similarity ≥ 0.5).
  - **After:** 0 false removals in that sample; the true ones ("දව"/"ධවදවසෙම", "සමානම"/"සමාන", "ලැබු"/"ලැබ", "පත්‍රයේි"/"පත්‍රේ") are kept.
- **Note:** samples of 10 SLR52 utterances have 40–48 words, under the 50-word bar, so they were all `unreliable_sample`. The samples were rebuilt with 14 utterances (55–70 words) to exercise NDW-50 and bands.

**Child R-2 (14-utterance samples):** 14–16 utterances per sample.
- **Issue B:** two part-word splices were missed. CTC fused them into one token ("දෙන්දෙන්දෙනවා", "දෙදෙදෙනා") because the 90 ms gaps were shorter than the pause break.
  - **Fix:** fused repetitions are split on ASR tokens only. A closed syllable (ending in al-lakuna) repeated 2+ times before a word starting with it is split off. An open syllable needs 3+ copies, and only the copies beyond two are split off, because real words such as දෙදෙනා ("two people") start with a doubled syllable.
  - **False-positive check:** the split changed **0 of 67,085** distinct words in the full SLR52 transcript list (803,748 tokens).

**Maze rules on fluent text:**
- Run on 9,265 fluent SLR52 sentences (40,277 tokens), the rules first marked 118 tokens (0.29 %). Most were grammatical reduplication ("යම් යම්", "කර කර", "නැවත නැවත", "කෙමෙන් කෙමෙන්"), partial reduplication ("තම තමන්", "වඩ වඩාත්") and "ආ" (also the word "came").
- **Fix:**
  - the reduplicatives found were added to the allow-list;
  - part-word fragments are limited to one written syllable (or one closed syllable);
  - the bare "ආ" was dropped from the fillers.
- **After:** 39 of 40,277 (0.10 %). This figure is **in-sample**: the allow-list additions came from the same sentences.

**Child R-3:** all 6 splices in the stuttered sample were mazes, and the clean sample had no false C1-aided removals.
- **Issue C:** a client polling during the job saw a `completed` sample with no `band` yet. The status was set before new words and bands were recomputed.
- **Fix:** results are written while still `processing`, the child is recomputed including that sample, and only then is it marked `completed`.

**Child R-4:** every completed sample already carries its band and vocabulary.
- Bands: samples 1–3 `baseline_building`, sample 4 (49 words) `not_reliable`, samples 5 and 6 `stable` (MLU +5 % / NDW −3 %; MLU −12 % / NDW −1 %).
- One false C1-aided removal remains: the echo compound "ඇඳුම් පැළඳුම්" ("clothes and such") looks like a repetition (known limitation).

### V-15 Transcript corrections (R-4)

Sample 1 was corrected with the true stuttered reference (`kind: corrected, editedBy: slp`):

- **Versions:** the 200 response has `currentVersion: 2`, and `transcripts` keeps both the `asr` and `corrected` versions.
- **ICC data:** `measuresByVersion` holds v1 asr (MLU 4.40, NDW-50 50, 66 words, %SS 8.48) and v2 corrected (MLU 4.38, NDW-50 48, 70 words, %SS 8.84), the raw vs corrected data the ICC study needs.
- **%SS:** recomputed from C1's 19 stuttered syllables over the corrected 215 syllables (it was 224); C1's original value is kept as `percentSS`.
- **Mazes:** on the corrected text, the text rules alone found all 6 splices (9 maze tokens).
- **Timings:** 36 of 79 tokens interpolated, none left untimed, segmentation `pause+punctuation`.
- **Validation:** empty text, `kind: asr`, `editedBy: child`, a missing `editedBy` → 422; an unknown sample → 404.

**Manual transcript for sample 5:**
- Its new-word count went from 4 to 48–50: a typed transcript is trusted, and this speaker read different sentences from the baseline speakers, so most words really are new to this "child".
- **Issue:** a correctly spelt word whose baseline copy was an ASR misspelling would also count as new. **Fix:** a stem within similarity 0.8 of a known stem (4+ letters) counts as `respelled`, not new.
- The first run merged "ගැනීම" (taking) with "මැනීම" (measuring), which differ only in the first letter, so the first letter must now match too. After: "නගරය"/"නගරයක" and "බෞද්ධ"/"බුද්ධ" are respelled; ගැනීම is not.

### V-16 Band confirmation and override

- **Confirm or override:**
  - confirming a baseline sample → 422 `band_not_available`;
  - a parent confirmation of `stable` → effective `stable`;
  - an override with no band → 422;
  - an SLP override to `gaining` → computed `stable`, effective `gaining`, both entries kept with `computedBand`.
- **Issue:** after an earlier sample was deleted (V-17), that sample became a baseline sample (`computed: baseline_building`) but the old override still made it `gaining`. **Fix:** overrides apply only while the computed band is below / stable / gaining; the history is kept. **After:** effective `baseline_building`, `bandConfirmed: true`.

### V-17 Known words, progress, summary, delete

- **Known words:** `PUT /children/R-4/known-words` with sample 6's two new words plus "බල්ලා", "බල්ලාට" → 3 stems (බල්ලා and බල්ලාට share a stem). Sample 6's new words went 2 → 0; `bySource.parent: 3`. An empty list → 422.
- **Progress:** `GET /progress` gave 6 points (date, topic, mode, transcript version and kind, MLU, NDW-50, words, new words / 100, band computed / effective / confirmed, spontaneous %SS, flags) and the latest-vs-previous deltas.
- **Summary:** `GET /summary` gave `band: stable`, `trend: needs_attention` (MLU −17 % between the last two reliable samples) and the vocabulary totals.
- **C1 next to C4:** after a C1 picture-description assessment was posted for R-4 through C1's own API, the summary showed `structuredTasks.picture_description.percentSS 9.9 (moderate)` next to `spontaneousPercentSS 6.1`.
- **Delete:** deleting baseline sample 3 → `{deleted: true}`, then 404 on a second delete. The next sample became a baseline sample; the vocabulary statuses shifted; the session's `sampleIds` went 1 → 0.

### V-18 Research endpoints

- **H4c:** six children (`H4C-0…5`), each with one personalised and one fixed sample, with typed lengths chosen so the differences were +10, +8, +5, +12, −3, +6 words. Result: `pairedChildren 6, medianDifference 6, W+ 20, W− 1, pOneSided 0.0313, pTwoSided 0.0625, exact`. `scipy.stats.wilcoxon` on the same differences: statistic 20, p = 0.03125 (greater) and 0.0625 (two-sided).
- **Normal approximation:** 20 differences with ties gave p = 0.0036 / 0.0072 vs scipy's 0.00354 / 0.00708.
  - **Cause:** no tie correction in the variance.
  - **Fix:** subtract Σ(t³−t)/48.
  - **After:** 0.0035 / 0.0071.
- **H4d:**
  - `?childId=R-4` gave 75 utterance rows. Utterances longer than the child's own MLU: 26, stutter rate 0.46. Others: 49, rate 0.10.
  - Across 4 children: 311 rows (0.29 vs 0.11).
  - `format=csv` → `text/csv` with a download name and the same rows.
  - `format=xml` → 422.
  - These rates come from C1's provisional detector on spliced adult speech, so they show the plumbing, not a finding.

### V-19 Level policy from the C4 band; queue

- **Below band:** child BELOW-1 had three baseline samples with 6-word utterances (MLU 4.29 / 3.75 / 4.00), then one with 3-word utterances (MLU 2.90) → computed `below` (MLU −27.7 %, composite −13.8 %). The next session had `preferConcrete: true, reasons: [c4_band_below]`, open share 0.11.
- **Checklist emerging:** CH-A (checklist "emerging", no samples) got `reasons: [checklist_emerging]` (V-10).
- **Queue:** three recordings uploaded together ran one at a time (`C4_JOB_CONCURRENCY=1`): processing / queued / queued, then done at 6.9 s, 11.6 s and 15.8 s.

### V-20 Language service down

- C4 health was `degraded` (`languageService: unreachable`).
- An ASR job retried after 2 s and 4 s, then `failed` with `language_service_unavailable`; the audio was deleted. A typed-transcript job failed the same way at the measures step.
- **Issue:** `PUT known-words` while the language service was down returned `503 database_unavailable`.
  - **Cause:** the shared error handler reads "ECONNREFUSED" in any error message as a database outage.
  - **Fix:** C4 converts language-service errors on request paths to their own code.
  - **After:** `503 language_service_unavailable` for both the known-word update and a correction, and the sample was unchanged (`currentVersion` 1).

### V-21 Crash recovery

- Three stuttered recordings were uploaded and the API was killed with one `processing` and two `queued`; their audio was still on disk.
- On restart the log showed `[api] c4: recovered unfinished jobs: { requeued: 3, failed: 0 }`.
- All three completed: the interrupted one with `attempts: 2`, the others with 1. The upload folder was empty afterwards.

### V-22 MongoDB down

- `docker stop swara-mongo`: `GET /children/R-4/progress` → `503 database_unavailable`; `/api/c4/health` → `degraded`, Mongo `disconnected`.
- After `docker start`, the same request returned 200 without restarting the API.

### V-23 Contracts and final re-run

- **Contracts:** real responses saved in `contracts/c4/`: `/transcribe` and `/analyze-language` on a stuttered SLR52 sample, and `/measures` on T3 (request and response). All parse with the API's zod mirror (`validation/schemas.js`).
- **`/analyze-language` directly:** audio → 200; nothing sent → 422 `input_required`; bad `c1_events` → 422; a transcript only → 200 with `transcription: null`.
- **Final re-run** after all fixes:
  - onboarding and catalog validation (V-7) unchanged;
  - selection on a fresh child: first-session probabilities 5:4:3:2:1, no category twice in a row, concrete policy open share 0.16;
  - T4 correction unchanged;
  - the ASR table in V-13.

### V-24 Feedback changes: ranked interests, selection priorities, topic cycle, topic-bank import, ASR fine-tuning (2026-10-20)
- **Selection** (child aged 8, 5 ranked categories, 27 sessions through the API):
  - the first 25 topics were all different; the 26th and 27th started a new cycle (`selection.cycle`: 25 topics, remaining 25 → 24);
  - each of the 5 categories got exactly 5 topics; the same category came twice in a row once, at the end of the cycle when only one category had topics left;
  - `progressSignal.inputs` held the C3 trend (read from C3), its source, the stuttering trend (C1 and C4) and the checklist level.
- **C3 and C1 inputs:**
  - with C3 TSS 85 → 62 seeded, a new session had `c3TssTrend: falling` (source `c3`), reason `c3_tss_falling`, `preferConcrete: true`;
  - with C1 %SS 4 → 8 seeded, the reason was `stuttering_rising` and the rank weights 8:4:2:1:0.5.
- **Fixed sessions:** `mode: fixed` → 422 `fixed_sessions_off`. **Follow-up skip:** after the main prompt, `skips {kind: follow_up}` was logged (index 0) and the next follow-up showed.
- **Topic bank:** `topicBank.js export` wrote 200 topics; `import` of that CSV rebuilt the bank with identical content (categories, topics, levels, prompts, follow-ups). A CSV with missing columns and one with 1 category of 3 topics were refused with the reasons. The original files were restored afterwards.
- **Overall progress** (`GET /api/children/:id/progress`, C1 %SS histories seeded): 2 points → `insufficient_data`; 9, 8.5, 9, 6, 5.5, 5 → `improved` (−3.33); 4, 4.5, 4, 7, 8, 7.5 → `needs_attention` (+3.33); 6–6.5 → `no_clear_change`; the improved history with C3 TSS 80 → 60 → `no_clear_change` with the reason. Another child's account got 403.
- **ASR fine-tuning:**
  - SLR52 shard 0 (asr_sinhala_0.zip, 915 MB) and the index were downloaded to the external drive;
  - `training/slr52.py` read the index (185,293 utterances; 11,550 on disk) and split shard 0 into train 8,896 / dev 647 / test 614 utterances (429 / 24 / 24 speakers), with no speaker or sentence shared between splits (1,393 train utterances dropped because their sentence is in dev or test);
  - the notebook's smoke run (current model, 10 steps on 64 utterances) was started but stopped by the system for low memory before it finished, while the simulator and the emulator were running too. **Training and evaluation are not verified yet.**
- **App:** `flutter analyze` (no errors); `api_adapters_test.dart` passes with the familiarity fields removed. The screens were not driven on the emulator (see C3 V-33).

## Not verified

- **Real children.** No recordings of Sinhala-speaking children (or any children who stutter) were available. Everything ran on adult read speech with spliced repetitions, which are cleaner than real stuttering.
- **Formats other than WAV.** Every upload to the service was 16 kHz WAV (the SLR52 FLAC files were converted by the test script). FLAC, OGG and MP3 go through the same libsndfile loader as C1 (whose log covers FLAC and OGG), but weren't sent to C4.
- **The team's own CTC model:** it doesn't exist yet; the fine-tuning notebook exists (V-24) but has not finished a run. The engine accepts any wav2vec2-CTC Hugging Face id or local path through `C4_CTC_MODEL`; two public checkpoints were tested.
- **Samples longer than 180 s:** C1 rejects them, so their stuttering would be `not_assessed` (configured limit; not run).
