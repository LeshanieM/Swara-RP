#!/usr/bin/env python3
"""Print a readable summary of the C2 model comparison report."""

import argparse
import json
import sys
from pathlib import Path


DEFAULT_REPORT = Path(__file__).parent / "reports" / "c2-comparison-2026-10-21.json"


def score_text(summary, metric):
    score = summary.get(metric)
    if not isinstance(score, dict) or score.get("mean") is None:
        return "n/a"
    mean = score["mean"] * 100
    sd = score.get("sd")
    return f"{mean:.1f}% +/- {sd * 100:.1f}" if sd is not None else f"{mean:.1f}%"


def print_report(report):
    summaries = report.get("summaries")
    if not isinstance(summaries, dict) or not summaries:
        raise ValueError("The report does not contain any model summaries.")

    models = sorted(
        summaries.items(),
        key=lambda item: (item[1].get("macro", {}).get("f1", {}).get("mean") or 0),
        reverse=True,
    )
    columns = [
        ("MODEL", 36),
        ("FG ACCURACY", 18),
        ("FG F1", 18),
        ("HM ACCURACY", 18),
        ("HM F1", 18),
        ("MACRO F1", 18),
        ("HM PR-AUC", 18),
    ]

    print("C2 MODEL ACCURACY COMPARISON")
    print(
        f"Data: {report.get('data', 'unknown')}   "
        f"Participants: {report.get('participants', '—')}   "
        f"Samples: {report.get('moments', '—')}   "
        f"Folds: {report.get('folds', '—')}   "
        f"Seed: {report.get('seed', '—')}"
    )
    print("Scores are mean +/- standard deviation across folds.")
    print("FG = facial category; HM = head movement category; Macro F1 averages both F1 scores.")
    print()

    header = "  ".join(name.ljust(width) for name, width in columns)
    print("=" * len(header))
    print(header)
    print("-" * len(header))

    for model_name, summary in models:
        fg = summary.get("FG", {})
        hm = summary.get("HM", {})
        macro = summary.get("macro", {})
        row = [
            model_name[:36],
            score_text(fg, "accuracy"),
            score_text(fg, "f1"),
            score_text(hm, "accuracy"),
            score_text(hm, "f1"),
            score_text(macro, "f1"),
            score_text(hm, "prAuc"),
        ]
        print("  ".join(value.ljust(width) for value, (_, width) in zip(row, columns)))

    baseline = summaries.get("0 majority class", {}).get("macro", {}).get("f1", {})
    if baseline.get("mean") is not None:
        print()
        print(f"Majority-class baseline macro F1: {score_text({'f1': baseline}, 'f1')}")


def main():
    parser = argparse.ArgumentParser(
        description="Display the C2 model accuracy comparison in a readable table."
    )
    parser.add_argument(
        "report",
        nargs="?",
        type=Path,
        default=DEFAULT_REPORT,
        help=f"JSON report to display (default: {DEFAULT_REPORT})",
    )
    args = parser.parse_args()

    try:
        with args.report.open(encoding="utf-8") as report_file:
            report = json.load(report_file)
        print_report(report)
    except (OSError, json.JSONDecodeError, ValueError) as error:
        print(f"Could not display accuracy report: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
