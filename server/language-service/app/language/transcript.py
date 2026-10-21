"""Turn a transcript (timed ASR words or typed text) into tokens.

Typed transcripts (human correction or fully manual) may use two SALT-style marks:
- text in round brackets is a maze the transcriber marked, e.g. "(ම ම) මම ගියා";
- "xxx" is an unintelligible word; it is kept but never counted as a word.
Sentence-ending punctuation (. ? ! ।) and line breaks end an utterance.

When a typed transcript replaces an ASR transcript, ``align_times`` copies the
ASR word timings onto the typed tokens, so pause-based utterances and C1 event
overlaps still work after a correction.
"""
import difflib
import re
from dataclasses import dataclass, field

from app.text.normalise import UNINTELLIGIBLE, normalise_token, tokenize
from app.text.stem import stem

_UTTERANCE_END = re.compile(r"[.?!।෴\n]+")
# Time given to each word a corrector inserted where the ASR heard nothing.
INSERTED_WORD_SEC = 0.4
# An ellipsis marks a pause inside an utterance, not its end.
_ELLIPSIS = re.compile(r"\.{2,}|…")
_PAREN = re.compile(r"\(([^()]*)\)")


@dataclass
class Token:
    text: str
    norm: str
    stem: str
    start: float | None = None
    end: float | None = None
    confidence: float | None = None
    maze: bool = False
    maze_reason: str | None = None
    unintelligible: bool = False
    break_after: bool = False  # a typed utterance boundary follows this token
    utterance: int | None = None
    extras: dict = field(default_factory=dict)

    @property
    def is_word(self) -> bool:
        return not self.maze and not self.unintelligible

    @property
    def timed(self) -> bool:
        return self.start is not None and self.end is not None


def _make(norm: str, text: str | None = None, **kw) -> Token:
    return Token(text=text or norm, norm=norm, stem=stem(norm), unintelligible=norm == UNINTELLIGIBLE, **kw)


# A Sinhala written syllable: a base letter plus its vowel signs, al-lakuna and ZWJ.
SYLLABLE = re.compile(r"[\u0D80-\u0DFF](?:\u200D[\u0D9A-\u0DC6]|[\u0DCA-\u0DDF\u0D82\u0D83\u200D])*|.", re.S)


def split_fused(token: str) -> list[str]:
    """Split a part-word repetition the ASR fused into one word.

    Short repetitions ("දෙ-දෙ-දෙනා") often decode with no word break. Real words
    can start with a doubled syllable (දෙදෙනා, "two people"), so:
    - a closed syllable (ending in al-lakuna) repeated 2+ times before a word
      that starts with it is split off: දෙන්දෙන්දෙනවා -> දෙන් දෙන් දෙනවා;
    - an open syllable needs 3+ copies, and only the copies beyond two are split:
      දෙදෙදෙනා -> දෙ දෙදෙනා.
    """
    units = SYLLABLE.findall(token)
    if len(units) < 3 or token.isascii():
        return [token]
    # The repeated piece is one written unit (දෙ) or two when it is a closed syllable (දෙ + න් = දෙන්).
    for n in (2, 1):
        piece = "".join(units[:n])
        k = 0
        while units[k * n:(k + 1) * n] == units[:n]:
            k += 1
        rest = "".join(units[k * n:])
        if not rest:
            continue
        if piece.endswith("්"):
            if k >= 2 and rest.startswith(piece[:-1]) and len(SYLLABLE.findall(rest)) >= 2:
                return [piece] * k + [rest]
        elif n == 1 and k >= 3:
            return [piece] * (k - 2) + [piece * 2 + rest]
    return [token]


def from_timed_words(words: list[dict]) -> list[Token]:
    """ASR words -> tokens. A word that normalises into several tokens shares its time span evenly."""
    tokens: list[Token] = []
    for w in words:
        parts = [p for part in tokenize(w["word"]) for p in split_fused(part)]
        if not parts:
            continue
        start, end = w.get("start"), w.get("end")
        step = (end - start) / len(parts) if start is not None and end is not None else None
        for k, part in enumerate(parts):
            tokens.append(_make(
                part, text=w["word"] if len(parts) == 1 else part,
                start=None if step is None else round(start + k * step, 3),
                end=None if step is None else round(start + (k + 1) * step, 3),
                confidence=w.get("confidence"),
            ))
    return tokens


def parse_typed(text: str) -> list[Token]:
    """Typed transcript -> tokens with marked mazes and typed utterance boundaries."""
    tokens: list[Token] = []
    text = _ELLIPSIS.sub(" ", text)
    pos = 0
    pieces: list[tuple[str, bool]] = []
    for m in _PAREN.finditer(text):
        pieces.append((text[pos:m.start()], False))
        pieces.append((m.group(1), True))
        pos = m.end()
    pieces.append((text[pos:], False))

    for chunk, marked in pieces:
        segments = _UTTERANCE_END.split(chunk)
        for s_idx, segment in enumerate(segments):
            for part in tokenize(segment):
                tok = _make(part)
                if marked:
                    tok.maze, tok.maze_reason = True, "marked"
                tokens.append(tok)
            # A punctuation mark or newline between segments closes the utterance.
            if s_idx < len(segments) - 1 and tokens:
                tokens[-1].break_after = True
    return tokens


def align_times(typed: list[Token], timed: list[Token]) -> float:
    """Copy timings from ``timed`` onto ``typed`` in place. Returns the share of typed tokens matched exactly."""
    if not typed or not timed:
        return 0.0
    matcher = difflib.SequenceMatcher(a=[t.norm for t in timed], b=[t.norm for t in typed], autojunk=False)
    matched = 0
    for op, a0, a1, b0, b1 in matcher.get_opcodes():
        if op == "equal":
            for k in range(b1 - b0):
                src, dst = timed[a0 + k], typed[b0 + k]
                dst.start, dst.end, dst.confidence = src.start, src.end, src.confidence
                matched += 1
        elif op in ("replace", "insert"):
            # Spread the typed tokens evenly over the time the replaced ASR words took,
            # or over the gap between their timed neighbours for an insertion.
            n = b1 - b0
            if op == "replace":
                span_start, span_end = timed[a0].start, timed[a1 - 1].end
            elif a0 > 0:
                # An inserted word follows its left neighbour closely, so a real pause after it survives.
                span_start = timed[a0 - 1].end
                limit = timed[a0].start if a0 < len(timed) else None
                span_end = None if span_start is None else span_start + INSERTED_WORD_SEC * n
                if limit is not None and span_end is not None:
                    span_end = min(span_end, limit)
            else:
                span_end = timed[0].start
                span_start = None if span_end is None else max(0.0, span_end - INSERTED_WORD_SEC * n)
            if span_start is None or span_end is None:
                continue
            step = max(span_end - span_start, 0.0) / n
            for k in range(n):
                dst = typed[b0 + k]
                dst.start = round(span_start + k * step, 3)
                dst.end = round(span_start + (k + 1) * step, 3)
                dst.extras["timingInterpolated"] = True
    return matched / len(typed)


def normalised_text(tokens: list[Token]) -> str:
    return " ".join(t.norm for t in tokens)


__all__ = ["Token", "from_timed_words", "parse_typed", "align_times", "normalised_text", "normalise_token"]
