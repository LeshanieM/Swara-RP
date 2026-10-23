"""Train and compare the C3 camera engagement model: logistic regression vs gradient boosting.

Reads the DAiSEE features from build_engagement.py. Clips where the face is visible in under
FACE_ABSENT_BELOW of the frames are dropped, as on the server (missing data, not disengagement).
Both models correct for the imbalance (about 6 % not engaged) with balanced class weights.

Evaluation: subject-grouped cross-validation over Train + Validation (no subject in both train and
test), then the official Test split, keeping only Test subjects that never appear in training.
Reported: plain accuracy beside the majority-class baseline, plus balanced accuracy, macro-F1,
ROC-AUC and the confusion matrix. The class-aware scores help interpret the imbalanced labels. The model
with the higher CV macro-F1 is written as a provisional candidate under training/artifacts; it does not
overwrite the API model.

    python -m training.train_engagement --data training/data/daisee/daisee_engagement.npz

Needs scikit-learn (requirements-learned.txt).
"""
import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import balanced_accuracy_score, confusion_matrix, f1_score, roc_auc_score
from sklearn.model_selection import GroupKFold
from sklearn.preprocessing import StandardScaler
from sklearn.utils.class_weight import compute_sample_weight

from app.config import SERVICE_ROOT
from app.engagement.features import FEATURES

FACE_ABSENT_BELOW = 0.3  # same as faceAbsentBelow in the API's engagementModel.json
DEFAULT_OUT = SERVICE_ROOT / "training" / "artifacts" / "engagementCameraModel.candidate.json"
MODELS = ("logistic", "gbdt")


class Imputer:
    """Training-set means for features that can be missing (e.g. no eye probability in a window)."""

    def fit(self, X):
        self.values = np.nan_to_num(np.nanmean(X, axis=0), nan=0.0)
        return self

    def transform(self, X):
        return np.where(np.isnan(X), self.values, X)


def fit(kind: str, X, y, seed: int):
    imp = Imputer().fit(X)
    Xi = imp.transform(X)
    if kind == "logistic":
        scaler = StandardScaler().fit(Xi)
        model = LogisticRegression(class_weight="balanced", C=1.0, max_iter=2000).fit(scaler.transform(Xi), y)
        return {"kind": kind, "imp": imp, "scaler": scaler, "model": model}
    model = GradientBoostingClassifier(n_estimators=150, max_depth=3, learning_rate=0.05, subsample=0.8, random_state=seed)
    model.fit(Xi, y, sample_weight=compute_sample_weight("balanced", y))
    return {"kind": kind, "imp": imp, "model": model}


def _inputs(m, X):
    Xi = m["imp"].transform(X)
    return m["scaler"].transform(Xi) if m["kind"] == "logistic" else Xi


def proba(m, X) -> np.ndarray:
    return m["model"].predict_proba(_inputs(m, X))[:, 1]


def raw(m, X) -> np.ndarray:
    """Log-odds of engaged, which the API's evaluator must reproduce."""
    return m["model"].decision_function(_inputs(m, X))


def metrics(y, p) -> dict:
    pred = (p >= 0.5).astype(int)
    tn, fp, fn, tp = confusion_matrix(y, pred, labels=[0, 1]).ravel()
    return {
        "n": int(len(y)), "notEngaged": int((y == 0).sum()),
        "accuracy": round(float(np.mean(pred == y)), 4),
        "majorityBaselineAccuracy": round(float(max(np.mean(y == 0), np.mean(y == 1))), 4),
        "balancedAccuracy": round(float(balanced_accuracy_score(y, pred)), 4),
        "macroF1": round(float(f1_score(y, pred, average="macro", zero_division=0)), 4),
        "rocAuc": round(float(roc_auc_score(y, p)), 4) if len(set(y.tolist())) == 2 else None,
        "confusion": {"tp": int(tp), "tn": int(tn), "fp": int(fp), "fn": int(fn)},
    }


def cross_validate(kind, X, y, groups, folds, seed) -> dict:
    n_splits = min(folds, len(set(groups.tolist())))
    if n_splits < 2:
        raise SystemExit("Need at least two subjects for grouped cross-validation.")
    per_fold, oof = [], np.zeros(len(y))
    for k, (tr, te) in enumerate(GroupKFold(n_splits=n_splits).split(X, y, groups)):
        if len(set(y[tr].tolist())) < 2:
            raise SystemExit(f"Fold {k} has only one class in training; too few not-engaged clips.")
        p = proba(fit(kind, X[tr], y[tr], seed + k), X[te])
        oof[te] = p
        per_fold.append(metrics(y[te], p))
    summary = {m: {"mean": round(float(np.mean([f[m] for f in per_fold])), 4), "sd": round(float(np.std([f[m] for f in per_fold])), 4)}
               for m in ("balancedAccuracy", "macroF1")}
    return {"nSplits": n_splits, "folds": per_fold, "summary": summary, "pooled": metrics(y, oof)}


def export(m, X_check) -> dict:
    out = {"type": m["kind"], "features": list(FEATURES),
           "impute": [round(float(v), 6) for v in m["imp"].values], "threshold": 0.5,
           # The API recomputes these on load and refuses the file if its evaluator disagrees with scikit-learn.
           "selfCheck": [{"x": [None if np.isnan(v) else float(v) for v in row], "raw": round(float(r), 6)}
                         for row, r in zip(X_check, raw(m, X_check))]}
    if m["kind"] == "logistic":
        out["logistic"] = {
            "mean": [round(float(v), 6) for v in m["scaler"].mean_],
            "scale": [round(float(v), 6) for v in m["scaler"].scale_],
            "intercept": round(float(m["model"].intercept_[0]), 6),
            "weights": [round(float(v), 6) for v in m["model"].coef_[0]],
        }
        return out
    gb = m["model"]
    trees = []
    for est in gb.estimators_[:, 0]:
        t = est.tree_
        trees.append({
            "feature": t.feature.tolist(), "threshold": [float(v) for v in t.threshold],
            "left": t.children_left.tolist(), "right": t.children_right.tolist(),
            "value": [round(float(v), 6) for v in t.value[:, 0, 0]],
        })
    # The raw score is init + learningRate × Σ tree values; recover init from the fitted model itself.
    x0 = m["imp"].transform(np.zeros((1, len(FEATURES))))
    tree_sum = sum(est.predict(x0)[0] for est in gb.estimators_[:, 0])
    init = float(gb.decision_function(x0)[0] - gb.learning_rate * tree_sum)
    out["gbdt"] = {"init": round(init, 6), "learningRate": gb.learning_rate, "trees": trees}
    return out


def report_md(r: dict) -> str:
    lines = [f"# C3 engagement camera model: {r['version']}", "", f"Trained {r['trainedAt']} on `{r['data']}`. {r['note']}".strip(), "",
             f"Rows (face visible ≥ {FACE_ABSENT_BELOW:.0%} of frames): {r['rows']}, dropped for no face: {r['droppedNoFace']}.", "",
             "| Model | CV balanced acc. | CV macro-F1 | Test accuracy | Majority baseline | Test balanced acc. | Test macro-F1 | Test ROC-AUC |", "|---|---|---|---|---|---|---|---|"]
    for kind in MODELS:
        cv, test = r["cv"][kind]["summary"], r["test"].get(kind)
        fmt = lambda s: f"{s['mean']:.3f} ± {s['sd']:.3f}"
        t = (f"{test['accuracy']:.3f} | {test['majorityBaselineAccuracy']:.3f} | {test['balancedAccuracy']:.3f} | {test['macroF1']:.3f} | {test['rocAuc'] if test['rocAuc'] is not None else '–'}"
             if test else "– | – | – | – | –")
        lines.append(f"| {kind} | {fmt(cv['balancedAccuracy'])} | {fmt(cv['macroF1'])} | {t} |")
    lines += ["", f"Exported: **{r['exported']}**. Test subjects kept: {r['testSubjects']}, removed for appearing in training: {r['testSubjectsOverlap']}.", ""]
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", type=Path, required=True)
    ap.add_argument("--folds", type=int, default=5)
    ap.add_argument("--seed", type=int, default=17)
    ap.add_argument("--export", choices=("auto", *MODELS), default="auto", help="auto = higher CV macro-F1")
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--report", type=Path, default=None, help="Markdown report (default: training/reports/<version>.md)")
    ap.add_argument("--note", default="", help="free text stored with the model (e.g. 'smoke run, not a result')")
    args = ap.parse_args()

    d = np.load(args.data, allow_pickle=False)
    if list(d["features"]) != list(FEATURES):
        raise SystemExit("Dataset was built with a different feature list; rebuild it.")
    X, y, groups, split = d["X"].astype(float), d["y"], d["groups"], d["split"]
    keep = X[:, FEATURES.index("facePresentRatio")] >= FACE_ABSENT_BELOW
    dropped = int((~keep).sum())
    X, y, groups, split = X[keep], y[keep], groups[keep], split[keep]

    dev = split != "Test"
    dev_subjects = set(groups[dev].tolist())
    overlap = sorted(set(groups[~dev].tolist()) & dev_subjects)
    test = ~dev & ~np.isin(groups, overlap)
    print(f"{len(y)} clips ({dropped} dropped for no face), {len(set(groups.tolist()))} subjects, "
          f"not engaged {int((y == 0).sum())} ({100 * (y == 0).mean():.1f} %); dev {int(dev.sum())}, test {int(test.sum())}")

    cv, test_metrics = {}, {}
    for kind in MODELS:
        cv[kind] = cross_validate(kind, X[dev], y[dev], groups[dev], args.folds, args.seed)
        s = cv[kind]["summary"]
        print(f"{kind:9s} CV balanced acc {s['balancedAccuracy']['mean']:.3f}±{s['balancedAccuracy']['sd']:.3f} "
              f"macro-F1 {s['macroF1']['mean']:.3f}±{s['macroF1']['sd']:.3f} ({cv[kind]['nSplits']} folds)")
    fitted = {kind: fit(kind, X[dev], y[dev], args.seed) for kind in MODELS}
    if test.any():
        for kind in MODELS:
            test_metrics[kind] = metrics(y[test], proba(fitted[kind], X[test]))
            print(f"{kind:9s} Test balanced acc {test_metrics[kind]['balancedAccuracy']:.3f} macro-F1 {test_metrics[kind]['macroF1']:.3f}")

    chosen = args.export if args.export != "auto" else max(MODELS, key=lambda k: cv[k]["summary"]["macroF1"]["mean"])
    trained_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
    version = f"c3-engagement-camera-{chosen}-{trained_at[:10]}"
    record = {
        "version": version, "trainedAt": trained_at, "data": args.data.name, "note": args.note,
        "rows": int(len(y)), "droppedNoFace": dropped, "exported": chosen,
        "testSubjects": len(set(groups[test].tolist())), "testSubjectsOverlap": len(overlap),
        "cv": cv, "test": test_metrics,
    }
    model_json = {
        "_note": "DAiSEE-trained research candidate; validate on the target SWARA population before deployment.",
        "version": version, "provisional": True, **export(fitted[chosen], X[dev][:: max(1, int(dev.sum()) // 8)][:8]),
        "training": {k: record[k] for k in ("trainedAt", "data", "note", "rows", "droppedNoFace", "testSubjects", "testSubjectsOverlap")}
        | {"label": "engaged = DAiSEE Engagement level 2 or 3", "classWeights": "balanced",
           "cv": {k: cv[k]["summary"] for k in MODELS}, "test": test_metrics},
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(model_json, indent=1) + "\n", encoding="utf-8")
    report = args.report or SERVICE_ROOT / "training" / "reports" / f"{version}.md"
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(report_md(record), encoding="utf-8")
    report.with_suffix(".json").write_text(json.dumps(record, indent=1) + "\n", encoding="utf-8")
    print(f"saved {args.out} ({chosen}) and {report}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
