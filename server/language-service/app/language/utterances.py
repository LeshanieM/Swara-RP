"""Utterance segmentation.

- Timed tokens: a silent gap of at least ``pause_sec`` between two words ends
  an utterance.
- Typed boundaries (sentence punctuation, line breaks) always end one too, so a
  corrected transcript can split or join utterances by editing punctuation.
- Untimed text with no punctuation becomes one utterance and is flagged.
"""
from app.language.transcript import Token


def segment(tokens: list[Token], pause_sec: float) -> tuple[int, str]:
    """Assign ``utterance`` to every token in place. Returns (count, method)."""
    if not tokens:
        return 0, "none"
    timed = all(t.timed for t in tokens)
    typed_breaks = any(t.break_after for t in tokens)
    current = 0
    for i, tok in enumerate(tokens):
        tok.utterance = current
        nxt = tokens[i + 1] if i + 1 < len(tokens) else None
        if nxt is None:
            break
        gap = (nxt.start - tok.end) if timed else 0.0
        if tok.break_after or (timed and gap >= pause_sec):
            current += 1
    if timed and typed_breaks:
        method = "pause+punctuation"
    elif timed:
        method = "pause"
    elif typed_breaks:
        method = "punctuation"
    else:
        method = "single_block"
    return current + 1, method
