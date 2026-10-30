import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/app.dart';
import 'package:slope_calculator/src/brand.dart';

void main() {
  testWidgets('the start screen shows the name and version', (tester) async {
    await tester.pumpWidget(const SlopeCalculatorApp());
    expect(find.text(appName), findsOneWidget);
    expect(find.textContaining('Version $appVersion'), findsOneWidget);
  });

  test('the version matches the release format', () {
    expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(appVersion), isTrue);
  });
}
