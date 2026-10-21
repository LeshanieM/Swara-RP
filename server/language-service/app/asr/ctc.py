"""CTC ASR (wav2vec2 / XLS-R / MMS style) with word timings from the CTC frames.

CTC emits one symbol per ~20 ms frame and only merges *adjacent identical*
frames, so a repeated sound or word ("ම ම මම") survives decoding; Whisper's
sequence decoder tends to drop it. Greedy decoding, no language model.

Long recordings are cut into ~``chunk_sec`` pieces at the quietest point near
each boundary, so memory stays flat and no word is cut in half.
"""
import logging
import threading

import numpy as np

from app.asr.base import AsrEngine, EngineUnavailable

log = logging.getLogger("c4.asr.ctc")
SEARCH_SEC = 2.0  # look this far either side of a chunk boundary for a quiet cut point
RMS_FRAME_SEC = 0.025
# Blank frames longer than this between two symbols force a word boundary (verification log: words
# were fused across sentence pauses because the model never emits "|" at the end of a sentence).
PAUSE_BREAK_SEC = 0.3


def _cut_points(signal: np.ndarray, sr: int, chunk_sec: float) -> list[int]:
    n = len(signal)
    chunk, search, frame = int(chunk_sec * sr), int(SEARCH_SEC * sr), int(RMS_FRAME_SEC * sr)
    cuts, pos = [0], 0
    while n - pos > chunk + search:
        lo, hi = pos + chunk - search, pos + chunk + search
        seg = signal[lo:hi]
        frames = len(seg) // frame
        rms = np.sqrt((seg[: frames * frame].reshape(frames, frame) ** 2).mean(axis=1))
        pos = lo + int(np.argmin(rms)) * frame + frame // 2
        cuts.append(pos)
    cuts.append(n)
    return cuts


class CtcEngine(AsrEngine):
    name = "ctc"
    repetition_preserving = True

    def __init__(self, model_id: str, device: str, chunk_sec: float):
        super().__init__(model_id, device)
        self.chunk_sec = chunk_sec
        self._lock = threading.Lock()  # one forward pass at a time; torch already uses all cores
        try:
            import torch
            from transformers import AutoModelForCTC, AutoProcessor
        except ImportError as exc:
            raise EngineUnavailable(f"dependency_not_installed: {exc.name}") from exc
        self._torch = torch
        try:
            self.processor = AutoProcessor.from_pretrained(model_id)
            self.model = AutoModelForCTC.from_pretrained(model_id).to(device).eval()
        except Exception as exc:  # network, missing files, wrong architecture
            raise EngineUnavailable(f"model_load_failed: {exc}") from exc
        tok = self.processor.tokenizer
        self.blank_id = tok.pad_token_id
        self.delimiter = getattr(tok, "word_delimiter_token", "|") or "|"
        self.vocab = tok.convert_ids_to_tokens(list(range(self.model.config.vocab_size)))
        self.special = set(tok.all_special_tokens) - {self.delimiter}
        self._index = {sym: i for i, sym in enumerate(self.vocab)}

    def log_probs(self, chunk: np.ndarray, sr: int):
        """Per-frame log-probabilities over the vocabulary ([frames, vocab], CPU float32) and the frame length in seconds."""
        torch = self._torch
        inputs = self.processor(chunk, sampling_rate=sr, return_tensors="pt")
        with self._lock, torch.inference_mode():
            logits = self.model(inputs.input_values.to(self.device)).logits[0]
        lp = torch.log_softmax(logits.float(), dim=-1).cpu()
        return lp, len(chunk) / sr / max(lp.shape[0], 1)

    def ids_for(self, text: str) -> list[int] | None:
        """The model's symbol ids for a word, or None if a character is outside the vocabulary."""
        ids = [self._index.get(self.delimiter if ch == " " else ch) for ch in text]
        return None if not ids or any(i is None or i == self.blank_id for i in ids) else ids

    def _chunk(self, chunk: np.ndarray, sr: int, offset: float) -> list[dict]:
        lp, frame_sec = self.log_probs(chunk, sr)
        return self.greedy_words(lp, frame_sec, offset)

    def greedy_words(self, lp, frame_sec: float, offset: float = 0.0) -> list[dict]:
        """Greedy CTC decoding of log-probabilities into timed words."""
        logp, ids = lp.max(dim=-1)
        ids, conf = ids.tolist(), logp.exp().tolist()

        words, chars, frames, confs, prev = [], [], [], [], None

        def flush():
            if chars:
                words.append({
                    "word": "".join(chars),
                    "start": round(offset + frames[0] * frame_sec, 3),
                    "end": round(offset + (frames[-1] + 1) * frame_sec, 3),
                    "confidence": round(float(np.mean(confs)), 4),
                })
            chars.clear(), frames.clear(), confs.clear()

        gap_frames = max(1, round(PAUSE_BREAK_SEC / frame_sec))
        for f, (i, c) in enumerate(zip(ids, conf)):
            if i == prev:
                if chars and i != self.blank_id and frames:
                    frames[-1] = f  # extend the current symbol over repeated frames
                continue
            prev = i
            if i == self.blank_id:
                continue
            sym = self.vocab[i] if i < len(self.vocab) else ""
            if sym in (self.delimiter, " "):
                flush()
            elif sym and sym not in self.special:
                # Models trained on single sentences rarely emit a delimiter at a pause,
                # so a long silence between two symbols also ends the word.
                if frames and f - frames[-1] > gap_frames:
                    flush()
                chars.append(sym)
                frames.append(f)
                confs.append(c)
        flush()
        return words

    def transcribe(self, signal: np.ndarray, sample_rate: int) -> dict:
        cuts = _cut_points(signal, sample_rate, self.chunk_sec)
        words = []
        for a, b in zip(cuts[:-1], cuts[1:]):
            if b - a < int(0.2 * sample_rate):
                continue
            words.extend(self._chunk(signal[a:b], sample_rate, a / sample_rate))
        return {"text": " ".join(w["word"] for w in words), "words": words, "wordTimings": "ctc", "chunks": len(cuts) - 1}
