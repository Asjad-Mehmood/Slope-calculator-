import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/app.dart';
import 'package:slope_calculator/src/state/store.dart';
import 'package:slope_calculator/src/ui/widgets.dart';

Future<void> open(WidgetTester tester, String page, {Store? store, Size size = const Size(1440, 1000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(SlopeCalculatorApp(store: store ?? Store.memory()));
  await tester.pumpAndSettle();
  await tester.tap(find.text(page).first);
  await tester.pumpAndSettle();
}

Finder box(String label) =>
    find.descendant(of: find.widgetWithText(NumberField, label), matching: find.byType(TextField));

void main() {
  group('crossfall', () {
    testWidgets('the Excel template example', (tester) async {
      await open(tester, 'Crossfall');
      expect(find.text('9.930 m'), findsOneWidget);
      expect(find.text('9.912 m'), findsOneWidget);
      expect(find.text('−0.070 m'), findsOneWidget);
    });

    testWidgets('rising away, and remembered', (tester) async {
      final store = Store.memory();
      await open(tester, 'Crossfall', store: store);
      await tester.tap(find.text('Rises away').first);
      await tester.pumpAndSettle();
      expect(find.text('10.070 m'), findsOneWidget);
      expect(store.readJson('crossfall')?['ldir'], 'riseAway');
    });

    testWidgets('a negative offset is refused', (tester) async {
      await open(tester, 'Crossfall');
      await tester.enterText(box('OFFSET').first, '-2');
      await tester.pump();
      expect(find.text('Offset distances can\'t be negative.'), findsWidgets);
    });
  });

  group('digital level', () {
    testWidgets('steps through the V28 example: the same first reading, and the checks at the end', (tester) async {
      await open(tester, 'Level');
      expect(find.text('READY'), findsOneWidget);
      await tester.tap(find.text('Step'));
      await tester.pump();
      expect(find.text('0.8504 m'), findsOneWidget);
      for (var i = 0; i < 15; i++) {
        await tester.tap(find.text('Step'));
        await tester.pump();
      }
      expect(find.text('CHECKS'), findsOneWidget);
      expect(find.textContaining('ΣBS − ΣFS ='), findsOneWidget);
      expect(
        find.textContaining('Closing error −0.3 mm against the design end level 98.750 m: within'),
        findsOneWidget,
      );
    });

    testWidgets('Rise & Fall books rises and falls', (tester) async {
      await open(tester, 'Level');
      await tester.tap(find.text('OPTIONS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rise & Fall'));
      await tester.pump();
      for (var i = 0; i < 16; i++) {
        await tester.tap(find.text('Step'));
        await tester.pump();
      }
      expect(find.text('FALL'), findsOneWidget);
      expect(find.textContaining('ΣRise − ΣFall ='), findsOneWidget);
    });

    testWidgets('a wrong line on the calculator explains itself', (tester) async {
      await open(tester, 'Calculator');
      await tester.enterText(box('INTERVAL'), '0');
      await tester.pump();
      await tester.tap(find.text('Level').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Interval must be greater than zero.'), findsOneWidget);
    });
  });

  group('optical trainer', () {
    testWidgets('watch shows the reading; practise marks an answer', (tester) async {
      await open(tester, 'Level');
      await tester.tap(find.text('Optical trainer'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('STAFF READING AT THE HORIZONTAL HAIR'), findsOneWidget);
      await tester.tap(find.text('Practise'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(box('YOUR READING'), '9.999');
      await tester.tap(find.text('Check'));
      await tester.pump();
      expect(find.textContaining('Not quite'), findsOneWidget);
      expect(find.text('Right 0 of 1. Within 2 mm counts as right.'), findsOneWidget);
    });
  });

  testWidgets('phone: crossfall and level fit', (tester) async {
    await open(tester, 'Crossfall', size: const Size(390, 844));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Level').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Step'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
