"""Print the latest C1 model evaluation report in a readable terminal table.

Run from server/speech-service with:
    .venv\\Scripts\\python.exe show_accuracy.py
"""
from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent
REPORT_DIR = ROOT / "training" / "reports"
HEAD_FILE = ROOT / "models" / "c1_head.joblib"
VERIFICATION_LOG = ROOT.parent / "VERIFICATION_LOG.md"


def pct(value: object) -> str:
    if not isinstance(value, (int, float)):
        return "n/a"
    return f"{value * 100:.1f}%"


def print_report(report: dict, path: Path) -> None:
    test = report.get("test", {})
    baseline = report.get("ruleBaselineTest", {})
    print(f"C1 stutter-type evaluation - {path.stem}")
    print("=" * 64)
    print(f"Dataset split: {report.get('split', 'unknown')} (held-out test set)")
    if report.get("input") == "acoustic" or report.get("inputs") == ["acoustic"]:
        print("Chosen feature set: acoustic only")
    else:
        print(f"Chosen XLS-R layer: {report.get('layer', 'unknown')}")
    print(f"{'Label':<24}{'Precision':>13}{'Recall':>13}{'F1':>13}")
    print("-" * 63)
    for label, scores in test.get("perLabel", {}).items():
        print(f"{label:<24}{pct(scores.get('precision')):>13}{pct(scores.get('recall')):>13}{pct(scores.get('f1')):>13}")
    print("-" * 63)
    print(f"{'Trained head macro-F1':<37}{pct(test.get('macroF1')):>13}")
    print(f"{'Acoustic baseline macro-F1':<37}{pct(baseline.get('macroF1')):>13}")
    print("\nMacro-F1 summarizes the five event labels; it is not ordinary accuracy.")
    print("This is a held-out SEP-28k-E adult-speech score, not validation on children.")
    print(f"Report: {path}")


def print_smoke_result() -> bool:
    """Show the documented synthetic smoke-set result without calling it real accuracy."""
    try:
        log = VERIFICATION_LOG.read_text(encoding="utf-8")
    except OSError:
        return False

    section = re.search(
        r"### V-21 Training notebooks and the trained detector.*?(?=\n### |\Z)",
        log,
        flags=re.DOTALL,
    )
    if not section:
        return False
    score = re.search(
        r"Test macro-F1 was ([0-9.]+) for the trained head vs ([0-9.]+) for the rule-based detector",
        section.group(0),
    )
    if not score:
        return False

    print("C1 smoke-run result (synthetic clips)")
    print("=" * 48)
    print(f"Trained XLS-R head macro-F1: {float(score.group(1)) * 100:.1f}%")
    print(f"Acoustic rule baseline macro-F1: {float(score.group(2)) * 100:.1f}%")
    print("IMPORTANT: this is a code smoke check using synthetic, spliced speech, not real-model accuracy.")
    print("The verification log says SEP-28k audio was not downloaded for this run.")
    print(f"Source: {VERIFICATION_LOG} (V-21)")
    return True


def main() -> int:
    reports = sorted(REPORT_DIR.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    if reports:
        try:
            report = json.loads(reports[0].read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            print(f"Could not read C1 report {reports[0]}: {exc}")
            return 1
        print_report(report, reports[0])
        return 0

    if print_smoke_result():
        print(f"\nNo real-data C1 report found under: {REPORT_DIR}")
        print(f"Trained head currently present: {'yes' if HEAD_FILE.is_file() else 'no'} ({HEAD_FILE})")
        print("To get real-data scores, run notebooks c1_01_data, c1_02_features, and c1_03_train.")
        return 0

    print("No C1 evaluation report found.")
    print(f"Expected reports under: {REPORT_DIR}")
    print(f"Trained XLS-R head present: {'yes' if HEAD_FILE.is_file() else 'no'} ({HEAD_FILE})")
    print("Run notebooks c1_01_data.ipynb, c1_02_features.ipynb, and c1_03_train.ipynb in order.")
    print("Notebook 3 evaluates on the held-out test split, compares the acoustic baseline, and writes this report.")
    print("Then run: .venv\\Scripts\\python.exe show_accuracy.py")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
