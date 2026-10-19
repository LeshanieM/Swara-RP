"""Local inference API for the trained DAiSEE engagement baseline."""

from __future__ import annotations

import os
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict, field_validator


DEFAULT_MODEL_PATH = Path(__file__).resolve().parent / "artifacts" / "engagement_model.joblib"
MODEL_PATH = Path(os.environ.get("C3_ENGAGEMENT_MODEL_PATH", DEFAULT_MODEL_PATH))

_model: Any | None = None
_feature_columns: list[str] = []
_positive_min_level: int | None = None


def _load_artifact() -> None:
    global _model, _feature_columns, _positive_min_level

    if not MODEL_PATH.is_file():
        _model = None
        _feature_columns = []
        _positive_min_level = None
        return

    artifact = joblib.load(MODEL_PATH)
    if not isinstance(artifact, dict):
        raise RuntimeError(f"Engagement artifact is not a model bundle: {MODEL_PATH}")

    model = artifact.get("model")
    columns = artifact.get("feature_columns")
    if model is None or not isinstance(columns, list) or not columns:
        raise RuntimeError(f"Engagement artifact is missing its model or feature schema: {MODEL_PATH}")
    if not all(isinstance(column, str) and column for column in columns):
        raise RuntimeError(f"Engagement artifact has an invalid feature schema: {MODEL_PATH}")
    if not callable(getattr(model, "predict_proba", None)):
        raise RuntimeError("Engagement model does not support probability predictions.")

    _model = model
    _feature_columns = columns
    _positive_min_level = artifact.get("positive_min_level")


@asynccontextmanager
async def lifespan(_: FastAPI):
    _load_artifact()
    yield


app = FastAPI(
    title="Swara C3 Engagement Research API",
    version="1.0.0",
    description=(
        "Local inference for the DAiSEE adult e-learning research baseline. "
        "This model is not validated for children or therapy use."
    ),
    lifespan=lifespan,
)


class PredictionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    features: dict[str, float | None]

    @field_validator("features", mode="before")
    @classmethod
    def validate_numeric_features(cls, value: Any) -> Any:
        if not isinstance(value, dict):
            raise ValueError("features must be an object of numeric values.")
        for name, feature_value in value.items():
            if feature_value is None:
                continue
            if isinstance(feature_value, bool) or not isinstance(feature_value, (int, float)):
                raise ValueError(f"Feature {name!r} must be a number or null.")
            if not np.isfinite(feature_value):
                raise ValueError(f"Feature {name!r} must be finite.")
        return value


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "model_loaded": _model is not None,
        "model_version": "daisee-binary-v1" if _model is not None else None,
    }


@app.post("/predict")
def predict(request: PredictionRequest) -> dict[str, Any]:
    if _model is None:
        raise HTTPException(
            status_code=503,
            detail=(
                "No trained model artifact is available. Run the C3 training "
                "pipeline first to create artifacts/engagement_model.joblib."
            ),
        )

    provided = set(request.features)
    expected = set(_feature_columns)
    missing = sorted(expected - provided)
    unexpected = sorted(provided - expected)
    if missing or unexpected:
        raise HTTPException(
            status_code=422,
            detail={
                "message": "Feature names must match the trained model schema.",
                "missing_features": missing,
                "unexpected_features": unexpected,
                "expected_features": _feature_columns,
            },
        )

    ordered_features = pd.DataFrame(
        [[np.nan if request.features[column] is None else request.features[column]
          for column in _feature_columns]],
        columns=_feature_columns,
        dtype=float,
    )
    probabilities = _model.predict_proba(ordered_features)[0]
    classes = list(_model.classes_)
    if 1 not in classes or 0 not in classes:
        raise RuntimeError("The trained model must contain both binary classes 0 and 1.")

    not_engaged_probability = float(probabilities[classes.index(0)])
    engaged_probability = float(probabilities[classes.index(1)])
    return {
        "model_version": "daisee-binary-v1",
        "binary_label_policy": (
            f"DAiSEE engagement level >= {_positive_min_level} is engaged."
        ),
        "engaged": engaged_probability >= 0.5,
        "engaged_probability": engaged_probability,
        "not_engaged_probability": not_engaged_probability,
        "threshold": 0.5,
        "research_notice": (
            "Adult e-learning baseline only; not validated for children, "
            "speech therapy, or clinical decisions."
        ),
    }
