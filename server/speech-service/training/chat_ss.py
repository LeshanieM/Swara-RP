"""%SS from a FluencyBank CHAT transcript (.cha), the reference for checking C1's severity score.

Counting follows FluCalc (CLAN manual §8.5) and the CHAT manual's disfluency codes (chapter 13):

  stuttering-like disfluencies (SLD)          typical disfluencies (TD, not counted in %SS)
  prolongation   s:paghetti                   phrase repetition   <that is a> [/]
  broken word    spa^ghetti                   revisions           [//]  <...> [//]  [///]
  block          ≠butter                      fragment            &+sn
  part-word rep  ↫r-r-r↫rabbit                filled pause        &-um
  whole-word rep dog [/] dog (monosyllabic)   pauses              (.)  (..)  (2.4)

The denominator is the intended syllables: repeated material, fillers, fragments, nonwords and events are not
counted. Two figures are returned: %SLD (FluCalc: every SLD event per 100 intended syllables) and %SS (stuttered
syllables: each stuttered word counted once, plus each extra monosyllabic word repetition), which is what C1's
%SS estimates. English syllables are counted with a vowel-group rule, which is close enough for a severity check.
"""
import re
from dataclasses import dataclass, field
from pathlib import Path

BULLET = re.compile("\x15(\\d+)_(\\d+)\x15")
SPEAKER_LINE = re.compile(r"^\*([A-Z0-9]+):\s*(.*)$")
VOWELS = re.compile(r"[aeiouy]+")


def syllables(word: str) -> int:
    w = re.sub(r"[^a-z]", "", word.lower())
    if not w:
        return 0
    n = len(VOWELS.findall(w))
    if w.endswith("e") and not w.endswith(("le", "ee", "ye")) and n > 1:
        n -= 1  # silent final e
    elif w.endswith("ed") and not w.endswith(("ted", "ded")) and n > 1:
        n -= 1  # past tense "-ed" is usually not a syllable (laughed, played)
    return max(1, n)


@dataclass
class Counts:
    syllables: int = 0
    words: int = 0
    prolongation: int = 0
    broken_word: int = 0
    block: int = 0
    part_word_repetition: int = 0
    word_repetition_mono: int = 0
    word_repetition_poly: int = 0
    phrase_repetition: int = 0
    revision: int = 0
    fragment: int = 0
    filled_pause: int = 0
    stuttered_words: int = 0
    segments_ms: list = field(default_factory=list)
    intended: list = field(default_factory=list)  # the intended words, for C1's transcript-based syllable count

    @property
    def sld(self) -> int:
        return self.prolongation + self.broken_word + self.block + self.part_word_repetition + self.word_repetition_mono

    def as_dict(self) -> dict:
        d = {k: v for k, v in self.__dict__.items() if k not in ("segments_ms", "intended")}
        d["sld"] = self.sld
        d["percentSLD"] = round(100 * self.sld / self.syllables, 2) if self.syllables else None
        d["percentSS"] = round(100 * (self.stuttered_words + self.word_repetition_mono) / self.syllables, 2) if self.syllables else None
        d["speechSec"] = round(sum(e - s for s, e in self.segments_ms) / 1000, 1)
        return d


def _main_lines(text: str, speaker: str):
    """Main tier lines of one speaker, with continuation lines joined, and their time bullets."""
    lines, current = [], None
    for raw in text.splitlines():
        if raw.startswith("\t") and current is not None:
            current += " " + raw.strip()
            continue
        if current is not None:
            lines.append(current)
            current = None
        m = SPEAKER_LINE.match(raw)
        if m and m.group(1) == speaker:
            current = m.group(2)
    if current is not None:
        lines.append(current)
    return lines


def _tokens(line: str) -> list[str]:
    line = BULLET.sub(" ", line)
    line = re.sub(r"\[[=%+!?*:][^\]]*\]", " ", line)  # comments, postcodes, error marks, replacements
    line = re.sub(r"\[!\]|\[\?\]|\(\.+\)|\(\d+(\.\d+)?\)", " ", line)  # stress marks, pauses
    line = re.sub(r"\[x\s*(\d+)\]", r" [x\1] ", line)
    line = line.replace("<", " < ").replace(">", " > ")
    return [t for t in re.split(r"\s+", line) if t and t not in {".", "?", "!", "+...", "+/.", "+//.", "+/?", "„", "‡"}]


def _score_word(word: str, c: Counts) -> tuple[int, str]:
    """Counts the codes inside one word; returns its intended syllables (0 for non-words) and the intended word."""
    if word.startswith("&-"):
        c.filled_pause += 1
        return 0, ""
    if word.startswith("&+"):
        c.fragment += 1
        return 0, ""
    if word.startswith(("&~", "&=", "&*")) or word.lower() in {"xxx", "yyy", "www"} or word.startswith("0"):
        return 0, ""
    stuttered = False
    pwr = word.count("↫") // 2
    if pwr:
        c.part_word_repetition += pwr
        stuttered = True
        word = re.sub("↫[^↫]*↫", "", word)  # the repeated segment is not part of the intended word
    if "≠" in word:
        c.block += word.count("≠")
        stuttered = True
    if "^" in word:
        c.broken_word += 1
        stuttered = True
    core = word.replace("≠", "").replace("^", "")
    if re.search(r"[A-Za-z]:+[A-Za-z]|[A-Za-z]:+$", core):
        c.prolongation += 1
        stuttered = True
    core = re.sub(r"[@].*$", "", core.replace(":", ""))  # @-suffixes (@b babbling, @s other language) dropped
    if stuttered:
        c.stuttered_words += 1
    return syllables(core), core


def count(text: str, speaker: str = "CHI") -> Counts:
    """Counts for one speaker of one CHAT transcript."""
    c = Counts()
    for raw in text.splitlines():
        m = SPEAKER_LINE.match(raw)
        if m and m.group(1) == speaker:
            for s, e in BULLET.findall(raw):
                c.segments_ms.append((int(s), int(e)))
    for line in _main_lines(text, speaker):
        toks = _tokens(line)
        i = 0
        group_start = None
        while i < len(toks):
            t = toks[i]
            if t == "<":
                group_start = i
                i += 1
                continue
            nxt = toks[i + 1] if i + 1 < len(toks) else ""
            if t == ">":
                # The end of a <phrase>: retraced (repetition / revision) when a retrace code follows.
                if nxt == "[/]":
                    c.phrase_repetition += 1
                elif nxt in {"[//]", "[///]", "[/-]"}:
                    c.revision += 1
                group_start = None
                i += 2 if nxt in {"[/]", "[//]", "[///]", "[/-]"} else 1
                continue
            # Retraced material: a word followed by [/], [//], [///] or [/-] is not intended speech.
            if nxt in {"[/]", "[//]", "[///]", "[/-]"}:
                if nxt == "[/]":
                    base = re.sub("↫[^↫]*↫|[≠^:]", "", t)
                    if syllables(base) <= 1:
                        c.word_repetition_mono += 1
                    else:
                        c.word_repetition_poly += 1
                else:
                    c.revision += 1
                i += 2
                continue
            if t.startswith("[x") and t.endswith("]"):  # older files: word [x 3]
                n = int(re.sub(r"\D", "", t) or 1)
                prev = toks[i - 1] if i else ""
                if syllables(prev) <= 1:
                    c.word_repetition_mono += n - 1
                else:
                    c.word_repetition_poly += n - 1
                i += 1
                continue
            if t.startswith("["):
                i += 1
                continue
            if group_start is not None and ">" in toks[i:]:
                close = toks.index(">", i)
                if close + 1 < len(toks) and toks[close + 1] in {"[/]", "[//]", "[///]", "[/-]"}:
                    i += 1  # inside a retraced group: skip, counted when the group closes
                    continue
                group_start = None
            syl, word = _score_word(t, c)
            if syl:
                c.syllables += syl
                c.words += 1
                c.intended.append(word)
            i += 1
    return c


def from_file(path: str | Path, speaker: str = "CHI") -> Counts:
    return count(Path(path).read_text(encoding="utf-8", errors="replace"), speaker)
