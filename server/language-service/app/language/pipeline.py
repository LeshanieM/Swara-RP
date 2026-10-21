"""Transcript -> tokens -> mazes -> utterances -> measures."""
from collections import Counter

from app.config import METHOD_VERSION
from app.language import mazes, measures, utterances
from app.language.transcript import align_times, from_timed_words, parse_typed
from app.text.syllables import count_syllables, token_syllables


def analyse_transcript(
    *,
    words: list[dict] | None,
    text: str | None,
    source: str,
    c1_events: list[dict] | None,
    c1_moments: list[dict] | None,
    duration_sec: float | None,
    pause_sec: float,
) -> dict:
    alignment = None
    if text is not None:
        tokens = parse_typed(text)
        if words:
            timed = from_timed_words(words)
            alignment = {"matchedShare": round(align_times(tokens, timed), 3), "asrTokens": len(timed)}
    else:
        tokens = from_timed_words(words or [])

    maze_counts = mazes.apply(tokens, c1_events)
    n_utts, method = utterances.segment(tokens, pause_sec)
    rows = measures.build_utterances(tokens, n_utts, c1_moments)
    values = measures.compute(tokens, rows, duration_sec)

    spoken = [t.norm for t in tokens if not t.unintelligible]
    lexicon = Counter(t.stem for t in tokens if t.is_word)
    forms: dict[str, set] = {}
    for t in tokens:
        if t.is_word:
            forms.setdefault(t.stem, set()).add(t.norm)

    return {
        "methodVersion": METHOD_VERSION,
        "source": source,
        "normalisedText": " ".join(t.norm for t in tokens),
        "cleanText": " ".join(t.norm for t in tokens if t.is_word),
        "tokens": [
            {
                "index": i, "text": t.text, "norm": t.norm, "stem": t.stem,
                "start": t.start, "end": t.end, "confidence": t.confidence,
                "maze": t.maze, "mazeReason": t.maze_reason, "unintelligible": t.unintelligible,
                "utterance": t.utterance, "syllables": token_syllables(t.norm),
                **({"c1Events": t.extras["c1Events"]} if "c1Events" in t.extras else {}),
                **({"reduplication": True} if t.extras.get("reduplication") else {}),
                **({"timingInterpolated": True} if t.extras.get("timingInterpolated") else {}),
            }
            for i, t in enumerate(tokens)
        ],
        "utterances": rows,
        "segmentation": {"method": method, "pauseSec": pause_sec},
        "mazes": {"total": sum(maze_counts.values()), "byReason": maze_counts},
        "measures": values,
        "syllables": {"total": count_syllables(spoken), "words": count_syllables([t.norm for t in tokens if t.is_word])},
        "lexicon": [{"stem": s, "count": c, "forms": sorted(forms[s])} for s, c in sorted(lexicon.items())],
        "alignment": alignment,
        "c1EventsUsed": c1_events is not None,
        "flags": measures.flags(values, method, duration_sec),
    }
