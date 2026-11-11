// Formation levels: the centreline level at every station of the slope, and the level at a set
// offset left and right of it, from each side's own crossfall (lib/src/calc/crossfall.dart).
//
//   Centre RL = Y1 + (X − X1) ÷ (X2 − X1) × (Y2 − Y1)          (slope.dart)
//   ΔRL       = offset × crossfall % ÷ 100
//   Side RL   = Centre RL − ΔRL  (falls away from the centreline)
//             = Centre RL + ΔRL  (rises away)
//
// Each side has its own offset, crossfall and direction, and can be left out.
import 'crossfall.dart';
import 'slope.dart';

/// Which sides are worked out besides the centreline
enum SidesMode {
  both,
  leftOnly,
  rightOnly,

  /// The centreline only: the table shows distance and change from the start instead
  none;

  bool get left => this == both || this == leftOnly;
  bool get right => this == both || this == rightOnly;
}

class SidesInput {
  const SidesInput({required this.mode, required this.left, required this.right});

  final SidesMode mode;
  final CrossfallSide left;
  final CrossfallSide right;

  /// What is wrong with the sides that are on, in words for the user, or null
  String? get problem {
    String? check(String name, CrossfallSide s) {
      if (!s.distance.isFinite || !s.slopePercent.isFinite) return 'Enter the $name offset and crossfall.';
      if (s.distance < 0) return 'The $name offset can\'t be negative.';
      // the sign is ignored, as on the Crossfall page: falls or rises away decides
      if (s.slopePercent.abs() > 100) return 'The $name crossfall is over 100 %: check it.';
      return null;
    }

    return (mode.left ? check('left', left) : null) ?? (mode.right ? check('right', right) : null);
  }

  /// ΔRL on each side: positive when the side is higher than the centreline
  double get leftDifference => mode.left ? _difference(left) : 0;
  double get rightDifference => mode.right ? _difference(right) : 0;

  static double _difference(CrossfallSide s) =>
      (s.direction == CrossfallDirection.riseAway ? 1 : -1) * s.distance * s.slopePercent.abs() / 100;
}

class FormationRow {
  const FormationRow({required this.station, required this.left, required this.right});

  final Station station;

  /// null when that side is off
  final double? left;
  final double? right;

  double get centre => station.level;
}

class FormationResult {
  FormationResult._(this.slope, this.sides, this.rows);

  final SlopeResult slope;
  final SidesInput sides;
  final List<FormationRow> rows;

  /// The three levels across the road at any chainage on the line (the cross-section)
  CrossfallResult at(double chainage) {
    final centre = slope.levelAt(chainage);
    return crossfall(
      centre,
      left: sides.mode.left ? sides.left : const CrossfallSide(slopePercent: 0, distance: 0),
      right: sides.mode.right ? sides.right : const CrossfallSide(slopePercent: 0, distance: 0),
    );
  }
}

/// The formation levels at every station of [slope]. Throws [ArgumentError] when
/// [SidesInput.problem] isn't null.
FormationResult formation(SlopeResult slope, SidesInput sides) {
  final problem = sides.problem;
  if (problem != null) throw ArgumentError(problem);
  final dl = sides.leftDifference, dr = sides.rightDifference;
  final rows = [
    for (final s in slope.stations)
      FormationRow(
        station: s,
        left: sides.mode.left ? s.level + dl : null,
        right: sides.mode.right ? s.level + dr : null,
      ),
  ];
  return FormationResult._(slope, sides, List.unmodifiable(rows));
}
