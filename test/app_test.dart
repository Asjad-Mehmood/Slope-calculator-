import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/app.dart';
import 'package:slope_calculator/src/brand.dart';
import 'package:slope_calculator/src/ui/settings.dart';
import 'package:slope_calculator/src/ui/widgets.dart';

Future<void> pumpAt(WidgetTester tester, Size size, {AppSettings? settings}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(SlopeCalculatorApp(settings: settings));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wide screen: menu with the name and version, and the example calculated', (tester) async {
    await pumpAt(tester, const Size(1440, 1000));
    expect(find.text(appName), findsOneWidget);
    expect(find.text('Version $appVersion'), findsOneWidget);
    expect(find.text('−1.500 %'), findsOneWidget);
    expect(find.textContaining('The ground falls 3.750 m over 250.000 m'), findsOneWidget);
  });

  testWidgets('phone: a bar along the bottom instead of the menu', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Version $appVersion'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong input shows the problem instead of results', (tester) async {
    await pumpAt(tester, const Size(1440, 1000));
    await tester.enterText(
      find.descendant(of: find.widgetWithText(NumberField, 'INTERVAL'), matching: find.byType(TextField)),
      '0',
    );
    await tester.pump();
    expect(find.text('Interval must be greater than zero.'), findsWidgets);
    expect(find.text('−1.500 %'), findsNothing);
  });

  testWidgets('Load example fills in the Excel template example', (tester) async {
    await pumpAt(tester, const Size(1440, 1000));
    await tester.tap(find.text('Load example'));
    await tester.pump();
    expect(find.text('−0.343 %'), findsOneWidget);
  });

  testWidgets('dark mode and text size', (tester) async {
    final settings = AppSettings();
    await pumpAt(tester, const Size(1440, 1000), settings: settings);
    await tester.tap(find.byTooltip('Dark mode'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, ThemeMode.dark);
    await tester.tap(find.byTooltip('Larger text'));
    await tester.pumpAndSettle();
    expect(settings.textScale, 1.05);
  });

  test('text size stays between 85 % and 130 %', () {
    final s = AppSettings();
    for (var i = 0; i < 20; i++) {
      s.growText();
    }
    expect(s.textScale, 1.3);
    expect(s.canGrowText, isFalse);
    for (var i = 0; i < 20; i++) {
      s.shrinkText();
    }
    expect(s.textScale, 0.85);
  });

  test('the version matches the release format', () {
    expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(appVersion), isTrue);
  });
}
