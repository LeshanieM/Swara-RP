"""Syllable counting, the same rule C1 uses for the %SS denominator.

Copied from speech-service/app/severity/syllables.py so the two services stay
independent; keep them in step if C1 changes its rule.

- Sinhala: one syllable per independent vowel and per consonant that is not
  killed by al-lakuna (U+0DCA).
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


def token_syllables(token: str) -> int:
    token = unicodedata.normalize("NFC", token)
    if any(ord(c) in SI_CONSONANTS or ord(c) in SI_INDEPENDENT_VOWELS for c in token):
        return _sinhala(token)
    return sum(_english(w) for w in _LATIN_WORD.findall(token.lower()))


def count_syllables(tokens: list[str]) -> int:
    return sum(token_syllables(t) for t in tokens)
