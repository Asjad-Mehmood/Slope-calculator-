// Steps 1 to 3: enter the line, see the slope, the profile and the level at every chainage.
// Phase 2 shows the design on the real calculations; phase 3 adds the probe, the project plate,
// remembered inputs and the rest.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calc/calc.dart';
import '../ui/profile_chart.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

const _intervals = [5.0, 10.0, 20.0, 25.0, 50.0, 100.0];

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _y1 = TextEditingController(text: '102.500');
  final _y2 = TextEditingController(text: '98.750');
  final _x1 = TextEditingController(text: '1+000');
  final _x2 = TextEditingController(text: '1+250');
  final _interval = TextEditingController(text: '20');
  final _focus = List.generate(5, (_) => FocusNode());
  int _decimals = 3;

  @override
  void dispose() {
    for (final c in [_y1, _y2, _x1, _x2, _interval]) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  double _level(TextEditingController c) => double.tryParse(c.text.trim()) ?? double.nan;
  double _chainage(TextEditingController c) => parseChainage(c.text) ?? double.nan;

  SlopeInput get _input => SlopeInput(
    startLevel: _level(_y1),
    endLevel: _level(_y2),
    startChainage: _chainage(_x1),
    endChainage: _chainage(_x2),
    interval: _level(_interval),
    decimals: _decimals,
  );

  void _loadExample() {
    setState(() {
      _y1.text = '1.900';
      _y2.text = '0.600';
      _x1.text = '0+000';
      _x2.text = '0+379.290';
      _interval.text = '20';
    });
  }

  @override
  Widget build(BuildContext context) {
    final input = _input;
    final problem = input.problem;
    final result = problem == null ? calculateSlope(input) : null;

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
                          if (result != null) ...[
                            const SizedBox(height: 16),
                            SectionCard(
                              title: 'Profile',
                              child: ProfileChart(result: result, height: 214),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (result != null) ...[const SizedBox(height: 16), _levels(result)],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _inputs(String? problem) {
    void next(int i) => i + 1 < _focus.length ? _focus[i + 1].requestFocus() : _focus[i].unfocus();
    Widget field(int i, TextEditingController c, String badge, String label, {String? helper}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NumberField(
        controller: c,
        focusNode: _focus[i],
        badge: badge,
        label: label,
        unit: 'm',
        helper: helper,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => next(i),
      ),
    );
    final x1 = parseChainage(_x1.text), x2 = parseChainage(_x2.text);
    final selected = double.tryParse(_interval.text.trim());

    return SectionCard(
      step: 1,
      title: 'Enter your data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field(0, _y1, 'Y1', 'Start level'),
          field(1, _y2, 'Y2', 'End level'),
          field(
            2,
            _x1,
            'X1',
            'Start chainage',
            helper: x1 == null ? 'Type 1+000 or 1000' : 'Chainage ${formatChainage(x1)}',
          ),
          field(
            3,
            _x2,
            'X2',
            'End chainage',
            helper: x2 == null ? 'Type 1+250 or 1250' : 'Chainage ${formatChainage(x2)}',
          ),
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
            onSelected: (v) => setState(() => _interval.text = v.toStringAsFixed(0)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: NumberField(
                  controller: _interval,
                  focusNode: _focus[4],
                  label: 'Interval',
                  unit: 'm',
                  signed: false,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectField<int>(
                  label: 'Decimals',
                  value: _decimals,
                  values: const [1, 2, 3, 4, 5],
                  text: (d) => '$d',
                  onChanged: (d) => setState(() => _decimals = d),
                ),
              ),
            ],
          ),
          if (problem != null) ...[const SizedBox(height: 14), Notice(problem, kind: NoticeKind.problem)],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _loadExample,
                icon: const Icon(Icons.auto_fix_high_outlined, size: 19),
                label: const Text('Load example'),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  for (final c in [_y1, _y2, _x1, _x2]) {
                    c.clear();
                  }
                  _focus.first.requestFocus();
                }),
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
    final tag = switch (dir) {
      SlopeDirection.falling => const Tag(
        'Falling',
        color: Color(0xFFE2AE34),
        textColor: Color(0xFF1B1405),
        icon: Icons.south_east_rounded,
      ),
      SlopeDirection.rising => const Tag(
        'Rising',
        color: Color(0xFFE2AE34),
        textColor: Color(0xFF1B1405),
        icon: Icons.north_east_rounded,
      ),
      SlopeDirection.level => const Tag(
        'Level',
        color: Color(0xFFE2AE34),
        textColor: Color(0xFF1B1405),
        icon: Icons.east_rounded,
      ),
    };
    final changeColor = dir == SlopeDirection.falling ? c.fall : (dir == SlopeDirection.rising ? c.rise : null);

    return SectionCard(
      step: 2,
      title: 'Results',
      trailing: TextButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: r.summary));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary copied')));
        },
        icon: const Icon(Icons.copy_rounded, size: 18),
        label: const Text('Copy'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final tiles = GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: box.maxWidth < 560 ? 1.9 : 2.1,
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
              if (box.maxWidth < 560) {
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
          const SizedBox(height: 14),
          Notice(r.summary.replaceAll(' %', '\u00A0%'), kind: NoticeKind.info),
        ],
      ),
    );
  }

  Widget _levels(SlopeResult r) {
    final d = r.decimals;
    return SectionCard(
      step: 3,
      title: 'Chainage levels',
      trailing: Text(
        '${r.stations.length} stations',
        style: TextStyle(color: context.colors.muted, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      child: DataGrid(
        columns: const ['Chainage', 'Distance (m)', 'Level (m)', 'Change (m)'],
        numeric: const {1, 2, 3},
        highlighted: {0, r.stations.length - 1},
        rows: [
          for (final s in r.stations)
            [s.label, fixed(s.distanceFromStart, 3), fixed(s.level, d), signed(s.changeFromStart, d)],
        ],
      ),
    );
  }
}
