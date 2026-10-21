"""Clip features for the C1 heads: acoustic (MFCC / pitch / energy, the same function the detector uses) and
mean-pooled XLS-R hidden states for several layers. Both are cached in chunks, so a long extraction resumes."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np
import soundfile as sf

from app.audio.prosody import FEATURES as ACOUSTIC_FEATURES, window_features

SR = 16000
CHUNK = 512


def _read(path: str) -> np.ndarray:
    audio, sr = sf.read(path, dtype="float32")
    if audio.ndim > 1:
        audio = audio.mean(axis=1)
    assert sr == SR, f"{path}: {sr} Hz (clips must be 16 kHz)"
    return audio


def _acoustic_one(path: str) -> np.ndarray:
    return window_features(_read(path), SR)


def _chunked(paths: list[str], cache: Path, name: str, compute):
    """Runs `compute(paths_chunk) -> array` per chunk of CHUNK clips, caching each chunk as .npy."""
    cache.mkdir(parents=True, exist_ok=True)
    parts = []
    for start in range(0, len(paths), CHUNK):
        f = cache / f"{name}_{start:07d}.npy"
        if f.exists():
            parts.append(np.load(f))
            continue
        arr = compute(paths[start:start + CHUNK])
        np.save(f, arr)
        parts.append(arr)
        print(f"  {name}: {min(start + CHUNK, len(paths))}/{len(paths)} clips", flush=True)
    return np.concatenate(parts) if parts else np.zeros((0,))


def acoustic(paths: list[str], cache: Path, workers: int = 4) -> np.ndarray:
    def compute(chunk):
        # librosa's heavy numerical work runs in NumPy/SciPy native code, while
        # threads avoid spawning fresh Python interpreters for every chunk.
        with ThreadPoolExecutor(max_workers=workers) as pool:
            return np.stack(list(pool.map(_acoustic_one, chunk, chunksize=16)))
    return _chunked(paths, Path(cache), "acoustic", compute)


def best_device() -> str:
    import torch
    if torch.cuda.is_available():
        return "cuda"
    if torch.backends.mps.is_available():
        return "mps"
    return "cpu"


def xlsr(paths: list[str], cache: Path, model_name: str, layers: list[int], device: str | None = None,
         batch: int = 16) -> dict[int, np.ndarray]:
    """Mean-pooled hidden states per clip for each requested layer (0 = the CNN feature projection)."""
    import torch
    from transformers import AutoFeatureExtractor, AutoModel

    device = device or best_device()
    extractor = AutoFeatureExtractor.from_pretrained(model_name)
    model = None  # loaded only if some chunk is not cached yet

    def compute(chunk):
        nonlocal model
        if model is None:
            model = AutoModel.from_pretrained(model_name).eval().to(device)
        out = {layer: [] for layer in layers}
        for i in range(0, len(chunk), batch):
            audio = [_read(p) for p in chunk[i:i + batch]]
            inputs = extractor(audio, sampling_rate=SR, return_tensors="pt", padding=True, return_attention_mask=True)
            mask = inputs.pop("attention_mask", None)
            with torch.inference_mode():
                hidden = model(**{k: v.to(device) for k, v in inputs.items()},
                               attention_mask=None if mask is None else mask.to(device),
                               output_hidden_states=True).hidden_states
            frames = hidden[0].shape[1]
            for j, a in enumerate(audio):
                n = max(1, min(frames, int(len(a) / SR * 50)))  # 50 encoder frames per second; ignore padding
                for layer in layers:
                    out[layer].append(hidden[layer][j, :n].float().mean(dim=0).cpu().numpy())
        return np.stack([np.stack(out[layer]) for layer in layers], axis=1)  # (n, layers, dim)

    if not paths:
        return {}
    arr = _chunked(paths, Path(cache), f"xlsr_{model_name.replace('/', '_')}_L{'-'.join(map(str, layers))}", compute)
    return {layer: arr[:, i, :] for i, layer in enumerate(layers)}


__all__ = ["acoustic", "xlsr", "best_device", "ACOUSTIC_FEATURES"]
