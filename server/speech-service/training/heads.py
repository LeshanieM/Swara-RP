"""C1 heads: train, tune per-label thresholds on the dev split, evaluate with F1 / macro-F1, compare with the
rule-based acoustic detector, and export the head file the service loads (app/detection/xlsr.py)."""
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import f1_score, precision_score, recall_score
from sklearn.multioutput import MultiOutputClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

THRESHOLD_GRID = np.round(np.arange(0.05, 0.96, 0.025), 3)


def make_head(kind: str, seed: int = 17):
    """'logreg': one balanced logistic regression per label. 'mlp': one small multi-label network."""
    if kind == "logreg":
        return make_pipeline(StandardScaler(), MultiOutputClassifier(
            LogisticRegression(class_weight="balanced", C=0.5, max_iter=3000), n_jobs=-1))
    if kind == "mlp":
        return make_pipeline(StandardScaler(), MLPClassifier(
            hidden_layer_sizes=(256,), alpha=1e-3, early_stopping=True, max_iter=300, random_state=seed))
    raise ValueError(kind)


def proba(model, X: np.ndarray) -> np.ndarray:
    """(n, labels) probabilities, whatever shape the estimator returns."""
    raw = model.predict_proba(X)
    return np.stack([p[:, 1] for p in raw], axis=1) if isinstance(raw, list) else np.asarray(raw)


def tune_thresholds(p: np.ndarray, y: np.ndarray, labels) -> dict[str, float]:
    """Per label, the threshold with the best F1 on these (dev) clips."""
    out = {}
    for i, lab in enumerate(labels):
        scores = [f1_score(y[:, i], p[:, i] >= t, zero_division=0) for t in THRESHOLD_GRID]
        out[lab] = float(THRESHOLD_GRID[int(np.argmax(scores))])
    return out


def evaluate(p_or_pred: np.ndarray, y: np.ndarray, labels, thresholds: dict | None = None) -> dict:
    """Per-label precision / recall / F1 and the macro-F1 over labels. Pass probabilities with thresholds, or
    0/1 predictions without."""
    pred = p_or_pred if thresholds is None else np.stack(
        [p_or_pred[:, i] >= thresholds[lab] for i, lab in enumerate(labels)], axis=1)
    per = {lab: {"precision": float(precision_score(y[:, i], pred[:, i], zero_division=0)),
                 "recall": float(recall_score(y[:, i], pred[:, i], zero_division=0)),
                 "f1": float(f1_score(y[:, i], pred[:, i], zero_division=0)),
                 "positives": int(y[:, i].sum())} for i, lab in enumerate(labels)}
    return {"perLabel": per, "macroF1": float(np.mean([v["f1"] for v in per.values()]))}


def rule_baseline(paths: list[str], labels) -> np.ndarray:
    """The service's default rule-based acoustic detector on each clip: a label is present when any of the clip's
    windows passes the pipeline threshold. The comparison row for the trained heads."""
    import soundfile as sf

    from app.audio.features import analyse_frames
    from app.config import get_settings
    from app.detection.acoustic import AcousticDetector
    from app.detection.base import LABELS as SERVICE_LABELS

    det, thr = AcousticDetector(), get_settings().window_threshold
    out = np.zeros((len(paths), len(labels)), dtype=int)
    for k, path in enumerate(paths):
        audio, sr = sf.read(path, dtype="float32")
        frames = analyse_frames(audio, sr)
        if not frames.active.any() or len(frames.nuclei) == 0:
            continue  # silence: nothing detected, as in the pipeline
        probs = det.detect(audio, sr, frames).probs
        for i, lab in enumerate(labels):
            out[k, i] = int((probs[:, SERVICE_LABELS.index(lab)] >= thr).any())
    return out


def export_head(path: Path, model, inputs: list[str], labels, thresholds: dict, layer: int | None,
                encoder: str | None, metrics: dict, note: str = "") -> str:
    import joblib

    stamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
    version = f"c1-head-{'+'.join(inputs)}-{stamp[:10]}"
    head = {"inputs": inputs, "layer": layer, "encoder": encoder, "model": model, "labels": list(labels),
            "thresholds": thresholds, "version": version,
            "training": {"trainedAt": stamp, "metrics": metrics, "note": note}}
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(head, path)
    return version
