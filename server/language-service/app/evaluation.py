"""ASR evaluation for H4a: error rates and repetition retention.

Repetition retention: the reference (a hand transcript that keeps every
repetition) is run through the same maze rules; each repetition token found
there (part-word, word or phrase repetition) is "retained" if the aligned
hypothesis has a token in that position, i.e. the ASR did not delete it.
An exact-match rate is reported next to it, because a kept-but-misspelt
repetition still shows the stutter but may not be removed as a maze.
"""
import difflib

import jiwer

from app.language import mazes
from app.language.transcript import parse_typed
from app.text.normalise import normalise_text

REPETITION_REASONS = {"part_word_repetition", "word_repetition", "phrase_repetition"}


def evaluate(reference: str, hypothesis: str) -> dict:
    ref_norm, hyp_norm = normalise_text(reference), normalise_text(hypothesis)
    ref_tokens, hyp_tokens = parse_typed(reference), parse_typed(hypothesis)
    mazes.apply(ref_tokens)
    mazes.apply(hyp_tokens)

    rep_idx = [i for i, t in enumerate(ref_tokens) if t.maze_reason in REPETITION_REASONS]
    matcher = difflib.SequenceMatcher(a=[t.norm for t in ref_tokens], b=[t.norm for t in hyp_tokens], autojunk=False)
    kept, exact = set(), set()
    for op, a0, a1, b0, b1 in matcher.get_opcodes():
        if op == "equal":
            exact.update(range(a0, a1))
            kept.update(range(a0, a1))
        elif op == "replace":
            # A substitution keeps a token in the slot; count up to as many as the hypothesis supplied.
            kept.update(range(a0, a0 + min(a1 - a0, b1 - b0)))

    n_rep = len(rep_idx)
    out = {
        "wer": round(jiwer.wer(ref_norm, hyp_norm), 4) if ref_norm else None,
        "cer": round(jiwer.cer(ref_norm, hyp_norm), 4) if ref_norm else None,
        "referenceWords": len(ref_norm.split()),
        "hypothesisWords": len(hyp_norm.split()),
        "repetition": {
            "referenceRepetitionTokens": n_rep,
            "retained": sum(1 for i in rep_idx if i in kept),
            "retainedExact": sum(1 for i in rep_idx if i in exact),
            "retention": round(sum(1 for i in rep_idx if i in kept) / n_rep, 4) if n_rep else None,
            "retentionExact": round(sum(1 for i in rep_idx if i in exact) / n_rep, 4) if n_rep else None,
            "hypothesisRepetitionTokens": sum(1 for t in hyp_tokens if t.maze_reason in REPETITION_REASONS),
        },
    }
    return out
