# Task 3 — Flutter Prediction App

This folder contains a one-page Flutter application connected to:

```text
https://african-football-market-value-api.onrender.com/predict
```

## What the app includes

- One scrollable and responsive page.
- All required variables needed by the `/predict` endpoint.
- Optional advanced performance inputs.
- Pydantic-compatible client-side range validation.
- A button labelled **Predict**.
- A loading indicator while the API request is running.
- A dedicated result area for either the predicted euro value or an error.
- Responsive two-column layout on wide screens and one column on phones.

## First-time setup

Open a terminal in `summative/FlutterApp`.

If the native Flutter platform folders are not present, run:

```powershell
flutter create . --project-name african_football_predictor --platforms=android,web,windows
```

Keep the supplied `lib/`, `test/`, and `pubspec.yaml` files if VS Code asks whether to replace them.

Then install the Dart packages:

```powershell
flutter pub get
```

## Run in Chrome

```powershell
flutter run -d chrome
```

The Render free service can take roughly a minute to wake up after inactivity.
The app waits up to 90 seconds and displays a helpful retry message.

## Run on Android

Ensure an Android emulator or connected phone is available:

```powershell
flutter devices
flutter run
```

For Android builds, confirm this permission exists near the top of
`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## Test the app

```powershell
flutter test
```

## Task 3 rubric coverage

- One page: yes.
- Prediction endpoint: public Render `/predict` URL.
- Inputs: all required API variables are represented; advanced optional fields
  are also available.
- Predict button: yes.
- Prediction/error display area: yes.
- Missing and out-of-range validation: yes.
- Organized, non-overlapping layout: responsive cards, wrapping fields, and a
  scroll view.

## Final GitHub location

Keep this folder at:

```text
linear_regression_model/
└── summative/
    └── FlutterApp/
```

Do not commit generated build folders such as `build/` or `.dart_tool/`.
