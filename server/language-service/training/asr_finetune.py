"""Fine-tune a CTC speech model for Sinhala (C4's ASR) on SLR52, and evaluate it with the service's own WER / CER.

Three starting points (``base``):
- the service's current model (default ``SpideyDLK/wav2vec2-large-xls-r-300m-sinhala-low-LR-part1``): continue
  training with its own vocabulary;
- ``facebook/wav2vec2-xls-r-300m``: a new CTC head on a character vocabulary built from the training text;
- ``facebook/mms-1b-all``: MMS with a new Sinhala **adapter** (only the adapter layers and the head are trained, as
  in the MMS paper), on the same character vocabulary.

The feature encoder is frozen in every case. Plain PyTorch loop (no Trainer), so it runs on CUDA, Apple MPS (CTC loss
falls back to the CPU there; set PYTORCH_ENABLE_MPS_FALLBACK=1) or CPU. The saved folder is a normal transformers
model + processor, which the service loads with ``C4_CTC_MODEL=<folder>``.
"""
import os

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")  # CTC loss has no MPS kernel; set before torch loads

import json  # noqa: E402
import math  # noqa: E402
import random  # noqa: E402
import time  # noqa: E402
from dataclasses import dataclass  # noqa: E402
from pathlib import Path  # noqa: E402

import numpy as np  # noqa: E402
import soundfile as sf  # noqa: E402

SR = 16000
MMS = "facebook/mms-1b-all"


def best_device() -> str:
    import torch

    if torch.cuda.is_available():
        return "cuda"
    if torch.backends.mps.is_available():
        return "mps"
    return "cpu"


def build_vocab(texts: list[str]) -> dict:
    """Character vocabulary (space -> "|"), plus the [UNK] and [PAD] (= CTC blank) tokens."""
    chars = sorted({ch for t in texts for ch in t if ch != " "})
    vocab = {ch: i for i, ch in enumerate(chars)}
    vocab["|"] = len(vocab)
    vocab["[UNK]"] = len(vocab)
    vocab["[PAD]"] = len(vocab)
    return vocab


def load_model(base: str, out_dir: Path, train_texts: list[str]):
    """(model, processor, mode) for the chosen starting point; new vocabularies are written to ``out_dir``."""
    from transformers import (AutoModelForCTC, AutoProcessor, Wav2Vec2CTCTokenizer, Wav2Vec2FeatureExtractor,
                              Wav2Vec2ForCTC, Wav2Vec2Processor)

    out_dir.mkdir(parents=True, exist_ok=True)
    if base != MMS:
        try:  # a Sinhala CTC checkpoint with its own processor: continue training with its vocabulary
            processor = AutoProcessor.from_pretrained(base)
            if getattr(processor, "tokenizer", None) is not None:
                model = AutoModelForCTC.from_pretrained(base)
                if model.config.vocab_size == len(processor.tokenizer):
                    model.freeze_feature_encoder()
                    return model, processor, "continue"
        except Exception:  # noqa: BLE001 - e.g. the bare XLS-R checkpoint has no tokenizer
            pass
    vocab = build_vocab(train_texts)
    (out_dir / "vocab.json").write_text(json.dumps(vocab, ensure_ascii=False))
    tokenizer = Wav2Vec2CTCTokenizer(str(out_dir / "vocab.json"), unk_token="[UNK]", pad_token="[PAD]", word_delimiter_token="|")
    fe = Wav2Vec2FeatureExtractor(feature_size=1, sampling_rate=SR, padding_value=0.0, do_normalize=True, return_attention_mask=True)
    processor = Wav2Vec2Processor(feature_extractor=fe, tokenizer=tokenizer)
    common = dict(vocab_size=len(vocab), pad_token_id=tokenizer.pad_token_id, ctc_loss_reduction="mean", ignore_mismatched_sizes=True)
    if base == MMS:
        model = Wav2Vec2ForCTC.from_pretrained(base, **common)
        model.init_adapter_layers()
        model.freeze_base_model()
        for p in model._get_adapters().values():  # noqa: SLF001 - the documented way to train MMS adapters
            p.requires_grad = True
        for p in model.lm_head.parameters():
            p.requires_grad = True
        return model, processor, "mms_adapter"
    model = Wav2Vec2ForCTC.from_pretrained(base, layerdrop=0.0, mask_time_prob=0.05, **common)
    model.freeze_feature_encoder()
    return model, processor, "new_head"


def read_audio(path: Path) -> np.ndarray:
    audio, sr = sf.read(str(path), dtype="float32", always_2d=True)
    audio = audio.mean(axis=1)
    if sr != SR:
        import soxr

        audio = soxr.resample(audio, sr, SR)
    return audio


@dataclass
class Batch:
    input_values: object
    attention_mask: object
    labels: object


def make_batch(processor, rows, device: str) -> Batch:
    import torch

    audios = [read_audio(Path(r["path"])) for r in rows]
    inputs = processor.feature_extractor(audios, sampling_rate=SR, padding=True, return_attention_mask=True, return_tensors="pt")
    labels = processor.tokenizer([r["norm"] for r in rows], padding=True, return_tensors="pt")
    lab = labels.input_ids.masked_fill(labels.attention_mask.ne(1), -100)
    return Batch(inputs.input_values.to(device), inputs.attention_mask.to(device), lab.to(device))


def train(model, processor, rows: list[dict], device: str, steps: int, batch_size: int = 8, lr: float = 1e-4,
          accumulate: int = 1, seed: int = 17, log_every: int = 25, max_sec: float = 15.0) -> list[dict]:
    """Trains for ``steps`` optimiser steps on ``rows`` (dicts with path, norm); returns the loss log."""
    import torch

    rng = random.Random(seed)
    model.to(device).train()
    params = [p for p in model.parameters() if p.requires_grad]
    opt = torch.optim.AdamW(params, lr=lr, weight_decay=0.0)
    warmup = max(1, steps // 10)
    # Linear warm-up over the first 10 % of steps, then linear decay to 0.
    sched = torch.optim.lr_scheduler.LambdaLR(
        opt, lambda s: (s + 1) / warmup if s < warmup else max(0.0, (steps - s) / max(1, steps - warmup)))
    log, t0, order = [], time.time(), []
    for step in range(steps):
        opt.zero_grad()
        total = 0.0
        for _ in range(accumulate):
            if len(order) < batch_size:
                order += rng.sample(range(len(rows)), len(rows))
            batch_rows = [rows[order.pop()] for _ in range(batch_size)]
            b = make_batch(processor, batch_rows, device)
            if b.input_values.shape[1] > max_sec * SR:  # very long clips: skip this batch (memory)
                continue
            loss = model(input_values=b.input_values, attention_mask=b.attention_mask, labels=b.labels).loss / accumulate
            if not math.isfinite(loss.item()):
                continue
            loss.backward()
            total += loss.item()
        torch.nn.utils.clip_grad_norm_(params, 1.0)
        opt.step()
        sched.step()
        if step % log_every == 0 or step == steps - 1:
            log.append({"step": step, "loss": round(total, 4), "lr": sched.get_last_lr()[0], "sec": round(time.time() - t0, 1)})
            print(log[-1], flush=True)
    model.eval()
    return log


def transcribe(model, processor, rows: list[dict], device: str, batch_size: int = 8) -> list[str]:
    import torch

    model.to(device).eval()
    out = []
    for i in range(0, len(rows), batch_size):
        chunk = rows[i:i + batch_size]
        audios = [read_audio(Path(r["path"])) for r in chunk]
        inputs = processor.feature_extractor(audios, sampling_rate=SR, padding=True, return_attention_mask=True, return_tensors="pt")
        with torch.inference_mode():
            logits = model(input_values=inputs.input_values.to(device), attention_mask=inputs.attention_mask.to(device)).logits
        ids = logits.argmax(dim=-1).cpu().numpy()
        out += [t.replace("|", " ").strip() for t in processor.tokenizer.batch_decode(ids)]
    return out


def score(references: list[str], hypotheses: list[str]) -> dict:
    """Corpus WER / CER on the service's normalised text (app.text.normalise), as the service's /evaluate-asr does."""
    import jiwer

    from app.text.normalise import normalise_text

    refs = [normalise_text(r) for r in references]
    hyps = [normalise_text(h) for h in hypotheses]
    pairs = [(r, h) for r, h in zip(refs, hyps) if r]
    refs, hyps = [p[0] for p in pairs], [p[1] for p in pairs]
    return {"wer": round(jiwer.wer(refs, hyps), 4), "cer": round(jiwer.cer(refs, hyps), 4), "utterances": len(refs)}


def save(model, processor, out_dir: Path, info: dict) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    model.save_pretrained(out_dir)
    processor.save_pretrained(out_dir)
    (out_dir / "swara_training.json").write_text(json.dumps(info, ensure_ascii=False, indent=1, default=str))
    return out_dir

