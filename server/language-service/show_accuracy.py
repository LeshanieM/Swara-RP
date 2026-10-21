"""Print the latest recorded C4 ASR benchmark or score a transcript pair.

From this directory:
    .venv\\Scripts\\python.exe show_accuracy.py
    .venv\\Scripts\\python.exe show_accuracy.py --reference reference.txt --hypothesis asr.txt
"""
from __future__ import annotations

import argparse
from pathlib import Path


BENCHMARK = {
    "ctc": {
        "name": "C4 default CTC",
        "model": "SpideyDLK/wav2vec2-large-xls-r-300m-sinhala-low-LR-part1",
        "clean_wer": 0.500,
        "clean_cer": 0.124,
        "stuttered_wer": 0.537,
        "stuttered_cer": 0.138,
        "retention": 0.889,
    },
    "whisper": {
        "name": "Whisper comparison",
        "model": "SinhaSpeech/whisper-small-sinhala-run11",
        "clean_wer": 0.306,
        "clean_cer": 0.071,
        "stuttered_wer": 0.373,
        "stuttered_cer": 0.095,
        "retention": 0.741,
    },
}


def percent(value: float) -> str:
    return f"{value * 100:.1f}%"


def print_benchmark() -> None:
    print("C4 Sinhala ASR - recorded benchmark")
    print("=" * 58)
    print(f"{'Engine':<20} {'Clean WER/CER':<20} {'Stutter WER/CER':<21} {'Rep. kept'}")
    print("-" * 75)
    for result in BENCHMARK.values():
        clean = f"{percent(result['clean_wer'])} / {percent(result['clean_cer'])}"
        stuttered = f"{percent(result['stuttered_wer'])} / {percent(result['stuttered_cer'])}"
        print(f"{result['name']:<20} {clean:<20} {stuttered:<21} {percent(result['retention'])}")
        print(f"  Model: {result['model']}")
    print("\nWER/CER are error rates (lower is better); repetition kept is a retention rate.")
    print("Test: adult Sinhala read speech (SLR52), with repetitions added to the stuttered samples.")
    print("These are recorded benchmark results, not a new run or child-speech accuracy claim.")
    print("Source: ../VERIFICATION_LOG_C4.md, V-23.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path, help="UTF-8 reference transcript")
    parser.add_argument("--hypothesis", type=Path, help="UTF-8 ASR transcript to compare")
    args = parser.parse_args()

    if bool(args.reference) != bool(args.hypothesis):
        parser.error("--reference and --hypothesis must be supplied together")
    if not args.reference:
        print_benchmark()
        return 0

    try:
        from app.evaluation import evaluate

        result = evaluate(
            args.reference.read_text(encoding="utf-8"),
            args.hypothesis.read_text(encoding="utf-8"),
        )
    except (OSError, ImportError) as exc:
        parser.error(str(exc))
    repetition = result["repetition"]
    print("C4 transcript comparison")
    print("=" * 32)
    print(f"WER (word error rate): {percent(result['wer'])}")
    print(f"CER (character error rate): {percent(result['cer'])}")
    print(f"Reference / hypothesis words: {result['referenceWords']} / {result['hypothesisWords']}")
    print(f"Repetition retention: {percent(repetition['retention']) if repetition['retention'] is not None else 'n/a'}")
    print(f"Exact repetition retention: {percent(repetition['retentionExact']) if repetition['retentionExact'] is not None else 'n/a'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
