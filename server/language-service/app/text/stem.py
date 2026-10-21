"""Light suffix stripping, so inflected forms of one word count once.

Sinhala inflects heavily (බල්ලා, බල්ලාට, බල්ලෝ, බල්ලෙක් are one word for NDW
and new-word counting). There is no lemmatiser for spoken child Sinhala, so this
strips common case, number, definiteness and verb-form suffixes, longest first,
in at most two passes, and never leaves a stem shorter than two letters.
It is a stated limitation: irregular forms (e.g. past tenses) stay separate.
"""
from app.text.normalise import grapheme_count

# Longest suffixes are tried first.
SINHALA_SUFFIXES = sorted([
    "වලින්", "වලට", "වලදී", "වල",            # plural inanimate cases
    "යන්ගේ", "යන්ට", "යන්",                  # plural animate
    "ගෙන්", "ගේ", "ගෙ",                      # genitive / ablative
    "ටත්", "ටයි", "ට",                       # dative (+ also / + emphatic)
    "ෙක්", "ක්", "ෙන්", "ින්", "කින්",        # indefinite, instrumental/ablative
    "ත්", "යි", "නේ",                        # also, emphatic, tag
    "න්නේ", "න්න", "නවද", "නවා", "පු",       # verb forms (present, infinitive, relative past)
    "ා", "ෝ", "ේ",                           # definite animate, plural, locative
], key=len, reverse=True)

# Pronouns inflect irregularly, and some stripped forms collide with other words
# (මගේ "my" would become මග "road"), so they map straight to their base form.
_PRONOUNS = {
    "මම": ["මම", "මා", "මගේ", "මට", "මාව", "මගෙන්", "මටත්", "මමත්"],
    "ඔයා": ["ඔයා", "ඔයාගේ", "ඔයාට", "ඔයාව", "ඔයාලා", "ඔයාලාගේ", "ඔයාලට"],
    "එයා": ["එයා", "එයාගේ", "එයාට", "එයාව", "එයාලා", "එයාලාගේ", "එයාලට"],
    "අපි": ["අපි", "අපේ", "අපිට", "අපට", "අපව", "අපිත්"],
    "ඔහු": ["ඔහු", "ඔහුගේ", "ඔහුට", "ඔහුව"],
    "ඇය": ["ඇය", "ඇයගේ", "ඇයට", "ඇයව"],
}
LEMMAS = {form: base for base, forms in _PRONOUNS.items() for form in forms}

ENGLISH_SUFFIXES = ["'s", "ing", "ed", "es", "s"]
MIN_STEM_LETTERS = 2


def _strip_once(token: str, suffixes: list[str], min_letters: int) -> str:
    for suffix in suffixes:
        if token.endswith(suffix) and len(token) > len(suffix):
            stem = token[: -len(suffix)]
            if grapheme_count(stem) >= min_letters:
                return stem
    return token


def stem(token: str) -> str:
    if not token:
        return token
    if token in LEMMAS:
        return LEMMAS[token]
    if token.isascii():
        return _strip_once(token, ENGLISH_SUFFIXES, 3)
    out = _strip_once(token, SINHALA_SUFFIXES, MIN_STEM_LETTERS)
    if out != token:
        out = _strip_once(out, SINHALA_SUFFIXES, MIN_STEM_LETTERS)
    return out
