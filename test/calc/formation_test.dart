import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/calc/calc.dart';

SlopeResult _line({double interval = 20, double x1 = 0, double x2 = 100, double y1 = 100, double y2 = 99}) =>
    calculateSlope(SlopeInput(startLevel: y1, endLevel: y2, startChainage: x1, endChainage: x2, interval: interval));

const _left2 = CrossfallSide(slopePercent: 2, distance: 5);
const _right25 = CrossfallSide(slopePercent: 2.5, distance: 5);

void main() {
  group('the acceptance test: 0+000 to 0+100, 100.000 to 99.000, every 20 m', () {
    final f = formation(_line(), const SidesInput(mode: SidesMode.both, left: _left2, right: _right25));

    test('length, slope and the level difference on each side', () {
      expect(f.slope.length, 100);
      expect(fixed(f.slope.percent, 3), '-1.000');
      expect(f.sides.leftDifference, closeTo(-0.100, 1e-12));
      expect(f.sides.rightDifference, closeTo(-0.125, 1e-12));
    });

    test('every station: chainage, left, centre and right', () {
      final want = [
        ['0+000', '99.900', '100.000', '99.875'],
        ['0+020', '99.700', '99.800', '99.675'],
        ['0+040', '99.500', '99.600', '99.475'],
        ['0+060', '99.300', '99.400', '99.275'],
        ['0+080', '99.100', '99.200', '99.075'],
        ['0+100', '98.900', '99.000', '98.875'],
      ];
      expect([
        for (final r in f.rows) [r.station.label, fixed(r.left!, 3), fixed(r.centre, 3), fixed(r.right!, 3)],
      ], want);
    });

    test('each level follows the formulas', () {
      for (final r in f.rows) {
        final x = r.station.chainage;
        final centre = 100 + (x - 0) / 100 * (99 - 100);
        expect(r.centre, closeTo(centre, 1e-9));
        expect(r.left, closeTo(centre - 5 * 2 / 100, 1e-9));
        expect(r.right, closeTo(centre - 5 * 2.5 / 100, 1e-9));
      }
    });

    test('the cross-section at any chainage between stations', () {
      final x = f.at(50);
      expect(x.centreLevel, closeTo(99.5, 1e-12));
      expect(x.leftLevel, closeTo(99.4, 1e-12));
      expect(x.rightLevel, closeTo(99.375, 1e-12));
    });
  });

  test('different offsets, crossfalls and directions on each side', () {
    final f = formation(
      _line(),
      const SidesInput(
        mode: SidesMode.both,
        left: CrossfallSide(slopePercent: 3, distance: 7.3, direction: CrossfallDirection.riseAway),
        right: CrossfallSide(slopePercent: 1.5, distance: 3.65),
      ),
    );
    expect(f.rows.first.left, closeTo(100.219, 1e-9));
    expect(f.rows.first.right, closeTo(99.94525, 1e-9));
    expect(f.rows.last.left, closeTo(99.219, 1e-9));
  });

  test('one side only, and the centreline only', () {
    final left = formation(_line(), const SidesInput(mode: SidesMode.leftOnly, left: _left2, right: _right25));
    expect(left.rows.first.left, closeTo(99.9, 1e-12));
    expect(left.rows.first.right, isNull);
    final right = formation(_line(), const SidesInput(mode: SidesMode.rightOnly, left: _left2, right: _right25));
    expect(right.rows.first.left, isNull);
    expect(right.rows.first.right, closeTo(99.875, 1e-12));
    final none = formation(_line(), const SidesInput(mode: SidesMode.none, left: _left2, right: _right25));
    expect(none.rows.every((r) => r.left == null && r.right == null), isTrue);
    expect(none.at(0).leftLevel, 100);
  });

  test('zero crossfall gives the centreline level', () {
    final f = formation(
      _line(),
      const SidesInput(mode: SidesMode.both, left: CrossfallSide(slopePercent: 0, distance: 5), right: _right25),
    );
    expect(f.rows[2].left, f.rows[2].centre);
  });

  test('a custom interval keeps the exact start and end, with the last short step', () {
    final f = formation(
      _line(interval: 15, x1: 3.5, x2: 100),
      const SidesInput(mode: SidesMode.both, left: _left2, right: _right25),
    );
    final labels = [for (final r in f.rows) r.station.label];
    expect(labels.first, '0+003.500');
    expect(labels.last, '0+100.000'); // off the 15 m grid, so written in full
    expect(labels, contains('0+090'));
    expect(f.rows.last.centre, 99);
    expect(f.rows.last.left, closeTo(98.9, 1e-12));
  });

  test('a side that is off is not checked; one that is on must be filled in', () {
    const bad = CrossfallSide(slopePercent: double.nan, distance: 5);
    expect(const SidesInput(mode: SidesMode.rightOnly, left: bad, right: _right25).problem, isNull);
    expect(const SidesInput(mode: SidesMode.both, left: bad, right: _right25).problem, contains('left'));
    expect(
      const SidesInput(
        mode: SidesMode.both,
        left: CrossfallSide(slopePercent: 2, distance: -1),
        right: _right25,
      ).problem,
      contains('negative'),
    );
    expect(
      const SidesInput(
        mode: SidesMode.both,
        left: _left2,
        right: CrossfallSide(slopePercent: 150, distance: 5),
      ).problem,
      contains('over 100'),
    );
    expect(
      () => formation(_line(), const SidesInput(mode: SidesMode.both, left: bad, right: _right25)),
      throwsArgumentError,
    );
  });
}
