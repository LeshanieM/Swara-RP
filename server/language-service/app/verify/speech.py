"""Did the child read the passage, or talk about the picture? (C3 reading and picture-description activities)

Both checks run on the ASR transcript, with stutter repetitions and fillers removed by the same maze rules as
language samples, so a stutter never counts against the child: this is a content check, not a fluency check.

- **Reading** (``check_reading``): the transcript is aligned with the passage word by word. A passage word counts as
  read when the aligned heard word is the same, or close in spelling (character similarity ≥ READ_WORD_SIMILARITY,
  which absorbs ASR spelling noise). ``wordsReadShare`` = words read ÷ passage words. WER and CER are reported too.
- **Picture description** (``check_keywords``): each keyword the description should mention is "found" when any heard
  word matches it, by stem or by close spelling (a fused stuttered prefix allowed, as in the word check).
  ``foundShare`` = keywords found ÷ keywords.

Decision: ``match`` (share ≥ the pass threshold), ``partial`` (≥ the partial threshold), ``mismatch``, or ``unclear``
when nothing was decoded. The thresholds are provisional (config ``C4_SPEECH_CHECK_*``) until calibrated on children.
"""
import difflib

from app.config import get_settings
from app.evaluation import evaluate
from app.language import mazes
from app.language.transcript import from_timed_words, parse_typed
from app.text.stem import stem
from app.verify.word import similarity, stutter_similarity

READ_WORD_SIMILARITY = 0.75
KEYWORD_SIMILARITY = 0.75
MIN_STEM_PREFIX = 3  # characters a stem must share as a prefix to count (සරුංගල / සරුංගලය)


def _heard_words(words: list[dict] | None, text: str | None) -> list:
    tokens = from_timed_words(words) if words is not None else parse_typed(text or "")
    mazes.apply(tokens)
    return [t for t in tokens if t.is_word]


def _decision(share: float | None, heard: list) -> str:
    s = get_settings()
    if not heard or share is None:
        return "unclear"
    if share >= s.speech_check_pass:
        return "match"
    if share >= s.speech_check_partial:
        return "partial"
    return "mismatch"


def check_reading(reference: str, words: list[dict] | None = None, text: str | None = None) -> dict:
    heard = _heard_words(words, text)
    ref = [t for t in parse_typed(reference) if t.is_word]
    if not ref:
        return {"decision": "unclear", "reason": "empty_reference", "wordsRead": 0, "referenceWords": 0, "wordsReadShare": None}
    a, b = [t.norm for t in ref], [t.norm for t in heard]
    read = set()
    for op, a0, a1, b0, b1 in difflib.SequenceMatcher(a=a, b=b, autojunk=False).get_opcodes():
        if op == "equal":
            read.update(range(a0, a1))
        elif op == "replace":
            for i, j in zip(range(a0, a1), range(b0, b1)):
                if similarity(a[i], b[j]) >= READ_WORD_SIMILARITY:
                    read.add(i)
    share = len(read) / len(ref)
    heard_text = " ".join(b)
    errors = evaluate(" ".join(a), heard_text) if heard else {"wer": None, "cer": None}
    return {
        "decision": _decision(share, heard),
        "wordsRead": len(read),
        "referenceWords": len(ref),
        "wordsReadShare": round(share, 3),
        "missedWords": [a[i] for i in range(len(a)) if i not in read][:50],
        "wer": errors["wer"],
        "cer": errors["cer"],
        "heard": heard_text,
    }


def _keyword_found(keyword: str, heard: list) -> str | None:
    k_norm = parse_typed(keyword)
    if not k_norm:
        return None
    k = k_norm[0].norm
    k_stem = stem(k)
    for t in heard:
        if t.stem == k_stem or t.norm == k:
            return t.norm
        if len(k_stem) >= MIN_STEM_PREFIX and (t.norm.startswith(k_stem) or k.startswith(t.stem) and len(t.stem) >= MIN_STEM_PREFIX):
            return t.norm
        sim, _ = stutter_similarity(k, t.norm)
        if sim >= KEYWORD_SIMILARITY:
            return t.norm
    return None


def check_keywords(keywords: list[str], words: list[dict] | None = None, text: str | None = None) -> dict:
    heard = _heard_words(words, text)
    found = {}
    for kw in keywords:
        hit = _keyword_found(kw, heard)
        if hit is not None:
            found[kw] = hit
    share = len(found) / len(keywords) if keywords else None
    return {
        "decision": _decision(share, heard),
        "keywords": keywords,
        "found": list(found),
        "matchedAs": found,
        "foundShare": round(share, 3) if share is not None else None,
        "heardWords": len(heard),
        "heard": " ".join(t.norm for t in heard),
    }
