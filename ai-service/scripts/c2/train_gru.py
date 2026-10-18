"""Train and evaluate the participant-independent CASA SRCD-GRU models."""

from __future__ import annotations

import argparse
import csv
import json
import random
import sys
from pathlib import Path
from typing import Any

import numpy as np
import torch
from sklearn.metrics import (average_precision_score, confusion_matrix, f1_score,
                             precision_score, recall_score, roc_auc_score)
from torch import nn
from torch.utils.data import DataLoader, TensorDataset


SERVICE_ROOT = Path(__file__).resolve().parents[2]
PROCESSED_ROOT = SERVICE_ROOT / "data" / "casa" / "processed"
WINDOW_ROOT = PROCESSED_ROOT / "windows"
BLENDSHAPE_NAMES_PATH = PROCESSED_ROOT / "features" / "blendshape_names.json"
OUTPUT_ROOT = SERVICE_ROOT / "models" / "c2_srcd_gru"
SEED = 42
FPS = 15
SEQ_LEN = 30
RAW_FEATURE_DIM = 111
FACE_PRESENT_INDEX = 55
FEATURE_NAMES: list[str] = []


class SRCDGRU(nn.Module):
    def __init__(self, input_dim: int, hidden: int = 64, num_layers: int = 2,
                 dropout: float = 0.2, num_classes: int = 2) -> None:
        super().__init__()
        self.gru = nn.GRU(input_dim, hidden, num_layers=num_layers,
                          batch_first=True, bidirectional=True,
                          dropout=dropout if num_layers > 1 else 0.0)
        self.dropout = nn.Dropout(dropout)
        self.head = nn.Linear(hidden * 2, num_classes)

    def forward(self, x: torch.Tensor, mask: torch.Tensor) -> torch.Tensor:
        out, _ = self.gru(x)
        out = self.dropout(out)
        weights = mask.unsqueeze(-1).float()
        pooled = (out * weights).sum(1) / weights.sum(1).clamp(min=1e-6)
        return self.head(pooled)


def set_seeds() -> None:
    random.seed(SEED)
    np.random.seed(SEED)
    torch.manual_seed(SEED)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(SEED)


def load_split(split: str) -> dict[str, np.ndarray]:
    path = WINDOW_ROOT / f"{split}.npz"
    with np.load(path, allow_pickle=True) as data:
        result = {key: data[key] for key in
                  ("X", "frame_mask", "y", "participant_id", "task", "media_file",
                   "window_start_ms", "window_end_ms")}
    if result["X"].shape[1:] != (SEQ_LEN, RAW_FEATURE_DIM):
        raise ValueError(f"Unexpected {split} X shape: {result['X'].shape}")
    if result["frame_mask"].shape != result["X"].shape[:2]:
        raise ValueError(f"Unexpected {split} frame_mask shape: {result['frame_mask'].shape}")
    if result["y"].shape != (len(result["X"]), 2):
        raise ValueError(f"Unexpected {split} y shape: {result['y'].shape}")
    return result


def fit_normalization(train_x: np.ndarray, train_mask: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    valid = train_x[train_mask].astype(np.float64, copy=False)
    if valid.size == 0:
        raise ValueError("No train frames have frame_mask=True")
    mean = valid.mean(axis=0).astype(np.float32)
    std = valid.std(axis=0).astype(np.float32)
    std[~np.isfinite(std) | (std < 1e-6)] = 1.0
    # face_present is a binary indicator and must remain in {0, 1}.
    mean[FACE_PRESENT_INDEX] = 0.0
    std[FACE_PRESENT_INDEX] = 1.0
    return mean, std


def apply_normalization(data: dict[str, np.ndarray], mean: np.ndarray,
                        std: np.ndarray) -> None:
    data["X"] = (data["X"] - mean[None, None, :]) / std[None, None, :]
    data["X"] = data["X"].astype(np.float32, copy=False)
    data["X"][..., FACE_PRESENT_INDEX] = np.clip(
        data["X"][..., FACE_PRESENT_INDEX], 0.0, 1.0
    )


def participant_baselines(data: dict[str, np.ndarray]) -> tuple[
        dict[str, tuple[np.ndarray, np.ndarray]], np.ndarray, np.ndarray, list[str]]:
    x, mask, y = data["X"], data["frame_mask"], data["y"]
    pids = data["participant_id"].astype(str)
    baselines: dict[str, tuple[np.ndarray, np.ndarray]] = {}
    missing_negative: list[str] = []
    for pid in sorted(set(pids)):
        windows = (pids == pid) & (y[:, 0] == 0) & (y[:, 1] == 0)
        frame_values = x[windows][mask[windows]]
        if len(frame_values) == 0:
            missing_negative.append(pid)
            continue
        median = np.median(frame_values, axis=0).astype(np.float32)
        mad = np.median(np.abs(frame_values - median), axis=0)
        scale = (1.4826 * mad + 1e-6).astype(np.float32)
        baselines[pid] = (median, scale)
    if not baselines:
        raise ValueError("No train participants have negative (FG=0, HM=0) windows")
    population_median = np.mean(np.stack([pair[0] for pair in baselines.values()]), axis=0)
    population_scale = np.mean(np.stack([pair[1] for pair in baselines.values()]), axis=0)
    population_scale = np.maximum(population_scale, 1e-6)
    return baselines, population_median.astype(np.float32), population_scale.astype(np.float32), missing_negative


def deviation_features(data: dict[str, np.ndarray],
                       baselines: dict[str, tuple[np.ndarray, np.ndarray]],
                       population_median: np.ndarray,
                       population_scale: np.ndarray,
                       *, participant_specific: bool) -> np.ndarray:
    x, mask = data["X"], data["frame_mask"]
    pids = data["participant_id"].astype(str)
    deviations = np.zeros_like(x, dtype=np.float32)
    for pid in np.unique(pids):
        indices = np.flatnonzero(pids == pid)
        if participant_specific and pid in baselines:
            median, scale = baselines[pid]
        else:
            median, scale = population_median, population_scale
        dev = np.clip((x[indices] - median[None, None, :]) /
                      scale[None, None, :], -5.0, 5.0)
        deviations[indices] = np.nan_to_num(dev, nan=0.0, posinf=5.0, neginf=-5.0)
    deviations[~mask] = 0.0
    return deviations


def augment_with_deviations(data: dict[str, np.ndarray],
                            baselines: dict[str, tuple[np.ndarray, np.ndarray]],
                            population_median: np.ndarray,
                            population_scale: np.ndarray,
                            *, participant_specific: bool) -> None:
    dev = deviation_features(data, baselines, population_median,
                             population_scale, participant_specific=participant_specific)
    data["X"] = np.concatenate([data["X"], dev], axis=2).astype(np.float32, copy=False)


def binary_metrics(y_true: np.ndarray, probabilities: np.ndarray,
                   threshold: float) -> tuple[dict[str, Any], np.ndarray]:
    y_true = y_true.astype(np.int32)
    predictions = (probabilities >= threshold).astype(np.int32)
    positives = int(y_true.sum())
    negatives = int(len(y_true) - positives)
    n_total = int(len(y_true))
    base_rate = float(positives / n_total) if n_total else 0.0
    majority_baseline_accuracy = max(base_rate, 1.0 - base_rate) if n_total else None
    accuracy = float(np.mean(predictions == y_true)) if n_total else None
    common = {
        "accuracy": accuracy,
        "base_rate": base_rate,
        "majority_baseline_accuracy": majority_baseline_accuracy,
        "delta_over_baseline": (accuracy - majority_baseline_accuracy)
        if accuracy is not None and majority_baseline_accuracy is not None else None,
        "n_total": n_total,
        "n_positive": positives,
        "n_negative": negatives,
    }
    if positives == 0:
        return ({**common, "precision": None, "recall": None, "f1": None, "pr_auc": None,
                 "roc_auc": None, "support": 0, "negative_support": negatives,
                 "confusion_matrix": confusion_matrix(y_true, predictions, labels=[0, 1]).tolist(),
                 "undefined": "no positive labels"}, predictions)
    precision = float(precision_score(y_true, predictions, zero_division=0))
    recall = float(recall_score(y_true, predictions, zero_division=0))
    f1 = float(f1_score(y_true, predictions, zero_division=0))
    pr_auc = float(average_precision_score(y_true, probabilities))
    roc_auc = float(roc_auc_score(y_true, probabilities)) if negatives else None
    return ({**common, "precision": precision, "recall": recall, "f1": f1,
             "pr_auc": pr_auc, "roc_auc": roc_auc, "support": positives,
             "negative_support": negatives,
             "confusion_matrix": confusion_matrix(y_true, predictions, labels=[0, 1]).tolist()},
            predictions)


def bootstrap_f1(y: np.ndarray, predictions: np.ndarray, participants: np.ndarray,
                 *, seed: int) -> tuple[float, float] | None:
    pids = participants.astype(str)
    unique_pids = np.unique(pids)
    if len(unique_pids) == 0 or int(y.sum()) == 0:
        return None
    rows_by_pid = {pid: np.flatnonzero(pids == pid) for pid in unique_pids}
    rng = np.random.default_rng(seed)
    samples: list[float] = []
    for _ in range(1000):
        sampled = rng.choice(unique_pids, size=len(unique_pids), replace=True)
        indices = np.concatenate([rows_by_pid[pid] for pid in sampled])
        samples.append(float(f1_score(y[indices], predictions[indices], zero_division=0)))
    low, high = np.quantile(samples, [0.025, 0.975])
    return float(low), float(high)


def evaluate(probabilities: np.ndarray, data: dict[str, np.ndarray],
             thresholds: dict[str, float], seed_offset: int) -> dict[str, Any]:
    valid_windows = np.asarray(data["frame_mask"]).any(axis=1)
    y = data["y"][valid_windows].astype(np.int32)
    probabilities = probabilities[valid_windows]
    pids = data["participant_id"][valid_windows].astype(str)
    labels = ("FG", "HM")
    classes: dict[str, Any] = {}
    per_participant: dict[str, Any] = {}
    f1_values = []
    for class_index, label in enumerate(labels):
        metrics, predictions = binary_metrics(y[:, class_index], probabilities[:, class_index],
                                              thresholds[label])
        ci = bootstrap_f1(y[:, class_index], predictions, pids,
                          seed=SEED + seed_offset + class_index)
        metrics["f1_95_ci"] = list(ci) if ci is not None else None
        metrics["bootstrap_f1_ci_95"] = list(ci) if ci is not None else None
        if metrics["f1"] is None:
            print(f"METRIC UNDEFINED: {label} has 0 positive labels")
        if metrics["roc_auc"] is None and metrics["support"]:
            print(f"METRIC UNDEFINED: {label} ROC-AUC requires both classes")
        classes[label] = metrics
        if metrics["f1"] is not None:
            f1_values.append(metrics["f1"])
        for pid in sorted(np.unique(pids)):
            indices = pids == pid
            entry = per_participant.setdefault(pid, {"n": int(indices.sum())})
            entry[f"{label}_f1"] = float(f1_score(y[indices, class_index], predictions[indices],
                                                   zero_division=0))
    macro_f1 = float(np.mean(f1_values)) if len(f1_values) == 2 else None
    return {"primary_metric": "F1 (accuracy is reported for reference only; see majority_baseline_accuracy)",
            "thresholds": thresholds, "classes": classes,
            "macro_f1": macro_f1, "per_participant_f1": per_participant}


def attach_assessment_status(metrics: dict[str, Any],
                             tuned: dict[str, dict[str, Any]]) -> None:
    for label in ("FG", "HM"):
        feasible = bool(tuned[label]["constraint_feasible"])
        if label == "HM":
            status = "not_assessed"
            reason = (tuned[label].get("reason") if not feasible else
                      "HM is designated not_assessed by the evaluation scope decision.")
        else:
            status = "assessed" if feasible else "assessed_with_caveat"
            reason = (None if feasible else
                      tuned[label].get("reason", "precision >= 0.5 constraint is infeasible"))
        metrics["classes"][label]["assessment_status"] = status
        if reason:
            metrics["classes"][label]["reason"] = reason


def predict(model: nn.Module, data: dict[str, np.ndarray], device: torch.device,
            batch_size: int) -> np.ndarray:
    model.eval()
    tensor_x = torch.from_numpy(np.ascontiguousarray(data["X"], dtype=np.float32))
    tensor_mask = torch.from_numpy(np.ascontiguousarray(data["frame_mask"], dtype=np.bool_))
    loader = DataLoader(TensorDataset(tensor_x, tensor_mask), batch_size=batch_size,
                        shuffle=False, num_workers=0)
    outputs: list[np.ndarray] = []
    with torch.no_grad():
        for batch_x, batch_mask in loader:
            logits = model(batch_x.to(device), batch_mask.to(device))
            outputs.append(torch.sigmoid(logits).cpu().numpy())
    return np.concatenate(outputs, axis=0)


def tune_thresholds(y: np.ndarray, probabilities: np.ndarray,
                    window_mask: np.ndarray) -> dict[str, dict[str, Any]]:
    candidates = [round(0.05 + index * 0.01, 2) for index in range(91)]
    selected_windows = window_mask.astype(bool)
    y = y[selected_windows].astype(np.int32)
    probabilities = probabilities[selected_windows]
    result: dict[str, dict[str, Any]] = {}
    for index, label in enumerate(("FG", "HM")):
        scored = []
        for threshold in candidates:
            metrics, _ = binary_metrics(y[:, index], probabilities[:, index], threshold)
            scored.append((threshold, metrics))

        best_f1 = max(item[1]["f1"] or 0.0 for item in scored)
        best_f1_threshold = min(
            (threshold for threshold, metrics in scored
             if abs((metrics["f1"] or 0.0) - best_f1) < 1e-12),
            key=lambda value: (abs(value - 0.5), value),
        )
        eligible = [(threshold, metrics) for threshold, metrics in scored
                    if metrics["precision"] is not None and metrics["precision"] >= 0.5]
        by_threshold = {threshold: metrics for threshold, metrics in scored}
        entry: dict[str, Any] = {
            "threshold_f1_max": float(best_f1_threshold),
            "threshold_precision_0.5": None,
            "constraint_feasible": bool(eligible),
            "val_precision_at_threshold_f1_max": by_threshold[best_f1_threshold]["precision"],
            "val_f1_at_threshold_f1_max": by_threshold[best_f1_threshold]["f1"],
        }
        if eligible:
            constrained_f1 = max(item[1]["f1"] or 0.0 for item in eligible)
            constrained_threshold = min(
                (threshold for threshold, metrics in eligible
                 if abs((metrics["f1"] or 0.0) - constrained_f1) < 1e-12),
                key=lambda value: (abs(value - 0.5), value),
            )
            entry["threshold_precision_0.5"] = float(constrained_threshold)
            entry["val_precision_at_threshold_precision_0.5"] = by_threshold[constrained_threshold]["precision"]
            entry["val_f1_at_threshold_precision_0.5"] = by_threshold[constrained_threshold]["f1"]
        else:
            best_precision = max(
                (item for item in scored if item[1]["precision"] is not None),
                key=lambda item: (item[1]["precision"], item[1]["f1"] or 0.0,
                                 -abs(item[0] - 0.5)),
            )
            entry["reason"] = (
                "no threshold in 0.05..0.95 achieves precision >= 0.5; "
                f"best precision = {best_precision[1]['precision']:.4f} "
                f"at threshold {best_precision[0]:.2f}"
            )
        result[label] = entry
    return result


def fit_model(mode: str, train: dict[str, np.ndarray], val: dict[str, np.ndarray],
              input_dim: int, pos_weight: np.ndarray, device: torch.device,
              config: dict[str, Any]) -> tuple[SRCDGRU, list[dict[str, float]], int, float]:
    model = SRCDGRU(input_dim=input_dim).to(device)
    criterion = nn.BCEWithLogitsLoss(
        pos_weight=torch.tensor(pos_weight, dtype=torch.float32, device=device)
    )
    optimizer = torch.optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(
        optimizer, mode="max", factor=0.5, patience=2
    )

    train_x = torch.from_numpy(np.ascontiguousarray(train["X"], dtype=np.float32))
    train_mask = torch.from_numpy(np.ascontiguousarray(train["frame_mask"], dtype=np.bool_))
    train_y = torch.from_numpy(np.ascontiguousarray(train["y"], dtype=np.float32))
    generator = torch.Generator().manual_seed(SEED)
    loader = DataLoader(TensorDataset(train_x, train_mask, train_y),
                        batch_size=32, shuffle=True, num_workers=0,
                        generator=generator)

    checkpoint_path = OUTPUT_ROOT / f"best_{mode}.pt"
    best_val_macro_f1 = -1.0
    best_epoch = 0
    patience_count = 0
    history: list[dict[str, float]] = []
    for epoch in range(1, 51):
        model.train()
        total_loss = 0.0
        seen = 0
        for batch_x, batch_mask, batch_y in loader:
            batch_x = batch_x.to(device)
            batch_mask = batch_mask.to(device)
            batch_y = batch_y.to(device)
            optimizer.zero_grad(set_to_none=True)
            logits = model(batch_x, batch_mask)
            loss = criterion(logits, batch_y)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()
            total_loss += float(loss.item()) * len(batch_x)
            seen += len(batch_x)

        train_loss = total_loss / max(1, seen)
        val_probabilities = predict(model, val, device, batch_size=128)
        val_loss_sum = 0.0
        val_count = 0
        model.eval()
        val_x = torch.from_numpy(np.ascontiguousarray(val["X"], dtype=np.float32))
        val_mask = torch.from_numpy(np.ascontiguousarray(val["frame_mask"], dtype=np.bool_))
        val_y = torch.from_numpy(np.ascontiguousarray(val["y"], dtype=np.float32))
        with torch.no_grad():
            for start in range(0, len(val_x), 128):
                end = min(start + 128, len(val_x))
                logits = model(val_x[start:end].to(device), val_mask[start:end].to(device))
                batch_loss = criterion(logits, val_y[start:end].to(device))
                val_loss_sum += float(batch_loss.item()) * (end - start)
                val_count += end - start
        val_loss = val_loss_sum / max(1, val_count)
        valid_val_windows = np.asarray(val["frame_mask"]).any(axis=1)
        val_predictions = val_probabilities[valid_val_windows] >= 0.5
        val_labels = val["y"][valid_val_windows]
        val_f1_fg = float(f1_score(val_labels[:, 0], val_predictions[:, 0], zero_division=0))
        val_f1_hm = float(f1_score(val_labels[:, 1], val_predictions[:, 1], zero_division=0))
        val_macro_f1 = (val_f1_fg + val_f1_hm) / 2.0
        scheduler.step(val_macro_f1)
        lr = float(optimizer.param_groups[0]["lr"])
        entry = {"epoch": float(epoch), "train_loss": train_loss,
                 "val_loss": val_loss,
                 "val_f1_FG": val_f1_fg,
                 "val_f1_HM": val_f1_hm,
                 "val_macro_f1": val_macro_f1, "lr": lr}
        history.append(entry)
        print(f"Epoch {epoch}: train_loss {train_loss:.3f} | val_loss {val_loss:.3f} | "
              f"val_F1_FG {entry['val_f1_FG']:.3f} | val_F1_HM {entry['val_f1_HM']:.3f} | "
              f"val_macro_F1 {val_macro_f1:.3f}", flush=True)

        if val_macro_f1 > best_val_macro_f1:
            best_val_macro_f1 = val_macro_f1
            best_epoch = epoch
            patience_count = 0
            torch.save({"model_state_dict": model.state_dict(), "input_dim": input_dim,
                        "epoch": epoch, "val_macro_f1_default": val_macro_f1}, checkpoint_path)
        else:
            patience_count += 1
        if patience_count >= 8:
            break

    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=True)
    model.load_state_dict(checkpoint["model_state_dict"])
    with (OUTPUT_ROOT / f"history_{mode}.csv").open("w", newline="", encoding="utf-8") as handle:
        fieldnames = ["epoch", "train_loss", "val_loss", "val_f1_FG", "val_f1_HM",
                      "val_macro_f1", "lr"]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(history)
    return model, history, best_epoch, best_val_macro_f1


def channel_names() -> list[str]:
    names = json.loads(BLENDSHAPE_NAMES_PATH.read_text(encoding="utf-8"))
    if len(names) != 52:
        raise ValueError(f"Expected 52 canonical blendshape names, got {len(names)}")
    raw = [f"blendshape:{name}" for name in names]
    raw += ["head_pose:pitch", "head_pose:yaw", "head_pose:roll", "face_present"]
    raw += [f"velocity_blendshape:{name}" for name in names]
    raw += ["velocity_head_pose:pitch", "velocity_head_pose:yaw", "velocity_head_pose:roll"]
    if len(raw) != RAW_FEATURE_DIM:
        raise AssertionError(f"Expected 111 feature names, got {len(raw)}")
    return raw


def pretty_metric(value: Any) -> str:
    return "METRIC UNDEFINED" if value is None else f"{value:.2f}"


def print_metric_section(title: str, metrics: dict[str, Any]) -> None:
    print(f"=== {title} metrics (primary: F1 / PR-AUC) ===")
    for label in ("FG", "HM"):
        item = metrics["classes"][label]
        ci = item.get("f1_95_ci")
        ci_text = "METRIC UNDEFINED" if ci is None else f"{ci[0]:.2f}–{ci[1]:.2f}"
        print(f"{label}: P={pretty_metric(item['precision'])} R={pretty_metric(item['recall'])} "
              f"F1={pretty_metric(item['f1'])} (95% CI {ci_text}) "
              f"PR-AUC={pretty_metric(item['pr_auc'])} ROC-AUC={pretty_metric(item['roc_auc'])} | "
              f"acc={item['accuracy']:.3f} (baseline={item['majority_baseline_accuracy']:.3f}, "
              f"delta={item['delta_over_baseline']:+.3f}) "
              f"CM={item['confusion_matrix']} support={item['support']}")
    print(f"Macro-F1: {pretty_metric(metrics['macro_f1'])}")


def train_mode(mode: str, device: torch.device) -> dict[str, Any]:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    set_seeds()
    # Test is intentionally not loaded here. Only train and validation are read
    # until checkpoint selection and validation threshold tuning are complete.
    train = load_split("train")
    val = load_split("val")
    train["X"] = train["X"].astype(np.float32, copy=True)
    val["X"] = val["X"].astype(np.float32, copy=True)

    mean, std = fit_normalization(train["X"], train["frame_mask"])
    np.savez_compressed(OUTPUT_ROOT / f"norm_stats_{mode}.npz", mean=mean, std=std,
                        face_present_index=np.asarray(FACE_PRESENT_INDEX),
                        feature_dim=np.asarray(RAW_FEATURE_DIM))
    apply_normalization(train, mean, std)
    apply_normalization(val, mean, std)

    speaker_relative: dict[str, Any] | None = None
    baselines = population_median = population_scale = None
    if mode == "srcd":
        baselines, population_median, population_scale, missing_negative = participant_baselines(train)
        augment_with_deviations(train, baselines, population_median,
                                population_scale, participant_specific=True)
        # Validation participants use only the train-population fallback.
        augment_with_deviations(val, baselines, population_median,
                                population_scale, participant_specific=False)
        speaker_relative = {
            "normalization_mode": "train_population_fallback",
            "feature_dim": RAW_FEATURE_DIM * 2,
            "raw_feature_dim": RAW_FEATURE_DIM,
            "deviation_feature_dim": RAW_FEATURE_DIM,
            "baseline_source": "negative train windows only (FG=0 and HM=0), per training participant",
            "fallback": "mean across training participants' per-channel medians and robust scales; used for validation/test and train participants without negative windows",
            "baseline_participants": len(baselines),
            "train_participants_without_negative_windows": missing_negative,
        }

    train_rates = train["y"].mean(axis=0)
    pos_weight = (1.0 - train_rates) / train_rates
    if not np.isfinite(pos_weight).all():
        raise ValueError(f"Non-finite train positive-class weights: {pos_weight}")
    input_dim = train["X"].shape[2]
    config: dict[str, Any] = {
        "mode": mode,
        "seed": SEED,
        "device": str(device),
        "fps": FPS,
        "sequence_length": SEQ_LEN,
        "raw_feature_dim": RAW_FEATURE_DIM,
        "input_feature_dim": input_dim,
        "hidden": 64,
        "num_layers": 2,
        "dropout": 0.2,
        "optimizer": "AdamW",
        "learning_rate": 1e-3,
        "weight_decay": 1e-4,
        "scheduler": {"name": "ReduceLROnPlateau", "mode": "max", "factor": 0.5,
                      "patience": 2, "metric": "validation default-threshold macro-F1"},
        "gradient_clip_norm": 1.0,
        "batch_size": 32,
        "max_epochs": 50,
        "early_stopping_patience": 8,
        "loss": "BCEWithLogitsLoss",
        "pos_weight": {"FG": float(pos_weight[0]), "HM": float(pos_weight[1])},
        "train_windows": len(train["X"]),
        "val_windows": len(val["X"]),
        "normalization_fit_split": "train only; frame_mask=True; face_present left unnormalized",
        "speaker_relative": speaker_relative,
    }
    (OUTPUT_ROOT / f"config_{mode}.json").write_text(json.dumps(config, indent=2), encoding="utf-8")

    print(f"=== Training {mode} ===")
    print(f"Train windows: {len(train['X'])} | Val windows: {len(val['X'])} | Test windows: (loaded only for final evaluation)")
    print(f"Feature dim: {input_dim}")
    print(f"pos_weight FG: {pos_weight[0]:.2f} | HM: {pos_weight[1]:.2f}")
    model, history, best_epoch, best_default_macro = fit_model(
        mode, train, val, input_dim, pos_weight, device, config
    )
    print(f"Best epoch: {best_epoch} | Best val macro-F1: {best_default_macro:.3f}")

    val_probabilities = predict(model, val, device, batch_size=128)
    tuned = tune_thresholds(val["y"], val_probabilities,
                            np.asarray(val["frame_mask"]).any(axis=1))
    thresholds_f1_max = {label: tuned[label]["threshold_f1_max"] for label in ("FG", "HM")}
    thresholds_precision = {
        label: (tuned[label]["threshold_precision_0.5"]
                if tuned[label]["threshold_precision_0.5"] is not None
                else tuned[label]["threshold_f1_max"])
        for label in ("FG", "HM")
    }
    (OUTPUT_ROOT / f"thresholds_{mode}.json").write_text(
        json.dumps(tuned, indent=2), encoding="utf-8"
    )
    print("Validation thresholds:")
    for label in ("FG", "HM"):
        raw_constrained = tuned[label]["threshold_precision_0.5"]
        constrained_text = f"{raw_constrained:.2f}" if raw_constrained is not None else "null (infeasible)"
        print(f"  {label}: threshold_f1_max={thresholds_f1_max[label]:.2f} | "
              f"threshold_precision_0.5={constrained_text}")

    val_default_metrics = evaluate(val_probabilities, val,
                                  {"FG": 0.5, "HM": 0.5}, seed_offset=100_000)
    attach_assessment_status(val_default_metrics, tuned)
    if not np.isclose(best_default_macro, val_default_metrics["macro_f1"], atol=1e-12):
        raise RuntimeError(
            "Checkpoint-selection score does not match threshold-0.5 validation macro-F1: "
            f"selected={best_default_macro:.12f}, recomputed={val_default_metrics['macro_f1']:.12f}"
        )
    val_metrics_f1_max = evaluate(val_probabilities, val, thresholds_f1_max,
                                  seed_offset=200_000)
    attach_assessment_status(val_metrics_f1_max, tuned)
    val_metrics = evaluate(val_probabilities, val, thresholds_precision,
                           seed_offset=210_000)
    attach_assessment_status(val_metrics, tuned)
    print_metric_section("VAL", val_metrics)

    # Final evaluation only: this is the first point where the test split is loaded.
    test = load_split("test")
    print(f"Final evaluation split counts: train={len(train['X'])} | val={len(val['X'])} | test={len(test['X'])}")
    test["X"] = test["X"].astype(np.float32, copy=True)
    apply_normalization(test, mean, std)
    if mode == "srcd":
        assert speaker_relative is not None
        assert baselines is not None and population_median is not None and population_scale is not None
        augment_with_deviations(test, baselines, population_median,
                                population_scale, participant_specific=False)
    test_probabilities = predict(model, test, device, batch_size=128)
    test_metrics_f1_max = evaluate(test_probabilities, test, thresholds_f1_max,
                                   seed_offset=300_000)
    attach_assessment_status(test_metrics_f1_max, tuned)
    test_metrics = evaluate(test_probabilities, test, thresholds_precision,
                            seed_offset=310_000)
    attach_assessment_status(test_metrics, tuned)
    print_metric_section("TEST", test_metrics)
    print_metric_section("TEST threshold_f1_max (secondary)", test_metrics_f1_max)
    print("Per-participant F1 (test):")
    for pid, values in sorted(test_metrics["per_participant_f1"].items(), key=lambda item: item[0]):
        print(f"  p{pid}: FG={values['FG_f1']:.2f} HM={values['HM_f1']:.2f} (n={values['n']})")

    cm_json = {"val": {label: val_metrics["classes"][label]["confusion_matrix"]
                        for label in ("FG", "HM")},
               "test": {label: test_metrics["classes"][label]["confusion_matrix"]
                         for label in ("FG", "HM")},
               "test_threshold_f1_max": {
                   label: test_metrics_f1_max["classes"][label]["confusion_matrix"]
                   for label in ("FG", "HM")}}
    (OUTPUT_ROOT / f"confusion_matrices_{mode}.json").write_text(
        json.dumps(cm_json, indent=2), encoding="utf-8"
    )

    report_lines = [f"SRCD-GRU classification report ({mode})",
                    f"Best epoch: {best_epoch}",
                    f"Best validation default-threshold macro-F1: {best_default_macro:.6f}",
                    f"Validation precision>=0.5 thresholds: FG={tuned['FG']['threshold_precision_0.5']}, HM={tuned['HM']['threshold_precision_0.5']}",
                    f"Validation F1-max thresholds: FG={thresholds_f1_max['FG']:.2f}, HM={thresholds_f1_max['HM']:.2f}"]
    for title, metrics in (("VAL primary precision>=0.5", val_metrics),
                           ("VAL secondary F1-max", val_metrics_f1_max),
                           ("TEST primary precision>=0.5", test_metrics),
                           ("TEST secondary F1-max", test_metrics_f1_max)):
        report_lines.append(f"\n{title}")
        for label in ("FG", "HM"):
            item = metrics["classes"][label]
            report_lines.append(
                f"{label}: precision={item['precision']} recall={item['recall']} f1={item['f1']} "
                f"accuracy={item['accuracy']} majority_baseline_accuracy={item['majority_baseline_accuracy']} "
                f"base_rate={item['base_rate']} delta_over_baseline={item['delta_over_baseline']} "
                f"n_total={item['n_total']} n_positive={item['n_positive']} n_negative={item['n_negative']} "
                f"pr_auc={item['pr_auc']} roc_auc={item['roc_auc']} "
                f"bootstrap_f1_ci_95={item['bootstrap_f1_ci_95']} support={item['support']} "
                f"confusion_matrix={item['confusion_matrix']}"
            )
        report_lines.append(f"Macro-F1: {metrics['macro_f1']}")
        report_lines.append("Per-participant F1:")
        report_lines.extend(f"  p{pid}: FG={item['FG_f1']:.6f} HM={item['HM_f1']:.6f} n={item['n']}"
                            for pid, item in sorted(metrics["per_participant_f1"].items()))
    (OUTPUT_ROOT / f"classification_report_{mode}.txt").write_text(
        "\n".join(report_lines) + "\n", encoding="utf-8"
    )

    results: dict[str, Any] = {
        "mode": mode,
        "seed": SEED,
        "best_epoch": best_epoch,
        "best_validation_macro_f1_default_threshold": best_default_macro,
        "mode_selection_metric": "validation macro-F1 at threshold 0.5, frame_mask.any(axis=1) windows only",
        "assessment_decision": {
            "HM": {
                "assessment_status": "not_assessed",
                "reason": "No reliable detection above chance; interpret alongside majority-class baseline accuracy.",
                "future_work": "Consider a conditional HM model trained only on FG-positive windows.",
            }
        },
        "thresholds": tuned,
        "pos_weight": {"FG": float(pos_weight[0]), "HM": float(pos_weight[1])},
        "train_windows": len(train["X"]),
        "val_windows": len(val["X"]),
        "test_windows": len(test["X"]),
        "feature_dim": input_dim,
        "feature_channels": {
            "raw": FEATURE_NAMES,
            "deviation": [f"deviation:{name}" for name in FEATURE_NAMES] if mode == "srcd" else [],
        },
        "normalization": {
            "fit_split": "train",
            "frame_mask_only": True,
            "face_present_normalized": False,
            "stats_path": str(OUTPUT_ROOT / f"norm_stats_{mode}.npz"),
        },
        "speaker_relative": speaker_relative,
        "history_epochs": len(history),
        "val_default_threshold_metrics": val_default_metrics,
        "val_threshold_f1_max_metrics": val_metrics_f1_max,
        "val_metrics": val_metrics,
        "test_threshold_f1_max_metrics": test_metrics_f1_max,
        "test_metrics": test_metrics,
        "test_loaded_for_final_evaluation_only": True,
    }
    results_path = OUTPUT_ROOT / f"results_{mode}.json"
    results_path.write_text(json.dumps(results, indent=2, allow_nan=False), encoding="utf-8")
    print(f"Saved results: {results_path}")

    other_mode = "srcd" if mode == "ordinary" else "ordinary"
    other_path = OUTPUT_ROOT / f"results_{other_mode}.json"
    if other_path.is_file():
        other = json.loads(other_path.read_text(encoding="utf-8"))
        if other.get("mode_selection_metric") == results["mode_selection_metric"]:
            current_val = val_default_metrics["macro_f1"]
            other_val = other["val_default_threshold_metrics"]["macro_f1"]
            best_mode = mode if current_val >= other_val else other_mode
            ordinary_val = other_val if other_mode == "ordinary" else current_val
            srcd_val = current_val if mode == "srcd" else other_val
            print(f"Val-selected best mode: {best_mode} "
                  f"(ordinary={ordinary_val:.3f}, srcd={srcd_val:.3f}; "
                  f"criterion=val_default_threshold_metrics['macro_f1'])")
            print("Test ablation scores (reported for both modes only; not used for selection):")
            ordinary_test = other["test_metrics"]["macro_f1"] if other_mode == "ordinary" else test_metrics["macro_f1"]
            srcd_test = test_metrics["macro_f1"] if mode == "srcd" else other["test_metrics"]["macro_f1"]
            print(f"  ordinary test macro-F1: {ordinary_test:.3f}")
            print(f"  srcd test macro-F1: {srcd_test:.3f}")
        else:
            print(f"Mode selection pending: rerun {other_mode} with this script version; "
                  "comparison uses validation macro-F1 at threshold 0.5 only.")
    return results


def prepare_saved_mode(mode: str, device: torch.device) -> dict[str, Any]:
    """Load a completed checkpoint and prepare validation-only thresholds."""
    train = load_split("train")
    val = load_split("val")
    train["X"] = train["X"].astype(np.float32, copy=True)
    val["X"] = val["X"].astype(np.float32, copy=True)
    with np.load(OUTPUT_ROOT / f"norm_stats_{mode}.npz") as stats:
        mean, std = stats["mean"].copy(), stats["std"].copy()
    apply_normalization(train, mean, std)
    apply_normalization(val, mean, std)

    baselines = population_median = population_scale = None
    speaker_relative = None
    if mode == "srcd":
        baselines, population_median, population_scale, missing_negative = participant_baselines(train)
        augment_with_deviations(train, baselines, population_median,
                                population_scale, participant_specific=True)
        augment_with_deviations(val, baselines, population_median,
                                population_scale, participant_specific=False)
        speaker_relative = {
            "normalization_mode": "train_population_fallback",
            "feature_dim": RAW_FEATURE_DIM * 2,
            "raw_feature_dim": RAW_FEATURE_DIM,
            "deviation_feature_dim": RAW_FEATURE_DIM,
            "baseline_source": "negative train windows only (FG=0 and HM=0), per training participant",
            "fallback": "mean across training participants' per-channel medians and robust scales; used for validation/test",
            "baseline_participants": len(baselines),
            "train_participants_without_negative_windows": missing_negative,
        }

    checkpoint_path = OUTPUT_ROOT / f"best_{mode}.pt"
    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=True)
    input_dim = int(checkpoint["input_dim"])
    model = SRCDGRU(input_dim=input_dim).to(device)
    model.load_state_dict(checkpoint["model_state_dict"])
    probabilities = predict(model, val, device, batch_size=128)
    tuned = tune_thresholds(val["y"], probabilities,
                            np.asarray(val["frame_mask"]).any(axis=1))
    (OUTPUT_ROOT / f"thresholds_{mode}.json").write_text(
        json.dumps(tuned, indent=2), encoding="utf-8"
    )

    selected_thresholds = {
        label: (tuned[label]["threshold_precision_0.5"]
                if tuned[label]["threshold_precision_0.5"] is not None
                else tuned[label]["threshold_f1_max"])
        for label in ("FG", "HM")
    }
    val_default = evaluate(probabilities, val, {"FG": 0.5, "HM": 0.5}, 100_000)
    val_f1_max = evaluate(probabilities, val,
                          {label: tuned[label]["threshold_f1_max"] for label in ("FG", "HM")},
                          200_000)
    val_selected = evaluate(probabilities, val, selected_thresholds, 210_000)
    for metrics in (val_default, val_f1_max, val_selected):
        attach_assessment_status(metrics, tuned)

    best_default_macro = float(checkpoint["val_macro_f1_default"])
    if not np.isclose(best_default_macro, val_default["macro_f1"], atol=1e-12):
        raise RuntimeError(
            f"{mode} checkpoint score mismatch: selected={best_default_macro:.12f}, "
            f"recomputed={val_default['macro_f1']:.12f}"
        )

    history_path = OUTPUT_ROOT / f"history_{mode}.csv"
    if history_path.is_file():
        with history_path.open(newline="", encoding="utf-8") as handle:
            for row in csv.DictReader(handle):
                print(f"Epoch {int(float(row['epoch']))}: train_loss {float(row['train_loss']):.3f} | "
                      f"val_loss {float(row['val_loss']):.3f} | "
                      f"val_F1_FG {float(row['val_f1_FG']):.3f} | "
                      f"val_F1_HM {float(row['val_f1_HM']):.3f} | "
                      f"val_macro_F1 {float(row['val_macro_f1']):.3f}")
    print(f"Best epoch: {checkpoint['epoch']} | Best val macro-F1: {best_default_macro:.3f}")
    print(f"=== Thresholds {mode} ===")
    for label in ("FG", "HM"):
        item = tuned[label]
        constrained = item["threshold_precision_0.5"]
        if constrained is None:
            print(f"{label}: threshold_precision_0.5=null (infeasible) | "
                  f"threshold_f1_max={item['threshold_f1_max']:.2f} | "
                  f"best_precision={item['val_precision_at_threshold_f1_max']:.3f} "
                  f"-> {label} will be marked not_assessed")
        else:
            print(f"{label}: threshold_precision_0.5={constrained:.2f} | "
                  f"threshold_f1_max={item['threshold_f1_max']:.2f} | feasible=true")
    return {
        "mode": mode, "train": train, "val": val, "model": model,
        "mean": mean, "std": std, "baselines": baselines,
        "population_median": population_median,
        "population_scale": population_scale,
        "speaker_relative": speaker_relative, "input_dim": input_dim,
        "checkpoint": checkpoint, "tuned": tuned,
        "selected_thresholds": selected_thresholds,
        "val_default": val_default, "val_f1_max": val_f1_max,
        "val_selected": val_selected,
    }


def finalize_saved_modes(device: torch.device) -> None:
    """Tune both completed modes on validation before loading the test split."""
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    contexts = {mode: prepare_saved_mode(mode, device) for mode in ("ordinary", "srcd")}
    print("Both modes have completed validation thresholding; loading test for final evaluation.")
    test_raw = load_split("test")
    print(f"Final evaluation split counts: train={len(contexts['ordinary']['train']['X'])} | "
          f"val={len(contexts['ordinary']['val']['X'])} | test={len(test_raw['X'])}")

    results_by_mode: dict[str, dict[str, Any]] = {}
    for mode, context in contexts.items():
        test = {key: (value.copy() if isinstance(value, np.ndarray) else value)
                for key, value in test_raw.items()}
        test["X"] = test["X"].astype(np.float32, copy=False)
        apply_normalization(test, context["mean"], context["std"])
        if mode == "srcd":
            augment_with_deviations(test, context["baselines"],
                                    context["population_median"],
                                    context["population_scale"],
                                    participant_specific=False)
        probabilities = predict(context["model"], test, device, batch_size=128)
        f1_thresholds = {label: context["tuned"][label]["threshold_f1_max"]
                         for label in ("FG", "HM")}
        test_f1_max = evaluate(probabilities, test, f1_thresholds, 300_000)
        test_selected = evaluate(probabilities, test, context["selected_thresholds"], 310_000)
        for metrics in (test_f1_max, test_selected):
            attach_assessment_status(metrics, context["tuned"])

        print(f"=== TEST metrics {mode} ===")
        for label in ("FG", "HM"):
            item = test_selected["classes"][label]
            threshold = context["selected_thresholds"][label]
            status = item["assessment_status"]
            if status == "not_assessed":
                threshold_description = f"f1_max threshold={threshold:.2f}, NOT ASSESSED"
            else:
                threshold_description = f"primary threshold={threshold:.2f}, feasible"
            print(f"{label} ({threshold_description}): P={pretty_metric(item['precision'])} "
                  f"R={pretty_metric(item['recall'])} F1={pretty_metric(item['f1'])} "
                  f"PR-AUC={pretty_metric(item['pr_auc'])} ROC-AUC={pretty_metric(item['roc_auc'])} | "
                  f"acc={item['accuracy']:.3f} (baseline={item['majority_baseline_accuracy']:.3f}, "
                  f"delta={item['delta_over_baseline']:+.3f})")
            if item.get("reason"):
                print(f"  {label} reason: {item['reason']}")
        print(f"Macro-F1: {pretty_metric(test_selected['macro_f1'])}")
        print("Per-participant F1 (test):")
        for pid, values in sorted(test_selected["per_participant_f1"].items()):
            print(f"  p{pid}: FG={values['FG_f1']:.2f} HM={values['HM_f1']:.2f} (n={values['n']})")

        val_primary = context["val_selected"]
        val_f1_max = context["val_f1_max"]
        results: dict[str, Any] = {
            "mode": mode,
            "seed": SEED,
            "best_epoch": int(context["checkpoint"]["epoch"]),
            "best_validation_macro_f1_default_threshold": float(context["checkpoint"]["val_macro_f1_default"]),
            "mode_selection_metric": "validation macro-F1 at threshold 0.5, frame_mask.any(axis=1) windows only",
            "assessment_decision": {
                "HM": {
                    "assessment_status": "not_assessed",
                    "reason": "No reliable detection above chance; interpret alongside majority-class baseline accuracy.",
                    "future_work": "Consider a conditional HM model trained only on FG-positive windows.",
                }
            },
            "thresholds": context["tuned"],
            "pos_weight": json.loads((OUTPUT_ROOT / f"config_{mode}.json").read_text(encoding="utf-8")).get("pos_weight"),
            "train_windows": len(context["train"]["X"]),
            "val_windows": len(context["val"]["X"]),
            "test_windows": len(test["X"]),
            "feature_dim": context["input_dim"],
            "feature_channels": {
                "raw": FEATURE_NAMES,
                "deviation": [f"deviation:{name}" for name in FEATURE_NAMES] if mode == "srcd" else [],
            },
            "normalization": {
                "fit_split": "train", "frame_mask_only": True,
                "face_present_normalized": False,
                "stats_path": str(OUTPUT_ROOT / f"norm_stats_{mode}.npz"),
            },
            "speaker_relative": context["speaker_relative"],
            "val_default_threshold_metrics": context["val_default"],
            "val_threshold_f1_max_metrics": val_f1_max,
            "val_metrics": val_primary,
            "test_threshold_f1_max_metrics": test_f1_max,
            "test_metrics": test_selected,
            "test_loaded_for_final_evaluation_only": True,
            "model_weights_changed": False,
        }
        results_by_mode[mode] = results

        confusion_json = {
            "val": {label: val_primary["classes"][label]["confusion_matrix"] for label in ("FG", "HM")},
            "test": {label: test_selected["classes"][label]["confusion_matrix"] for label in ("FG", "HM")},
            "test_threshold_f1_max": {label: test_f1_max["classes"][label]["confusion_matrix"] for label in ("FG", "HM")},
        }
        (OUTPUT_ROOT / f"confusion_matrices_{mode}.json").write_text(
            json.dumps(confusion_json, indent=2), encoding="utf-8")
        (OUTPUT_ROOT / f"results_{mode}.json").write_text(
            json.dumps(results, indent=2, allow_nan=False), encoding="utf-8")
        (OUTPUT_ROOT / f"classification_report_{mode}.txt").write_text(
            f"SRCD-GRU {mode}; selected checkpoint validation macro-F1 at threshold 0.5: "
            f"{results['best_validation_macro_f1_default_threshold']:.6f}\n"
            f"HM assessment_status: not_assessed\n"
            f"VAL: {json.dumps(val_primary, indent=2)}\n"
            f"TEST: {json.dumps(test_selected, indent=2)}\n"
            f"TEST F1-max secondary: {json.dumps(test_f1_max, indent=2)}\n",
            encoding="utf-8")
        print(f"Saved results: {OUTPUT_ROOT / f'results_{mode}.json'}")

    ordinary_val = results_by_mode["ordinary"]["val_default_threshold_metrics"]["macro_f1"]
    srcd_val = results_by_mode["srcd"]["val_default_threshold_metrics"]["macro_f1"]
    best_mode = "ordinary" if ordinary_val >= srcd_val else "srcd"
    print(f"Val-selected best mode: {best_mode} (ordinary={ordinary_val:.3f}, "
          f"srcd={srcd_val:.3f}; criterion=validation threshold-0.5 macro-F1)")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument("--features", choices=("ordinary", "srcd"))
    mode_group.add_argument(
        "--finalize-saved", action="store_true",
        help="Tune both saved checkpoints on validation, then evaluate both on test without retraining.",
    )
    parser.add_argument("--device", choices=("cpu", "cuda"), default="cpu")
    args = parser.parse_args()
    if args.device == "cuda" and not torch.cuda.is_available():
        raise SystemExit("CUDA was requested but is unavailable")
    device = torch.device(args.device)
    global FEATURE_NAMES
    FEATURE_NAMES = channel_names()
    if args.finalize_saved:
        finalize_saved_modes(device)
    else:
        assert args.features is not None
        train_mode(args.features, device)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
