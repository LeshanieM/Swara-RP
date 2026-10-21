"""Maze removal: mark fillers and repetitions so they don't inflate word counts.

Rules, applied in order to tokens not already marked:
1. ``filler``: a filled pause from the list below (Sinhala and English), or a
   token that is only a held vowel / "ම්" sound.
2. ``phrase_repetition``: an immediately repeated 2- or 3-word phrase; the
   first copy is the maze.
3. ``part_word_repetition`` / ``word_repetition``: a run of identical tokens.
   If the token after the run starts with the repeated piece and the piece is
   one written syllable or one closed syllable ("බ බ බල්ලා", "දෙන් දෙනවා"), the run is
   a part-word repetition; otherwise
   every copy but the last is a word repetition. A single short fragment before
   a word that starts with it is also a part-word repetition, and so is the
   whole word said just before the fragments ("මම ම ම මම").
   Sinhala reduplication is grammatical ("හෙමින් හෙමින්", "ලොකු ලොකු"), so exactly
   two copies of a word in ``REDUPLICATIVES`` are kept, unless C1 heard a repetition there.
4. ``c1_repetition`` / ``c1_interjection`` (timed tokens only): C1 found a sound or
   word repetition over two or more tokens, and a covered token resembles a word
   after it (prefix, contained, or similarity ≥ C1_SIMILARITY); or an interjection
   over a short token. This catches repetitions the ASR spelled differently,
   which the exact text rules can't see. C1 alone is not enough: on clean read
   speech its provisional detector fires on unrelated neighbouring words.
"""
import difflib

from app.language.transcript import SYLLABLE, Token
from app.text.normalise import AL_LAKUNA, grapheme_count

FILLERS = {
    # Sinhala filled pauses / hesitation sounds
    # (a bare "ආ" is left out: it is also the word "came"; a held "ආආආ" is still caught below)
    "අ", "අං", "අම්", "අම්ම්", "ම්", "ම්ම්", "හ්ම්", "හ්ම්ම්", "ඉ", "ඊ", "එ", "අහ්", "ආහ්", "ඔහ්",
    # English
    "um", "umm", "uh", "uhh", "er", "erm", "hmm", "hm", "mm", "mmm", "ah", "eh",
}
# Words commonly doubled on purpose. Seeded by hand, then extended with the doubled words
# found in fluent SLR52 transcripts (verification log).
REDUPLICATIVES = {
    "හෙමින්", "ඉක්මනට", "ලොකු", "පොඩි", "එක", "එකින්", "ටික", "ටිකෙන්", "මොන", "කොයි", "කවුද", "මොනවා",
    "හොඳ", "අලුත්", "වෙන", "කොච්චර", "එහෙ", "මෙහෙ", "කොහෙ", "නොයෙක්", "අතරින්",
    "යම්", "කර", "එළ", "එල", "එක්", "ඒ", "නියමයි", "තැන", "නැවත", "කෙමෙන්", "හරි", "තව", "දැන්",
    "හිත", "උඩින්", "කට", "දුවලා", "ඉල්ල", "බැණ", "කියව", "බල", "ගිහින්", "ඇවිත්",
}
C1_REPETITION_TYPES = {"sound_repetition", "word_repetition"}
# How alike two spellings must be for a C1-located repetition to be removed.
C1_SIMILARITY = 0.5
MAX_PART_WORD_LETTERS = 2


def _is_filler(norm: str) -> bool:
    if norm in FILLERS:
        return True
    # A held sound typed or decoded as one letter three or more times, e.g. "අඅඅ", "mmmm".
    # Two is not enough: "මම" is the word "I".
    core = norm.replace(AL_LAKUNA, "")
    return len(core) >= 3 and len(set(core)) == 1


def _mark(tok: Token, reason: str) -> None:
    tok.maze, tok.maze_reason = True, reason


def _fragment(norm: str) -> str:
    return norm.rstrip(AL_LAKUNA)


def _short_fragment(piece: str) -> bool:
    """One written syllable (බ, දෙ) or one closed syllable (දෙන්), like a stuttered fragment.

    Longer prefixes are usually partial reduplication (තම තමන්, වඩ වඩාත්), not stuttering.
    """
    if piece.isascii():
        return len(piece) <= MAX_PART_WORD_LETTERS
    units = SYLLABLE.findall(piece)
    return len(units) == 1 or (len(units) == 2 and piece.endswith(AL_LAKUNA))


def _is_part_word(piece: str, nxt: Token | None) -> bool:
    frag = _fragment(piece)
    return bool(
        nxt and frag and nxt.norm != piece and nxt.norm.startswith(frag)
        and len(nxt.norm) > len(frag) and _short_fragment(piece)
    )


def _resembles(piece: str, word: str) -> bool:
    """Loose match for repetitions the ASR spelled differently ("දව" / "ධවදවසෙම", "ලැබු" / "ලැබ")."""
    frag = _fragment(piece)
    if not frag:
        return False
    if word.startswith(frag) or frag in word:
        return True
    return difflib.SequenceMatcher(a=piece, b=word, autojunk=False).ratio() >= C1_SIMILARITY


def _overlap(tok: Token, start: float, end: float) -> float:
    if not tok.timed or tok.end <= tok.start:
        return 0.0
    return max(0.0, min(tok.end, end) - max(tok.start, start)) / (tok.end - tok.start)


def _c1_repetition_at(run: list[Token], events: list[dict]) -> bool:
    return any(
        ev["type"] in C1_REPETITION_TYPES and any(_overlap(t, ev["start"], ev["end"]) > 0 for t in run)
        for ev in events
    )


def apply(tokens: list[Token], c1_events: list[dict] | None = None) -> dict:
    """Mark mazes in place; returns counts per reason."""
    events = c1_events or []
    for tok in tokens:
        if not tok.maze and not tok.unintelligible and _is_filler(tok.norm):
            _mark(tok, "filler")

    # Phrase repetitions (longest first) over the tokens still counted as words.
    for n in (3, 2):
        words = [t for t in tokens if t.is_word]
        i = 0
        while i + 2 * n <= len(words):
            first, second = words[i:i + n], words[i + n:i + 2 * n]
            if [t.norm for t in first] == [t.norm for t in second]:
                for t in first:
                    _mark(t, "phrase_repetition")
                i += n
            else:
                i += 1

    words = [t for t in tokens if t.is_word]
    i = 0
    while i < len(words):
        k = i + 1
        while k < len(words) and words[k].norm == words[i].norm:
            k += 1
        run, nxt = words[i:k], words[k] if k < len(words) else None
        if _is_part_word(words[i].norm, nxt):
            for t in run:
                _mark(t, "part_word_repetition")
            # "මම ම ම මම": the word said before the fragments is repeated after them.
            if i > 0 and words[i - 1].norm == nxt.norm and not words[i - 1].maze:
                _mark(words[i - 1], "word_repetition")
        elif len(run) >= 2:
            grammatical = len(run) == 2 and run[0].norm in REDUPLICATIVES and not _c1_repetition_at(run, events)
            if grammatical:
                run[0].extras["reduplication"] = True
            else:
                for t in run[:-1]:
                    _mark(t, "word_repetition")
        i = k

    for ev in events:
        covered = [t for t in tokens if _overlap(t, ev["start"], ev["end"]) >= 0.5]
        for t in covered:
            t.extras.setdefault("c1Events", []).append(ev["type"])
        if ev["type"] in C1_REPETITION_TYPES and len(covered) >= 2:
            # C1 says where; the text must agree: a word goes only if it resembles a word after it.
            after_event = next((t for t in tokens[tokens.index(covered[-1]) + 1:] if t.is_word), None)
            for k, t in enumerate(covered[:-1]):
                later = covered[k + 1:] + ([after_event] if after_event else [])
                if t.is_word and any(_resembles(t.norm, o.norm) for o in later):
                    _mark(t, "c1_repetition")
        elif ev["type"] == "interjection":
            for t in covered:
                if t.is_word and grapheme_count(t.norm) <= 2:
                    _mark(t, "c1_interjection")

    counts: dict[str, int] = {}
    for t in tokens:
        if t.maze:
            counts[t.maze_reason] = counts.get(t.maze_reason, 0) + 1
    return counts
