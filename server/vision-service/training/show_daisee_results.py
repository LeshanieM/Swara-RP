#!/usr/bin/env python3
"""Print a compact Component 3 DAiSEE model-results table."""

import argparse
import json
import sys
from pathlib import Path

DEFAULT_REPORT = Path(__file__).parent / "reports" / "c3-engagement-camera-gbdt-2026-10-21.json"


def pct(value):
    return "n/a" if value is None else f"{value * 100:.1f}%"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", nargs="?", type=Path, default=DEFAULT_REPORT,
                        help="JSON report path (defaults to the saved Component 3 report)")
    args = parser.parse_args()

    try:
        with args.report.open(encoding="utf-8") as f:
            report = json.load(f)

        print("C3 DAiSEE CAMERA ENGAGEMENT MODEL RESULTS")
        print(f"{report.get('rows', 'n/a'):,} clips | "
              f"{report.get('testSubjects', 'n/a')} held-out subjects | "
              f"5-fold subject CV | Selected: {str(report.get('exported', 'n/a')).upper()}")
        print()
        print(f"{'MODEL':<12} {'TEST ACC':>9} {'BAL ACC':>9} {'MACRO-F1':>9} "
              f"{'ROC-AUC':>9} {'CV BAL ACC':>12} {'CV MACRO-F1':>13}")
        print("-" * 78)
        for name in ("logistic", "gbdt"):
            test = report.get("test", {}).get(name, {})
            cv = report.get("cv", {}).get(name, {}).get("summary", {})
            print(f"{name.upper():<12} "
                  f"{pct(test.get('accuracy')):>9} "
                  f"{pct(test.get('balancedAccuracy')):>9} "
                  f"{pct(test.get('macroF1')):>9} "
                  f"{pct(test.get('rocAuc')):>9} "
                  f"{pct(cv.get('balancedAccuracy', {}).get('mean')):>12} "
                  f"{pct(cv.get('macroF1', {}).get('mean')):>13}")

        baseline = report.get("test", {}).get(report.get("exported"), {}).get("majorityBaselineAccuracy")
        if baseline is not None:
            print(f"\nAlways-engaged baseline accuracy: {pct(baseline)}")
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"Could not display DAiSEE results: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
