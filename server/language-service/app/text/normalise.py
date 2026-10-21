"""Sinhala/English text normalisation for language-sample analysis.

- NFC normalisation, so the same word typed two ways is one word.
- ZWJ (U+200D) is kept only where it builds a conjunct, yansaya, rakaransaya or
  repaya, i.e. next to al-lakuna with a consonant on the other side. Any other
  ZWJ, and every ZWNJ, zero-width space and BOM, is removed.
- Punctuation, symbols and the kunddaliya (෴) are removed. Hyphens become spaces,
  so a typed part-word repetition such as "බ-බ-බල්ලා" becomes separate tokens.
- Latin letters are lower-cased.
"""
import re
import unicodedata

ZWJ = "\u200d"
ZWNJ = "\u200c"
AL_LAKUNA = "්"
KUNDDALIYA = "෴"
_INVISIBLE = {ZWNJ, "\u200b", "\ufeff", "\u2060"}
# "xxx" marks an unintelligible word in typed transcripts (SALT convention).
UNINTELLIGIBLE = "xxx"


def is_sinhala_consonant(ch: str) -> bool:
    return 0x0D9A <= ord(ch) <= 0x0DC6


def is_sinhala(ch: str) -> bool:
    return 0x0D80 <= ord(ch) <= 0x0DFF


def _keep_zwj(text: str, i: int) -> bool:
    prev = text[i - 1] if i > 0 else ""
    nxt = text[i + 1] if i + 1 < len(text) else ""
    after = text[i + 2] if i + 2 < len(text) else ""
    # consonant + al-lakuna + ZWJ + consonant (yansaya, rakaransaya, repaya, conjuncts)
    if prev == AL_LAKUNA and nxt and is_sinhala_consonant(nxt):
        return True
    # consonant + ZWJ + al-lakuna + consonant (touching letters)
    return bool(prev and is_sinhala_consonant(prev) and nxt == AL_LAKUNA and after and is_sinhala_consonant(after))


def clean_invisibles(text: str) -> str:
    text = unicodedata.normalize("NFC", text)
    out = []
    for i, ch in enumerate(text):
        if ch in _INVISIBLE:
            continue
        if ch == ZWJ and not _keep_zwj(text, i):
            continue
        out.append(ch)
    return "".join(out)


def _is_punct_or_symbol(ch: str) -> bool:
    if ch == KUNDDALIYA:
        return True
    cat = unicodedata.category(ch)
    return cat[0] in ("P", "S")


def normalise_text(text: str) -> str:
    """Whole-text normalisation; whitespace is collapsed to single spaces."""
    text = clean_invisibles(text)
    chars = []
    for i, ch in enumerate(text):
        # Keep English contractions ("don't") as one word.
        if ch in "'’" and 0 < i < len(text) - 1 and text[i - 1].isascii() and text[i - 1].isalpha() \
                and text[i + 1].isascii() and text[i + 1].isalpha():
            chars.append("'")
        else:
            chars.append(" " if _is_punct_or_symbol(ch) else ch)
    return re.sub(r"\s+", " ", "".join(chars)).strip().lower()


def normalise_token(token: str) -> str:
    return normalise_text(token).replace(" ", "")


def tokenize(text: str) -> list[str]:
    return [t for t in normalise_text(text).split(" ") if t]


def grapheme_count(token: str) -> int:
    """Rough written-syllable length: base letters, ignoring vowel signs and al-lakuna."""
    return sum(1 for ch in token if not unicodedata.category(ch).startswith("M") and ch != ZWJ)
