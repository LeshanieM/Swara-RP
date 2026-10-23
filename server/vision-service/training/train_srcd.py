"""Train and compare the learned SRCD classifiers (GRU vs small temporal transformer).

Reads a dataset from build_dataset.py, runs participant-grouped cross-validation
(no participant in both train and test) and reports, per class (FG, HM): accuracy
next to the majority-class baseline, precision, recall, F1 and PR-AUC (mean ± SD
over folds). The decision threshold of each class is tuned on a validation split
held out from the training participants, never on the test fold. A class whose
cross-validated precision is below --min-precision, or whose accuracy is not above
the majority baseline, is marked "not assessed": the saved checkpoint records it,
and the service then uses the label-free SRCD decision for that class instead.
Finally it fits the chosen architecture on all data and saves the checkpoint the
service loads (models/c2_srcd.pt).

    .venv/bin/python -m training.train_srcd --data data/casa.npz --save-arch gru

Needs requirements-learned.txt (torch, scikit-learn).
"""
import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import torch
from sklearn.metrics import accuracy_score, average_precision_score, f1_score, precision_score, recall_score
from sklearn.model_selection import GroupKFold
from torch import nn

from app.config import get_settings
from app.detection import nets
from app.features import catalog

CATS = ("FG", "HM")
THRESHOLD_GRID = np.round(np.arange(0.05, 0.951, 0.025), 3)
MIN_PRECISION = 0.5  # a class below this cross-validated precision is "not assessed"


def class_metrics(y_true: np.ndarray, y_pred: np.ndarray, scores: np.ndarray | None = None,
                  y_train: np.ndarray | None = None) -> dict:
    """Per class: accuracy, majority-class accuracy (the training fold's majority label, or the test set's when no
    training labels are given), precision, recall, F1, PR-AUC (only with scores; None for 0/1 decisions) and support.
    Plus "macro" F1 over the classes."""
    out = {}
    for i, c in enumerate(CATS):
        t, p = y_true[:, i], y_pred[:, i]
        majority = int(round((y_train[:, i] if y_train is not None else t).mean()))
        out[c] = {
            "accuracy": float(accuracy_score(t, p)),
            "majorityAccuracy": float(np.mean(t == majority)),
            "precision": float(precision_score(t, p, zero_division=0)),
            "recall": float(recall_score(t, p, zero_division=0)),
            "f1": float(f1_score(t, p, zero_division=0)),
            "prAuc": float(average_precision_score(t, scores[:, i])) if scores is not None and len(set(t)) > 1 else None,
            "positives": int(t.sum()), "n": int(len(t)),
        }
    out["macro"] = {"f1": float(np.mean([out[c]["f1"] for c in CATS]))}
    return out


def tune_thresholds(scores: np.ndarray, y: np.ndarray) -> dict:
    """Per class, the threshold with the best F1 on validation data (0.5 when the class has no positives there)."""
    out = {}
    for i, c in enumerate(CATS):
        if y[:, i].sum() == 0:
            out[c] = 0.5
            continue
        f1 = [f1_score(y[:, i], scores[:, i] >= t, zero_division=0) for t in THRESHOLD_GRID]
        out[c] = float(THRESHOLD_GRID[int(np.argmax(f1))])
    return out


def validation_split(groups: np.ndarray, seed: int, share: float = 0.2) -> tuple[np.ndarray, np.ndarray]:
    """Indices of a participant-grouped train / validation split of one training set (no person in both)."""
    people = np.array(sorted(set(groups.tolist())))
    rng = np.random.default_rng(seed)
    rng.shuffle(people)
    n_val = max(1, int(round(share * len(people)))) if len(people) > 1 else 0
    val = np.isin(groups, people[:n_val])
    return np.flatnonzero(~val), np.flatnonzero(val)


def summarise(per_fold: list[dict]) -> dict:
    """Mean ± SD over folds of every per-class metric."""
    out = {}
    for c in CATS:
        out[c] = {}
        for m in ("accuracy", "majorityAccuracy", "precision", "recall", "f1", "prAuc"):
            v = [f[c][m] for f in per_fold if f[c][m] is not None]
            out[c][m] = {"mean": float(np.mean(v)), "sd": float(np.std(v))} if v else None
    out["macro"] = {"f1": {"mean": float(np.mean([f["macro"]["f1"] for f in per_fold])),
                           "sd": float(np.std([f["macro"]["f1"] for f in per_fold]))}}
    return out


def assessed(summary: dict, min_precision: float = MIN_PRECISION) -> dict:
    """A class is assessed only if its cross-validated precision reaches min_precision and its accuracy beats the
    majority-class baseline; otherwise the model is not trusted for it."""
    out = {}
    for c in CATS:
        s = summary[c]
        out[c] = bool(s["precision"]["mean"] >= min_precision and s["accuracy"]["mean"] > s["majorityAccuracy"]["mean"])
    return out


def fit(arch: str, X: np.ndarray, y: np.ndarray, epochs: int, lr: float, seed: int) -> nn.Module:
    torch.manual_seed(seed)
    model = nets.build(arch, X.shape[2], X.shape[1])
    # Weight positives by the class ratio: FG/HM moments are the minority.
    pos = y.sum(axis=0).clip(min=1)
    pos_weight = torch.tensor((len(y) - pos) / pos, dtype=torch.float32)
    loss_fn = nn.BCEWithLogitsLoss(pos_weight=pos_weight)
    opt = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-3)
    xt, yt = torch.from_numpy(X), torch.from_numpy(y.astype(np.float32))
    batch = 32
    model.train()
    for _ in range(epochs):
        order = torch.randperm(len(xt))
        for i in range(0, len(xt), batch):
            idx = order[i:i + batch]
            opt.zero_grad()
            loss = loss_fn(model(xt[idx]), yt[idx])
            loss.backward()
            opt.step()
    model.eval()
    return model


def predict(model: nn.Module, X: np.ndarray) -> np.ndarray:
    with torch.no_grad():
        return torch.sigmoid(model(torch.from_numpy(X))).numpy()


def cross_validate(arch: str, X, y, groups, folds: int, epochs: int, lr: float, seed: int) -> dict:
    n_splits = min(folds, len(set(groups)))
    if n_splits < 2:
        raise SystemExit("Need at least two participants for grouped cross-validation.")
    per_fold = []
    for k, (tr, te) in enumerate(GroupKFold(n_splits=n_splits).split(X, y, groups)):
        fit_idx, val_idx = validation_split(groups[tr], seed + k)
        fit_idx, val_idx = tr[fit_idx], tr[val_idx]
        model = fit(arch, X[fit_idx], y[fit_idx], epochs, lr, seed + k)
        thr = tune_thresholds(predict(model, X[val_idx]), y[val_idx]) if len(val_idx) else {c: 0.5 for c in CATS}
        scores = predict(model, X[te])
        pred = np.stack([scores[:, i] >= thr[c] for i, c in enumerate(CATS)], axis=1).astype(int)
        m = class_metrics(y[te], pred, scores, y_train=y[tr])
        m["thresholds"] = thr
        m["test_participants"] = sorted(set(groups[te].tolist()))
        per_fold.append(m)
    summary = summarise(per_fold)
    return {"arch": arch, "params": nets.n_params(nets.build(arch, X.shape[2], X.shape[1])),
            "folds": per_fold, "metrics": summary, "n_splits": n_splits,
            "thresholds": {c: float(np.median([f["thresholds"][c] for f in per_fold])) for c in CATS}}


def save_checkpoint(model: nn.Module, arch: str, X, y, groups, out: Path, data_name: str, epochs: int,
                    cv: dict | None = None, note: str = "", thresholds: dict | None = None,
                    assessed_classes: dict | None = None) -> None:
    """The checkpoint the service loads (app/detection/learned.py). ``thresholds`` are the validation-tuned ones;
    ``assessed_classes`` marks classes the model may decide (False = the service uses label-free SRCD for it)."""
    out.parent.mkdir(parents=True, exist_ok=True)
    trained_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
    torch.save({
        "arch": arch,
        "version": f"srcd-{arch}-{trained_at[:10]}",
        "features": list(catalog.SCORED_NAMES),
        "seq_len": int(X.shape[1]),
        "n_input": int(X.shape[2]),
        "model_kwargs": {},
        "state_dict": model.state_dict(),
        "thresholds": thresholds or {"FG": 0.5, "HM": 0.5},
        "assessed": assessed_classes or {c: True for c in CATS},
        "audio_dim": 0,
        "training": {
            "data": data_name, "moments": int(len(y)), "participants": int(len(set(groups.tolist()))),
            "trainedAt": trained_at, "epochs": epochs, "cv": cv, "note": note,
        },
    }, out)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", type=Path, required=True)
    ap.add_argument("--archs", default="gru,transformer")
    ap.add_argument("--save-arch", choices=("gru", "transformer"), default="gru")
    ap.add_argument("--folds", type=int, default=5)
    ap.add_argument("--epochs", type=int, default=60)
    ap.add_argument("--lr", type=float, default=3e-3)
    ap.add_argument("--seed", type=int, default=17)
    ap.add_argument("--out", type=Path, default=get_settings().learned_model_path)
    ap.add_argument("--note", default="", help="free text stored in the checkpoint (e.g. 'smoke run, not a result')")
    ap.add_argument("--min-precision", type=float, default=MIN_PRECISION,
                    help="cross-validated precision a class needs to be decided by the model (else: not assessed)")
    args = ap.parse_args()

    d = np.load(args.data, allow_pickle=False)
    X, y, groups = d["X"], d["y"], d["groups"]
    if list(d["features"]) != list(catalog.SCORED_NAMES):
        raise SystemExit("Dataset was built with a different feature list; rebuild it.")
    print(f"{len(y)} moments, {len(set(groups))} participants, FG+ {int(y[:, 0].sum())}, HM+ {int(y[:, 1].sum())}")

    report = {}
    for arch in args.archs.split(","):
        r = cross_validate(arch, X, y, groups, args.folds, args.epochs, args.lr, args.seed)
        report[arch] = r
        m = r["metrics"]
        print(f"{arch:12s} params {r['params']:6d} ({r['n_splits']} folds)")
        for c in CATS:
            pr = m[c]["prAuc"]["mean"] if m[c]["prAuc"] else float("nan")
            print(f"  {c}: acc {m[c]['accuracy']['mean']:.2f} (majority {m[c]['majorityAccuracy']['mean']:.2f}) "
                  f"P {m[c]['precision']['mean']:.2f} R {m[c]['recall']['mean']:.2f} F1 {m[c]['f1']['mean']:.2f}"
                  f"±{m[c]['f1']['sd']:.2f} PR-AUC {pr:.2f} thr {r['thresholds'][c]:.2f}")

    chosen = report.get(args.save_arch)
    ok = assessed(chosen["metrics"], args.min_precision) if chosen else None
    model = fit(args.save_arch, X, y, args.epochs, args.lr, args.seed)
    save_checkpoint(model, args.save_arch, X, y, groups, args.out, data_name=args.data.name, epochs=args.epochs,
                    cv=chosen["metrics"] if chosen else None, note=args.note,
                    thresholds=chosen["thresholds"] if chosen else None, assessed_classes=ok)
    print(f"saved {args.out} ({args.save_arch}); assessed classes: {ok}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
