// A level book: backsights, intermediate sights and foresights reduced to levels, by the Height of
// Instrument or the Rise & Fall method, with the arithmetic checks, the misclosure on a known
// closing level and the misclosure spread back over the setups.
import 'dart:math' as math;

enum BookingMethod { heightOfInstrument, riseAndFall }

/// One line of the book: a point with the staff readings taken on it.
///
/// A change point has a foresight (read from the setup before) and a backsight (read from the
/// next). The first line has only a backsight, on the opening benchmark.
class BookRow {
  const BookRow({this.chainage, this.backsight, this.intermediate, this.foresight, this.remark = ''});

  /// Where the point is along the line, if known; used for the design level and adjustment
  final double? chainage;
  final double? backsight;
  final double? intermediate;
  final double? foresight;
  final String remark;
}

class ReducedRow {
  const ReducedRow({
    required this.row,
    required this.level,
    required this.setup,
    this.heightOfInstrument,
    this.rise,
    this.fall,
  });

  final BookRow row;

  /// The reduced level (RL)
  final double level;

  /// Which setup the point's level was read from (the first is 1; the opening benchmark is 0)
  final int setup;

  /// On a line with a backsight: the height of instrument for the next readings
  final double? heightOfInstrument;

  /// Rise & Fall: the rise or fall from the reading before
  final double? rise;
  final double? fall;
}

/// Sums are compared to 0.01 mm: readings are booked to 0.1 mm, so anything bigger is a real slip.
const arithmeticTolerance = 0.00001;

class ReducedBook {
  const ReducedBook({required this.method, required this.rows});

  final BookingMethod method;
  final List<ReducedRow> rows;

  int get setups => rows.last.setup;

  double get sumBacksights => _sum((r) => r.row.backsight);
  double get sumForesights => _sum((r) => r.row.foresight);
  double get sumIntermediates => _sum((r) => r.row.intermediate);
  double get sumRises => _sum((r) => r.rise);
  double get sumFalls => _sum((r) => r.fall);

  double get firstLevel => rows.first.level;
  double get lastLevel => rows.last.level;

  /// ΣBS − ΣFS = last RL − first RL
  bool get arithmeticCheckPasses =>
      (sumBacksights - sumForesights - (lastLevel - firstLevel)).abs() < arithmeticTolerance;

  /// Rise & Fall: ΣRise − ΣFall = last RL − first RL
  bool get riseFallCheckPasses => (sumRises - sumFalls - (lastLevel - firstLevel)).abs() < arithmeticTolerance;

  /// Height of Instrument: ΣIS + ΣFS + Σ(RL except the first) = Σ(HI × readings taken from it)
  bool get heightOfInstrumentCheckPasses {
    final applications = <int, int>{};
    for (final r in rows.skip(1)) {
      applications[r.setup] = (applications[r.setup] ?? 0) + 1;
    }
    var his = 0.0;
    for (final r in rows) {
      final hi = r.heightOfInstrument;
      if (hi == null) continue;
      // the HI on a line belongs to the next setup: the setup after the one this point was read from
      his += hi * (applications[r.setup + 1] ?? 0);
    }
    final levels = rows.skip(1).fold(0.0, (s, r) => s + r.level);
    return (sumIntermediates + sumForesights + levels - his).abs() < arithmeticTolerance * rows.length;
  }

  double _sum(double? Function(ReducedRow) f) => rows.fold(0.0, (s, r) => s + (f(r) ?? 0));
}

/// The book's mistakes in words for the user, or an empty list when it can be reduced.
List<String> bookProblems(List<BookRow> rows) {
  final problems = <String>[];
  if (rows.length < 2) return ['A level book needs at least a backsight and a foresight.'];
  bool reading(double? v) => v != null && v.isFinite;
  final first = rows.first;
  if (!reading(first.backsight) || first.intermediate != null || first.foresight != null) {
    problems.add('Line 1 must have only a backsight, on the benchmark.');
  }
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    final line = 'Line ${i + 1}';
    final hasIs = r.intermediate != null, hasFs = r.foresight != null;
    if (hasIs && hasFs) problems.add('$line has both an intermediate sight and a foresight.');
    if (!hasIs && !hasFs) problems.add('$line has no intermediate sight or foresight.');
    if (hasIs && r.backsight != null) problems.add('$line: a backsight goes with a foresight (a change point).');
    for (final v in [r.backsight, r.intermediate, r.foresight]) {
      if (v != null && !v.isFinite) problems.add('$line has a reading that is not a number.');
    }
  }
  final last = rows.last;
  if (last.foresight == null || last.backsight != null) problems.add('The last line must end with a foresight.');
  return problems;
}

/// Reduces the book from [openingLevel], the benchmark's level on line 1.
/// Throws [ArgumentError] when [bookProblems] finds a mistake.
ReducedBook reduceBook(
  List<BookRow> rows, {
  required double openingLevel,
  BookingMethod method = BookingMethod.heightOfInstrument,
}) {
  final problems = bookProblems(rows);
  if (problems.isNotEmpty) throw ArgumentError(problems.first);

  final out = <ReducedRow>[];
  var setup = 1;
  var hi = openingLevel + rows.first.backsight!;
  var previous = rows.first.backsight!; // Rise & Fall: the reading before, in the same setup
  var level = openingLevel;
  out.add(ReducedRow(row: rows.first, level: openingLevel, setup: 0, heightOfInstrument: hi));

  for (final row in rows.skip(1)) {
    final reading = row.intermediate ?? row.foresight!;
    double? rise, fall;
    if (method == BookingMethod.heightOfInstrument) {
      level = hi - reading;
    } else {
      final change = previous - reading;
      if (change >= 0) {
        rise = change;
      } else {
        fall = -change;
      }
      level = level + change;
    }
    final readFrom = setup;
    double? newHi;
    if (row.backsight != null) {
      newHi = level + row.backsight!;
      hi = newHi;
      previous = row.backsight!;
      setup++;
    } else {
      previous = reading;
    }
    out.add(ReducedRow(row: row, level: level, setup: readFrom, heightOfInstrument: newHi, rise: rise, fall: fall));
  }
  return ReducedBook(method: method, rows: List.unmodifiable(out));
}

class Misclosure {
  const Misclosure({required this.closingLevel, required this.error, required this.allowable, required this.lengthKm});

  /// The level the run should have closed on
  final double closingLevel;

  /// Measured − known, in metres (positive: the run ended too high)
  final double error;

  /// C × √K, in metres
  final double allowable;
  final double lengthKm;

  bool get withinTolerance => error.abs() <= allowable + 1e-12;
}

/// The misclosure on a known closing level, against C√K millimetres ([c] mm, the run's length in km).
Misclosure misclosure(ReducedBook book, {required double closingLevel, required double lengthKm, double c = 12}) {
  return Misclosure(
    closingLevel: closingLevel,
    error: book.lastLevel - closingLevel,
    allowable: c * math.sqrt(math.max(0, lengthKm)) / 1000,
    lengthKm: lengthKm,
  );
}

/// The levels with the misclosure spread equally over the setups: every point read from setup s
/// moves by −error × s ÷ setups, so the benchmark stays and the last point lands on the closing level.
List<double> adjustedLevels(ReducedBook book, Misclosure m) {
  final n = book.setups;
  return [for (final r in book.rows) r.level - m.error * r.setup / n];
}
