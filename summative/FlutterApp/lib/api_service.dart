import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String predictionUrl =
      'https://african-football-market-value-api.onrender.com/predict';

  final http.Client _client;

  Future<double> predict(Map<String, dynamic> payload) async {
    try {
      final response = await _client
          .post(
            Uri.parse(predictionUrl),
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 90));

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        final value = decoded['predicted_market_value_eur'];

        if (value is num) {
          return value.toDouble();
        }

        throw const ApiException(
          'The API returned a response without a numeric prediction.',
        );
      }

      throw ApiException(_extractError(decoded, response.statusCode));
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. The free Render service may be '
        'waking up. Wait a few seconds and press Predict again.',
      );
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException(
        'The server returned a response that could not be read.',
      );
    } catch (error) {
      throw ApiException(
        'Could not connect to the prediction API. Check your internet '
        'connection and try again. Details: $error',
      );
    }
  }

  String _extractError(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }

      if (detail is List) {
        final messages = detail
            .whereType<Map>()
            .map((item) => item['msg']?.toString())
            .whereType<String>()
            .toList();

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    return 'Prediction failed with HTTP status $statusCode.';
  }

  void close() {
    _client.close();
  }
}
