from __future__ import annotations

from pathlib import Path
from typing import Literal

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from football_value.data_prep import prepare_model_features


BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "models" / "best_model.joblib"

app = FastAPI(
    title="Young African Football Market Value API",
    version="0.1.0",
    description="Predicts a young African football player's market value.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


class PlayerInput(BaseModel):
    age: int = Field(ge=16, le=25)
    nationality: str = Field(min_length=3, max_length=3)
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


@app.get("/")
def root() -> dict[str, str]:
    return {
        "message": "Young African Football Market Value API",
        "docs": "/docs",
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "healthy" if MODEL_PATH.exists() else "model_missing",
    }


@app.post("/predict", response_model=PredictionOutput)
def predict(payload: PlayerInput) -> PredictionOutput:
    if not MODEL_PATH.exists():
        raise HTTPException(status_code=503, detail="Saved model is missing.")

    try:
        raw_input = pd.DataFrame([payload.model_dump()])
        model_input = prepare_model_features(raw_input)
        model = joblib.load(MODEL_PATH)
        prediction = max(0.0, float(model.predict(model_input)[0]))
    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=f"Prediction failed: {error}",
        ) from error

    return PredictionOutput(
        predicted_market_value_eur=round(prediction, 2),
    )
