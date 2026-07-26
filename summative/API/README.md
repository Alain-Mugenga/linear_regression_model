# Task 2 API

## Run locally

From the `summative` folder:

```powershell
uv sync --frozen
uv run uvicorn API.prediction:app --reload
```

Open Swagger UI:

```text
http://127.0.0.1:8000/docs
```

## Endpoints

- `GET /` — API information
- `GET /health` — confirms that the saved model is available
- `POST /predict` — predicts a player's market value
- `POST /retrain` — accepts a CSV and retrains the existing estimator structure

## Retraining CSV format

The uploaded file must use the same 38-column structure as:

```text
linear_regression/dataset.csv
```

It must include `Bonservis`, which is the target value used for retraining.

## CORS reasoning

The API permits `GET` and `POST` requests because those are the only methods
needed by Swagger, the prediction client, and the retraining upload.

By default, all origins are allowed so the public Swagger UI and a future
frontend can call the API during grading. Credentials are disabled, so the API
does not accept browser cookies or credentialed cross-origin requests.

For production, set `ALLOWED_ORIGINS` to a comma-separated list of trusted
frontend origins, for example:

```text
https://your-flutter-web-app.example,https://your-school-demo.example
```
