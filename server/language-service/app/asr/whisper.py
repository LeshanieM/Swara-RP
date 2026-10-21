"""Whisper baseline (an existing Sinhala fine-tune; no training needed).

Kept for H4a: CTC vs Whisper on error rate and repetition retention. Word
timestamps come from the model's cross-attention alignment heads when the
checkpoint has them ("word" timings); otherwise words get times spread evenly
across each decoded segment ("segment" timings).
"""
import logging
import threading

import numpy as np

from app.asr.base import AsrEngine, EngineUnavailable

log = logging.getLogger("c4.asr.whisper")


class WhisperEngine(AsrEngine):
    name = "whisper"
    repetition_preserving = False

    def __init__(self, model_id: str, device: str):
        super().__init__(model_id, device)
        self._lock = threading.Lock()
        try:
            from transformers import pipeline
        except ImportError as exc:
            raise EngineUnavailable(f"dependency_not_installed: {exc.name}") from exc
        try:
            self.pipe = pipeline("automatic-speech-recognition", model=model_id, device=device, chunk_length_s=30)
        except Exception as exc:
            raise EngineUnavailable(f"model_load_failed: {exc}") from exc
        # Some fine-tunes store eos_token_id as a list; Whisper's timestamp processor needs one id.
        # The pipeline keeps its own copy of the generation config, so fix both.
        eos = self.pipe.model.config.eos_token_id
        for gen in (self.pipe.model.generation_config, getattr(self.pipe, "generation_config", None)):
            if gen is not None and isinstance(gen.eos_token_id, list):
                gen.eos_token_id = eos if isinstance(eos, int) else gen.eos_token_id[0]
        self.word_timestamps = bool(getattr(self.pipe.model.generation_config, "alignment_heads", None))

    def _run(self, signal: np.ndarray, sample_rate: int, timestamps) -> dict:
        # The pipeline pops keys from the dict it is given, so each call gets a fresh one.
        def audio():
            return {"raw": signal.copy(), "sampling_rate": sample_rate}
        try:
            return self.pipe(audio(), return_timestamps=timestamps, generate_kwargs={"language": "sinhala", "task": "transcribe"})
        except (ValueError, TypeError) as exc:
            # Some fine-tunes have no language tokens configured; let the model decide.
            log.info("whisper: language-forced decoding failed (%s); retrying without it", exc)
            return self.pipe(audio(), return_timestamps=timestamps)

    def transcribe(self, signal: np.ndarray, sample_rate: int) -> dict:
        duration = len(signal) / sample_rate
        with self._lock:
            out = self._run(signal, sample_rate, "word" if self.word_timestamps else True)
        words = []
        for seg in out.get("chunks") or [{"text": out["text"], "timestamp": (0.0, duration)}]:
            start, end = seg["timestamp"]
            start = start or 0.0
            end = end if end is not None else duration
            parts = seg["text"].split()
            step = max(end - start, 0.0) / max(len(parts), 1)
            for k, part in enumerate(parts):
                words.append({"word": part, "start": round(start + k * step, 3),
                              "end": round(start + (k + 1) * step, 3), "confidence": None})
        return {"text": out["text"].strip(), "words": words, "wordTimings": "word" if self.word_timestamps else "segment"}
