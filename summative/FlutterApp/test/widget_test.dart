import 'package:african_football_predictor/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('prediction page contains the required controls', (tester) async {
    await tester.pumpWidget(const FootballValueApp());

    expect(find.text('African Football Value Predictor'), findsOneWidget);
    expect(find.text('Predict'), findsOneWidget);
    expect(find.text('Prediction result'), findsOneWidget);
  });
}
