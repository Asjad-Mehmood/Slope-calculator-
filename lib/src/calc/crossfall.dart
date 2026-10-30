// Crossfall: the level at an offset from the centreline, from the slope % across the road.

/// Whether the surface goes up or down moving away from the centreline.
enum CrossfallDirection { riseAway, fallAway }

class CrossfallSide {
  const CrossfallSide({
    required this.slopePercent,
    required this.distance,
    this.direction = CrossfallDirection.fallAway,
  });

  /// The crossfall, in %; its sign is ignored, [direction] says up or down
  final double slopePercent;

  /// The offset from the centreline, in metres
  final double distance;
  final CrossfallDirection direction;
}

class CrossfallResult {
  const CrossfallResult({required this.centreLevel, required this.leftLevel, required this.rightLevel});

  final double centreLevel;
  final double leftLevel;
  final double rightLevel;

  /// Positive: the side is higher than the centreline
  double get leftDifference => leftLevel - centreLevel;
  double get rightDifference => rightLevel - centreLevel;
}

/// What is wrong with the input, in words for the user, or null when it can be calculated.
String? crossfallProblem(double centreLevel, CrossfallSide left, CrossfallSide right) {
  final values = [centreLevel, left.slopePercent, left.distance, right.slopePercent, right.distance];
  if (values.any((v) => !v.isFinite)) return 'Check centreline, slope and distance inputs.';
  if (left.distance < 0 || right.distance < 0) return 'Offset distances can\'t be negative.';
  return null;
}

/// Level = CL + direction × distance × |slope %| ÷ 100, on each side.
/// Throws [ArgumentError] when [crossfallProblem] isn't null.
CrossfallResult crossfall(double centreLevel, {required CrossfallSide left, required CrossfallSide right}) {
  final problem = crossfallProblem(centreLevel, left, right);
  if (problem != null) throw ArgumentError(problem);
  double side(CrossfallSide s) {
    final sign = s.direction == CrossfallDirection.riseAway ? 1 : -1;
    return centreLevel + sign * s.distance * s.slopePercent.abs() / 100;
  }

  return CrossfallResult(centreLevel: centreLevel, leftLevel: side(left), rightLevel: side(right));
}
