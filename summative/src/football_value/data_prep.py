from __future__ import annotations

import re
import numpy as np
import pandas as pd


COLUMN_RENAME = {
    "Oyuncu": "player",
    "Yaş": "age",
    "Uyruk": "nationality",
    "Mevki": "position_code",
    "Sezon": "season",
    "Lig": "league",
    "Kategori": "competition_category",
    "MP": "matches_played",
    "DK": "minutes_played",
    "GLS": "goals",
    "AST": "assists",
    "ASR": "average_rating",
    "TOS": "total_shots",
    "SOT": "shots_on_target",
    "BCM": "big_chances_missed",
    "KEYP": "key_passes",
    "BCC": "big_chances_created",
    "SDR": "successful_dribbles",
    "APS": "accurate_passes",
    "APS%": "pass_accuracy_percent",
    "ALB": "accurate_long_balls",
    "LBA%": "long_ball_accuracy_percent",
    "ACR": "accurate_crosses",
    "CA%": "cross_accuracy_percent",
    "CLS": "clearances",
    "YC": "yellow_cards",
    "RC": "red_cards",
    "ELTG": "errors_leading_to_goal",
    "DRP": "dribbled_past",
    "TACK": "tackles",
    "INT": "interceptions",
    "BLS": "blocked_shots",
    "ADW": "aerial_duels_won",
    "xG": "expected_goals",
    "xA": "expected_assists",
    "GI": "goal_involvements",
    "XGI": "expected_goal_involvements",
    "Bonservis": "market_value_raw",
}

MARKET_VALUE_CORRECTIONS = {
    "400.00": "400.000",
    "30.000.00": "30.000.000",
    "28.000.00": "28.000.000",
    "1.000.00": "1.000.000",
    "20.000.00": "20.000.000",
    "1.500.00": "1.500.000",
    "12.000.0000": "12.000.000",
    "5.000.0000": "5.000.000",
    "30.000.0000": "30.000.000",
    "800.0000": "800.000",
}

AFRICAN_NATIONALITIES = {
    "ALG": "Algeria",
    "BUR": "Burkina Faso",
    "CIV": "Côte d'Ivoire",
    "CMR": "Cameroon",
    "COD": "DR Congo",
    "EGY": "Egypt",
    "GAM": "Gambia",
    "GBS": "Guinea-Bissau",
    "GHA": "Ghana",
    "MAR": "Morocco",
    "MLI": "Mali",
    "NGR": "Nigeria",
    "SEN": "Senegal",
    "ZAM": "Zambia",
    "ZIM": "Zimbabwe",
}

POSITION_LABELS = {
    "D": "Defender",
    "OS": "Midfielder",
    "F": "Forward",
}

COUNT_COLUMNS = [
    "goals",
    "assists",
    "total_shots",
    "shots_on_target",
    "big_chances_missed",
    "key_passes",
    "big_chances_created",
    "successful_dribbles",
    "accurate_passes",
    "accurate_long_balls",
    "accurate_crosses",
    "clearances",
    "yellow_cards",
    "red_cards",
    "errors_leading_to_goal",
    "dribbled_past",
    "tackles",
    "interceptions",
    "blocked_shots",
    "aerial_duels_won",
]

RAW_MODEL_COLUMNS = [
    "age",
    "nationality",
    "position_code",
    "season",
    "league",
    "competition_category",
    "matches_played",
    "minutes_played",
    "goals",
    "assists",
    "average_rating",
    "total_shots",
    "shots_on_target",
    "big_chances_missed",
    "key_passes",
    "big_chances_created",
    "successful_dribbles",
    "accurate_passes",
    "pass_accuracy_percent",
    "accurate_long_balls",
    "long_ball_accuracy_percent",
    "accurate_crosses",
    "cross_accuracy_percent",
    "clearances",
    "yellow_cards",
    "red_cards",
    "errors_leading_to_goal",
    "dribbled_past",
    "tackles",
    "interceptions",
    "blocked_shots",
    "aerial_duels_won",
]

NUMERIC_FEATURES = [
    "age",
    "season_start_year",
    "matches_played",
    "minutes_played",
    "minutes_per_match",
    "average_rating",
    "pass_accuracy_percent",
    "long_ball_accuracy_percent",
    "cross_accuracy_percent",
    "goal_contributions_per90",
    "shot_accuracy",
    "goals_per_shot",
] + [f"{column}_per90" for column in COUNT_COLUMNS]

CATEGORICAL_FEATURES = [
    "nationality",
    "position",
    "league",
    "competition_category",
]


def season_start_year(value: object) -> int:
    text = str(value).strip()

    if "/" in text:
        first_part = int(text.split("/")[0])
        return 2000 + first_part if first_part < 50 else 1900 + first_part

    if re.fullmatch(r"\d{4}", text):
        return int(text)

    raise ValueError(f"Unsupported season format: {value!r}")


def clean_source_dataset(raw_data: pd.DataFrame) -> pd.DataFrame:
    missing_source_columns = set(COLUMN_RENAME).difference(raw_data.columns)
    if missing_source_columns:
        raise KeyError(
            "The uploaded dataset is missing expected columns: "
            + ", ".join(sorted(missing_source_columns))
        )

    data = raw_data.rename(columns=COLUMN_RENAME).copy()

    for column in data.select_dtypes(include="object").columns:
        data[column] = data[column].astype(str).str.strip()

    data["market_value_clean"] = data["market_value_raw"].replace(
        MARKET_VALUE_CORRECTIONS
    )

    valid_market_format = data["market_value_clean"].str.fullmatch(
        r"\d{1,3}(?:\.\d{3})*"
    )
    if not valid_market_format.all():
        invalid_values = (
            data.loc[~valid_market_format, "market_value_clean"]
            .drop_duplicates()
            .to_list()
        )
        raise ValueError(
            f"Unrecognized market-value formats remain: {invalid_values}"
        )

    data["market_value_eur"] = (
        data["market_value_clean"]
        .str.replace(".", "", regex=False)
        .astype("int64")
    )

    data["season_start_year"] = data["season"].map(season_start_year)
    data["position"] = data["position_code"].map(POSITION_LABELS)

    return data


def filter_mission_population(
    data: pd.DataFrame,
    minimum_age: int = 16,
    maximum_age: int = 25,
) -> pd.DataFrame:
    mission_data = data.loc[
        data["nationality"].isin(AFRICAN_NATIONALITIES)
        & data["age"].between(minimum_age, maximum_age, inclusive="both")
    ].copy()

    mission_data["nationality_name"] = mission_data["nationality"].map(
        AFRICAN_NATIONALITIES
    )
    mission_data["player_season_group"] = (
        mission_data["player"].astype(str)
        + "__"
        + mission_data["season"].astype(str)
    )

    return mission_data


def prepare_model_features(data: pd.DataFrame) -> pd.DataFrame:
    missing_columns = set(RAW_MODEL_COLUMNS).difference(data.columns)
    if missing_columns:
        raise KeyError(
            "The prediction input is missing required columns: "
            + ", ".join(sorted(missing_columns))
        )

    features = data.copy()
    features["season_start_year"] = features["season"].map(
        season_start_year
    )
    features["position"] = features["position_code"].map(POSITION_LABELS)

    minutes = pd.to_numeric(
        features["minutes_played"],
        errors="coerce",
    ).replace(0, np.nan)

    matches = pd.to_numeric(
        features["matches_played"],
        errors="coerce",
    ).replace(0, np.nan)

    for column in COUNT_COLUMNS:
        values = pd.to_numeric(features[column], errors="coerce")
        features[f"{column}_per90"] = values * 90.0 / minutes

    features["minutes_per_match"] = (
        pd.to_numeric(features["minutes_played"], errors="coerce")
        / matches
    )
    features["goal_contributions_per90"] = (
        (
            pd.to_numeric(features["goals"], errors="coerce")
            + pd.to_numeric(features["assists"], errors="coerce")
        )
        * 90.0
        / minutes
    )
    features["shot_accuracy"] = (
        pd.to_numeric(features["shots_on_target"], errors="coerce")
        / pd.to_numeric(
            features["total_shots"],
            errors="coerce",
        ).replace(0, np.nan)
    )
    features["goals_per_shot"] = (
        pd.to_numeric(features["goals"], errors="coerce")
        / pd.to_numeric(
            features["total_shots"],
            errors="coerce",
        ).replace(0, np.nan)
    )

    return features[NUMERIC_FEATURES + CATEGORICAL_FEATURES].copy()
