// The digital level simulator's planning: a level run along the slope line from the start level
// (the benchmark) to the end, with simulated staff readings, booked and checked.
//
// The level stands halfway between its backsight and foresight (balanced sights, so collimation
// error cancels) and reads every station in between as an intermediate sight. A setup reaches as
// far as the max sight allows and every reading stays on the staff. Where even the next station
// can't be reached in one setup (a steep slope), change points are added between stations. V28
// didn't, and booked readings like −2.40 m and 5.60 m on a 4 m staff.
import 'dart:math' as math;

import 'level_book.dart';
import 'slope.dart';

class LevelRunOptions {
  const LevelRunOptions({
    this.maxSight = 50,
    this.noiseMm = 0.3,
    this.collimationMmPer100m = 0,
    this.instrumentHeight = 1.6,
    this.minReading = 0.35,
    this.maxReading = 3.9,
    this.seed = 7,
    this.allowableC = 12,
  });

  /// The longest sight, in metres; kept between 10 and 100
  final double maxSight;

  /// The spread of the reading error (one standard deviation), in mm; 0 for perfect readings
  final double noiseMm;

  /// The level's collimation error: mm of reading per 100 m of sight
  final double collimationMmPer100m;

  /// The line of sight above the ground under the level, in metres
  final double instrumentHeight;

  /// Readings kept between these on a 4 m staff: near the foot is in the dirt, the top is unsteady
  final double minReading;
  final double maxReading;

  /// The same seed always gives the same readings; "New run" picks the next with [nextSeed]
  final int seed;

  /// C in the allowable misclosure C√K mm
  final double allowableC;

  double get sightLimit => maxSight.clamp(10, 100).toDouble();
}

/// The seed for "New run": the same sequence V28 used.
int nextSeed(int seed) => (_mul32(seed, 2654435761) + 12345) % _two32;

const _two32 = 4294967296;

// a × b keeping the low 32 bits (JavaScript's Math.imul, unsigned), in halves so no step passes
// 2^53: exact on the web as well as on Windows.
int _mul32(int a, int b) {
  a %= _two32;
  final low = a * (b % 65536);
  final high = (a * (b ~/ 65536 % 65536)) % _two32;
  return (low + high * 65536) % _two32;
}

enum SightKind { backsight, intermediate, foresight }

class SimulatedReading {
  const SimulatedReading({
    required this.setup,
    required this.kind,
    required this.chainage,
    required this.instrumentChainage,
    required this.heightOfInstrument,
    required this.reading,
    required this.isStation,
  });

  /// Which setup took the reading, from 1
  final int setup;
  final SightKind kind;
  final double chainage;
  final double instrumentChainage;

  /// The true height of the line of sight at this setup
  final double heightOfInstrument;

  /// The staff reading, rounded to 0.1 mm as a digital level shows it
  final double reading;

  /// False for a change point added between stations
  final bool isStation;

  double get sightDistance => (chainage - instrumentChainage).abs();
}

class LevelRunPoint {
  const LevelRunPoint({
    required this.chainage,
    required this.isStation,
    required this.designLevel,
    required this.reduced,
    required this.adjustedLevel,
  });

  final double chainage;
  final bool isStation;

  /// The level on the slope line at this chainage
  final double designLevel;
  final ReducedRow reduced;
  final double adjustedLevel;

  double get level => reduced.level;

  /// Reduced level − design level, in mm
  double get differenceMm => (level - designLevel) * 1000;
}

class LevelRun {
  const LevelRun({
    required this.slope,
    required this.options,
    required this.readings,
    required this.book,
    required this.points,
    required this.closing,
  });

  final SlopeResult slope;
  final LevelRunOptions options;

  /// In the order they're taken: BS, IS …, FS, then the next setup
  final List<SimulatedReading> readings;
  final ReducedBook book;
  final List<LevelRunPoint> points;

  /// Against the design end level Y2, allowable C√K with K the line's length in km
  final Misclosure closing;

  int get setups => book.setups;
  int get changePointsAdded => points.where((p) => !p.isStation).length;
}

/// The most stations the simulator steps through
const maxSimulatorStations = 400;

/// Why the run can't be planned, in words for the user, or null.
String? levelRunProblem(SlopeResult slope, LevelRunOptions options) {
  if (slope.stations.length > maxSimulatorStations) {
    return 'Too many stations for the simulator. Use a larger interval.';
  }
  final o = options;
  if (!(o.minReading >= 0 && o.minReading < o.instrumentHeight && o.instrumentHeight < o.maxReading)) {
    return 'The staff limits must be below and above the instrument height.';
  }
  if (_longestSetup(slope, o) < 1) {
    final limit = 2 * (o.instrumentHeight - o.minReading) * 100;
    return 'The slope is too steep to level with the staff (over ${limit.toStringAsFixed(0)} %). '
        'Use trigonometric heighting instead.';
  }
  return null;
}

// The longest backsight-to-foresight span with every reading on the staff: on a straight line the
// readings change by |M| × span ÷ 2 either side of the instrument height.
double _longestSetup(SlopeResult slope, LevelRunOptions o) {
  final m = slope.slopePerMetre.abs();
  var span = 2 * o.sightLimit;
  if (m > 0) {
    span = math.min(span, 2 * (o.instrumentHeight - o.minReading) / m);
    span = math.min(span, 2 * (o.maxReading - o.instrumentHeight) / m);
  }
  return span;
}

/// Plans and books the level run. Throws [ArgumentError] when [levelRunProblem] isn't null.
LevelRun simulateLevelRun(SlopeResult slope, {LevelRunOptions options = const LevelRunOptions()}) {
  final problem = levelRunProblem(slope, options);
  if (problem != null) throw ArgumentError(problem);
  final o = options;
  final random = _Random(o.seed);
  final stations = [for (final s in slope.stations) s.chainage];
  const eps = 1e-9;

  bool fitsOnStaff(double from, double to) {
    final hi = slope.levelAt((from + to) / 2) + o.instrumentHeight;
    final inside = stations.where((c) => c > from + eps && c < to - eps);
    for (final c in [from, ...inside, to]) {
      final r = hi - slope.levelAt(c);
      if (r < o.minReading - eps || r > o.maxReading + eps) return false;
    }
    return true;
  }

  final readings = <SimulatedReading>[];
  var at = stations.first;
  var setup = 0;
  while (at < stations.last - eps) {
    setup++;
    // The furthest station this setup can reach; if none, a change point as far as the staff allows
    double? to;
    for (final c in stations.reversed) {
      if (c <= at + eps) break;
      if ((c - at) / 2 > o.sightLimit + eps) continue;
      if (fitsOnStaff(at, c)) {
        to = c;
        break;
      }
    }
    final atStation = to != null;
    to ??= at + _longestSetup(slope, o) * 0.98;

    final level = (at + to) / 2;
    final hi = slope.levelAt(level) + o.instrumentHeight;
    double read(double c) {
      final distance = (c - level).abs();
      var r = hi - slope.levelAt(c) + o.collimationMmPer100m * distance / 100 / 1000;
      if (o.noiseMm > 0) r += random.gaussian() * o.noiseMm / 1000;
      return (r * 10000).round() / 10000;
    }

    SimulatedReading sight(SightKind kind, double c, bool isStation) => SimulatedReading(
      setup: setup,
      kind: kind,
      chainage: c,
      instrumentChainage: level,
      heightOfInstrument: hi,
      reading: read(c),
      isStation: isStation,
    );

    final atIsStation = stations.any((c) => (c - at).abs() < eps);
    readings.add(sight(SightKind.backsight, at, atIsStation));
    for (final c in stations.where((c) => c > at + eps && c < to! - eps)) {
      readings.add(sight(SightKind.intermediate, c, true));
    }
    readings.add(sight(SightKind.foresight, to, atStation));
    at = to;
  }

  // Booked as a surveyor would: the foresight and the next backsight share a line (a change point)
  final rows = <BookRow>[];
  final isStation = <bool>[];
  for (final r in readings) {
    switch (r.kind) {
      case SightKind.backsight when r.setup == 1:
        rows.add(BookRow(chainage: r.chainage, backsight: r.reading, remark: 'BM'));
        isStation.add(r.isStation);
      case SightKind.backsight:
        final last = rows.removeLast();
        rows.add(BookRow(chainage: last.chainage, backsight: r.reading, foresight: last.foresight, remark: 'CP'));
      case SightKind.intermediate:
        rows.add(BookRow(chainage: r.chainage, intermediate: r.reading));
        isStation.add(true);
      case SightKind.foresight:
        final end = (r.chainage - stations.last).abs() < eps;
        rows.add(BookRow(chainage: r.chainage, foresight: r.reading, remark: end ? 'End' : ''));
        isStation.add(r.isStation);
    }
  }

  final book = reduceBook(rows, openingLevel: slope.startLevel);
  final closing = misclosure(book, closingLevel: slope.endLevel, lengthKm: slope.length / 1000, c: o.allowableC);
  final adjusted = adjustedLevels(book, closing);
  final points = [
    for (var i = 0; i < book.rows.length; i++)
      LevelRunPoint(
        chainage: rows[i].chainage!,
        isStation: isStation[i],
        designLevel: slope.levelAt(rows[i].chainage!),
        reduced: book.rows[i],
        adjustedLevel: adjusted[i],
      ),
  ];
  return LevelRun(
    slope: slope,
    options: o,
    readings: List.unmodifiable(readings),
    book: book,
    points: List.unmodifiable(points),
    closing: closing,
  );
}

// The same generator V28 used (a linear congruential generator and Box-Muller), so a seed gives
// the same readings here as it did there. Exact with the web's 53-bit numbers too.
class _Random {
  _Random(this._seed);
  int _seed;

  double next() {
    _seed = (_seed * 1664525 + 1013904223) % _two32;
    return _seed / _two32;
  }

  double gaussian() {
    var u = next();
    if (u == 0) u = 1e-9;
    final v = next();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  }
}
