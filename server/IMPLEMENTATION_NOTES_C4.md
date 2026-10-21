# Swara server, Component 4: implementation notes

*2026-10-17. Paths are relative to `Swara-RP/server/`. The C4 API code is in `api/src/modules/c4/`, and the ML service in `language-service/`. This file records what C4 had to do, where each part lives, the deviations from the C4 plan, the decisions, the changes made because of verification, and the known limits. What was run and seen is in `VERIFICATION_LOG_C4.md`.*

C4's method is **stutter-robust Sinhala language-sample analysis**:

1. a CTC ASR that keeps repetitions;
2. optional human correction;
3. maze removal, helped by C1's timestamps;
4. pause-based utterances;
5. measures.

Around it sit the topic banks with personalised selection, the parent checklist, baseline-relative bands, cross-session new words, spontaneous %SS from C1, and the data for H4c and H4d.

## 1. What C4 had to do, and where it lives

### Topics and onboarding

| Requirement | Implementation |
|---|---|
| Two topic banks (5–10, 11–14), ≥ 20 interest categories × 5 topics, Sinhala, each with a main prompt, 2–3 follow-ups and a level (concrete / open) | `data/topicBank.json`: 2 × 20 × 5 = 200 topics, Sinhala + English, `reviewed: false`. Checked at startup by `services/catalogService.js` (unique ids, levels, 2–3 follow-ups, both languages; it warns if a band has fewer than 20 categories) |
| The child (with a parent for 5–10) ranks 5 favourite categories at onboarding | `PUT /children/:id/profile`: exactly 5 distinct categories from the child's band (`ChildLanguageProfile`, collection `c4_profiles`) |
| One topic per session: age-band filter, then category weights 5:4:3:2:1 skipping last session's category, then level by progress, then least-recently-used. These are weights, not a strict order | `services/topicSelector.js`, two seeded weighted draws (category, then topic). The response holds every candidate's weights and probability plus the seed |
| Level by progress: falling C3 TSS or a C4 "below" band → concrete; otherwise open allowed | `sessionService.levelPolicy`: the latest C4 effective band, the client's `c3TssTrend` and the checklist level |
| Skipping a follow-up moves to the next follow-up; skipping the main prompt moves to the next topic; skips are logged | `POST /sessions/:id/skips`, `POST /sessions/:id/next-prompt`; `LanguageSession.skips[]` |
| Fixed vs personalised topics (H4c) | `mode: fixed` serves `data/fixedTopics.json` (8 everyday topics per band, in order) |

### The analysis pipeline

| Requirement | Implementation |
|---|---|
| CTC ASR that keeps repetitions | `language-service/app/asr/ctc.py`: greedy CTC decoding with word timings from the frames; lazy loading behind `C4_ASR_ENGINE` / `C4_CTC_MODEL` (`asr/registry.py`) |
| Existing Sinhala Whisper fine-tunes as the comparison | `asr/whisper.py` (`engine=whisper`), with word timestamps from the model's alignment heads |
| Optional human correction (SLP or parent edits the transcript) | `PUT /samples/:id/transcript` (`corrected` or `manual`). Every version is kept (`transcripts[]`, `measuresByVersion[]`), and the old timings are aligned onto the new text (`language/transcript.align_times`) |
| Maze / repetition removal by a rule list, aided by C1 event timestamps | `language/mazes.py`: fillers, phrase, word and part-word repetitions, SALT-style marked mazes `( … )`, and C1-located repetitions confirmed by the text |
| Pause-based utterance segmentation | `language/utterances.py`: a ≥ 1.0 s gap (`C4_UTTERANCE_PAUSE_SEC`); typed punctuation and line breaks also split |
| MLU in words, labelled as such | `measures.mluWords`, `mluLabel: "words"` |
| NDW on the first 50 tokens, on lemmas / stems | `measures.ndw50` (null under 50 words) and `ndwAll`, on stems from `text/stem.py` |
| MATTR, window 25 | `measures.mattr25` (on stems) |
| New words per 100 tokens against the child's cumulative lemma set, plus an optional parent checklist of words | `services/vocabularyService.js`; `PUT /children/:id/known-words` |
| New-word safeguards: corrected transcripts, or seen at least twice; the first 2–3 sessions are the starting vocabulary; stem matching | All three, with `C4_BASELINE_SESSIONS=3`. ASR words heard once wait in `pendingStems`. A near-spelling of a known stem counts as `respelled` |
| Text normalisation: NFC; keep ZWJ inside conjuncts; strip stray ZWJ / ZWNJ; strip punctuation and ෴; flag samples under 50 tokens | `text/normalise.py`; flags `unreliable_sample` (< 50 words) and `short_sample` |
| Sample length: ≥ 5 utterances and about 50 words, or 3 minutes; shorter samples kept but flagged | `measures.flags`: `short_sample` unless the audio is ≥ 180 s |

### Levels, the stuttering link, research data and integration

| Requirement | Implementation |
|---|---|
| Three bands relative to the child's own baseline (below / stable / gaining), confirmed by SLP or parent; no age-norm label | `services/bandService.js`: baseline = mean MLU and NDW-50 of the first 3 reliable samples, ±10 % rule; `POST /samples/:id/band-confirmation` (confirm or override) |
| Parent checklist per age band at onboarding sets the starting band; the child never rates themself | `data/checklist.json` (the 3 + 3 items in the plan); `POST /children/:id/checklist` (respondent `parent` or `slp` only) → `startingLevel` |
| Stuttering link: C4 sends its recording to C1's detector and reports spontaneous %SS next to C1's structured-task %SS; C4 supplies the exact syllable count | `services/c1Link.js` calls C1's speech service with the ASR transcript; `stuttering.percentSS(Current)`; `GET /children/:id/summary` shows both |
| H4d: per utterance, length, complexity and whether C1 found a stutter | `analysis.utterances[]` (`wordCount`, `complexity`, `stutter`); `GET /research/h4d` (JSON or CSV) |
| H4c: personalised vs fixed, paired Wilcoxon | `GET /research/h4c` (exact up to 16 pairs, normal approximation with tie and continuity corrections above; checked against scipy) |
| H4a: WER/CER on test clips and repetition retention | `POST /evaluate-asr` in the language service |
| `/analyze-language` sharing the C1 audio upload | `language-service` `POST /analyze-language`; the API uses `/transcribe` + `/measures` so that C1 can run in between (D3) |
| `CommunicationAssessment` extended and actually saved; comparison screens fed by API data | `LanguageSample` (collection `c4_language_samples`) saves everything; `GET /children/:id/progress` gives the series and latest-vs-previous deltas |
| Async job + polling, results saved, lazy model loading | Same pattern as C1: `sampleService` on the shared `JobQueue`, atomic claim, retries, `recover()` on startup |

## 2. Deviations from the plan, and why

| # | Deviation | Why |
|---|---|---|
| D1 | The ASR is a **public XLS-R-300m Sinhala CTC fine-tune**, not the team's MMS adapter | No trained adapter exists yet. A check on Hugging Face confirmed that `mms-1b-all` has no Sinhala adapter. Two public XLS-R Sinhala checkpoints were compared on real SLR52 speech; the better one (`SpideyDLK/…-low-LR-part1`, CER 0.10–0.12 vs 0.23) is the default. It is a CTC model, so the method is unchanged, and the team's model drops in through `C4_CTC_MODEL`. Decided with the user |
| D2 | A **separate `language-service/` (:8012)** instead of a new endpoint in C1's speech service | C1's service stays untouched, and the C1, C2 and C4 branches don't conflict. torch + transformers stay out of C1's lightweight service. It mirrors C2's `vision-service/`. Decided with the user |
| D3 | The API calls `/transcribe` → C1 → `/measures` rather than one `/analyze-language` call | Maze removal needs C1's event timestamps, and C1 needs C4's transcript for the exact syllable count. Splitting the call lets each step feed the next, and lets a correction re-run only the cheap text step. `/analyze-language` still exists for direct experiments |
| D4 | C4 **calls C1's speech service directly** and stores the result in the C4 sample, instead of creating a C1 assessment | Spontaneous speech isn't one of C1's tasks. Creating C1 assessments would mix it into C1's per-task history and summary (the context C3 reads). C1's `speechClient` and response schema are reused, so the C1 contract is still checked. The call uses C1's non-reader scoring (`picture_description`) |
| D5 | After a correction, %SS = C1's stuttered syllables ÷ the corrected syllable count, using a copy of C1's syllable rule in the language service | The audio is deleted after the job (privacy), so C1 can't be re-run. C1 still owns the method: the stutter count comes from C1, and the rule is a copy of C1's (`text/syllables.py`; keep them in step) |
| D6 | The parent checklist sets a **starting level** (emerging / developing / established), not a starting below / stable / gaining band | below / stable / gaining are changes against the child's own baseline, so a single checklist can't place a child in them. The level feeds topic selection (an "emerging" child starts with concrete topics) and stays on the profile as an independent check against the ASR measures |
| D7 | MATTR and NDW are computed on **stems**, and a small **pronoun lemma table** is applied before suffix stripping | NDW must count inflected forms once. Suffix stripping alone merged "මගේ" (my) with "මග" (road) (log V-2) |
| D8 | Authentication came later, with the shared API; "parent mode" routes record who acted (`respondent`, `editedBy`, `by`) | Login (JWT) and the parent-mode PIN now wrap the checklist, known-words, transcript and band routes (`server/README.md`, Auth) |
| D9 | **One sample per session**; a retry is allowed only after a failed sample | The plan's unit is one topic per session. Two samples in one session would count twice in progress and H4c (log V-10) |
| D10 | Topic content is **placeholder** (`reviewed: false`): 200 topics and the checklist wording | Written for development so the full flow and the selection weights can run. An SLP or teacher must check every prompt before use. Topics to look at closely: climate change, people and elephants, online safety, exams, `11-14.adventures-and-challenges.02` |
| D11 | C3's TSS trend is a **request field** (`c3TssTrend`) instead of being read from C3 | C3 lives on another branch. Once the modules are merged, `sessionService.levelPolicy` can read it from C3's summary |

## 3. Design decisions

- **Same structure as C1:** shared plumbing (config, MongoDB, error envelope, validation, `ApiError`, job queue) is reused unchanged. C4 owns only its module, its three collections (`c4_profiles`, `c4_sessions`, `c4_language_samples`), its uploads (`uploads/c4/`) and `language-service/`. The shared files changed are `modules/index.js` (one line), `config/env.js` (C4 variables), `.env.example`, `.gitignore` and `README.md`.
- **Contract checked at the boundary:** the language service's responses are pydantic models (`app/schemas.py`) and the API checks each one against a zod mirror before saving. Real examples are in `contracts/c4/`.
- **Everything derived is recomputed for the whole child.** New words and bands depend on all earlier samples, so after any sample is added, corrected or deleted, the child's samples are replayed oldest first. An early correction therefore fixes all later counts. A sample is marked `completed` only after this recompute (log V-14).
- **Every transcript version is kept** with its own measures, giving the raw ASR vs corrected vs manual comparison (ICC, Bland-Altman) without extra work.
- **Explainable selection:** every session stores the policy, its inputs, each candidate's weights and probability, and the seed, so a choice can be shown to an SLP and reproduced.
- **Privacy:**
  - audio is deleted after every job, successful or not;
  - transcripts are kept, because corrections and new-word history need them;
  - `storedPath` and the upload transcript are never returned.
- **Degrades instead of failing:**
  - C1 down → `stuttering: not_assessed` with the reason;
  - an ASR model that won't load → health says so, and typed transcripts still work;
  - language service down → transient retries, then `failed`; request paths return `503 language_service_unavailable`.
- **Method versioning:** each analysis stores `methodVersion` (`c4-language-0.1`), and each topic bank, checklist and fixed list has a version.

## 4. The rules, in detail

### Mazes (`language/mazes.py`), in order

1. **Fillers:** අ, අම්, ම්, හ්ම්, ඉ, ඊ, එ, … and um / uh, or one letter held 3+ times ("අඅඅ").
2. **Phrase repetitions:** a 2–3 word phrase said twice; the first copy is the maze.
3. **Word and part-word repetitions:**
   - a run of identical words → all but the last;
   - a fragment of one written syllable (or one closed syllable) before a word that starts with it → part-word, and also the whole word said just before the fragments ("මම ම ම මම").
   - Exactly two copies of a known reduplicative ("හෙමින් හෙමින්", "යම් යම්", "කර කර", …) are kept as grammar.
4. **C1-located repetitions:** a word C1 heard a repetition over is removed only if it resembles a word after it (prefix, contained, or similarity ≥ 0.5). C1 alone removed real words on clean speech (log V-14).
5. **Fused ASR repetitions:** "දෙන්දෙන්දෙනවා" and "දෙදෙදෙනා" are split into fragments plus the word before the rules run (ASR tokens only). The split changed 0 of 67,085 real SLR52 words.

### Bands (`services/bandService.js`)

- Reliable samples only (≥ 50 words).
- Baseline = mean MLU and NDW-50 of the first 3 reliable samples.
- Composite = mean relative change: > +10 % gaining, < −10 % below, otherwise stable. The threshold is provisional.
- An override applies only while the computed band is comparable.

### Topic selection (`services/topicSelector.js`)

- **Category:** weights 5:4:3:2:1, and 0 for last session's category. In the long run, blocking repeats gives shares ∝ w(15 − w): about 29 / 26 / 21 / 15 / 8 %. Verified over 400 sessions.
- **Topic within the category:**
  - level weight: 0.2 for open topics when concrete is preferred;
  - least-recently-used rank weight: 1, 0.1, 0.01, …, ranked within each level when concrete is preferred.

## 5. Changes made because of verification

Details are in `VERIFICATION_LOG_C4.md`.

| Log | Problem seen | Change |
|---|---|---|
| V-2 | "මම" ("I") read as a filler | The held-sound rule needs 3+ copies |
| V-2 | "බල්ලා" (dog) counted as a clause link (-ලා) | "-ල්ලා" excluded |
| V-2 | "මගේ" (my) stemmed to "මග" (road) | Pronoun lemma table |
| V-3 | "පොත්" counted as a conditional (-ොත්) | Clause endings only on words of 5+ code points |
| V-5 | A corrector's inserted word swallowed the pause after it | Inserted words get at most 0.4 s |
| V-7 | Empty checklist object shown before answering | No array default |
| V-8 | One combined draw flattened the category shares | Two-stage draw |
| V-8 | Topics repeated inside a category (93 / 400) | Least-recently-used rank weights (3 / 400) |
| V-8 | Concrete policy too weak (open 48 %) | LRU ranked within level (open 16 %) |
| V-10 | A recorded session accepted a second recording | One sample per session (a retry only after failure) |
| V-11 | Whisper baseline crashed (pipeline pops the input dict; list-valued `eos_token_id`) | Fresh input per call; `eos_token_id` fixed in both generation configs; word timestamps enabled |
| V-13 | CTC fused words across sentence pauses (WER 0.575) | A > 0.3 s blank run forces a word boundary (WER 0.411, retention 0.76 → 0.90) |
| V-14 | The C1-aided rule removed real words on clean speech | C1 says where; the text must agree |
| V-14 | Fast part-word repetitions fused into one ASR token were missed | Fused-repetition split (ASR tokens only) |
| V-14 | Maze rules marked 0.29 % of fluent text (reduplication, partial reduplication, "ආ") | Allow-list extended, part-word fragments limited to one syllable, "ආ" dropped (0.10 %, in-sample) |
| V-14 | A sample showed `completed` before its band existed | Recompute first, then mark completed |
| V-15 | ASR misspellings in the baseline made corrected words look new | Near-spelling guard (same first letter, similarity ≥ 0.8) |
| V-16 | An override outlived a recompute that made the sample a baseline sample | Overrides apply only to comparable bands |
| V-18 | Wilcoxon normal approximation ignored ties | Tie-corrected variance (matches scipy) |
| V-20 | A language-service outage on a request path was reported as `database_unavailable` | C4 maps those errors to `language_service_unavailable` |

## 6. Known limitations

- **No child speech was available.** Verification used adult read speech (SLR52) with spliced repetitions. Expect a much higher error rate on children speaking freely; this is why the correction step exists. The plan expects > 40 % WER on stuttering children.
- **ASR quality:**
  - on these one-minute samples the interim CTC model had WER 0.41–0.54 and CER 0.10–0.14;
  - the Whisper fine-tune has the lower error rate (WER 0.31–0.37) but keeps fewer repetitions (0.74 vs 0.89);
  - most kept repetitions are misspelt (exact match about 0.2).
- **C1's provisional detector** reports a block at most sentence pauses in clean read speech, so spontaneous %SS on fluent speech was 5–9 %. That is C1's to calibrate. It also makes the H4d stutter flags noisy until C1 is calibrated or its XLS-R head is used.
- **Stemming is light suffix stripping** plus a pronoun table: irregular forms (e.g. past tenses) stay separate, and some unrelated words can share a stem.
- **Reduplication vs repetition** can't always be told apart from text. Two copies of a word on the allow-list are kept; other doubled words count as mazes unless the transcriber marks otherwise. Echo compounds ("ඇඳුම් පැළඳුම්") can be removed when C1 also fires there.
- **Complexity is a proxy:** 1 + clause links from a word list and verb endings, not a parse.
- **Band thresholds** (±10 %) and the baseline size (3) are provisional and need checking against SLP judgements.
- **Utterance segmentation is pause-only** for ASR transcripts (≥ 1.0 s). Fast talkers can run two utterances together, and long hesitations split one. Typed punctuation in corrections fixes both.
- **Samples over 180 s** get no C1 analysis (C1's limit); the language measures still run (the language service allows 300 s).
- **Single-instance queue,** as in C1: jobs survive restarts, but two API instances would each run their own queue.

## 7. Next steps (outside this task)

1. Train the team's Sinhala CTC model (MMS adapter or XLS-R on SLR52, split by speaker and sentence), set `C4_CTC_MODEL`, and re-run the H4a table (`/evaluate-asr`) on SLR52 test data and the team's child-style clips.
2. SLP / teacher review of `data/topicBank.json` and `data/checklist.json`.
3. Collect corrected and manual transcripts for the ICC study (they are already versioned per sample), and calibrate the band threshold.
4. Fit the H4d logistic regression (grouped by child) on `/research/h4d?format=csv` once C1 is calibrated on child speech.
5. Flutter: done.
   - Onboarding, sessions, recording, polling and the comparison screens are on the API.
   - The parent checklist follows the first onboarding.
   - The transcription screen has a parent correction (`PUT /samples/:id/transcript`, kind `corrected`).
   - The next-session screen confirms or overrides the band.
   - Sessions alternate personalised / fixed (by the child's session count), so `GET /research/h4c` gets pairs.
6. Read C3's TSS trend directly now that the modules share one API (D11).

## Changes after the team's feedback (2026-10-20)

| # | Decision | Reason |
|---|---|---|
| D12 | The familiarity step is removed: the child picks 5 favourite categories **ranked 1st to 5th** (tap order, with a drag-to-reorder list), and that order is saved | The team (and the supervisor) found familiarity impossible to rate, and the app was re-sorting the ranking by it, overriding the child's own order. The server already took only the ranked list |
| D13 | **Every session is personalised**; fixed-topic sessions need `C4_ALLOW_FIXED=1` (otherwise 422 `fixed_sessions_off`) | The feedback asks for one topic per session from the child's interests. The fixed sequence and `/research/h4c` remain for a separate research arm |
| D14 | Topic selection follows the requested priority order, and the server reads every input itself: age group (bank per band) → ranked interests (5:4:3:2:1) → progress (C3's TSS trend read from C3, the C4 band, the checklist: "falling" or "below" prefer concrete topics) → variety and stuttering rate | Before, C3 counted only if the app sent `c3TssTrend` (it never did, and the values didn't match C3's). C1 %SS is now used: a rise of ≥ 2 points between the last two C1 assessments, or the last two C4 samples, prefers concrete topics and steepens the weights towards the top-ranked categories (8:4:2:1:0.5). Every input is stored with the session (`progressSignal`, `selection`) |
| D15 | **No topic repeats until all 25** of the child's topics were used (then a new cycle starts); last session's category stays blocked when another is left | The old rule only made a repeat unlikely. The category can repeat once at the end of a cycle, when only one category has topics left |
| D16 | The recording screen asks for **at least 5 sentences**, asks "keep going?" when the child stops before 30 s, and has **"Skip this question"** for a follow-up the child doesn't understand (logged as a `follow_up` skip). Topics may have 2–4 follow-ups | The feedback asks for 5 sentences and a way to skip a question. The minimum is a prompt, not a block: a short answer is still analysed and flagged |
| D17 | C4's %SS (C1 run on every C4 answer) is shown on the results, comparison and next-session screens and on Progress | It was computed on the server but never shown |
| D18 | Topic bank import/export: `node src/modules/c4/scripts/topicBank.js export|import <file.csv>`, with `data/topicBank.template.csv` | The team's topic bank is a document; a spreadsheet is the easiest way in. Import checks 20+ categories × exactly 5 topics per band, 2–4 follow-ups, both languages, and rebuilds the fixed sequence from the new bank. The bank stays `reviewed: false` until checked |
| D19 | ASR fine-tuning: `language-service/notebooks/c4_01_asr_finetune.ipynb` (SLR52, speaker- and sentence-disjoint splits; continue the current model, XLS-R-300m with a new head, or an MMS-1B adapter) | The plan asks for the team's own model. The export is a normal transformers folder: `C4_CTC_MODEL=<folder>` switches the service (and C3's checks) to it |
