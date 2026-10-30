import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/calc/crossfall.dart';
import 'package:slope_calculator/src/calc/numbers.dart';

void main() {
  test('the Excel template example: CL 10.000, 2 % and 2.5 % over 3.5 m, both falling away', () {
    final r = crossfall(
      10,
      left: const CrossfallSide(slopePercent: 2, distance: 3.5),
      right: const CrossfallSide(slopePercent: 2.5, distance: 3.5),
    );
    expect(r.leftLevel, closeTo(9.93, 1e-12));
    expect(r.rightLevel, closeTo(9.9125, 1e-12));
    expect(signed(r.leftDifference, 3), '−0.070');
    expect(signed(r.rightDifference, 4), '−0.0875');
  });

  test('rising away from the centreline', () {
    final r = crossfall(
      10,
      left: const CrossfallSide(slopePercent: 3, distance: 5, direction: CrossfallDirection.riseAway),
      right: const CrossfallSide(slopePercent: 0, distance: 5),
    );
    expect(r.leftLevel, closeTo(10.15, 1e-12));
    expect(r.rightLevel, 10);
  });

  test('the slope sign is ignored; the direction decides', () {
    final r = crossfall(
      10,
      left: const CrossfallSide(slopePercent: -2, distance: 3.5),
      right: const CrossfallSide(slopePercent: -2, distance: 3.5, direction: CrossfallDirection.riseAway),
    );
    expect(r.leftLevel, closeTo(9.93, 1e-12));
    expect(r.rightLevel, closeTo(10.07, 1e-12));
  });

  test('zero offset gives the centreline level', () {
    final r = crossfall(
      4.2,
      left: const CrossfallSide(slopePercent: 2, distance: 0),
      right: const CrossfallSide(slopePercent: 2, distance: 0),
    );
    expect(r.leftLevel, 4.2);
    expect(r.rightDifference, 0);
  });

  test('input checks', () {
    const ok = CrossfallSide(slopePercent: 2, distance: 3.5);
    expect(crossfallProblem(10, ok, ok), isNull);
    expect(crossfallProblem(double.nan, ok, ok), 'Check centreline, slope and distance inputs.');
    expect(
      crossfallProblem(10, const CrossfallSide(slopePercent: 2, distance: -1), ok),
      'Offset distances can\'t be negative.',
    );
    expect(
      () => crossfall(10, left: ok, right: const CrossfallSide(slopePercent: 2, distance: -1)),
      throwsArgumentError,
    );
  });
}
