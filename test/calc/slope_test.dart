import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/calc/numbers.dart';
import 'package:slope_calculator/src/calc/slope.dart';

SlopeResult slope(
  double y1,
  double y2,
  double x1,
  double x2,
  double interval, {
  StationSpacing spacing = StationSpacing.roundChainages,
}) => calculateSlope(
  SlopeInput(startLevel: y1, endLevel: y2, startChainage: x1, endChainage: x2, interval: interval, spacing: spacing),
);

List<String> labels(SlopeResult r) => [for (final s in r.stations) s.label];
List<String> levels(SlopeResult r, [int d = 3]) => [for (final s in r.stations) fixed(s.level, d)];

void main() {
  group('the V28 example: 102.5 to 98.75 over 1+000 to 1+250, every 20 m', () {
    final r = slope(102.5, 98.75, 1000, 1250, 20);

    test('slope, rise, length and gradient', () {
      expect(r.rise, closeTo(-3.75, 1e-12));
      expect(r.length, 250);
      expect(r.slopePerMetre, closeTo(-0.015, 1e-12));
      expect(signed(r.percent, 3), '−1.500');
      expect(fixed(r.gradient!, 1), '66.7');
      expect(r.direction, SlopeDirection.falling);
    });

    test('14 stations on round chainages, the end with its decimals', () {
      expect(r.stations, hasLength(14));
      expect(labels(r).take(3), ['1+000', '1+020', '1+040']);
      expect(labels(r).skip(12), ['1+240', '1+250.000']);
    });

    test('levels and change from start, as V28 shows them', () {
      expect(levels(r).take(3), ['102.500', '102.200', '101.900']);
      expect(levels(r).skip(12), ['98.900', '98.750']);
      expect(signed(r.stations[1].changeFromStart, 3), '−0.300');
      expect(fixed(r.stations.last.distanceFromStart, 3), '250.000');
    });

    test('the end level is exactly Y2, with no rounding drift', () {
      expect(r.stations.last.level, 98.75);
      expect(r.levelAt(1250), 98.75);
    });

    test('the sentence under the results', () {
      expect(r.summary, 'The ground falls 3.750 m over 250.000 m, a gradient of about 1 in 66.7 (−1.500 %).');
    });
  });

  group('the Excel template example: 1.9 to 0.6 over 0 to 379.29, every 20 m', () {
    final r = slope(1.9, 0.6, 0, 379.29, 20);

    test('slope % and gradient match the template formulas', () {
      expect(signed(r.percent, 3), '−0.343');
      expect(r.slopePerMetre, closeTo(-1.3 / 379.29, 1e-15));
      expect(fixed(r.gradient!, 3), '291.762');
    });

    test('20 stations and the levels the V28 CSV gave', () {
      expect(r.stations, hasLength(20));
      expect(levels(r).take(4), ['1.900', '1.831', '1.763', '1.694']);
      expect(labels(r).last, '0+379.290');
      expect(levels(r).last, '0.600');
    });

    test('counted from the start, as the template counts, gives the same stations here', () {
      final t = slope(1.9, 0.6, 0, 379.29, 20, spacing: StationSpacing.fromStart);
      expect(labels(t), labels(r));
    });
  });

  group('stations', () {
    test('round chainages from an odd start: 1+013, 1+020, 1+040 …', () {
      final r = slope(10, 11, 1013, 1100, 20);
      expect(labels(r), ['1+013.000', '1+020', '1+040', '1+060', '1+080', '1+100']);
    });

    test('counted from the start: 1+013, 1+033, 1+053 …', () {
      final r = slope(10, 11, 1013, 1100, 20, spacing: StationSpacing.fromStart);
      expect(labels(r), ['1+013', '1+033', '1+053', '1+073', '1+093', '1+100.000']);
    });

    test('an end on the grid is not repeated', () {
      expect(labels(slope(1, 2, 0, 100, 20)), ['0+000', '0+020', '0+040', '0+060', '0+080', '0+100']);
    });

    test('decimal intervals do not add a ghost station at the end', () {
      expect(slope(1, 2, 0, 0.3, 0.1).stations, hasLength(4));
    });

    test('an interval with decimals: half-metre stations keep their decimals (V28 rounded them)', () {
      expect(labels(slope(1, 2, 0, 50, 12.5)), ['0+000', '0+012.500', '0+025', '0+037.500', '0+050']);
    });

    test('negative chainages', () {
      expect(labels(slope(5, 5, -50, 50, 25)), ['-0+050', '-0+025', '0+000', '0+025', '0+050']);
    });

    test('an interval longer than the line gives just the two ends', () {
      expect(labels(slope(1, 2, 0, 15, 20)), ['0+000', '0+015.000']);
    });
  });

  group('direction', () {
    test('rising: 10 to 12 over 200 m is +1 %, 1 in 100', () {
      final r = slope(10, 12, 0, 200, 50);
      expect(r.direction, SlopeDirection.rising);
      expect(r.percent, closeTo(1, 1e-12));
      expect(r.gradient, closeTo(100, 1e-9));
      expect(r.summary, 'The ground rises 2.000 m over 200.000 m, a gradient of about 1 in 100.0 (+1.000 %).');
    });

    test('level: no gradient, its own sentence', () {
      final r = slope(7, 7, 0, 100, 20);
      expect(r.direction, SlopeDirection.level);
      expect(r.gradient, isNull);
      expect(r.percent, 0);
      expect(r.summary, 'The line is level over 100.000 m.');
    });
  });

  group('level at any chainage', () {
    final r = slope(102.5, 98.75, 1000, 1250, 20);
    test('between stations', () {
      expect(r.levelAt(1125), closeTo(100.625, 1e-12));
      expect(r.levelAt(1001), closeTo(102.485, 1e-12));
    });
    test('knows the ends of the line', () {
      expect(r.covers(1000), isTrue);
      expect(r.covers(1250), isTrue);
      expect(r.covers(999.9), isFalse);
      expect(r.covers(1250.1), isFalse);
    });
  });

  group('input checks', () {
    SlopeInput input({double y1 = 1, double y2 = 2, double x1 = 0, double x2 = 100, double iv = 20}) =>
        SlopeInput(startLevel: y1, endLevel: y2, startChainage: x1, endChainage: x2, interval: iv);

    test('every value must be a number', () {
      expect(input(y1: double.nan).problem, 'Enter all values.');
      expect(input(x2: double.infinity).problem, 'Enter all values.');
    });

    test('X2 must be after X1', () {
      expect(input(x2: 0).problem, 'End point X2 must be greater than start point X1.');
      expect(input(x2: -5).problem, 'End point X2 must be greater than start point X1.');
    });

    test('the interval must be above zero', () {
      expect(input(iv: 0).problem, 'Interval must be greater than zero.');
      expect(input(iv: -20).problem, 'Interval must be greater than zero.');
    });

    test('at most 5000 stations', () {
      expect(input(x2: 10000, iv: 2).problem, isNull);
      expect(input(x2: 10001, iv: 2).problem, 'Too many stations. Use a larger interval.');
    });

    test('calculating a bad input throws with the same words', () {
      expect(
        () => calculateSlope(input(iv: 0)),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Interval must be greater than zero.')),
      );
    });

    test('decimals are kept between 1 and 5', () {
      SlopeResult withDecimals(int d) => calculateSlope(
        SlopeInput(startLevel: 1, endLevel: 2, startChainage: 0, endChainage: 10, interval: 5, decimals: d),
      );
      expect(withDecimals(0).decimals, 1);
      expect(withDecimals(9).decimals, 5);
      expect(withDecimals(3).decimals, 3);
    });
  });
}
