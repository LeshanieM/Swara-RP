"""Fine-tune and evaluate the C4 Sinhala CTC model with visible console progress.

Uses the same speaker/sentence-disjoint SLR52 split and training helpers as
notebooks/c4_01_asr_finetune.ipynb, while allowing an existing local shard ZIP
to be used offline. Defaults are sized for a CPU run and update only the CTC
output head; use --train-scope full to fine-tune the complete transformer on a GPU.
"""
from __future__ import annotations

import argparse
import gc
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

from training import asr_finetune as ft, slr52


CURRENT = "SpideyDLK/wav2vec2-large-xls-r-300m-sinhala-low-LR-part1"
METRIC_ENGINE = "jiwer"


def _edit_distance(reference, hypothesis) -> int:
    previous = list(range(len(hypothesis) + 1))
    for i, left in enumerate(reference, 1):
        current = [i]
        for j, right in enumerate(hypothesis, 1):
            current.append(min(current[-1] + 1, previous[j] + 1,
                               previous[j - 1] + (left != right)))
        previous = current
    return previous[-1]


def _score(references: list[str], hypotheses: list[str]) -> dict:
    """Use jiwer when installed, with the same corpus edit rates as an offline fallback."""
    global METRIC_ENGINE
    try:
        return ft.score(references, hypotheses)
    except ModuleNotFoundError as exc:
        if exc.name != "jiwer":
            raise
    from app.text.normalise import normalise_text

    METRIC_ENGINE = "built-in edit distance (jiwer unavailable in this environment)"
    refs = [normalise_text(text) for text in references]
    hyps = [normalise_text(text) for text in hypotheses]
    pairs = [(ref, hyp) for ref, hyp in zip(refs, hyps) if ref]
    refs, hyps = [pair[0] for pair in pairs], [pair[1] for pair in pairs]
    ref_words = sum(len(ref.split()) for ref in refs)
    ref_chars = sum(len(ref.replace(" ", "")) for ref in refs)
    wer_errors = sum(_edit_distance(ref.split(), hyp.split()) for ref, hyp in zip(refs, hyps))
    cer_errors = sum(_edit_distance(ref.replace(" ", ""), hyp.replace(" ", ""))
                     for ref, hyp in zip(refs, hyps))
    return {"wer": round(wer_errors / ref_words, 4) if ref_words else 0.0,
            "cer": round(cer_errors / ref_chars, 4) if ref_chars else 0.0,
            "utterances": len(refs)}


def sampled_rows(df, split: str, limit: int) -> list[dict]:
    subset = df[df["split"] == split].sample(frac=1, random_state=17)
    return subset.head(limit or None).to_dict("records")


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="backslashreplace")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=Path, default=Path("data/slr52"))
    parser.add_argument("--shards", default="0", help="SLR52 shard ids, for example 0 or 0123456789abcdef")
    parser.add_argument("--base", default=os.environ.get("SWARA_C4_BASE", CURRENT))
    parser.add_argument("--steps", type=int, default=200)
    parser.add_argument("--batch-size", type=int, default=1)
    parser.add_argument("--accumulate", type=int, default=1)
    parser.add_argument("--max-train", type=int, default=1024, help="0 uses all available training utterances")
    parser.add_argument("--max-eval", type=int, default=128, help="0 uses all dev and test utterances")
    parser.add_argument("--device", default=None, help="cuda, mps, or cpu; defaults to automatic selection")
    parser.add_argument("--train-scope", choices=("head", "full"), default="head",
                        help="train the CTC output head (CPU-friendly) or the full model (GPU recommended)")
    parser.add_argument("--out", type=Path, default=Path("models/c4_asr"))
    parser.add_argument("--report-dir", type=Path, default=Path("training/reports"))
    parser.add_argument("--skip-baseline", action="store_true", help="skip scoring the current public model")
    args = parser.parse_args()

    device = args.device or ft.best_device()
    print(f"Data: {args.data} | shards: {args.shards} | base: {args.base}", flush=True)
    print(f"Training: {args.steps} steps, batch {args.batch_size} x accumulate {args.accumulate}, device {device}", flush=True)

    slr52.fetch(args.data, list(args.shards))
    df = slr52.split(slr52.read_index(args.data))
    df = df[df["available"]]
    train_rows = sampled_rows(df, "train", args.max_train)
    dev_rows = sampled_rows(df, "dev", args.max_eval)
    test_rows = sampled_rows(df, "test", args.max_eval)
    if not train_rows or not dev_rows or not test_rows:
        raise ValueError("SLR52 needs available utterances in train, dev, and test splits")
    print(f"Available split: {len(df)} utterances; using {len(train_rows)} train / "
          f"{len(dev_rows)} dev / {len(test_rows)} test", flush=True)

    baseline = None
    if not args.skip_baseline:
        from transformers import AutoModelForCTC, AutoProcessor

        print("Loading current public C4 model for baseline...", flush=True)
        processor = AutoProcessor.from_pretrained(CURRENT)
        model = AutoModelForCTC.from_pretrained(CURRENT).eval()
        started = time.time()
        baseline = _score(
            [row["text"] for row in test_rows],
            ft.transcribe(model, processor, test_rows, device, batch_size=args.batch_size),
        )
        print(f"Current-model test WER/CER: {baseline} ({time.time() - started:.0f}s)", flush=True)
        del model, processor
        gc.collect()

    model, processor, mode = ft.load_model(args.base, args.out, [row["norm"] for row in train_rows])
    if args.train_scope == "head":
        for parameter in model.parameters():
            parameter.requires_grad = False
        for parameter in model.lm_head.parameters():
            parameter.requires_grad = True
    trainable = sum(parameter.numel() for parameter in model.parameters() if parameter.requires_grad)
    print(f"Fine-tune mode: {mode} ({args.train_scope}); trainable parameters: {trainable:,}", flush=True)
    loss_log = ft.train(
        model, processor, train_rows, device, steps=args.steps,
        batch_size=args.batch_size, accumulate=args.accumulate,
    )

    dev = _score(
        [row["text"] for row in dev_rows],
        ft.transcribe(model, processor, dev_rows, device, batch_size=args.batch_size),
    )
    test = _score(
        [row["text"] for row in test_rows],
        ft.transcribe(model, processor, test_rows, device, batch_size=args.batch_size),
    )
    speakers = {split: int(df.loc[df["split"] == split, "speaker"].nunique())
                for split in ("train", "dev", "test")}
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    info = {
        "base": args.base, "mode": mode, "shards": list(args.shards), "steps": args.steps,
        "batch": args.batch_size, "accumulate": args.accumulate, "device": device,
        "trainScope": args.train_scope,
        "trainUtterances": len(train_rows), "devUtterances": len(dev_rows), "testUtterances": len(test_rows),
        "speakers": speakers, "baselineTest": baseline, "dev": dev, "test": test,
        "lossLog": loss_log, "trainedAt": stamp, "metricEngine": METRIC_ENGINE,
        "note": "Fine-tuned from local OpenSLR SLR52 audio with speaker- and sentence-disjoint splits.",
    }
    ft.save(model, processor, args.out, info)
    args.report_dir.mkdir(parents=True, exist_ok=True)
    report = args.report_dir / f"c4-asr-{stamp}.json"
    report.write_text(json.dumps(info, indent=2, ensure_ascii=False, default=str), encoding="utf-8")
    md = [f"# C4 ASR fine-tuning ({stamp})", "", info["note"], "",
          f"Base: `{args.base}` ({mode}); SLR52 shards: `{args.shards}`; steps: {args.steps}.", "",
          f"Speaker counts (train/dev/test): {speakers}.", "",
          "| Model | WER | CER | Utterances |", "|---|---:|---:|---:|"]
    for name, values in (("Current public baseline", baseline), ("Fine-tuned C4", test)):
        if values:
            md.append(f"| {name} | {values['wer']:.4f} | {values['cer']:.4f} | {values['utterances']} |")
    md += ["", f"Dev score: WER {dev['wer']:.4f}, CER {dev['cer']:.4f} ({dev['utterances']} utterances).", ""]
    (args.report_dir / f"c4-asr-{stamp}.md").write_text("\n".join(md), encoding="utf-8")

    print(f"Fine-tuned test WER/CER: {test}", flush=True)
    print(f"Saved model: {args.out}", flush=True)
    print(f"Saved report: {report}", flush=True)

    del model, processor
    gc.collect()
    from app.asr.ctc import CtcEngine

    engine = CtcEngine(str(args.out), "cpu", 20.0)
    clip = ft.read_audio(Path(test_rows[0]["path"]))
    print("Service model check:", engine.transcribe(clip, ft.SR)["text"], flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
