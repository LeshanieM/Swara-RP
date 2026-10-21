"""Syllable counting for the %SS denominator.

- Sinhala: one syllable per independent vowel and per consonant that is not
  killed by al-lakuna (U+0DCA). Conjuncts written with ZWJ therefore count
  once (the first consonant carries al-lakuna). Text is NFC-normalised.
- English (and other Latin text): vowel groups per word, silent final "e"
  dropped, at least one per word.
"""
import re
import unicodedata

AL_LAKUNA = "්"
SI_INDEPENDENT_VOWELS = range(0x0D85, 0x0D97)
SI_CONSONANTS = range(0x0D9A, 0x0DC7)
_LATIN_WORD = re.compile(r"[a-z]+(?:'[a-z]+)?")
_VOWEL_GROUP = re.compile(r"[aeiouy]+")


def _sinhala(word: str) -> int:
    count = 0
    for i, ch in enumerate(word):
        cp = ord(ch)
        if cp in SI_INDEPENDENT_VOWELS:
            count += 1
        elif cp in SI_CONSONANTS and not (i + 1 < len(word) and word[i + 1] == AL_LAKUNA):
            count += 1
    return count


def _english(word: str) -> int:
    groups = len(_VOWEL_GROUP.findall(word))
    if word.endswith("e") and not word.endswith(("le", "ee", "ye")) and groups > 1:
        groups -= 1
    return max(1, groups)


def count_syllables(text: str) -> dict:
    """Returns total syllables and per-script word counts."""
    text = unicodedata.normalize("NFC", text)
    sinhala_words = latin_words = total = 0
    for token in text.split():
        if any(ord(c) in SI_CONSONANTS or ord(c) in SI_INDEPENDENT_VOWELS for c in token):
            n = _sinhala(token)
            sinhala_words += 1 if n else 0
            total += n
        else:
            for word in _LATIN_WORD.findall(token.lower()):
                latin_words += 1
                total += _english(word)
    return {"total": total, "sinhalaWords": sinhala_words, "latinWords": latin_words}
