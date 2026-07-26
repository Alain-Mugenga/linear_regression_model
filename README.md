# Linear Regression Model

## Mission and problem
Help young Africans discover and develop their sporting talent.
Use football performance data to identify development potential.
Predict young African players' market values using regression.
Support academies and scouts while keeping final decisions human-led.

## Repository structure

```text
linear_regression_model/
└── summative/
    ├── linear_regression/
    │   ├── multivariate.ipynb
    │   └── dataset.csv
    ├── API/
    │   ├── prediction.py
    │   └── models/
    ├── FlutterApp/
    ├── src/football_value/
    ├── pyproject.toml
    └── uv.lock
```

## Run with UV

```powershell
cd summative
setup_project.bat

# Or run manually:
uv lock --refresh --default-index https://pypi.org/simple
uv sync --locked --default-index https://pypi.org/simple
```

Run the API locally:

```powershell
uv run uvicorn API.prediction:app --reload
```

Swagger UI:

```text
http://127.0.0.1:8000/docs
```

## Submission links

- Public API endpoint: 
Swagger UI : https://african-football-market-value-api.onrender.com/docs
Health Check : https://african-football-market-value-api.onrender.com/health
- YouTube demo: ``

## Flutter app



## UV lock file


