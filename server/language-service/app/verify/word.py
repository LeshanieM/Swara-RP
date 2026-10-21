"""Did the child say the expected word? (C3 word activities)

One CTC forward pass gives two signals:

1. **Text:** the greedy transcript, with stutter repetitions and fillers removed by
   the same maze rules as language samples, compared with the expected word by
   character similarity. "අ අ අම්මා" is the right word said with a stutter, so it
   matches: this is a content check, not a fluency check (fluency is C1's job).
   The ASR often fuses a repetition into the word ("පරපපරපුර", "බවටබවට"), so a
   heard word also matches on its ending when everything before it is repeats of
   the word's opening; "කමල" for "මල" does not ("ක" is not a piece of "මල").
2. **Acoustic:** on the frames of the word that is left, how well each candidate
   (the expected word and the alternatives, e.g. the item's other words and
   listed confusables such as අක්කා for අම්මා) explains the audio, as CTC
   negative log-likelihood per frame. Every candidate is also scored in its
   stuttered forms (opening piece + word, piece × 2 + word, word × 2) and keeps
   its best, so a stutter neither hurts the expected word nor favours it over an
   alternative. ``gop`` is the expected word's NLL minus the best free path's NLL
   (0 = fits as well as anything could).

The decision is ``match``, ``mismatch`` or ``unclear``; unclear means the clip
can't be judged (nothing decoded, low confidence, borderline) and the app should
ask for the word again. The thresholds are provisional (config ``C4_VERIFY_*``)
until calibrated on children's recordings.
"""
import time

from app.config import get_settings
from app.language import mazes
from app.language.transcript import SYLLABLE, from_timed_words
from app.text.normalise import normalise_token

# Audio kept either side of the word's decoded span when scoring candidates.
SPAN_PAD_SEC = 0.15
# A stuttered prefix must be this close to repeats of the word's opening (ASR spelling of fragments is noisy).
PREFIX_SIMILARITY = 0.6
# Opening pieces tried as part-word repetitions: up to this many written syllables.
MAX_PIECE_UNITS = 3


def similarity(a: str, b: str) -> float:
    """1 - character edit distance / longer length (0..1)."""
    if not a or not b:
        return 0.0
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return 1 - prev[-1] / max(len(a), len(b))


def _pieces(word: str) -> list[str]:
    """Opening pieces of a word a stutter may repeat: 1..MAX_PIECE_UNITS written syllables, and the whole word."""
    units = SYLLABLE.findall(word)
    pieces = ["".join(units[:n]) for n in range(1, min(MAX_PIECE_UNITS, len(units) - 1) + 1)]
    return pieces + [word]


def stutter_similarity(expected: str, heard: str) -> tuple[float, bool]:
    """Similarity of ``heard`` to ``expected``, allowing a fused stuttered prefix. Returns (similarity, prefix_removed)."""
    best, removed = similarity(expected, heard), False
    bounds = [m.end() for m in SYLLABLE.finditer(heard)][:-1]
    for k in bounds:
        prefix, rest = heard[:k], heard[k:]
        # The prefix must look like one or more repeats of an opening piece of the word.
        if max(similarity(prefix, (p * (len(prefix) // len(p) + 1))[:len(prefix)]) for p in _pieces(expected)) < PREFIX_SIMILARITY:
            continue
        sim = similarity(expected, rest)
        if sim > best:
            best, removed = sim, True
    return best, removed


def stuttered_forms(word: str) -> list[str]:
    """The word plus the forms a stutter gives it: piece + word, piece + piece + word (part-word), word + word."""
    forms = [word]
    for p in _pieces(word):
        forms += [p + word] + ([p + p + word] if p != word else [])
    return forms


def _best_nll(engine, torch, seg, word: str) -> tuple[float, str | None]:
    """Lowest per-frame NLL over the word's stuttered forms, and the form that gave it."""
    best, form = float("inf"), None
    for f in stuttered_forms(word):
        ids = engine.ids_for(f)
        if ids is None:
            continue
        nll = _nll_per_frame(torch, seg, ids, engine.blank_id)
        if nll < best:
            best, form = nll, f
    return best, form


def _nll_per_frame(torch, lp, ids: list[int], blank: int) -> float:
    """CTC negative log-likelihood of one symbol sequence over ``lp`` ([frames, vocab]), per frame."""
    frames = lp.shape[0]
    loss = torch.nn.functional.ctc_loss(
        lp.unsqueeze(1), torch.tensor([ids]), torch.tensor([frames]), torch.tensor([len(ids)]),
        blank=blank, reduction="sum", zero_infinity=False,
    )
    value = float(loss)
    return round(value / frames, 4) if value != float("inf") else float("inf")


def verify(engine, signal, sample_rate: int, expected: str, alternatives: list[str] | None = None) -> dict:
    s = get_settings()
    t0 = time.perf_counter()
    exp = normalise_token(expected)
    alts = []
    for a in alternatives or []:
        n = normalise_token(a)
        if n and n != exp and n not in alts:
            alts.append(n)

    out = {
        "expected": exp, "heard": None, "heardRaw": "", "similarity": 0.0,
        "scores": {"expected": None, "gop": None, "alternatives": []},
        "confidence": None, "span": None, "tokens": [], "reasons": [],
    }

    def done(decision: str, *reasons: str) -> dict:
        out["decision"] = decision
        out["reasons"].extend(reasons)
        out["processingSec"] = round(time.perf_counter() - t0, 2)
        return out

    exp_ids = engine.ids_for(exp)
    if exp_ids is None:
        return done("unclear", "expected_not_in_vocab")

    lp, frame_sec = engine.log_probs(signal, sample_rate)
    words = engine.greedy_words(lp, frame_sec)
    out["heardRaw"] = " ".join(w["word"] for w in words)
    tokens = from_timed_words(words)
    mazes.apply(tokens)
    out["tokens"] = [{"text": t.norm, "start": t.start, "end": t.end, "maze": t.maze_reason} for t in tokens]
    content = [t for t in tokens if t.is_word] or tokens
    if not content:
        return done("unclear", "no_speech_decoded")

    # Text: the best single token, or all remaining tokens joined (a word decoded in two pieces).
    heard_options = [t.norm for t in content] + ([("".join(t.norm for t in content))] if len(content) > 1 else [])
    best = max(((h, *stutter_similarity(exp, h)) for h in heard_options), key=lambda x: x[1])
    out["heard"], out["similarity"] = best[0], round(best[1], 4)
    if best[2]:
        out["reasons"].append("stuttered_prefix_removed")
    confs = [t.confidence for t in content if t.confidence is not None]
    out["confidence"] = round(sum(confs) / len(confs), 4) if confs else None

    # Acoustic: score the candidates on the remaining word's frames.
    start = max(0.0, min(t.start for t in content) - SPAN_PAD_SEC)
    end = min(lp.shape[0] * frame_sec, max(t.end for t in content) + SPAN_PAD_SEC)
    out["span"] = {"start": round(start, 3), "end": round(end, 3)}
    seg = lp[int(start / frame_sec):max(int(start / frame_sec) + 1, int(round(end / frame_sec)))]
    torch = engine._torch
    free = round(float(-seg.max(dim=-1).values.sum()) / seg.shape[0], 4)
    nll_exp, form = _best_nll(engine, torch, seg, exp)
    out["scores"]["expected"] = nll_exp if nll_exp != float("inf") else None
    out["scores"]["expectedForm"] = form
    gop = round(nll_exp - free, 4) if nll_exp != float("inf") else None
    out["scores"]["gop"] = gop

    alt_scores = []
    for a in alts:
        nll, _ = _best_nll(engine, torch, seg, a)
        alt_scores.append({
            "word": a, "nll": nll if nll != float("inf") else None,
            "similarity": round(max(stutter_similarity(a, h)[0] for h in heard_options), 4),
        })
    out["scores"]["alternatives"] = alt_scores
    scored = [x["nll"] for x in alt_scores if x["nll"] is not None]
    margin = None
    if scored and nll_exp != float("inf"):
        margin = round(min(scored) - nll_exp, 4)  # > 0: the expected word fits better than every alternative
    out["scores"]["margin"] = margin
    return done(*decide(out, s))


def decide(out: dict, s) -> tuple[str, str]:
    """The decision and its reason from the measured signals (kept separate so thresholds can be calibrated offline)."""
    sim, conf = out["similarity"], out["confidence"]
    gop, margin = out["scores"]["gop"], out["scores"]["margin"]
    alts = out["scores"]["alternatives"]
    best_alt = max(alts, key=lambda x: x["similarity"], default=None)

    # The transcript alone decides only when no alternative reads at least as well (else the acoustics decide).
    if sim >= s.verify_text_match and not (best_alt and best_alt["similarity"] >= sim):
        return "match", "transcript_matches"
    if margin is not None and margin <= -s.verify_margin:
        winner = min((x for x in alts if x["nll"] is not None), key=lambda x: x["nll"])
        return "mismatch", f"alternative_fits_better:{winner['word']}"
    if best_alt and best_alt["similarity"] >= s.verify_text_match and best_alt["similarity"] > sim:
        return "mismatch", f"transcript_matches_alternative:{best_alt['word']}"
    if gop is not None and gop <= s.verify_gop_match and (margin is None or margin >= s.verify_margin):
        return "match", "acoustic_fit"
    if conf is not None and conf < s.verify_min_confidence:
        return "unclear", "low_confidence"
    if (gop is None or gop >= s.verify_gop_mismatch) and sim < s.verify_text_mismatch:
        return "mismatch", "expected_word_does_not_fit"
    return "unclear", "borderline"
