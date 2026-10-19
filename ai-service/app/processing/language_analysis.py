"""Transparent Sinhala transcript measures; text-only segmentation is a documented fallback."""
import re
import unicodedata

TOKEN_RE = re.compile(r"[\w\u0D80-\u0DFF]+(?:['’][\w\u0D80-\u0DFF]+)*", re.UNICODE)


def normalize_sinhala(text: str) -> str:
    text = unicodedata.normalize("NFC", text or "")
    text = re.sub("[\u200b\ufeff]", "", text)
    return re.sub(r"\s+", " ", text).strip()


def tokenize(text: str):
    return TOKEN_RE.findall(normalize_sinhala(text))


def calculate_mattr(tokens, window_size=10):
    if not tokens:
        return {"value": None, "windowSize": window_size, "windows": 0}
    if len(tokens) < window_size:
        return {"value": len(set(tokens)) / len(tokens), "windowSize": window_size, "windows": 1, "short": True}
    scores = [len(set(tokens[i:i + window_size])) / window_size for i in range(len(tokens) - window_size + 1)]
    return {"value": sum(scores) / len(scores), "windowSize": window_size, "windows": len(scores)}


def analyze_transcript(transcript: str, previous_words=None):
    original = transcript or ""
    normalized = normalize_sinhala(original)
    tokens = tokenize(normalized)
    chunks = re.split(r"(?<=[.!?।])\s+|\n+", normalized)
    utterances = []
    for index, chunk in enumerate(filter(None, (part.strip() for part in chunks)), 1):
        count = len(tokenize(chunk))
        if count:
            utterances.append({"utteranceId": f"u{index}", "text": chunk, "start": None, "end": None,
                               "wordCount": count, "syllableCount": None, "complexityProxy": count,
                               "c1EventOverlap": None, "c1EventTypes": []})
    prior = {normalize_sinhala(w).casefold() for w in (previous_words or [])}
    new_words = sorted({word.casefold() for word in tokens if word.casefold() not in prior})
    first = [word.casefold() for word in tokens[:50]]
    short = len(tokens) < 50 or len(utterances) < 5
    return {"transcript": original, "normalizedTranscript": normalized, "utterances": utterances,
            "measures": {"wordCount": len(tokens), "utteranceCount": len(utterances),
                         "MLU_words": len(tokens) / len(utterances) if utterances else None,
                         "NDW": len(set(first)), "NDW_observedWords": len(first), "NDW_shortSample": len(tokens) < 50,
                         "MATTR": calculate_mattr([w.casefold() for w in tokens]), "newWords": [],
                         "newWordStatus": "baseline_pending", "newWordMethod": "Exact NFC-normalized comparison; first two completed sessions establish a provisional baseline."},
            "shortSample": short, "reliabilityFlags": ["short_sample"] if short else []}
