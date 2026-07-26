from __future__ import annotations

from datetime import datetime, timezone
from io import BytesIO
import json
import os
from pathlib import Path
import shutil
from threading import Lock
from typing import Literal

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.base import clone
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import GroupShuffleSplit

from football_value.data_prep import (
    clean_source_dataset,
    filter_mission_population,
    prepare_model_features,
)


BASE_DIR = Path(__file__).resolve().parent
SUMMATIVE_DIR = BASE_DIR.parent
MODEL_DIR = BASE_DIR / "models"
MODEL_PATH = MODEL_DIR / "best_model.joblib"
MODEL_BACKUP_PATH = MODEL_DIR / "best_model_backup.joblib"
METADATA_PATH = MODEL_DIR / "model_metadata.json"
BASE_DATASET_PATH = SUMMATIVE_DIR / "linear_regression" / "dataset.csv"

MAX_UPLOAD_BYTES = 10 * 1024 * 1024
RETRAIN_LOCK = Lock()


def get_allowed_origins() -> list[str]:
    raw_value = os.getenv("ALLOWED_ORIGINS", "*")
    origins = [origin.strip() for origin in raw_value.split(",") if origin.strip()]
    return origins or ["*"]


ALLOWED_ORIGINS = get_allowed_origins()

app = FastAPI(
    title="Young African Football Market Value API",
    version="0.2.0",
    description=(
        "Predicts the market value of young African football players and "
        "supports retraining from an uploaded CSV dataset."
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


class PlayerInput(BaseModel):
    age: int = Field(ge=16, le=25)
    nationality: Literal[
        "ALG",
        "BUR",
        "CIV",
        "CMR",
        "COD",
        "EGY",
        "GAM",
        "GBS",
        "GHA",
        "MAR",
        "MLI",
        "NGR",
        "RWA",
        "SEN",
        "ZAM",
        "ZIM",
    ]
    position_code: Literal["D", "OS", "F"]
    season: str = Field(pattern=r"^(\d{2}/\d{2}|\d{4})$")
    league: str = Field(min_length=2, max_length=100)
    competition_category: str = Field(min_length=2, max_length=100)
    matches_played: int = Field(ge=1, le=80)
    minutes_played: int = Field(ge=1, le=7000)
    goals: int = Field(ge=0, le=100)
    assists: int = Field(ge=0, le=100)
    average_rating: float | None = Field(default=None, ge=0, le=10)
    total_shots: float | None = Field(default=None, ge=0, le=500)
    shots_on_target: float | None = Field(default=None, ge=0, le=500)
    big_chances_missed: int | None = Field(default=None, ge=0, le=100)
    key_passes: int | None = Field(default=None, ge=0, le=500)
    big_chances_created: int | None = Field(default=None, ge=0, le=100)
    successful_dribbles: int | None = Field(default=None, ge=0, le=500)
    accurate_passes: float | None = Field(default=None, ge=0, le=10000)
    pass_accuracy_percent: float | None = Field(default=None, ge=0, le=100)
    accurate_long_balls: float | None = Field(default=None, ge=0, le=2000)
    long_ball_accuracy_percent: float | None = Field(default=None, ge=0, le=100)
    accurate_crosses: float | None = Field(default=None, ge=0, le=1000)
    cross_accuracy_percent: float | None = Field(default=None, ge=0, le=100)
    clearances: int | None = Field(default=None, ge=0, le=1000)
    yellow_cards: int | None = Field(default=None, ge=0, le=50)
    red_cards: int | None = Field(default=None, ge=0, le=20)
    errors_leading_to_goal: int | None = Field(default=None, ge=0, le=50)
    dribbled_past: int | None = Field(default=None, ge=0, le=500)
    tackles: int | None = Field(default=None, ge=0, le=1000)
    interceptions: int | None = Field(default=None, ge=0, le=1000)
    blocked_shots: float | None = Field(default=None, ge=0, le=500)
    aerial_duels_won: float | None = Field(default=None, ge=0, le=1000)


class PredictionOutput(BaseModel):
    predicted_market_value_eur: float


class RetrainingOutput(BaseModel):
    status: str
    uploaded_filename: str
    uploaded_rows: int
    combined_raw_rows: int
    eligible_training_rows: int
    unique_player_season_groups: int
    validation_mae_eur: float
    validation_rmse_eur: float
    validation_r2: float
    model_saved_to: str
    retrained_at_utc: str


def load_model():
    if not MODEL_PATH.exists():
        raise HTTPException(status_code=503, detail="Saved model is missing.")

    try:
        return joblib.load(MODEL_PATH)
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Could not load the saved model: {error}",
        ) from error


def read_uploaded_csv(contents: bytes) -> pd.DataFrame:
    try:
        return pd.read_csv(BytesIO(contents))
    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=f"The uploaded file is not a readable CSV: {error}",
        ) from error


def save_retraining_metadata(
    *,
    uploaded_filename: str,
    uploaded_rows: int,
    combined_raw_rows: int,
    eligible_training_rows: int,
    validation_mae_eur: float,
    validation_rmse_eur: float,
    validation_r2: float,
    retrained_at_utc: str,
) -> None:
    metadata: dict[str, object] = {}

    if METADATA_PATH.exists():
        try:
            metadata = json.loads(METADATA_PATH.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            metadata = {}

    metadata["last_retraining"] = {
        "uploaded_filename": uploaded_filename,
        "uploaded_rows": uploaded_rows,
        "combined_raw_rows": combined_raw_rows,
        "eligible_training_rows": eligible_training_rows,
        "validation_mae_eur": validation_mae_eur,
        "validation_rmse_eur": validation_rmse_eur,
        "validation_r2": validation_r2,
        "retrained_at_utc": retrained_at_utc,
    }

    METADATA_PATH.write_text(
        json.dumps(metadata, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )


@app.get("/")
def root() -> dict[str, str]:
    return {
        "message": "Young African Football Market Value API",
        "docs": "/docs",
        "prediction_endpoint": "/predict",
        "retraining_endpoint": "/retrain",
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "healthy" if MODEL_PATH.exists() else "model_missing",
        "model_path": str(MODEL_PATH),
    }


@app.post("/predict", response_model=PredictionOutput)
def predict(payload: PlayerInput) -> PredictionOutput:
    try:
        raw_input = pd.DataFrame([payload.model_dump()])
        model_input = prepare_model_features(raw_input)
        model = load_model()
        prediction = max(0.0, float(model.predict(model_input)[0]))
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=f"Prediction failed: {error}",
        ) from error

    return PredictionOutput(
        predicted_market_value_eur=round(prediction, 2),
    )


@app.post(
    "/retrain",
    response_model=RetrainingOutput,
    summary="Retrain the current model using an uploaded CSV",
)
async def retrain(
    file: UploadFile = File(
        ...,
        description=(
            "CSV with the same 38-column structure as "
            "linear_regression/dataset.csv, including Bonservis."
        ),
    ),
) -> RetrainingOutput:
    filename = file.filename or "uploaded.csv"

    if not filename.lower().endswith(".csv"):
        raise HTTPException(
            status_code=400,
            detail="Only CSV files are accepted.",
        )

    contents = await file.read()

    if not contents:
        raise HTTPException(status_code=400, detail="The uploaded CSV is empty.")

    if len(contents) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=413,
            detail="The uploaded CSV is larger than 10 MB.",
        )

    if not BASE_DATASET_PATH.exists():
        raise HTTPException(
            status_code=500,
            detail=f"Base dataset is missing at {BASE_DATASET_PATH}.",
        )

    uploaded_raw = read_uploaded_csv(contents)

    if uploaded_raw.empty:
        raise HTTPException(
            status_code=400,
            detail="The uploaded CSV contains no rows.",
        )

    with RETRAIN_LOCK:
        try:
            base_raw = pd.read_csv(BASE_DATASET_PATH)
            combined_raw = (
                pd.concat([base_raw, uploaded_raw], ignore_index=True)
                .drop_duplicates()
                .reset_index(drop=True)
            )

            cleaned_data = clean_source_dataset(combined_raw)
            mission_data = filter_mission_population(
                cleaned_data,
                minimum_age=16,
                maximum_age=25,
            )

            if len(mission_data) < 20:
                raise ValueError(
                    "Fewer than 20 eligible young African player rows remain "
                    "after cleaning and filtering."
                )

            model_features = prepare_model_features(mission_data)
            target = mission_data["market_value_eur"].copy()
            groups = mission_data["player_season_group"].copy()

            if groups.nunique() < 5:
                raise ValueError(
                    "At least five unique player-season groups are required."
                )

            splitter = GroupShuffleSplit(
                n_splits=1,
                test_size=0.20,
                random_state=42,
            )
            train_indices, validation_indices = next(
                splitter.split(
                    model_features,
                    target,
                    groups=groups,
                )
            )

            current_model = load_model()
            validation_model = clone(current_model)
            validation_model.fit(
                model_features.iloc[train_indices],
                target.iloc[train_indices],
            )

            validation_predictions = np.maximum(
                0.0,
                np.asarray(
                    validation_model.predict(
                        model_features.iloc[validation_indices]
                    ),
                    dtype=float,
                ),
            )
            validation_actual = target.iloc[validation_indices]

            validation_mae = float(
                mean_absolute_error(
                    validation_actual,
                    validation_predictions,
                )
            )
            validation_rmse = float(
                np.sqrt(
                    mean_squared_error(
                        validation_actual,
                        validation_predictions,
                    )
                )
            )
            validation_r2 = float(
                r2_score(
                    validation_actual,
                    validation_predictions,
                )
            )

            deployment_model = clone(current_model)
            deployment_model.fit(model_features, target)

            MODEL_DIR.mkdir(parents=True, exist_ok=True)

            if MODEL_PATH.exists():
                shutil.copy2(MODEL_PATH, MODEL_BACKUP_PATH)

            temporary_model_path = MODEL_DIR / "best_model_retrained.tmp.joblib"
            joblib.dump(deployment_model, temporary_model_path)
            temporary_model_path.replace(MODEL_PATH)

            retrained_at = datetime.now(timezone.utc).isoformat()

            save_retraining_metadata(
                uploaded_filename=filename,
                uploaded_rows=len(uploaded_raw),
                combined_raw_rows=len(combined_raw),
                eligible_training_rows=len(mission_data),
                validation_mae_eur=validation_mae,
                validation_rmse_eur=validation_rmse,
                validation_r2=validation_r2,
                retrained_at_utc=retrained_at,
            )
        except HTTPException:
            raise
        except Exception as error:
            raise HTTPException(
                status_code=400,
                detail=f"Retraining failed: {error}",
            ) from error

    return RetrainingOutput(
        status="retrained",
        uploaded_filename=filename,
        uploaded_rows=len(uploaded_raw),
        combined_raw_rows=len(combined_raw),
        eligible_training_rows=len(mission_data),
        unique_player_season_groups=int(groups.nunique()),
        validation_mae_eur=round(validation_mae, 2),
        validation_rmse_eur=round(validation_rmse, 2),
        validation_r2=round(validation_r2, 4),
        model_saved_to=str(MODEL_PATH),
        retrained_at_utc=retrained_at,
    )
