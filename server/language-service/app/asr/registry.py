"""Lazy ASR engine registry.

Engines load on first use (or in the background with C4_PRELOAD=1), so a model
that fails to download or load never stops the service from starting; the text
endpoints keep working and /health says what went wrong.
"""
import logging
import threading
import time

from app.asr.base import AsrEngine, EngineUnavailable
from app.config import get_settings

log = logging.getLogger("c4.asr")
ENGINES = ("ctc", "whisper")

_engines: dict[str, AsrEngine] = {}
_errors: dict[str, str] = {}
_load_sec: dict[str, float] = {}
_loading: set[str] = set()
_lock = threading.Lock()


def _model_for(name: str) -> str:
    s = get_settings()
    return s.ctc_model if name == "ctc" else s.whisper_model


def _build(name: str) -> AsrEngine:
    s = get_settings()
    if name == "ctc":
        from app.asr.ctc import CtcEngine
        return CtcEngine(s.ctc_model, s.device, s.ctc_chunk_sec)
    if name == "whisper":
        from app.asr.whisper import WhisperEngine
        return WhisperEngine(s.whisper_model, s.device)
    raise EngineUnavailable(f"unknown_engine: {name}")


def get(name: str | None = None) -> AsrEngine:
    name = name or get_settings().asr_engine
    if name == "none":
        raise EngineUnavailable("asr_disabled: C4_ASR_ENGINE=none; send a transcript instead")
    if name not in ENGINES:
        raise EngineUnavailable(f"unknown_engine: {name}")
    with _lock:
        if name in _engines:
            return _engines[name]
        _loading.add(name)
        try:
            t0 = time.perf_counter()
            log.info("loading ASR engine %s (%s)", name, _model_for(name))
            engine = _build(name)
            _engines[name] = engine
            _load_sec[name] = round(time.perf_counter() - t0, 1)
            _errors.pop(name, None)
            log.info("ASR engine %s loaded in %.1f s", name, _load_sec[name])
            return engine
        except EngineUnavailable as exc:
            _errors[name] = str(exc)
            raise
        finally:
            _loading.discard(name)


def preload() -> None:
    def run():
        try:
            get()
        except EngineUnavailable as exc:
            log.warning("preload failed: %s", exc)
    threading.Thread(target=run, daemon=True, name="asr-preload").start()


def status() -> dict:
    out = {}
    for name in ENGINES:
        if name in _engines:
            state = "loaded"
        elif name in _loading:
            state = "loading"
        elif name in _errors:
            state = "unavailable"
        else:
            state = "not_loaded"
        out[name] = {"status": state, "model": _model_for(name), "loadSec": _load_sec.get(name), "error": _errors.get(name)}
    return out
