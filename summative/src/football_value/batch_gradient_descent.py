from __future__ import annotations

import numpy as np
from sklearn.base import BaseEstimator, RegressorMixin
from sklearn.utils.validation import check_array, check_is_fitted, check_X_y


class BatchGradientDescentRegressor(RegressorMixin, BaseEstimator):
    """Multiple linear regression optimized with full-batch gradient descent."""

    def __init__(
        self,
        learning_rate: float = 0.01,
        max_epochs: int = 1200,
        l2_alpha: float = 0.0001,
        tolerance: float = 1e-8,
        n_iter_no_change: int = 80,
    ) -> None:
        self.learning_rate = learning_rate
        self.max_epochs = max_epochs
        self.l2_alpha = l2_alpha
        self.tolerance = tolerance
        self.n_iter_no_change = n_iter_no_change

    def _initialize(self, X: np.ndarray) -> None:
        self.coef_ = np.zeros(X.shape[1], dtype=float)
        self.intercept_ = 0.0
        self.train_loss_ = []
        self.validation_loss_ = []
        self.n_features_in_ = X.shape[1]

    def _gradient_step(self, X: np.ndarray, y: np.ndarray) -> float:
        predictions = X @ self.coef_ + self.intercept_
        errors = predictions - y
        sample_count = X.shape[0]

        weight_gradient = (2.0 / sample_count) * (X.T @ errors)
        weight_gradient += 2.0 * self.l2_alpha * self.coef_
        intercept_gradient = 2.0 * float(np.mean(errors))

        weight_gradient = np.clip(weight_gradient, -1000.0, 1000.0)
        intercept_gradient = float(
            np.clip(intercept_gradient, -1000.0, 1000.0)
        )

        self.coef_ -= self.learning_rate * weight_gradient
        self.intercept_ -= self.learning_rate * intercept_gradient

        updated_predictions = X @ self.coef_ + self.intercept_
        return float(np.mean((updated_predictions - y) ** 2))

    def fit(self, X, y):
        X_checked, y_checked = check_X_y(
            X,
            y,
            accept_sparse=False,
            y_numeric=True,
        )
        X_checked = np.asarray(X_checked, dtype=float)
        y_checked = np.asarray(y_checked, dtype=float)

        self._initialize(X_checked)
        best_loss = np.inf
        epochs_without_improvement = 0

        for _ in range(self.max_epochs):
            loss = self._gradient_step(X_checked, y_checked)
            self.train_loss_.append(loss)

            if not np.isfinite(loss):
                raise FloatingPointError(
                    "Gradient descent diverged. Reduce the learning rate."
                )

            if best_loss - loss > self.tolerance:
                best_loss = loss
                epochs_without_improvement = 0
            else:
                epochs_without_improvement += 1

            if epochs_without_improvement >= self.n_iter_no_change:
                break

        self.n_iter_ = len(self.train_loss_)
        return self

    def fit_with_validation(self, X, y, X_validation, y_validation):
        X_checked, y_checked = check_X_y(
            X,
            y,
            accept_sparse=False,
            y_numeric=True,
        )
        X_validation_checked = check_array(
            X_validation,
            accept_sparse=False,
        )

        X_checked = np.asarray(X_checked, dtype=float)
        y_checked = np.asarray(y_checked, dtype=float)
        X_validation_checked = np.asarray(
            X_validation_checked,
            dtype=float,
        )
        y_validation_checked = np.asarray(y_validation, dtype=float)

        self._initialize(X_checked)
        best_loss = np.inf
        epochs_without_improvement = 0

        for _ in range(self.max_epochs):
            training_loss = self._gradient_step(X_checked, y_checked)
            validation_predictions = (
                X_validation_checked @ self.coef_ + self.intercept_
            )
            validation_loss = float(
                np.mean(
                    (validation_predictions - y_validation_checked) ** 2
                )
            )

            self.train_loss_.append(training_loss)
            self.validation_loss_.append(validation_loss)

            if best_loss - validation_loss > self.tolerance:
                best_loss = validation_loss
                epochs_without_improvement = 0
            else:
                epochs_without_improvement += 1

            if epochs_without_improvement >= self.n_iter_no_change:
                break

        self.n_iter_ = len(self.train_loss_)
        return self

    def predict(self, X):
        check_is_fitted(self, ["coef_", "intercept_"])
        X_checked = check_array(X, accept_sparse=False)
        return (
            np.asarray(X_checked, dtype=float) @ self.coef_
            + self.intercept_
        )
