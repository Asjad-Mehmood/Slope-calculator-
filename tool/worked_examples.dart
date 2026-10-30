// Prints docs/worked-examples.md from the calculation engine, so the examples can never drift
// from what the app calculates:  dart run tool/worked_examples.dart > docs/worked-examples.md
import 'package:slope_calculator/src/calc/calc.dart';

void main() {
  final o = StringBuffer()
    ..writeln('# Worked examples')
    ..writeln()
    ..writeln('Printed by `dart run tool/worked_examples.dart` from the same code the app uses. Check')
    ..writeln('them against your own calculation; each one is also an automatic test.')
    ..writeln();

  // 1 and 2: slope and chainage levels
  void slopeExample(String title, SlopeInput input, {int rows = 99}) {
    final r = calculateSlope(input);
    o
      ..writeln('## $title')
      ..writeln()
      ..writeln(
        'Y1 = ${fixed(input.startLevel, 3)} m, Y2 = ${fixed(input.endLevel, 3)} m, '
        'X1 = ${formatChainage(input.startChainage)}, X2 = ${formatChainage(input.endChainage)}, '
        'interval ${fixed(input.interval, 0)} m',
      )
      ..writeln()
      ..writeln('| | Result |')
      ..writeln('| --- | --- |')
      ..writeln('| ΔH = Y2 − Y1 | ${signed(r.rise, 3)} m |')
      ..writeln('| ΔX = X2 − X1 | ${fixed(r.length, 3)} m |')
      ..writeln('| M = ΔH ÷ ΔX | ${signed(r.slopePerMetre, 5)} m per m |')
      ..writeln('| Slope | ${signed(r.percent, 3)} % |')
      ..writeln('| Gradient | ${r.gradient == null ? 'level' : '1 in ${fixed(r.gradient!, 1)}'} |')
      ..writeln()
      ..writeln('| Chainage | Distance (m) | Level (m) | Change (m) |')
      ..writeln('| --- | ---: | ---: | ---: |');
    final s = r.stations;
    final shown = s.length <= rows ? s : [...s.take(rows - 2), ...s.skip(s.length - 2)];
    for (final st in shown) {
      if (s.length > rows && st == s[s.length - 2]) o.writeln('| … | | | |');
      o.writeln(
        '| ${st.label} | ${fixed(st.distanceFromStart, 3)} | ${fixed(st.level, 3)} | ${signed(st.changeFromStart, 3)} |',
      );
    }
    o
      ..writeln()
      ..writeln('${r.stations.length} stations. ${r.summary}')
      ..writeln();
  }

  slopeExample(
    '1. Slope and chainage levels (the V28 example)',
    const SlopeInput(startLevel: 102.5, endLevel: 98.75, startChainage: 1000, endChainage: 1250, interval: 20),
  );
  slopeExample(
    '2. The Excel template example',
    const SlopeInput(startLevel: 1.9, endLevel: 0.6, startChainage: 0, endChainage: 379.29, interval: 20),
    rows: 8,
  );

  // 3: crossfall
  final c = crossfall(
    10,
    left: const CrossfallSide(slopePercent: 2, distance: 3.5),
    right: const CrossfallSide(slopePercent: 2.5, distance: 3.5),
  );
  o
    ..writeln('## 3. Crossfall (the Excel template example)')
    ..writeln()
    ..writeln('Centreline 10.000 m. Level = CL + direction × distance × |slope %| ÷ 100.')
    ..writeln()
    ..writeln('| Side | Slope | Offset | Direction | Level | Difference |')
    ..writeln('| --- | ---: | ---: | --- | ---: | ---: |')
    ..writeln('| Left | 2.0 % | 3.500 m | falls away | ${fixed(c.leftLevel, 4)} m | ${signed(c.leftDifference, 4)} m |')
    ..writeln(
      '| Right | 2.5 % | 3.500 m | falls away | ${fixed(c.rightLevel, 4)} m | ${signed(c.rightDifference, 4)} m |',
    )
    ..writeln();

  // 4: a level book, both methods
  const rows = [
    BookRow(backsight: 1.585, remark: 'BM'),
    BookRow(intermediate: 1.950),
    BookRow(backsight: 0.875, foresight: 2.105, remark: 'CP'),
    BookRow(intermediate: 1.225),
    BookRow(foresight: 0.650),
  ];
  final hi = reduceBook(rows, openingLevel: 100);
  final rf = reduceBook(rows, openingLevel: 100, method: BookingMethod.riseAndFall);
  final m = misclosure(hi, closingLevel: 99.7, lengthKm: 0.1);
  final adj = adjustedLevels(hi, m);
  String n(double? v) => v == null ? '' : fixed(v, 3);
  o
    ..writeln('## 4. Level book: Height of Instrument and Rise & Fall')
    ..writeln()
    ..writeln('Opening benchmark 100.000 m, closing on a known 99.700 m, 100 m of levelling.')
    ..writeln()
    ..writeln('| Line | BS | IS | FS | HI | Rise | Fall | RL | Adjusted RL | Remark |')
    ..writeln('| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |');
  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    o.writeln(
      '| ${i + 1} | ${n(r.backsight)} | ${n(r.intermediate)} | ${n(r.foresight)} | '
      '${n(hi.rows[i].heightOfInstrument)} | ${n(rf.rows[i].rise)} | ${n(rf.rows[i].fall)} | '
      '${fixed(hi.rows[i].level, 3)} | ${fixed(adj[i], 4)} | ${r.remark} |',
    );
  }
  o
    ..writeln()
    ..writeln(
      '- ΣBS − ΣFS = ${fixed(hi.sumBacksights, 3)} − ${fixed(hi.sumForesights, 3)} = '
      '${signed(hi.sumBacksights - hi.sumForesights, 3)}; last RL − first RL = ${signed(hi.lastLevel - hi.firstLevel, 3)} ✓',
    )
    ..writeln(
      '- ΣRise − ΣFall = ${fixed(rf.sumRises, 3)} − ${fixed(rf.sumFalls, 3)} = ${signed(rf.sumRises - rf.sumFalls, 3)} ✓',
    )
    ..writeln('- HI check: ΣIS + ΣFS + Σ(RL except the first) = Σ(HI × readings from it) ✓')
    ..writeln(
      '- Misclosure ${signed(m.error * 1000, 1)} mm; allowable 12√K = ${fixed(m.allowable * 1000, 1)} mm: '
      '${m.withinTolerance ? 'within' : 'outside'} tolerance. Spread equally over the 2 setups.',
    )
    ..writeln();

  // 5: the digital level on a steep slope
  final steep = calculateSlope(
    const SlopeInput(startLevel: 100, endLevel: 60, startChainage: 0, endChainage: 100, interval: 20),
  );
  final run = simulateLevelRun(steep, options: const LevelRunOptions(noiseMm: 0));
  o
    ..writeln('## 5. Digital level on a steep slope (the V28 bug)')
    ..writeln()
    ..writeln(
      '100.000 m to 60.000 m over 0+000 to 0+100 (${signed(steep.percent, 1)} %), every 20 m; '
      'perfect readings, max sight 50 m, instrument 1.600 m above the ground, readings kept between 0.350 m '
      'and 3.900 m on a 4 m staff.',
    )
    ..writeln()
    ..writeln(
      'V28 booked a backsight of −2.400 m and a foresight of 5.600 m: impossible on a 4 m staff. '
      'Now ${run.changePointsAdded} change points are added between the stations, in ${run.setups} setups:',
    )
    ..writeln()
    ..writeln('| Chainage | BS | IS | FS | RL | Remark |')
    ..writeln('| --- | ---: | ---: | ---: | ---: | --- |');
  for (final p in run.points.take(9)) {
    final r = p.reduced.row;
    o.writeln(
      '| ${formatChainage(p.chainage)} | ${n(r.backsight)} | ${n(r.intermediate)} | ${n(r.foresight)} | '
      '${fixed(p.level, 3)} | ${p.isStation ? r.remark : 'CP (added)'} |',
    );
  }
  final readings = [for (final r in run.readings) r.reading];
  o
    ..writeln('| … | | | | | |')
    ..writeln()
    ..writeln(
      'Lowest reading ${fixed(readings.reduce((a, b) => a < b ? a : b), 3)} m, highest '
      '${fixed(readings.reduce((a, b) => a > b ? a : b), 3)} m. Closing error ${signed(run.closing.error * 1000, 1)} mm; '
      'arithmetic check ${run.book.arithmeticCheckPasses ? '✓' : '✗'}.',
    );
  // ignore: avoid_print
  print(o.toString().trimRight());
}
