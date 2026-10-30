// Chainage: a distance along the line written as kilometres + metres, 1250.5 m → 1+250.500.
import 'dart:math' as math;

/// 1250.5 → `1+250.500`, 20 → `0+020.000`, -20 → `-0+020.000`. With [decimals] 0: `1+250`.
///
/// The value is rounded before it is split, so 999.9996 m shows as `1+000.000`, never `0+1000.000`.
String formatChainage(double metres, {int decimals = 3}) {
  final factor = math.pow(10, decimals);
  final rounded = (metres.abs() * factor).round() / factor;
  final km = (rounded / 1000 + 1e-9).floor();
  final rest = math.max(0.0, rounded - km * 1000);
  final width = 3 + (decimals > 0 ? decimals + 1 : 0);
  final sign = metres < 0 && rounded != 0 ? '-' : '';
  return '$sign$km+${rest.toStringAsFixed(decimals).padLeft(width, '0')}';
}

final _chainagePattern = RegExp(r'^([+-]?)(\d+)\s*\+\s*(\d+(?:\.\d*)?)$');
final _plainNumber = RegExp(r'^[+-]?(\d+(\.\d*)?|\.\d+)$');

/// Reads a chainage typed as `1+250.5`, `1 + 250`, `-0+020` or as plain metres `1250.5`.
/// Returns null when it isn't one; the metres after the + must be under 1000.
double? parseChainage(String text) {
  final t = text.trim();
  if (_plainNumber.hasMatch(t)) return double.parse(t);
  final m = _chainagePattern.firstMatch(t);
  if (m == null) return null;
  final metres = double.parse(m.group(3)!);
  if (metres >= 1000) return null;
  final value = int.parse(m.group(2)!) * 1000 + metres;
  return m.group(1) == '-' ? -value : value;
}
