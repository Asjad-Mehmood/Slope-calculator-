import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/app.dart';
import 'package:slope_calculator/src/state/store.dart';

void main() {
  test('the app only looks for updates when main() asks it to', () {
    expect(const SlopeCalculatorApp().checkForUpdates, isFalse);
    expect(SlopeCalculatorApp(store: Store.memory(), checkForUpdates: true).checkForUpdates, isTrue);
  });
}
