// Phase 9: every page at phone, tablet, laptop and large-screen sizes, with the system text size
// at 100 %, 150 % and 200 % (Windows display and accessibility settings, a phone's font size),
// in light and dark: nothing may overflow or throw.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/app.dart';

import 'signed_in.dart';

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
  await settle(tester);
}

/// Lets transitions finish; the optical trainer animates for as long as it is on screen, so this
/// doesn't wait for everything to stop
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls every scrollable to its end, so the bottom of each page is built and laid out too
Future<void> scrollAll(WidgetTester tester) async {
  for (final state in tester.stateList<ScrollableState>(find.byType(Scrollable)).toList()) {
    if (!state.mounted || state.position.axis != Axis.vertical) continue;
    final p = state.position;
    if (p.maxScrollExtent > 0) {
      p.jumpTo(p.maxScrollExtent);
      await tester.pump();
    }
  }
}

/// "Calculator: overflowed by 20 pixels on the right at lib/src/…:349" for each problem
String describe(String where, FlutterErrorDetails e) {
  final text = e.toString();
  final what = RegExp(r'overflowed by [0-9.]+ pixels on the \w+').firstMatch(text)?[0] ?? e.exceptionAsString();
  final at = RegExp(r'lib/src/\S+?\.dart:\d+').firstMatch(text)?[0] ?? 'Flutter';
  return '$where: $what at $at';
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

          final problems = <String>[];
          var where = 'start';
          final report = FlutterError.onError;
          FlutterError.onError = (e) => problems.add(describe(where, e));
          addTearDown(() => FlutterError.onError = report);

          await tester.pumpWidget(SlopeCalculatorApp(store: signedInStore()));
          await tester.pumpAndSettle();
          for (final page in pages) {
            where = page;
            await open(tester, page);
            await scrollAll(tester);
          }
          // the second tab of Level, and the project plate
          where = 'Optical trainer';
          await open(tester, 'Level');
          await tester.tap(find.text('Optical trainer'));
          await settle(tester);
          await scrollAll(tester);
          where = 'Project plate';
          await open(tester, 'Calculator');
          await tester.tap(
            find.byTooltip('Project plate').evaluate().isEmpty
                ? find.text('Project plate')
                : find.byTooltip('Project plate'),
          );
          await settle(tester);
          await scrollAll(tester);
          FlutterError.onError = report;
          expect(problems.toSet().toList(), isEmpty);
        });
      }
    }
  }
}
