# API

Run from the `summative` folder:

```powershell
uv run uvicorn API.prediction:app --reload
```

Open `http://127.0.0.1:8000/docs` to test the POST `/predict` endpoint.
