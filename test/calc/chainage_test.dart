import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/calc/chainage.dart';
import 'package:slope_calculator/src/calc/numbers.dart';

void main() {
  group('formatChainage', () {
    test('kilometres + metres with 3 decimals', () {
      expect(formatChainage(1250.5), '1+250.500');
      expect(formatChainage(20), '0+020.000');
      expect(formatChainage(0), '0+000.000');
      expect(formatChainage(12345.678), '12+345.678');
    });

    test('negative chainages, and no "-0" for a tiny negative', () {
      expect(formatChainage(-20), '-0+020.000');
      expect(formatChainage(-0.0001), '0+000.000');
    });

    test('rounds before splitting: 999.9996 is 1+000.000, not 0+1000.000 (a V28 slip)', () {
      expect(formatChainage(999.9996), '1+000.000');
      expect(formatChainage(1999.99951), '2+000.000');
    });

    test('other decimals', () {
      expect(formatChainage(1250, decimals: 0), '1+250');
      expect(formatChainage(5.25, decimals: 1), '0+005.3');
      expect(formatChainage(7, decimals: 0), '0+007');
    });
  });

  group('parseChainage', () {
    test('reads chainage and plain metres', () {
      expect(parseChainage('1+250.5'), 1250.5);
      expect(parseChainage(' 1 + 250 '), 1250);
      expect(parseChainage('-0+020'), -20);
      expect(parseChainage('1250.5'), 1250.5);
      expect(parseChainage('+5'), 5);
      expect(parseChainage('.5'), 0.5);
    });

    test('refuses what is not a chainage', () {
      for (final bad in ['', 'abc', '1+', '1+1000', '1++20', '1+20+3', '1,250']) {
        expect(parseChainage(bad), isNull, reason: bad);
      }
    });

    test('a formatted chainage reads back to the same value', () {
      for (final v in [0.0, 19.999, 1250.5, 98765.432, -45.5]) {
        expect(parseChainage(formatChainage(v)), closeTo(v, 1e-9));
      }
    });
  });

  group('numbers', () {
    test('fixed never shows -0', () {
      expect(fixed(2.5, 3), '2.500');
      expect(fixed(-0.0001, 3), '0.000');
      expect(fixed(-1.23456, 2), '-1.23');
    });

    test('signed uses a real minus sign, a plus for positive and none for zero', () {
      expect(signed(-3.75, 3), '−3.750');
      expect(signed(0.3, 3), '+0.300');
      expect(signed(0, 3), '0.000');
      expect(signed(-0.0004, 3), '0.000');
    });
  });
}
