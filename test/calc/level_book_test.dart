import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/calc/level_book.dart';
import 'package:slope_calculator/src/calc/numbers.dart';

// A worked example, reduced by hand both ways:
//   line  BS     IS     FS     HI        RL        rise   fall
//   1     1.585                101.585   100.000                  BM
//   2            1.950                    99.635           0.365
//   3     0.875         2.105  100.355    99.480           0.155   CP
//   4            1.225                    99.130           0.350
//   5                   0.650             99.705    0.575
const book = [
  BookRow(backsight: 1.585, remark: 'BM'),
  BookRow(intermediate: 1.950),
  BookRow(backsight: 0.875, foresight: 2.105, remark: 'CP'),
  BookRow(intermediate: 1.225),
  BookRow(foresight: 0.650),
];

List<String> rls(ReducedBook b) => [for (final r in b.rows) fixed(r.level, 3)];

void main() {
  group('Height of Instrument', () {
    final b = reduceBook(book, openingLevel: 100);

    test('reduced levels and heights of instrument', () {
      expect(rls(b), ['100.000', '99.635', '99.480', '99.130', '99.705']);
      expect(fixed(b.rows[0].heightOfInstrument!, 3), '101.585');
      expect(fixed(b.rows[2].heightOfInstrument!, 3), '100.355');
      expect(b.setups, 2);
    });

    test('checks: ΣBS − ΣFS = last − first, and the HI check', () {
      expect(fixed(b.sumBacksights, 3), '2.460');
      expect(fixed(b.sumForesights, 3), '2.755');
      expect(b.arithmeticCheckPasses, isTrue);
      expect(b.heightOfInstrumentCheckPasses, isTrue);
    });
  });

  group('Rise & Fall', () {
    final b = reduceBook(book, openingLevel: 100, method: BookingMethod.riseAndFall);

    test('gives the same levels', () {
      expect(rls(b), ['100.000', '99.635', '99.480', '99.130', '99.705']);
    });

    test('rises and falls, and ΣRise − ΣFall = last − first', () {
      expect(fixed(b.rows[1].fall!, 3), '0.365');
      expect(fixed(b.rows[4].rise!, 3), '0.575');
      expect(fixed(b.sumRises, 3), '0.575');
      expect(fixed(b.sumFalls, 3), '0.870');
      expect(b.riseFallCheckPasses, isTrue);
      expect(b.arithmeticCheckPasses, isTrue);
    });
  });

  test('a booking slip fails the checks', () {
    final b = reduceBook(book, openingLevel: 100);
    final slipped = ReducedBook(
      method: b.method,
      rows: [
        ...b.rows.take(4),
        ReducedRow(row: b.rows[4].row, level: b.rows[4].level + 0.01, setup: b.rows[4].setup),
      ],
    );
    expect(slipped.arithmeticCheckPasses, isFalse);
    expect(slipped.heightOfInstrumentCheckPasses, isFalse);
  });

  group('closing on a known level', () {
    final b = reduceBook(book, openingLevel: 100);

    test('5 mm high over 100 m is outside 12√K (3.8 mm) and inside 20√K (6.3 mm)', () {
      final m12 = misclosure(b, closingLevel: 99.7, lengthKm: 0.1);
      expect((m12.error * 1000).toStringAsFixed(1), '5.0');
      expect((m12.allowable * 1000).toStringAsFixed(1), '3.8');
      expect(m12.withinTolerance, isFalse);
      expect(misclosure(b, closingLevel: 99.7, lengthKm: 0.1, c: 20).withinTolerance, isTrue);
    });

    test('the adjustment spreads it over the setups and closes exactly', () {
      final adjusted = adjustedLevels(b, misclosure(b, closingLevel: 99.7, lengthKm: 0.1));
      expect([for (final l in adjusted) fixed(l, 4)], ['100.0000', '99.6325', '99.4775', '99.1250', '99.7000']);
    });
  });

  group('book checks', () {
    test('a correct book has no problems', () => expect(bookProblems(book), isEmpty));

    test('finds the usual slips', () {
      expect(bookProblems(const [BookRow(backsight: 1)]), ['A level book needs at least a backsight and a foresight.']);
      expect(
        bookProblems(const [BookRow(foresight: 1), BookRow(foresight: 1)]),
        contains('Line 1 must have only a backsight, on the benchmark.'),
      );
      expect(
        bookProblems(const [BookRow(backsight: 1), BookRow(intermediate: 1, foresight: 2), BookRow(foresight: 1)]),
        contains('Line 2 has both an intermediate sight and a foresight.'),
      );
      expect(
        bookProblems(const [BookRow(backsight: 1), BookRow(), BookRow(foresight: 1)]),
        contains('Line 2 has no intermediate sight or foresight.'),
      );
      expect(
        bookProblems(const [BookRow(backsight: 1), BookRow(backsight: 1, foresight: 1)]),
        contains('The last line must end with a foresight.'),
      );
      expect(
        bookProblems(const [BookRow(backsight: 1), BookRow(backsight: 1, intermediate: 1), BookRow(foresight: 1)]),
        contains('Line 2: a backsight goes with a foresight (a change point).'),
      );
    });

    test('reducing a wrong book throws with the first problem', () {
      expect(() => reduceBook(const [BookRow(backsight: 1)], openingLevel: 0), throwsArgumentError);
    });
  });
}
