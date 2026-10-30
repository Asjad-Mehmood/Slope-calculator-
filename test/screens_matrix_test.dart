// Phase 9: every page at phone, tablet, laptop and large-screen sizes, with the system text size
// at 100 %, 150 % and 200 % (Windows display and accessibility settings, a phone's font size),
// in light and dark: nothing may overflow or throw.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/app.dart';
import 'package:slope_calculator/src/state/store.dart';

const sizes = {
  'small phone 360×640': Size(360, 640),
  'phone 390×844': Size(390, 844),
  'tablet 768×1024': Size(768, 1024),
  'laptop 1280×720': Size(1280, 720),
  'desktop 1920×1080': Size(1920, 1080),
};
const textScales = [1.0, 1.5, 2.0];
const pages = ['Calculator', 'Crossfall', 'Level', 'Saved', 'Settings'];

Future<void> open(WidgetTester tester, String page) async {
  await tester.tap(find.byKey(ValueKey('nav $page')));
  await tester.pumpAndSettle();
}

/// Scrolls every scrollable to its end, so the bottom of each page is built and laid out too
Future<void> scrollAll(WidgetTester tester) async {
  for (final state in tester.stateList<ScrollableState>(find.byType(Scrollable)).toList()) {
    if (!state.mounted) continue;
    final p = state.position;
    if (p.maxScrollExtent > 0) {
      p.jumpTo(p.maxScrollExtent);
      await tester.pump();
    }
  }
}

void main() {
  for (final MapEntry(key: name, value: size) in sizes.entries) {
    for (final scale in textScales) {
      for (final dark in [false, true]) {
        testWidgets('$name, text ${(scale * 100).round()} %, ${dark ? 'dark' : 'light'}', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);

          await tester.pumpWidget(SlopeCalculatorApp(store: Store.memory()));
          await tester.pumpAndSettle();
          for (final page in pages) {
            await open(tester, page);
            await scrollAll(tester);
            expect(tester.takeException(), isNull, reason: page);
          }
          // the second tab of Level, and the project plate
          await open(tester, 'Level');
          await tester.tap(find.text('Optical trainer'));
          await tester.pumpAndSettle();
          await scrollAll(tester);
          expect(tester.takeException(), isNull, reason: 'Optical trainer');
          await open(tester, 'Calculator');
          await tester.tap(
            find.byTooltip('Project plate').evaluate().isEmpty
                ? find.text('Project plate')
                : find.byTooltip('Project plate'),
          );
          await tester.pumpAndSettle();
          await scrollAll(tester);
          expect(tester.takeException(), isNull, reason: 'Project plate');
        });
      }
    }
  }
}
