# Summative Project

- `linear_regression/multivariate.ipynb`: Task 1 regression notebook.
- `API/prediction.py`: FastAPI prediction starter using the saved model.
- `FlutterApp/`: location for the Flutter application.
- `src/football_value/`: reusable preprocessing and model utilities.

From this directory run:

```powershell
uv sync --frozen
uv run uvicorn API.prediction:app --reload
```
