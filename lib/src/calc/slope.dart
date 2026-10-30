// The slope of a straight line between two levels, and the level at each chainage along it.
import 'chainage.dart';
import 'numbers.dart';

/// Where the stations between the start and the end go.
enum StationSpacing {
  /// On round chainages: with a 20 m interval from 1+013, the stations are 1+013, 1+020, 1+040 …
  roundChainages,

  /// Counted from the start: from 1+013, the stations are 1+013, 1+033, 1+053 …
  fromStart,
}

enum SlopeDirection { rising, falling, level }

/// The most stations one calculation makes; more is almost always a typing mistake.
const maxStations = 5000;

// Two chainages closer than this (in metres) are the same point.
const _same = 1e-9;

class SlopeInput {
  const SlopeInput({
    required this.startLevel,
    required this.endLevel,
    required this.startChainage,
    required this.endChainage,
    required this.interval,
    this.decimals = 3,
    this.spacing = StationSpacing.roundChainages,
  });

  /// Y1 and Y2, in metres
  final double startLevel;
  final double endLevel;

  /// X1 and X2, in metres along the line
  final double startChainage;
  final double endChainage;

  /// Metres between stations
  final double interval;

  /// Decimals for levels in tables and reports, 1 to 5
  final int decimals;
  final StationSpacing spacing;

  /// What is wrong with the input, in words for the user, or null when it can be calculated.
  String? get problem {
    final values = [startLevel, endLevel, startChainage, endChainage, interval];
    if (values.any((v) => !v.isFinite)) return 'Enter all values.';
    if (endChainage <= startChainage) return 'End point X2 must be greater than start point X1.';
    if (interval <= 0) return 'Interval must be greater than zero.';
    if ((endChainage - startChainage) / interval > maxStations) return 'Too many stations. Use a larger interval.';
    return null;
  }
}

class Station {
  const Station({
    required this.chainage,
    required this.distanceFromStart,
    required this.level,
    required this.changeFromStart,
    required this.onGrid,
  });

  final double chainage;
  final double distanceFromStart;
  final double level;
  final double changeFromStart;

  /// A whole-metre station on the interval's grid (1+020): shown without decimals, like a peg.
  final bool onGrid;

  /// `1+020` for a station on the grid, `1+013.500` for any other.
  String get label => formatChainage(chainage, decimals: onGrid ? 0 : 3);
}

class SlopeResult {
  SlopeResult._(this.input, this.stations);

  final SlopeInput input;
  final List<Station> stations;

  double get startLevel => input.startLevel;
  double get endLevel => input.endLevel;
  double get startChainage => input.startChainage;
  double get endChainage => input.endChainage;

  /// ΔH = Y2 − Y1
  double get rise => input.endLevel - input.startLevel;

  /// ΔX = X2 − X1
  double get length => input.endChainage - input.startChainage;

  /// M = ΔH ÷ ΔX, metres per metre
  double get slopePerMetre => rise / length;

  double get percent => slopePerMetre * 100;

  /// N in "1 in N"; null when the line is level
  double? get gradient => rise == 0 ? null : (length / rise).abs();

  SlopeDirection get direction => rise > 0
      ? SlopeDirection.rising
      : rise < 0
      ? SlopeDirection.falling
      : SlopeDirection.level;

  int get decimals => input.decimals.clamp(1, 5);

  /// The level on the line at [chainage]. Outside X1 to X2 the line is carried on.
  double levelAt(double chainage) {
    // Interpolated from both ends, so the end chainage gives exactly Y2
    final t = (chainage - startChainage) / length;
    return startLevel + rise * t;
  }

  bool covers(double chainage) => chainage >= startChainage - _same && chainage <= endChainage + _same;

  /// "The ground falls 3.750 m over 250.000 m, a gradient of about 1 in 66.7 (−1.500 %)."
  String get summary {
    if (rise == 0) return 'The line is level over ${fixed(length, 3)} m.';
    final verb = rise < 0 ? 'falls' : 'rises';
    return 'The ground $verb ${fixed(rise.abs(), 3)} m over ${fixed(length, 3)} m, '
        'a gradient of about 1 in ${fixed(gradient!, 1)} (${signed(percent, 3)} %).';
  }
}

/// Works out the slope and the stations. Throws [ArgumentError] when [SlopeInput.problem] isn't null.
SlopeResult calculateSlope(SlopeInput input) {
  final problem = input.problem;
  if (problem != null) throw ArgumentError(problem);

  final x1 = input.startChainage, x2 = input.endChainage, step = input.interval;
  final chainages = <double>[x1];
  if (input.spacing == StationSpacing.roundChainages) {
    for (var k = (x1 / step + _same).floor() + 1; k * step < x2 - _same; k++) {
      chainages.add(k * step);
    }
  } else {
    for (var k = 1; x1 + k * step < x2 - _same; k++) {
      chainages.add(x1 + k * step);
    }
  }
  chainages.add(x2);

  final result = SlopeResult._(input, const []);
  bool onGrid(double c) {
    final whole = (c - c.roundToDouble()).abs() < 1e-6;
    final base = input.spacing == StationSpacing.roundChainages ? 0.0 : x1;
    final steps = (c - base) / step;
    return whole && (steps - steps.roundToDouble()).abs() < 1e-6;
  }

  final stations = [
    for (final c in chainages)
      Station(
        chainage: c,
        distanceFromStart: c - x1,
        level: result.levelAt(c),
        changeFromStart: result.levelAt(c) - input.startLevel,
        onGrid: onGrid(c),
      ),
  ];
  return SlopeResult._(input, List.unmodifiable(stations));
}
