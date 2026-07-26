# Linear Regression Model Deployment Summative

## Mission and Problem

My mission is to help young Africans discover and develop their sporting talents.  
This project focuses on young African football players and predicts their market value from performance data.  
The solution can support academies and scouts in identifying players who may benefit from development and investment.  
It promotes data-informed opportunities for athletes to build successful careers within Africa.

## Project Overview

This repository contains the three parts of the summative assignment:

1. **Task 1 — Linear Regression:** Data cleaning, visualization, feature engineering, model training, comparison, and model saving.
2. **Task 2 — FastAPI:** Public prediction and retraining endpoints with Pydantic validation and CORS middleware.
3. **Task 3 — Flutter App:** A one-page user interface that sends player information to the deployed prediction API.

## Repository Structure

```text
linear_regression_model/
├── README.md
└── summative/
    ├── linear_regression/
    │   ├── multivariate.ipynb
    │   ├── dataset.csv
    │   └── outputs/
    ├── API/
    │   ├── prediction.py
    │   ├── models/
    │   │   ├── best_model.joblib
    │   │   ├── model_metadata.json
    │   │   └── sample_player_input.json
    │   └── README.md
    ├── FlutterApp/
    │   ├── lib/
    │   ├── test/
    │   ├── pubspec.yaml
    │   └── README.md
    ├── src/
    ├── pyproject.toml
    ├── uv.lock
    ├── requirements.txt
    └── .python-version
```

## Public API

The API is publicly deployed on Render.

- **Swagger UI:** https://african-football-market-value-api.onrender.com/docs
- **Prediction endpoint:** https://african-football-market-value-api.onrender.com/predict
- **Health check:** https://african-football-market-value-api.onrender.com/health
- **Retraining endpoint:** https://african-football-market-value-api.onrender.com/retrain

The prediction endpoint accepts a JSON request through `POST /predict` and returns the predicted market value in euros. Input data types and realistic numeric ranges are enforced using Pydantic.

> The free Render service may take up to about one minute to wake up after a period of inactivity.

## YouTube Demo

**Demo video: https://youtu.be/wVbp-9epVpE 

## Running the Flutter App

### Requirements

Install the following before running the app:

- Flutter SDK
- Google Chrome for web testing, or an Android emulator/connected Android device
- VS Code with the Flutter and Dart extensions

Confirm Flutter is available:

```powershell
flutter doctor
```

### Run the App in Chrome

From the repository root:

```powershell
cd summative/FlutterApp
flutter pub get
flutter run -d chrome
```

The app already uses the deployed API endpoint:

```text
https://african-football-market-value-api.onrender.com/predict
```

Enter the player information, press **Predict**, and the predicted market value or an error message will appear in the result area.

### Run the App on Android

Start an Android emulator or connect an Android phone, then run:

```powershell
cd summative/FlutterApp
flutter pub get
flutter devices
flutter run
```

For Android, ensure the following permission exists in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Run Flutter Tests

```powershell
cd summative/FlutterApp
flutter test
```

## Running Task 1 with UV

This project uses **UV**, not `pip`, for Python package and virtual-environment management.

From the repository root:

```powershell
cd summative
uv sync --frozen
uv run jupyter lab
```

Open:

```text
linear_regression/multivariate.ipynb
```

The notebook uses portable paths, displays DataFrames using expressions such as `raw_df.head()`, and includes the executed outputs, visualizations, model comparisons, loss curves, saved-model step, and sample prediction.

## Running the API Locally

From the repository root:

```powershell
cd summative
uv sync --frozen
uv run uvicorn API.prediction:app --reload
```

Open the local Swagger UI at:

```text
http://127.0.0.1:8000/docs
```

The public Swagger URL should be used for grading:

```text
https://african-football-market-value-api.onrender.com/docs
```

## Models Compared in Task 1

The notebook compares four regression algorithms:

1. Batch Gradient Descent Linear Regression
2. Stochastic Gradient Descent Linear Regression
3. Decision Tree Regressor
4. Random Forest Regressor

The best-performing model is saved and reused by the FastAPI prediction endpoint.

## API Features

- `GET /` — API information
- `GET /health` — model and service health check
- `POST /predict` — market-value prediction
- `POST /retrain` — retrains the model from an uploaded CSV
- Pydantic data types and range constraints
- CORS middleware for frontend access
- Interactive Swagger documentation
- Public Render deployment
