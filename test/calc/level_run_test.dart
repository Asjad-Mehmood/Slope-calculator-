import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/calc/calc.dart';

SlopeResult line(double y1, double y2, double x1, double x2, double interval) =>
    calculateSlope(SlopeInput(startLevel: y1, endLevel: y2, startChainage: x1, endChainage: x2, interval: interval));

void expectOnStaff(LevelRun run) {
  for (final r in run.readings) {
    expect(r.reading, inInclusiveRange(0.35 - 0.002, 3.9 + 0.002), reason: '${r.kind} at ${r.chainage}');
  }
}

void main() {
  group('the V28 example: 102.5 to 98.75 over 1+000 to 1+250, every 20 m', () {
    final slope = line(102.5, 98.75, 1000, 1250, 20);
    final run = simulateLevelRun(slope);

    test('the same plan as V28: 3 setups, 16 readings', () {
      expect(run.setups, 3);
      expect(run.readings, hasLength(16));
      expect(run.changePointsAdded, 0);
    });

    test('the same readings and checks as V28 for seed 7', () {
      expect(run.readings.first.reading, 0.8504);
      expect(run.readings[1].reading, 1.1503);
      expect(fixed(run.book.sumBacksights, 4), '2.9249');
      expect(fixed(run.book.sumForesights, 4), '6.6752');
      expect(run.book.arithmeticCheckPasses, isTrue);
      expect((run.closing.error * 1000).toStringAsFixed(1), '-0.3');
      expect((run.closing.allowable * 1000).toStringAsFixed(1), '6.0');
      expect(run.closing.withinTolerance, isTrue);
    });

    test('the book: BM, change points and End', () {
      expect(run.points.first.reduced.row.remark, 'BM');
      expect(run.points.last.reduced.row.remark, 'End');
      expect(run.points.where((p) => p.reduced.row.remark == 'CP'), hasLength(2));
      expect(run.points, hasLength(14));
      expect(run.points.every((p) => p.isStation), isTrue);
    });
  });

  test('perfect readings land exactly on the line', () {
    final run = simulateLevelRun(line(102.5, 98.75, 1000, 1250, 20), options: const LevelRunOptions(noiseMm: 0));
    expect(run.readings.first.reading, 0.85);
    for (final p in run.points) {
      expect(p.differenceMm.abs(), lessThan(0.05));
    }
    expect(run.closing.error.abs(), lessThan(1e-9));
    expect(run.book.heightOfInstrumentCheckPasses, isTrue);
    final rf = reduceBook(
      [for (final p in run.points) p.reduced.row],
      openingLevel: 102.5,
      method: BookingMethod.riseAndFall,
    );
    expect(rf.riseFallCheckPasses, isTrue);
    expect(rf.lastLevel, closeTo(run.book.lastLevel, 1e-9));
  });

  test('max sight works (it did nothing in V28): 20 m gives 7 setups, every sight within 20 m', () {
    final run = simulateLevelRun(line(102.5, 98.75, 1000, 1250, 20), options: const LevelRunOptions(maxSight: 20));
    expect(run.setups, 7);
    for (final r in run.readings) {
      expect(r.sightDistance, lessThanOrEqualTo(20 + 1e-9));
    }
  });

  group('steep slopes (V28 booked −2.40 m and 5.60 m on a 4 m staff)', () {
    test('100 to 60 over 100 m: change points are added and every reading stays on the staff', () {
      final run = simulateLevelRun(line(100, 60, 0, 100, 20), options: const LevelRunOptions(noiseMm: 0));
      expectOnStaff(run);
      expect(run.changePointsAdded, greaterThan(0));
      expect(run.setups, greaterThanOrEqualTo(17));
      expect(run.closing.error.abs(), lessThan(0.0005));
      expect(run.book.arithmeticCheckPasses, isTrue);
      expect(run.points.last.chainage, 100);
      expect(run.points.where((p) => p.isStation), hasLength(6));
    });

    test('rising steeply works the same way', () {
      final run = simulateLevelRun(line(60, 100, 0, 100, 20));
      expectOnStaff(run);
      expect(run.book.arithmeticCheckPasses, isTrue);
      expect(run.closing.withinTolerance, isTrue);
    });

    test('added change points are marked, not counted as stations', () {
      final run = simulateLevelRun(line(100, 60, 0, 100, 20));
      final added = run.points.where((p) => !p.isStation).toList();
      expect(added, isNotEmpty);
      for (final p in added) {
        expect(p.reduced.row.remark, 'CP');
        expect(p.reduced.row.backsight, isNotNull);
      }
    });

    test('too steep for a staff at all: a clear message', () {
      final steep = line(100, 0, 0, 10, 5);
      expect(levelRunProblem(steep, const LevelRunOptions()), contains('too steep to level'));
      expect(() => simulateLevelRun(steep), throwsArgumentError);
    });
  });

  test('a level line: one setup per 100 m with a 50 m max sight', () {
    final run = simulateLevelRun(line(5, 5, 0, 300, 20), options: const LevelRunOptions(noiseMm: 0));
    expect(run.setups, 3);
    expect(run.readings.every((r) => r.reading == 1.6), isTrue);
  });

  test('balanced sights cancel collimation error at the end', () {
    final run = simulateLevelRun(
      line(102.5, 98.75, 1000, 1250, 20),
      options: const LevelRunOptions(noiseMm: 0, collimationMmPer100m: 5),
    );
    expect(run.closing.error.abs(), lessThan(0.0003));
    // but the intermediate sights, at other distances, show it
    expect(run.points.any((p) => p.differenceMm.abs() > 0.4), isTrue);
  });

  group('seeds', () {
    final slope = line(102.5, 98.75, 1000, 1250, 20);
    List<double> readings(int seed) => [
      for (final r in simulateLevelRun(slope, options: LevelRunOptions(seed: seed)).readings) r.reading,
    ];

    test('the same seed gives the same readings; New run gives different ones', () {
      expect(readings(7), readings(7));
      expect(readings(nextSeed(7)), isNot(readings(7)));
    });

    test('New run follows V28\'s sequence', () {
      // (7 × 2654435761 + 12345) mod 2^32, as Math.imul gives it
      expect(nextSeed(7), (7 * 2654435761 + 12345) % 4294967296);
      expect(nextSeed(4294967295), inInclusiveRange(0, 4294967295));
    });
  });

  test('too many stations for the simulator', () {
    expect(
      levelRunProblem(line(1, 2, 0, 1000, 2), const LevelRunOptions()),
      'Too many stations for the simulator. Use a larger interval.',
    );
  });
}
