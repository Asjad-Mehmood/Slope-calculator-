// Steps 1 to 3: enter the centreline and the crossfall on each side, see the slope, its profile
// and the cross-section at the probe, and the levels at every chainage in one table (Chainage,
// Left RL, Centre RL, Right RL) with "Go to chainage". The inputs are remembered between sessions.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calc/calc.dart';
import '../state/calculation.dart';
import '../ui/profile_chart.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'crossfall_screen.dart' show CrossSection;

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.calculation});
  final Calculation calculation;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

const _intervals = [5.0, 10.0, 20.0, 25.0, 50.0, 100.0];

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final Map<String, TextEditingController> _boxes = {
    for (final f in [...Calculation.fields, ...Calculation.sideFields])
      f: TextEditingController(text: widget.calculation.text(f)),
  };
  final _focus = List.generate(5, (_) => FocusNode());
  final _goTo = TextEditingController();

  /// Where the probe stands; null puts it in the middle of the line
  double? _probe;

  /// The chainage found with "Go to chainage"
  double? _found;

  Calculation get calc => widget.calculation;

  @override
  void initState() {
    super.initState();
    calc.addListener(_syncBoxes);
  }

  /// A saved calculation was opened: show its values in the boxes
  void _syncBoxes() {
    for (final f in [...Calculation.fields, ...Calculation.sideFields]) {
      final box = _boxes[f]!;
      if (box.text != calc.text(f)) box.text = calc.text(f);
    }
  }

  @override
  void dispose() {
    calc.removeListener(_syncBoxes);
    for (final c in [..._boxes.values, _goTo]) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _fill(Map<String, String> values) {
    calc.load(values);
    for (final f in Calculation.fields) {
      _boxes[f]!.text = calc.text(f);
    }
    setState(() => _probe = _found = null);
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: calc,
      builder: (context, _) {
        final result = calc.result;
        final problem = calc.problem;
        final formation = calc.formationResult;
        return LayoutBuilder(
          builder: (context, box) {
            final pad = box.maxWidth < 720 ? 14.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResponsiveRow(
                        breakpoint: 960,
                        flex: const [5, 7],
                        children: [
                          _inputs(problem),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _results(result, problem),
                              if (result != null) ...[const SizedBox(height: 16), _profile(result, formation)],
                            ],
                          ),
                        ],
                      ),
                      if (result != null) ...[const SizedBox(height: 16), _levels(result, formation)],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _inputs(String? problem) {
    void next(int i) => i + 1 < _focus.length ? _focus[i + 1].requestFocus() : _focus[i].unfocus();
    Widget field(int i, String key, String badge, String label, {String? helper}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NumberField(
        controller: _boxes[key]!,
        focusNode: _focus[i],
        badge: badge,
        label: label,
        unit: 'm',
        helper: helper,
        onChanged: (v) {
          calc.setText(key, v);
          _probe = _found = null;
        },
        onSubmitted: (_) => next(i),
      ),
    );
    String chainageHelp(String key, String example) {
      final v = parseChainage(calc.text(key));
      return v == null ? 'Type $example or ${example.replaceAll('+', '')}' : 'Chainage ${formatChainage(v)}';
    }

    final selected = double.tryParse(calc.text('interval').trim());

    return SectionCard(
      step: 1,
      title: 'Enter your data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field(0, 'y1', 'Y1', 'Start level'),
          field(1, 'y2', 'Y2', 'End level'),
          field(2, 'x1', 'X1', 'Start chainage', helper: chainageHelp('x1', '1+000')),
          field(3, 'x2', 'X2', 'End chainage', helper: chainageHelp('x2', '1+250')),
          const SizedBox(height: 4),
          Text(
            'CHAINAGE INTERVAL',
            style: TextStyle(
              color: context.colors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 10),
          ChoiceRow<double>(
            values: _intervals,
            selected: _intervals.contains(selected) ? selected : null,
            label: (v) => '${v.toStringAsFixed(0)} m',
            semanticLabel: 'Chainage interval',
            onSelected: (v) {
              final text = v.toStringAsFixed(0);
              _boxes['interval']!.text = text;
              calc.setText('interval', text);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: NumberField(
                  controller: _boxes['interval']!,
                  focusNode: _focus[4],
                  label: 'Interval',
                  unit: 'm',
                  signed: false,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) => calc.setText('interval', v),
                  onSubmitted: (_) => next(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectField<int>(
                  label: 'Decimals',
                  value: calc.decimals,
                  values: const [1, 2, 3, 4, 5],
                  text: (d) => '$d',
                  onChanged: (d) => calc.decimals = d,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _sidesInputs(),
          if (problem != null) ...[const SizedBox(height: 14), Notice(problem, kind: NoticeKind.problem)],
          if (problem == null && calc.sidesProblem != null) ...[
            const SizedBox(height: 14),
            Notice(calc.sidesProblem!, kind: NoticeKind.problem),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _fill(Calculation.templateExample);
                  _toast('Example loaded: 1.900 m to 0.600 m over 379.290 m');
                },
                icon: const Icon(Icons.auto_fix_high_outlined, size: 19),
                label: const Text('Load example'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  calc.clear();
                  for (final f in [...Calculation.fields, ...Calculation.sideFields]) {
                    _boxes[f]!.text = calc.text(f);
                  }
                  _focus.first.requestFocus();
                },
                icon: const Icon(Icons.backspace_outlined, size: 19),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _results(SlopeResult? r, String? problem) {
    final c = context.colors;
    if (r == null) {
      return SectionCard(
        step: 2,
        title: 'Results',
        child: Notice(problem ?? 'Enter all four values to see the result.'),
      );
    }
    final dir = r.direction;
    final (String word, IconData icon) = switch (dir) {
      SlopeDirection.falling => ('Falling', Icons.south_east_rounded),
      SlopeDirection.rising => ('Rising', Icons.north_east_rounded),
      SlopeDirection.level => ('Level', Icons.east_rounded),
    };
    final tag = Tag(word, color: c.accent, textColor: c.onAccent, icon: icon);
    final changeColor = dir == SlopeDirection.falling ? c.fall : (dir == SlopeDirection.rising ? c.rise : null);
    final summary = r.summary.replaceAll(' %', ' %');

    return SectionCard(
      step: 2,
      title: 'Results',
      trailing: TextButton.icon(
        onPressed: () {
          Clipboard.setData(
            ClipboardData(
              text:
                  'Slope calculation\n'
                  'Y1 ${fixed(r.startLevel, 3)} m, Y2 ${fixed(r.endLevel, 3)} m, '
                  'X1 ${formatChainage(r.startChainage)}, X2 ${formatChainage(r.endChainage)}\n'
                  '${r.summary}',
            ),
          );
          _toast('Summary copied');
        },
        icon: const Icon(Icons.copy_rounded, size: 18),
        label: const Text('Copy'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final narrow = box.maxWidth < 560;
              final tiles = GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: narrow ? 1.9 : 2.1,
                children: [
                  ResultTile(
                    label: 'ΔH rise / fall',
                    value: '${signed(r.rise, r.decimals)} m',
                    valueColor: changeColor,
                  ),
                  ResultTile(label: 'Length ΔX', value: '${fixed(r.length, 3)} m'),
                  ResultTile(label: 'Slope per metre', value: signed(r.slopePerMetre, 5)),
                  ResultTile(label: 'Gradient', value: r.gradient == null ? 'Level' : '1 in ${fixed(r.gradient!, 1)}'),
                ],
              );
              final hero = HeroResult(
                label: 'Slope',
                value: '${signed(r.percent, 3)} %',
                tag: tag,
                footer: 'M = (Y2 − Y1) ÷ (X2 − X1)',
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [hero, const SizedBox(height: 12), tiles],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: hero),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: tiles),
                ],
              );
            },
          ),
          if (calc.mode != SidesMode.none) ...[const SizedBox(height: 12), _sideTiles(r)],
          const SizedBox(height: 14),
          Notice(summary),
        ],
      ),
    );
  }

  /// Start and end on the centreline, and each side's crossfall and offset. A side's crossfall is
  /// signed: − falls away from the centreline, + rises away
  Widget _sideTiles(SlopeResult r) {
    final sides = calc.sides;
    String pct(bool on, CrossfallSide s) => on
        ? '${s.direction == CrossfallDirection.fallAway && s.slopePercent != 0 ? '−' : (s.slopePercent == 0 ? '' : '+')}${fixed(s.slopePercent.abs(), 2)} %'
        : 'Off';
    String off(bool on, CrossfallSide s) => on ? '${fixed(s.distance, 3)} m' : 'Off';
    return LayoutBuilder(
      builder: (context, box) => GridView.count(
        crossAxisCount: box.maxWidth < 560 ? 2 : 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: box.maxWidth < 560 ? 1.9 : 2.1,
        children: [
          ResultTile(label: 'Start CL RL', value: '${fixed(r.startLevel, r.decimals)} m'),
          ResultTile(label: 'Left crossfall', value: pct(sides.mode.left, sides.left)),
          ResultTile(label: 'Left offset', value: off(sides.mode.left, sides.left)),
          ResultTile(label: 'End CL RL', value: '${fixed(r.endLevel, r.decimals)} m'),
          ResultTile(label: 'Right crossfall', value: pct(sides.mode.right, sides.right)),
          ResultTile(label: 'Right offset', value: off(sides.mode.right, sides.right)),
        ],
      ),
    );
  }

  /// Which sides, and each side's offset, crossfall and direction
  Widget _sidesInputs() {
    final c = context.colors;
    final mode = calc.mode;
    Text label(String t) => Text(
      t,
      style: TextStyle(color: c.muted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.9),
    );
    Widget side(
      String name,
      String offset,
      String percent,
      CrossfallDirection dir,
      ValueChanged<CrossfallDirection> set,
    ) => Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: c.cardSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label('${name.toUpperCase()} SIDE'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: NumberField(
                  controller: _boxes[offset]!,
                  label: '$name offset',
                  unit: 'm',
                  signed: false,
                  onChanged: (v) => calc.setText(offset, v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumberField(
                  controller: _boxes[percent]!,
                  label: '$name crossfall',
                  unit: '%',
                  signed: false,
                  onChanged: (v) => calc.setText(percent, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ChoiceRow<CrossfallDirection>(
            values: const [CrossfallDirection.fallAway, CrossfallDirection.riseAway],
            selected: dir,
            label: (d) => d == CrossfallDirection.fallAway ? 'Falls away ↓' : 'Rises away ↑',
            semanticLabel: '$name side direction',
            onSelected: set,
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label('CROSSFALL · LEFT AND RIGHT OF THE CENTRELINE'),
        const SizedBox(height: 10),
        ChoiceRow<SidesMode>(
          values: SidesMode.values,
          selected: mode,
          label: (m) => switch (m) {
            SidesMode.both => 'Both sides',
            SidesMode.leftOnly => 'Left only',
            SidesMode.rightOnly => 'Right only',
            SidesMode.none => 'Centreline',
          },
          semanticLabel: 'Sides',
          onSelected: (m) => calc.mode = m,
        ),
        if (mode.left) side('Left', 'lo', 'lc', calc.leftDirection, (d) => calc.leftDirection = d),
        if (mode.right) side('Right', 'ro', 'rc', calc.rightDirection, (d) => calc.rightDirection = d),
      ],
    );
  }

  Widget _profile(SlopeResult r, FormationResult? f) {
    final c = context.colors;
    final probe = (_probe ?? (r.startChainage + r.endChainage) / 2).clamp(r.startChainage, r.endChainage);
    return SectionCard(
      title: 'Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileChart(result: r, height: 214, probe: probe, onProbe: (ch) => setState(() => _probe = ch)),
          const SizedBox(height: 6),
          Slider(
            value: probe,
            min: r.startChainage,
            max: r.endChainage,
            activeColor: c.accent,
            label: formatChainage(probe),
            semanticFormatterCallback: (v) => 'Chainage ${formatChainage(v)}',
            onChanged: (v) => setState(() => _probe = v),
          ),
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.place_outlined, size: 18, color: c.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Probe at ${formatChainage(probe)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.muted, fontWeight: FontWeight.w600, fontFeatures: tabular),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // the level stays whole: smaller rather than cut, with large text on a phone
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${fixed(r.levelAt(probe), r.decimals)} m',
                          style: TextStyle(
                            color: c.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            fontFeatures: tabular,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (f != null && f.sides.mode != SidesMode.none) ...[
            const SizedBox(height: 18),
            Divider(height: 1, color: c.line),
            const SizedBox(height: 14),
            Text(
              'CROSS-SECTION AT ${formatChainage(probe)}',
              style: TextStyle(color: c.muted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.9),
            ),
            const SizedBox(height: 6),
            CrossSection(
              result: f.at(probe),
              left: f.sides.mode.left ? f.sides.left : const CrossfallSide(slopePercent: 0, distance: 0),
              right: f.sides.mode.right ? f.sides.right : const CrossfallSide(slopePercent: 0, distance: 0),
              height: 200,
            ),
          ],
        ],
      ),
    );
  }

  Widget _levels(SlopeResult r, FormationResult? f) {
    final d = r.decimals;
    final c = context.colors;
    final found = _found;
    int? focus;
    if (found != null) {
      var best = 0;
      for (var i = 1; i < r.stations.length; i++) {
        if ((r.stations[i].chainage - found).abs() < (r.stations[best].chainage - found).abs()) best = i;
      }
      focus = best;
    }

    void go(String text) {
      final ch = parseChainage(text);
      if (ch == null) {
        _toast('Type a chainage, like 1+125 or 1125');
        return;
      }
      if (!r.covers(ch)) {
        _toast(
          '${formatChainage(ch)} is outside the line (${formatChainage(r.startChainage)} to ${formatChainage(r.endChainage)})',
        );
        return;
      }
      setState(() => _found = _probe = ch);
    }

    return SectionCard(
      step: 3,
      title: 'Chainage levels',
      trailing: Text(
        '${r.stations.length} stations',
        style: TextStyle(color: c.muted, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 330,
                child: TextField(
                  controller: _goTo,
                  onSubmitted: go,
                  textInputAction: TextInputAction.search,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Go to chainage, e.g. 1+125',
                    hintMaxLines: 1,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Go',
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: () => go(_goTo.text),
                    ),
                  ),
                ),
              ),
              if (found != null)
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Level at '),
                      TextSpan(
                        text: formatChainage(found),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ': '),
                      TextSpan(
                        text: f == null || f.sides.mode == SidesMode.none
                            ? '${fixed(r.levelAt(found), d)} m'
                            : [
                                if (f.sides.mode.left) 'L ${fixed(f.at(found).leftLevel, d)}',
                                'CL ${fixed(f.at(found).centreLevel, d)}',
                                if (f.sides.mode.right) 'R ${fixed(f.at(found).rightLevel, d)}',
                              ].join('  ·  '),
                        style: TextStyle(fontWeight: FontWeight.w800, color: c.ink),
                      ),
                    ],
                  ),
                  style: TextStyle(color: c.muted, fontSize: 15, fontFeatures: tabular),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (f == null || f.sides.mode == SidesMode.none)
            DataGrid(
              columns: const ['Chainage', 'Distance (m)', 'Level (m)', 'Change (m)'],
              numeric: const {1, 2, 3},
              highlighted: {0, r.stations.length - 1},
              focusRow: focus,
              rows: [
                for (final s in r.stations)
                  [s.label, fixed(s.distanceFromStart, 3), fixed(s.level, d), signed(s.changeFromStart, d)],
              ],
            )
          else
            _formationGrid(f, focus),
        ],
      ),
    );
  }

  /// The one table of levels: Chainage | Left RL | Centre RL | Right RL, the centre in the middle
  Widget _formationGrid(FormationResult f, int? focus) {
    final d = f.slope.decimals;
    final left = f.sides.mode.left, right = f.sides.mode.right;
    return DataGrid(
      groups: ['', if (left) 'LEFT SIDE', 'CENTRELINE', if (right) 'RIGHT SIDE'],
      columns: ['Chainage', if (left) 'Left RL (m)', 'Centre RL (m)', if (right) 'Right RL (m)'],
      numeric: {for (var i = 1; i <= (left ? 1 : 0) + 1 + (right ? 1 : 0); i++) i},
      centred: {for (var i = 1; i <= (left ? 1 : 0) + 1 + (right ? 1 : 0); i++) i},
      accentColumn: left ? 2 : 1,
      highlighted: {0, f.rows.length - 1},
      focusRow: focus,
      minWidth: 520,
      rows: [
        for (final row in f.rows)
          [row.station.label, if (left) fixed(row.left!, d), fixed(row.centre, d), if (right) fixed(row.right!, d)],
      ],
    );
  }
}
