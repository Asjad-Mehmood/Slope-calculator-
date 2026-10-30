// Step 5: the digital level simulator. A level run along the slope line from the calculator:
// setups, readings to 0.1 mm on the display, the level book filling in reading by reading (Height
// of Instrument or Rise & Fall) and the checks at the end. Training and checking only: it doesn't
// connect to or copy any instrument.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../calc/calc.dart';
import '../state/calculation.dart';
import '../state/store.dart';
import '../ui/settings.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class DigitalLevelScreen extends StatefulWidget {
  const DigitalLevelScreen({super.key, required this.calculation, required this.settings, required this.store});
  final Calculation calculation;
  final AppSettings settings;
  final Store store;

  @override
  State<DigitalLevelScreen> createState() => _DigitalLevelScreenState();
}

enum _Speed {
  slow('Slow', 1600),
  normal('Normal', 1000),
  fast('Fast', 400);

  const _Speed(this.label, this.ms);
  final String label;
  final int ms;
}

class _DigitalLevelScreenState extends State<DigitalLevelScreen> with SingleTickerProviderStateMixin {
  static const _key = 'levelRun';

  late double _maxSight, _noise, _collimation;
  late BookingMethod _method;
  late _Speed _speed;
  int _seed = 7;

  /// How many readings have been taken
  int _taken = 0;
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    final j = widget.store.readJson(_key) ?? const {};
    _maxSight = ((j['maxSight'] as num?)?.toDouble() ?? 50).clamp(10, 100);
    _noise = ((j['noise'] as num?)?.toDouble() ?? 0.3).clamp(0, 5);
    _collimation = ((j['collimation'] as num?)?.toDouble() ?? 0).clamp(-20, 20);
    _method = BookingMethod.values.asNameMap()[j['method']] ?? BookingMethod.heightOfInstrument;
    _speed = _Speed.values.asNameMap()[j['speed']] ?? _Speed.normal;
    widget.calculation.addListener(_reset);
    widget.settings.addListener(_reset);
  }

  @override
  void dispose() {
    widget.calculation.removeListener(_reset);
    widget.settings.removeListener(_reset);
    _ticker.dispose();
    super.dispose();
  }

  void _saveOptions() => widget.store.writeJson(_key, {
    'maxSight': _maxSight,
    'noise': _noise,
    'collimation': _collimation,
    'method': _method.name,
    'speed': _speed.name,
  });

  LevelRunOptions get _options => LevelRunOptions(
    maxSight: _maxSight,
    noiseMm: _noise,
    collimationMmPer100m: _collimation,
    seed: _seed,
    allowableC: widget.settings.allowableC,
  );

  void _reset() {
    if (!mounted) return;
    _ticker.stop();
    setState(() => _taken = 0);
  }

  void _tick(Duration elapsed) {
    if (elapsed - _last < Duration(milliseconds: _speed.ms)) return;
    _last = elapsed;
    _step();
  }

  void _step() {
    final run = _run().$1;
    if (run == null) return;
    setState(() => _taken = math.min(_taken + 1, run.readings.length));
    if (_taken >= run.readings.length) _ticker.stop();
  }

  void _play() {
    final run = _run().$1;
    if (run == null) return;
    if (_ticker.isActive) {
      _ticker.stop();
      setState(() {});
      return;
    }
    if (_taken >= run.readings.length) _taken = 0;
    _last = Duration.zero;
    _step();
    _ticker.start();
  }

  (LevelRun?, String?) _run() {
    final slope = widget.calculation.result;
    if (slope == null) {
      return (null, 'The line on the Calculator has a problem: ${widget.calculation.problem}');
    }
    final problem = levelRunProblem(slope, _options);
    if (problem != null) return (null, problem);
    return (simulateLevelRun(slope, options: _options), null);
  }

  @override
  Widget build(BuildContext context) {
    final (run, problem) = _run();
    return LayoutBuilder(
      builder: (context, box) {
        final pad = box.maxWidth < 720 ? 14.0 : 28.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: run == null
                  ? SectionCard(
                      step: 5,
                      title: 'Digital level',
                      child: Notice(problem!, kind: NoticeKind.problem),
                    )
                  : _body(run, box.maxWidth),
            ),
          ),
        );
      },
    );
  }

  Widget _body(LevelRun run, double width) {
    final c = context.colors;
    final current = _taken == 0 ? null : run.readings[_taken - 1];
    final done = _taken >= run.readings.length;
    final playing = _ticker.isActive;

    final scene = SectionCard(
      step: 5,
      title: 'Digital level run',
      trailing: Text(
        '${run.setups} setups · ${run.readings.length} readings',
        style: TextStyle(color: c.muted, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'A digital level and barcode staff run along your slope from ${formatChainage(run.slope.startChainage)} '
            '(benchmark ${fixed(run.slope.startLevel, 3)} m) to ${formatChainage(run.slope.endChainage)}.',
            style: TextStyle(color: c.muted, height: 1.45),
          ),
          const SizedBox(height: 14),
          ResponsiveRow(
            breakpoint: 760,
            flex: const [8, 4],
            children: [
              LevelRunScene(run: run, current: current),
              _Display(run: run, current: current, taken: _taken, rows: _bookUpTo(run)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _play,
                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(
                  playing
                      ? 'Pause'
                      : done
                      ? 'Run again'
                      : (_taken == 0 ? 'Start the run' : 'Carry on'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: done
                    ? null
                    : () {
                        _ticker.stop();
                        _step();
                      },
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Step'),
              ),
              OutlinedButton.icon(
                onPressed: _taken == 0 ? null : _reset,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Reset'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _seed = nextSeed(_seed);
                  _reset();
                },
                icon: const Icon(Icons.casino_outlined),
                label: const Text('New run'),
              ),
            ],
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        scene,
        const SizedBox(height: 16),
        _optionsCard(run),
        const SizedBox(height: 16),
        _book(run, width),
        if (done) ...[const SizedBox(height: 16), _checks(run)],
      ],
    );
  }

  Widget _optionsCard(LevelRun run) {
    Widget pick<T>(String label, T value, List<T> values, String Function(T) text, ValueChanged<T> set) => SizedBox(
      width: 170,
      child: SelectField<T>(
        label: label,
        value: value,
        values: values,
        text: text,
        onChanged: (v) {
          set(v);
          _saveOptions();
          _reset();
        },
      ),
    );
    return SectionCard(
      title: 'Options',
      optional: true,
      initiallyOpen: false,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          pick<double>(
            'Max sight (m)',
            _maxSight,
            const [10, 20, 30, 40, 50, 60, 80, 100],
            (v) => '${v.round()}',
            (v) => _maxSight = v,
          ),
          pick<double>(
            'Reading noise (mm)',
            _noise,
            const [0, 0.1, 0.3, 0.5, 1, 2],
            (v) => fixed(v, 1),
            (v) => _noise = v,
          ),
          pick<double>(
            'Collimation (mm/100 m)',
            _collimation,
            const [-10, -5, -2, 0, 2, 5, 10],
            (v) => v == 0 ? '0' : signed(v, 0),
            (v) => _collimation = v,
          ),
          pick<_Speed>('Speed', _speed, _Speed.values, (v) => v.label, (v) => _speed = v),
          SegmentedButton<BookingMethod>(
            segments: const [
              ButtonSegment(value: BookingMethod.heightOfInstrument, label: Text('Height of Instrument')),
              ButtonSegment(value: BookingMethod.riseAndFall, label: Text('Rise & Fall')),
            ],
            selected: {_method},
            onSelectionChanged: (v) {
              setState(() => _method = v.first);
              _saveOptions();
            },
          ),
        ],
      ),
    );
  }

  /// The book as far as the readings taken, and whether the last line's backsight is still to come
  ({int rows, bool backsightPending}) _bookUpTo(LevelRun run) {
    var rows = 0;
    var pending = false;
    for (final r in run.readings.take(_taken)) {
      switch (r.kind) {
        case SightKind.backsight:
          if (r.setup == 1) rows = 1;
          pending = false;
        case SightKind.intermediate:
          rows++;
        case SightKind.foresight:
          rows++;
          pending = run.book.rows[rows - 1].row.backsight != null;
      }
    }
    return (rows: rows, backsightPending: pending);
  }

  Widget _book(LevelRun run, double width) {
    final c = context.colors;
    final shown = _bookUpTo(run);
    final reduced = _method == BookingMethod.heightOfInstrument
        ? run.book
        : reduceBook(
            [for (final p in run.points) p.reduced.row],
            openingLevel: run.slope.startLevel,
            method: BookingMethod.riseAndFall,
          );
    String n(double? v) => v == null ? '' : fixed(v, 4);
    final hi = _method == BookingMethod.heightOfInstrument;
    final columns = [
      'Chainage',
      'BS',
      'IS',
      'FS',
      if (hi) 'HI' else ...['Rise', 'Fall'],
      'RL',
      'Design RL',
      'Diff (mm)',
      'Remark',
    ];
    final rows = <List<String>>[];
    for (var i = 0; i < shown.rows; i++) {
      final p = run.points[i];
      final r = reduced.rows[i];
      final hideBs = shown.backsightPending && i == shown.rows - 1;
      rows.add([
        formatChainage(p.chainage),
        hideBs ? '' : n(r.row.backsight),
        n(r.row.intermediate),
        n(r.row.foresight),
        if (hi) hideBs ? '' : n(r.heightOfInstrument) else ...[n(r.rise), n(r.fall)],
        fixed(r.level, 4),
        fixed(p.designLevel, 4),
        signed((r.level - p.designLevel) * 1000, 1),
        p.isStation ? r.row.remark : 'CP added',
      ]);
    }
    final grid = DataGrid(
      columns: columns,
      numeric: {for (var i = 1; i < columns.length - 1; i++) i},
      highlighted: {if (rows.isNotEmpty) rows.length - 1},
      focusRow: rows.isEmpty ? null : rows.length - 1,
      maxHeight: 380,
      rows: rows,
    );
    return SectionCard(
      title: 'Level book',
      trailing: Text(
        hi ? 'Height of Instrument' : 'Rise & Fall',
        style: TextStyle(color: c.muted, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      child: rows.isEmpty
          ? const Notice('Press Start the run or Step. Each reading is booked here as it is taken.')
          : (width < 900
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: 900, child: grid),
                  )
                : grid),
    );
  }

  Widget _checks(LevelRun run) {
    final c = context.colors;
    final b = _method == BookingMethod.heightOfInstrument
        ? run.book
        : reduceBook(
            [for (final p in run.points) p.reduced.row],
            openingLevel: run.slope.startLevel,
            method: BookingMethod.riseAndFall,
          );
    final m = run.closing;
    Widget check(bool ok, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label: ok ? 'Passed' : 'Failed',
        child: Notice(text, kind: ok ? NoticeKind.success : NoticeKind.problem),
      ),
    );
    return SectionCard(
      title: 'Checks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (label, value) in [
                ('Setups', '${run.setups}'),
                ('Readings', '${run.readings.length}'),
                ('ΣBS', fixed(b.sumBacksights, 4)),
                ('ΣFS', fixed(b.sumForesights, 4)),
                ('Closing error', '${signed(m.error * 1000, 1)} mm'),
                ('Allowable', '${fixed(m.allowable * 1000, 1)} mm'),
              ])
                SizedBox(
                  width: 170,
                  child: ResultTile(label: label, value: value),
                ),
            ],
          ),
          const SizedBox(height: 14),
          check(
            b.arithmeticCheckPasses,
            'ΣBS − ΣFS = ${signed(b.sumBacksights - b.sumForesights, 4)} and last RL − first RL = '
            '${signed(b.lastLevel - b.firstLevel, 4)}',
          ),
          if (_method == BookingMethod.riseAndFall)
            check(b.riseFallCheckPasses, 'ΣRise − ΣFall = ${signed(b.sumRises - b.sumFalls, 4)}')
          else
            check(b.heightOfInstrumentCheckPasses, 'ΣIS + ΣFS + Σ(RL except the first) = Σ(HI × readings from it)'),
          check(
            m.withinTolerance,
            'Closing error ${signed(m.error * 1000, 1)} mm against the design end level ${fixed(m.closingLevel, 3)} m: '
            '${m.withinTolerance ? 'within' : 'outside'} ${fixed(widget.settings.allowableC, 0)}√K = '
            '${fixed(m.allowable * 1000, 1)} mm (K = ${fixed(m.lengthKm, 3)} km)',
          ),
          if (run.changePointsAdded > 0)
            Notice(
              '${run.changePointsAdded} change points were added between stations so every reading stays on the 4 m staff.',
            ),
          const SizedBox(height: 8),
          Text(
            'A training and checking simulator. It does not connect to or copy any instrument.',
            style: TextStyle(color: c.muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

/// The instrument's display: the reading to 0.1 mm, the distance, HI and RL.
class _Display extends StatelessWidget {
  const _Display({required this.run, required this.current, required this.taken, required this.rows});
  final LevelRun run;
  final SimulatedReading? current;
  final int taken;
  final ({int rows, bool backsightPending}) rows;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF8DFFBF), dim = Color(0xFF63B58A);
    const mono = TextStyle(fontFamily: readingFont, color: green, fontFeatures: tabular);
    final r = current;
    final kind = switch (r?.kind) {
      SightKind.backsight => 'BS',
      SightKind.intermediate => 'IS',
      SightKind.foresight => 'FS',
      null => '',
    };
    final rl = rows.rows == 0 ? null : run.book.rows[rows.rows - 1].level;
    return Semantics(
      liveRegion: true,
      label: r == null ? 'Display: ready' : 'Display: $kind ${fixed(r.reading, 4)} metres',
      child: Container(
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(minHeight: 230),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF233A2C), width: 3),
        ),
        child: ExcludeSemantics(
          child: r == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DIGITAL LEVEL', style: mono.copyWith(color: dim, fontSize: 12, letterSpacing: 1.5)),
                    const SizedBox(height: 18),
                    Text('READY', style: mono.copyWith(fontSize: 34, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(
                      'Press Start or Step.\nBarcode staff · 0.1 mm',
                      style: mono.copyWith(color: dim, fontSize: 13, height: 1.5),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SETUP ${r.setup}/${run.setups}  $kind',
                      style: mono.copyWith(color: dim, fontSize: 12.5, letterSpacing: 1.2),
                    ),
                    Text(
                      'CH ${formatChainage(r.chainage)}',
                      style: mono.copyWith(color: dim, fontSize: 12.5, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${fixed(r.reading, 4)} m',
                        style: mono.copyWith(fontSize: 36, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('Staff reading', style: mono.copyWith(color: dim, fontSize: 12)),
                    const SizedBox(height: 10),
                    Text('Dist  ${fixed(r.sightDistance, 2)} m', style: mono.copyWith(fontSize: 14)),
                    if (rl != null) Text('RL    ${fixed(rl, 4)} m', style: mono.copyWith(fontSize: 14)),
                    if (r.sightDistance > run.options.sightLimit + 0.01)
                      Text('Distance above max sight', style: mono.copyWith(color: const Color(0xFFFFC46B))),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Side view: the ground along the slope, the level on its tripod and the staff, with the line of
/// sight while a reading is taken. Heights are drawn larger than lengths so the staff shows.
class LevelRunScene extends StatelessWidget {
  const LevelRunScene({super.key, required this.run, required this.current, this.height = 250});
  final LevelRun run;
  final SimulatedReading? current;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Side view of the level run',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _ScenePainter(run, current, context.colors)),
      ),
    ),
  );
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.run, this.current, this.c);
  final LevelRun run;
  final SimulatedReading? current;
  final SlopeColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final s = run.slope;
    final dark = c.card.computeLuminance() < 0.2;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark ? const [Color(0xFF13284A), Color(0xFF1B355E)] : const [Color(0xFFE6F0FB), Color(0xFFF5F8FD)],
        ).createShader(Offset.zero & size),
    );
    const left = 30.0, right = 30.0, base = 26.0;
    final w = size.width - left - right;
    final lo = math.min(s.startLevel, s.endLevel), hiL = math.max(s.startLevel, s.endLevel);
    final ps = math.min(30.0, (size.height - base - 30) / (hiL - lo + 4.4)); // px per metre of height
    double x(double ch) => left + (ch - s.startChainage) / s.length * w;
    double y(double lv) => size.height - base - (lv - lo) * ps;

    final ground = Path()..moveTo(x(s.startChainage), size.height);
    for (final st in s.stations) {
      ground.lineTo(x(st.chainage), y(st.level));
    }
    ground
      ..lineTo(x(s.endChainage), size.height)
      ..close();
    canvas.drawPath(ground, Paint()..color = dark ? const Color(0xFF3E6B3A) : const Color(0xFF9FCB86));
    canvas.drawLine(
      Offset(x(s.startChainage), y(s.startLevel)),
      Offset(x(s.endChainage), y(s.endLevel)),
      Paint()
        ..color = dark ? const Color(0xFF7FB06A) : const Color(0xFF4D7A3B)
        ..strokeWidth = 2.5,
    );
    for (final p in run.points) {
      canvas.drawCircle(
        Offset(x(p.chainage), y(p.designLevel)),
        p.isStation ? 3.2 : 2.2,
        Paint()..color = p.isStation ? Colors.white : c.accent,
      );
    }

    final r = current;
    if (r == null) return;
    // the level on its tripod
    final ix = x(r.instrumentChainage), ig = y(s.levelAt(r.instrumentChainage));
    final iy = y(r.heightOfInstrument);
    final legs = Paint()
      ..color = const Color(0xFFC9A227)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final dx in [-12.0, 0.0, 12.0]) {
      canvas.drawLine(Offset(ix, iy + 8), Offset(ix + dx, ig), legs);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(ix, iy), width: 30, height: 16), const Radius.circular(4)),
      Paint()..color = const Color(0xFF33415C),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(ix - 4, iy), width: 10, height: 6),
      Paint()..color = const Color(0xFF8DFFBF),
    );

    // the staff: 4 m, barcode
    final sx = x(r.chainage), sg = y(s.levelAt(r.chainage)), stTop = sg - 4 * ps;
    canvas.drawRect(Rect.fromLTRB(sx - 5, stTop, sx + 5, sg), Paint()..color = const Color(0xFFF2F2EE));
    final bars = Paint()..color = const Color(0xFF14182A);
    // a fixed barcode-like pattern (decoration only)
    for (var i = 0; i < 40; i++) {
      if ((i * 7 + i ~/ 3) % 3 == 0) {
        canvas.drawRect(Rect.fromLTRB(sx - 5, stTop + i * 0.1 * ps, sx + 5, stTop + (i + 1) * 0.1 * ps), bars);
      }
    }
    canvas.drawRect(
      Rect.fromLTRB(sx - 5, stTop, sx + 5, sg),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF5A6684),
    );
    // the line of sight to the reading
    final toward = sx >= ix ? 1.0 : -1.0;
    canvas.drawLine(
      Offset(ix + 15 * toward, iy),
      Offset(sx - 6 * toward, iy),
      Paint()
        ..color = const Color(0xFFE53935)
        ..strokeWidth = 2,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: fixed(r.reading, 4),
        style: TextStyle(fontFamily: readingFont, fontSize: 12, fontWeight: FontWeight.w700, color: c.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(sx + (toward > 0 ? -tp.width - 10 : 10), iy - tp.height - 4));
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.run != run || old.current != current || old.c != c;
}
