"""Train an offline, acoustic-only C1 head on the available SEP-28k-E clips.

This is the CPU-friendly alternative to notebooks/c1_02_features.ipynb and
c1_03_train.ipynb. It consumes the acoustic cache created by notebook 2 (or
by the commands in this training run), tunes thresholds on dev, evaluates on
the speaker-separated test split, then exports the normal service head/report.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd

from training import heads, sep28k


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=Path, default=Path("data/sep28k"))
    parser.add_argument("--head-out", type=Path, default=Path("models/c1_head.joblib"))
    parser.add_argument("--report-dir", type=Path, default=Path("training/reports"))
    parser.add_argument("--skip-rule-baseline", action="store_true")
    args = parser.parse_args()

    index = pd.read_csv(args.data / "clips_index.csv", dtype={"EpId": str, "ClipId": str})
    acoustic = np.load(args.data / "features" / "acoustic.npy")
    if len(index) != len(acoustic):
        raise ValueError(f"Feature/index row mismatch: {len(acoustic)} vs {len(index)}")

    y = sep28k.targets(index, min_votes=2)
    keep = sep28k.usable(index)
    split = index["SEP28k-E"].to_numpy()
    masks = {name: keep & (split == name) for name in ("train", "dev", "test")}
    if any(not masks[name].any() for name in masks):
        raise ValueError("All SEP28k-E train, dev, and test splits need usable clips")

    labels = sep28k.LABELS
    runs = []
    for kind in ("logreg", "mlp"):
        model = heads.make_head(kind).fit(acoustic[masks["train"]], y[masks["train"]])
        dev_prob = heads.proba(model, acoustic[masks["dev"]])
        thresholds = heads.tune_thresholds(dev_prob, y[masks["dev"]], labels)
        dev_score = heads.evaluate(dev_prob, y[masks["dev"]], labels, thresholds)["macroF1"]
        runs.append({"head": kind, "model": model, "thresholds": thresholds,
                     "devMacroF1": dev_score})
        print(f"{kind} dev macro-F1: {dev_score:.3f}", flush=True)

    best = max(runs, key=lambda row: row["devMacroF1"])
    test_mask = masks["test"]
    test_prob = heads.proba(best["model"], acoustic[test_mask])
    test_metrics = heads.evaluate(test_prob, y[test_mask], labels, best["thresholds"])
    baseline = None
    if not args.skip_rule_baseline:
        test_paths = index.loc[test_mask, "path"].tolist()
        baseline = heads.evaluate(heads.rule_baseline(test_paths, labels), y[test_mask], labels)

    comparison = []
    for row in runs:
        test_prob_for_row = heads.proba(row["model"], acoustic[test_mask])
        comparison.append({
            "inputs": "acoustic",
            "head": row["head"],
            "dev macro-F1": row["devMacroF1"],
            "test macro-F1": heads.evaluate(
                test_prob_for_row, y[test_mask], labels, row["thresholds"]
            )["macroF1"],
        })

    note = ("Acoustic-only model trained on locally available SEP-28k episodes; "
            "test split is speaker-separated SEP-28k-E. XLS-R embeddings were not extracted.")
    metrics = {
        "split": "SEP28k-E",
        "minVotes": 2,
        "layer": None,
        "chosenOn": "dev macro-F1",
        "input": "acoustic",
        "encoder": None,
        "note": note,
        "test": test_metrics,
        "ruleBaselineTest": baseline or {},
        "comparison": comparison,
        "clips": {name: int(mask.sum()) for name, mask in masks.items()},
    }
    version = heads.export_head(
        args.head_out, best["model"], ["acoustic"], labels, best["thresholds"],
        None, None, metrics, note,
    )
    args.report_dir.mkdir(parents=True, exist_ok=True)
    (args.report_dir / f"{version}.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    rows = []
    for label, score in test_metrics["perLabel"].items():
        rows.append({"label": label, **score,
                     "rule-based F1": (baseline or {}).get("perLabel", {}).get(label, {}).get("f1")})
    rows.append({"label": "macro-F1", "f1": test_metrics["macroF1"],
                 "rule-based F1": (baseline or {}).get("macroF1")})
    report = pd.DataFrame(rows).set_index("label").round(3).to_markdown()
    md = (f"# {version}\n\n{note}\n\nChosen on dev: acoustic / {best['head']}.\n\n"
          f"## Test split (SEP-28k-E)\n\n{report}\n\n"
          "## Head comparison\n\n" + pd.DataFrame(comparison).round(3).to_markdown(index=False) + "\n")
    (args.report_dir / f"{version}.md").write_text(md, encoding="utf-8")

    print(f"chosen on dev: acoustic / {best['head']}", flush=True)
    print(f"test macro-F1: {test_metrics['macroF1']:.3f}", flush=True)
    if baseline:
        print(f"rule-based test macro-F1: {baseline['macroF1']:.3f}", flush=True)
    print(f"exported head: {args.head_out}", flush=True)
    print(f"report: {args.report_dir / (version + '.json')}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
