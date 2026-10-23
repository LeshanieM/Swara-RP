"""Language-sample measures and the per-utterance rows for H4d.

All counts use words left after maze removal; "xxx" (unintelligible) never counts.
- MLU in **words** (labelled as such; not morphemes): words ÷ utterances with ≥ 1 word.
- NDW-50: different stems in the first 50 words; null under 50 words. ``ndwAll`` is over every word.
- MATTR-25: mean type-token ratio of every 25-word window (on stems); null under 25 words.
- Complexity proxy per utterance: 1 + clause links (free conjunctions and the
  Sinhala clause-chaining verb endings below). A proxy, not a parse.
"""
from app.language.transcript import Token

NDW_SAMPLE = 50
MATTR_WINDOW = 25
MIN_RELIABLE_WORDS = 50
MIN_UTTERANCES = 5
LONG_SAMPLE_SEC = 180.0

CLAUSE_WORDS = {
    # Sinhala conjunctions and clause links
    "නිසා", "හින්දා", "මොකද", "කියලා", "කියා", "නමුත්", "ඒත්", "හැබැයි", "සහ", "හා", "සමඟ", "වගේම",
    "නම්", "විට", "කොට", "වෙලාවේ", "පස්සේ", "පසු", "කලින්", "තුරු", "නිසාම", "එතකොට", "ඊට", "ඊළඟට",
    # English
    "because", "and", "but", "so", "when", "if", "then", "that", "which", "who", "after", "before", "while",
}
# Non-final verb forms that chain clauses: කරලා (having done), ගියොත් (if goes),
# යද්දී (while going), ආවාම (when came).
CLAUSE_SUFFIXES = ("ලා", "ලාම", "ොත්", "ද්දී", "ාම")
MOMENT_TOLERANCE_SEC = 0.1


def _complexity(words: list[Token]) -> int:
    links = 0
    for t in words:
        # "-ල්ලා" is excluded: it ends nouns such as බල්ලා (dog) far more often than verbs.
        # Short words are skipped: පොත් (books) ends like ගියොත් (if [he] goes).
        chained = (not t.norm.isascii() and len(t.norm) >= 5 and t.norm.endswith(CLAUSE_SUFFIXES)
                   and not t.norm.endswith(("ල්ලා", "ල්ලාම")))
        if t.norm in CLAUSE_WORDS or chained:
            links += 1
    return 1 + links


def _round(x: float | None, nd: int = 3) -> float | None:
    return None if x is None else round(x, nd)


def build_utterances(tokens: list[Token], count: int, moments: list[dict] | None) -> list[dict]:
    rows = []
    for u in range(count):
        toks = [t for t in tokens if t.utterance == u]
        words = [t for t in toks if t.is_word]
        timed = bool(toks) and all(t.timed for t in toks)
        start = min(t.start for t in toks) if timed else None
        end = max(t.end for t in toks) if timed else None
        if moments is None or not timed:
            stutter, n_moments = None, None
        else:
            hits = [m for m in moments
                    if m["start"] < end + MOMENT_TOLERANCE_SEC and m["end"] > start - MOMENT_TOLERANCE_SEC]
            stutter, n_moments = bool(hits), len(hits)
        rows.append({
            "index": u,
            "start": _round(start),
            "end": _round(end),
            "text": " ".join(t.norm for t in toks),
            "cleanText": " ".join(t.norm for t in words),
            "wordCount": len(words),
            "mazeCount": sum(1 for t in toks if t.maze),
            "complexity": _complexity(words),
            "mazeOnly": not words,
            "stutter": stutter,
            "stutterMoments": n_moments,
        })
    return rows


def compute(tokens: list[Token], utterances: list[dict], duration_sec: float | None) -> dict:
    words = [t for t in tokens if t.is_word]
    stems = [t.stem for t in words]
    counted = [u for u in utterances if u["wordCount"] > 0]
    n = len(words)

    mattr = None
    if n >= MATTR_WINDOW:
        windows = [len(set(stems[i:i + MATTR_WINDOW])) / MATTR_WINDOW for i in range(n - MATTR_WINDOW + 1)]
        mattr = sum(windows) / len(windows)

    maze_tokens = sum(1 for t in tokens if t.maze)
    spoken = [t for t in tokens if not t.unintelligible]
    return {
        "mluWords": _round(n / len(counted), 2) if counted else None,
        "ndw50": len(set(stems[:NDW_SAMPLE])) if n >= NDW_SAMPLE else None,
        "ndwAll": len(set(stems)),
        "mattr25": _round(mattr),
        "ttr": _round(len(set(stems)) / n) if n else None,
        "totalWords": n,
        "totalTokens": len(tokens),
        "mazeTokens": maze_tokens,
        "mazeRatio": _round(maze_tokens / len(spoken)) if spoken else None,
        "unintelligibleTokens": sum(1 for t in tokens if t.unintelligible),
        "utteranceCount": len(counted),
        "mazeOnlyUtterances": len(utterances) - len(counted),
        "meanComplexity": _round(sum(u["complexity"] for u in counted) / len(counted), 2) if counted else None,
        "wordsPerMinute": _round(n / (duration_sec / 60), 1) if duration_sec else None,
        "mluLabel": "words",
    }


def flags(measures: dict, method: str, duration_sec: float | None) -> list[str]:
    out = []
    words, utts = measures["totalWords"], measures["utteranceCount"]
    if words == 0:
        out.append("empty_transcript")
    if words < MIN_RELIABLE_WORDS:
        out.append("unreliable_sample")
    long_enough = duration_sec is not None and duration_sec >= LONG_SAMPLE_SEC
    if (utts < MIN_UTTERANCES or words < MIN_RELIABLE_WORDS) and not long_enough:
        out.append("short_sample")
    if method == "single_block" and words > 0:
        out.append("no_utterance_boundaries")
    return out
