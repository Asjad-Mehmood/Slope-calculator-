import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/app.dart';
import 'package:slope_calculator/src/brand.dart';
import 'package:slope_calculator/src/state/store.dart';
import 'package:slope_calculator/src/ui/settings.dart';
import 'package:slope_calculator/src/ui/widgets.dart';

import 'signed_in.dart';

Future<void> pumpAt(WidgetTester tester, Size size, {Store? store}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(SlopeCalculatorApp(store: signedInStore(store)));
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
    final store = Store.memory();
    await pumpAt(tester, const Size(1440, 1000), store: store);
    await tester.tap(find.byTooltip('Dark mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Larger text').first);
    await tester.pumpAndSettle();
    final settings = AppSettings(store);
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.textScale, 1.05);
  });

  test('text size stays between 85 % and 130 %', () {
    final s = AppSettings(Store.memory());
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

  Finder box(String label) =>
      find.descendant(of: find.widgetWithText(NumberField, label), matching: find.byType(TextField));

  testWidgets('inputs are remembered when the app opens again', (tester) async {
    final store = Store.memory();
    await pumpAt(tester, const Size(1440, 1000), store: store);
    await tester.enterText(box('START LEVEL'), '110');
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await pumpAt(tester, const Size(1440, 1000), store: store);
    expect(find.text('110'), findsOneWidget);
  });

  testWidgets('go to chainage gives the level there', (tester) async {
    await pumpAt(tester, const Size(1440, 1000));
    await tester.enterText(find.widgetWithText(TextField, 'Go to chainage, e.g. 1+125'), '1+125');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.textContaining('100.625 m', findRichText: true), findsWidgets);
  });

  testWidgets('go to a chainage outside the line explains why not', (tester) async {
    await pumpAt(tester, const Size(1440, 1000));
    await tester.enterText(find.widgetWithText(TextField, 'Go to chainage, e.g. 1+125'), '2+000');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.textContaining('is outside the line'), findsOneWidget);
  });

  testWidgets('the project plate is saved and its name shows on the button', (tester) async {
    final store = Store.memory();
    await pumpAt(tester, const Size(1440, 1000), store: store);
    await tester.tap(find.text('Project plate'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Project name'), 'Ring Road');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Ring Road'), findsOneWidget);
    expect(store.readJson('projectPlate'), {'project': 'Ring Road'});
  });

  testWidgets('settings: stations counted from the start change the table', (tester) async {
    await pumpAt(tester, const Size(1440, 1000));
    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('From the start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calculator').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load example'));
    await tester.pumpAndSettle();
    expect(find.text('0+020'), findsOneWidget);
  });

  testWidgets('phone: the project plate opens full screen', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byTooltip('Project plate'));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('the version matches the release format', () {
    expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(appVersion), isTrue);
  });
}
