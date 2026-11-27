import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/app.dart';
import 'package:slope_calculator/src/brand.dart';
import 'package:slope_calculator/src/support/app_info.dart';
import 'package:slope_calculator/src/support/crash_log.dart';

import 'signed_in.dart';

void main() {
  tearDown(() => CrashLog.last.value = null);

  testWidgets('Help: what is new, the guide, report a problem and the open-source licences', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(SlopeCalculatorApp(store: signedInStore()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('help')));
    await tester.pumpAndSettle();
    expect(find.text('Version $appVersion · exceltokml.com'), findsOneWidget);
    for (final t in ["What's new", 'User guide', 'Report a problem', 'Open-source licences']) {
      expect(find.text(t), findsOneWidget);
    }
    await tester.tap(find.text('Open-source licences'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  test('Report a problem opens the contact form with the program and version', () {
    final u = Uri.parse(appInfo.reportUrl);
    expect(u.host, 'www.exceltokml.com');
    expect(u.path, '/contact');
    expect(u.queryParameters, containsPair('topic', 'problem'));
    expect(u.queryParameters, containsPair('program', 'slope'));
    expect(u.queryParameters, containsPair('version', appVersion));
    expect(u.queryParameters['platform'], isNotEmpty);
  });

  testWidgets('an error shows a notice instead of a grey screen, and it closes', (tester) async {
    await tester.pumpWidget(SlopeCalculatorApp(store: signedInStore()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('crash notice')), findsNothing);

    CrashLog.record(StateError('the test error'), StackTrace.current);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('crash notice')), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.textContaining('the test error'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('crash notice')), findsNothing);
  });
}
