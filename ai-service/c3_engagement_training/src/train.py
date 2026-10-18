"""Train and compare lightweight binary DAiSEE engagement classifiers."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import balanced_accuracy_score, classification_report, confusion_matrix, f1_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.utils.class_weight import compute_sample_weight


META_COLUMNS = {
    "clip_id", "split", "engagement_level", "binary_engaged", "video_path", "subject_id", "positive_min_level",
}


def subject_safe_check(frame: pd.DataFrame) -> None:
    if "subject_id" not in frame:
        raise ValueError("Feature file has no subject_id. Rebuild the manifest; do not claim a subject-safe result.")
    per_subject = frame.groupby("subject_id")["split"].nunique()
    leaked = per_subject[per_subject > 1]
    if not leaked.empty:
        raise ValueError(f"Subject leakage across official splits: {leaked.head().to_dict()}")


def metrics(y_true: pd.Series, y_pred: np.ndarray) -> dict:
    return {
        "balanced_accuracy": round(float(balanced_accuracy_score(y_true, y_pred)), 4),
        "macro_f1": round(float(f1_score(y_true, y_pred, average="macro", zero_division=0)), 4),
        "confusion_matrix": confusion_matrix(y_true, y_pred, labels=[0, 1]).tolist(),
        "classification_report": classification_report(y_true, y_pred, labels=[0, 1], output_dict=True, zero_division=0),
    }


def make_models(random_state: int) -> dict[str, Pipeline]:
    return {
        "logistic_regression": Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
            ("classifier", LogisticRegression(class_weight="balanced", max_iter=2000, random_state=random_state)),
        ]),
        "hist_gradient_boosting": Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("classifier", HistGradientBoostingClassifier(max_iter=250, learning_rate=0.06, max_leaf_nodes=15,
                                                            l2_regularization=1.0, random_state=random_state)),
        ]),
    }


def fit_model(model: Pipeline, name: str, x: pd.DataFrame, y: pd.Series) -> Pipeline:
    if name == "hist_gradient_boosting":
        # HistGradientBoostingClassifier has no class_weight argument in this
        # scikit-learn release, so use equivalent balanced sample weights.
        model.fit(x, y, classifier__sample_weight=compute_sample_weight("balanced", y))
    else:
        model.fit(x, y)
    return model


def main() -> None:
    parser = argparse.ArgumentParser(description="Compare class-balanced DAiSEE engagement classifiers.")
    parser.add_argument("--features", type=Path, required=True, help="CSV made by extract_features.py for all official splits.")
    parser.add_argument("--artifacts-dir", type=Path, default=Path("artifacts"))
    parser.add_argument("--random-state", type=int, default=42)
    parser.add_argument(
        "--positive-min-level", type=int, default=2,
        help="Must match build_manifest. Default 2 means high/very high is engaged.",
    )
    args = parser.parse_args()

    frame = pd.read_csv(args.features)
    required = {"split", "binary_engaged", "subject_id"}
    missing = required - set(frame.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")
    if not set(frame["split"].unique()).issuperset({"train", "validation", "test"}):
        raise ValueError("Features must include the official train, validation and test splits.")
    if "positive_min_level" not in frame or set(frame["positive_min_level"].dropna().unique()) != {args.positive_min_level}:
        raise ValueError(
            "Feature file label policy does not match --positive-min-level. Rebuild the manifest/features or use the matching value."
        )
    subject_safe_check(frame)

    feature_columns = [column for column in frame.columns if column not in META_COLUMNS]
    if not feature_columns:
        raise ValueError("No numeric feature columns found.")
    frame[feature_columns] = frame[feature_columns].apply(pd.to_numeric, errors="coerce")
    train, validation, test = (frame.loc[frame.split == split].copy() for split in ("train", "validation", "test"))
    print("Binary counts:", {split: subset.binary_engaged.value_counts().to_dict()
                             for split, subset in (("train", train), ("validation", validation), ("test", test))})

    selection: dict[str, dict] = {}
    models = make_models(args.random_state)
    for name, model in models.items():
        fit_model(model, name, train[feature_columns], train.binary_engaged)
        selection[name] = metrics(validation.binary_engaged, model.predict(validation[feature_columns]))
        print(f"{name} validation: balanced accuracy={selection[name]['balanced_accuracy']}, "
              f"macro-F1={selection[name]['macro_f1']}")

    # Balanced accuracy is the primary selection metric; macro-F1 breaks ties.
    winner = max(selection, key=lambda name: (selection[name]["balanced_accuracy"], selection[name]["macro_f1"]))
    final_model = make_models(args.random_state)[winner]
    train_validation = pd.concat([train, validation], ignore_index=True)
    fit_model(final_model, winner, train_validation[feature_columns], train_validation.binary_engaged)
    test_result = metrics(test.binary_engaged, final_model.predict(test[feature_columns]))
    print(f"Selected {winner}; official test balanced accuracy={test_result['balanced_accuracy']}, "
          f"macro-F1={test_result['macro_f1']}")

    args.artifacts_dir.mkdir(parents=True, exist_ok=True)
    joblib.dump({"model": final_model, "feature_columns": feature_columns,
                 "positive_min_level": args.positive_min_level},
                args.artifacts_dir / "engagement_model.joblib")
    report = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "dataset": "DAiSEE official Train/Validation/Test label files",
        "binary_target": (
            f"Engagement level >= {args.positive_min_level} is engaged; lower ordinal levels are not engaged."
        ),
        "selection_split": "validation",
        "test_split": "official test, evaluated once after validation selection",
        "subject_safety": "checked participant directory identifiers have no overlap across splits",
        "feature_columns": feature_columns,
        "validation_comparison": selection,
        "selected_model": winner,
        "official_test": test_result,
    }
    (args.artifacts_dir / "metrics.json").write_text(json.dumps(report, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
