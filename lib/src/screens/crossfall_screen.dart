// Step 4: crossfall. The levels left and right of the centreline from the slope % across the
// road, with a cross-section drawing. The inputs are remembered.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../calc/calc.dart';
import '../state/store.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class CrossfallScreen extends StatefulWidget {
  const CrossfallScreen({super.key, required this.store});
  final Store store;

  @override
  State<CrossfallScreen> createState() => _CrossfallScreenState();
}

class _CrossfallScreenState extends State<CrossfallScreen> {
  static const _key = 'crossfall';
  // The Excel template's example
  static const _defaults = {'cl': '10.000', 'ls': '2', 'ld': '3.5', 'rs': '2.5', 'rd': '3.5'};

  late final Map<String, TextEditingController> _boxes;
  late CrossfallDirection _left, _right;

  @override
  void initState() {
    super.initState();
    final j = widget.store.readJson(_key) ?? const {};
    _boxes = {for (final e in _defaults.entries) e.key: TextEditingController(text: (j[e.key] as String?) ?? e.value)};
    _left = CrossfallDirection.values.asNameMap()[j['ldir']] ?? CrossfallDirection.fallAway;
    _right = CrossfallDirection.values.asNameMap()[j['rdir']] ?? CrossfallDirection.fallAway;
  }

  @override
  void dispose() {
    for (final c in _boxes.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    widget.store.writeJson(_key, {
      for (final e in _boxes.entries) e.key: e.value.text,
      'ldir': _left.name,
      'rdir': _right.name,
    });
    setState(() {});
  }

  double _n(String k) => double.tryParse(_boxes[k]!.text.trim()) ?? double.nan;

  @override
  Widget build(BuildContext context) {
    final centre = _n('cl');
    final left = CrossfallSide(slopePercent: _n('ls'), distance: _n('ld'), direction: _left);
    final right = CrossfallSide(slopePercent: _n('rs'), distance: _n('rd'), direction: _right);
    final problem = crossfallProblem(centre, left, right);
    final result = problem == null ? crossfall(centre, left: left, right: right) : null;

    return LayoutBuilder(
      builder: (context, box) {
        final pad = box.maxWidth < 720 ? 14.0 : 28.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: ResponsiveRow(
                breakpoint: 960,
                flex: const [5, 7],
                children: [
                  _inputs(problem),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _results(result, problem, left, right),
                      if (result != null) ...[
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Cross-section',
                          child: CrossSection(result: result, left: left, right: right),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _inputs(String? problem) {
    Widget field(String key, String badge, String label, String unit) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NumberField(controller: _boxes[key]!, badge: badge, label: label, unit: unit, onChanged: (_) => _save()),
    );
    Widget direction(CrossfallDirection value, ValueChanged<CrossfallDirection> set) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SegmentedButton<CrossfallDirection>(
        segments: const [
          ButtonSegment(
            value: CrossfallDirection.fallAway,
            icon: Icon(Icons.south_east_rounded),
            label: Text('Falls away'),
          ),
          ButtonSegment(
            value: CrossfallDirection.riseAway,
            icon: Icon(Icons.north_east_rounded),
            label: Text('Rises away'),
          ),
        ],
        selected: {value},
        onSelectionChanged: (v) {
          set(v.first);
          _save();
        },
      ),
    );
    Text heading(String s) => Text(
      s,
      style: TextStyle(color: context.colors.muted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.9),
    );

    return SectionCard(
      step: 4,
      title: 'Crossfall from the centreline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field('cl', 'CL', 'Centreline level', 'm'),
          const SizedBox(height: 4),
          heading('LEFT SIDE'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: field('ls', 'L%', 'Slope', '%')),
              const SizedBox(width: 12),
              Expanded(child: field('ld', 'L', 'Offset', 'm')),
            ],
          ),
          direction(_left, (v) => _left = v),
          heading('RIGHT SIDE'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: field('rs', 'R%', 'Slope', '%')),
              const SizedBox(width: 12),
              Expanded(child: field('rd', 'R', 'Offset', 'm')),
            ],
          ),
          direction(_right, (v) => _right = v),
          if (problem != null) Notice(problem, kind: NoticeKind.problem),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                for (final e in _defaults.entries) {
                  _boxes[e.key]!.text = e.value;
                }
                _left = _right = CrossfallDirection.fallAway;
                _save();
              },
              icon: const Icon(Icons.auto_fix_high_outlined, size: 19),
              label: const Text('Load example'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results(CrossfallResult? r, String? problem, CrossfallSide left, CrossfallSide right) {
    final c = context.colors;
    if (r == null) {
      return SectionCard(title: 'Results', child: Notice(problem ?? 'Enter the centreline level and both sides.'));
    }
    Color? tint(double d) => d < 0 ? c.fall : (d > 0 ? c.rise : null);
    return SectionCard(
      title: 'Results',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
            children: [
              ResultTile(label: 'Left level', value: '${fixed(r.leftLevel, 3)} m'),
              ResultTile(label: 'Right level', value: '${fixed(r.rightLevel, 3)} m'),
              ResultTile(
                label: 'Left difference',
                value: '${signed(r.leftDifference, 3)} m',
                valueColor: tint(r.leftDifference),
              ),
              ResultTile(
                label: 'Right difference',
                value: '${signed(r.rightDifference, 3)} m',
                valueColor: tint(r.rightDifference),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Notice(
            'Level = CL ${left.direction == CrossfallDirection.fallAway ? '−' : '+'} '
            '${fixed(left.distance, 3)} × ${fixed(left.slopePercent.abs(), 2)} ÷ 100 = ${fixed(r.leftLevel, 4)} m on the left; '
            'CL ${right.direction == CrossfallDirection.fallAway ? '−' : '+'} '
            '${fixed(right.distance, 3)} × ${fixed(right.slopePercent.abs(), 2)} ÷ 100 = ${fixed(r.rightLevel, 4)} m on the right.',
          ),
        ],
      ),
    );
  }
}

/// The road across: the centreline in the middle and each side at its slope (exaggerated so a
/// 2 % crossfall can be seen), with the levels written at the edges.
class CrossSection extends StatelessWidget {
  const CrossSection({super.key, required this.result, required this.left, required this.right, this.height = 220});
  final CrossfallResult result;
  final CrossfallSide left;
  final CrossfallSide right;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Cross-section: left edge ${fixed(result.leftLevel, 3)} m, centreline ${fixed(result.centreLevel, 3)} m, '
        'right edge ${fixed(result.rightLevel, 3)} m',
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _CrossSectionPainter(result, left, right, context.colors)),
    ),
  );
}

class _CrossSectionPainter extends CustomPainter {
  _CrossSectionPainter(this.r, this.left, this.right, this.c);
  final CrossfallResult r;
  final CrossfallSide left, right;
  final SlopeColors c;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 24.0, top = 34.0, bottom = 46.0;
    final cx = size.width / 2;
    final total = math.max(left.distance + right.distance, 0.001);
    final half = size.width / 2 - pad;
    final lx = cx - half * (left.distance / math.max(left.distance, right.distance).clamp(0.001, double.infinity));
    final rx = cx + half * (right.distance / math.max(left.distance, right.distance).clamp(0.001, double.infinity));
    // vertical exaggeration so the biggest difference uses about half the height
    final biggest = [r.leftDifference.abs(), r.rightDifference.abs(), total * 0.002].reduce(math.max);
    final h = size.height - top - bottom;
    final scale = h * 0.45 / biggest;
    final cy = top + h / 2 + (r.leftDifference + r.rightDifference) / 2 * scale * 0.5;
    double y(double diff) => cy - diff * scale;

    final surface = Path()
      ..moveTo(lx, y(r.leftDifference))
      ..lineTo(cx, cy)
      ..lineTo(rx, y(r.rightDifference));
    final body = Path.from(surface)
      ..lineTo(rx, size.height - bottom + 10)
      ..lineTo(lx, size.height - bottom + 10)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.muted.withValues(alpha: 0.30), c.muted.withValues(alpha: 0.06)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      surface,
      Paint()
        ..color = c.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    // centreline
    final dash = Paint()
      ..color = c.ink.withValues(alpha: 0.6)
      ..strokeWidth = 1.4;
    for (var yy = top - 18; yy < size.height - bottom + 10; yy += 9) {
      canvas.drawLine(Offset(cx, yy), Offset(cx, yy + 5), dash);
    }
    for (final p in [Offset(lx, y(r.leftDifference)), Offset(cx, cy), Offset(rx, y(r.rightDifference))]) {
      canvas.drawCircle(p, 6, Paint()..color = c.card);
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = c.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
    _text(canvas, 'CL ${fixed(r.centreLevel, 3)}', Offset(cx, top - 24), bold: true);
    _text(canvas, fixed(r.leftLevel, 3), Offset(lx + 20, y(r.leftDifference) - 22), bold: true, align: TextAlign.left);
    _text(
      canvas,
      fixed(r.rightLevel, 3),
      Offset(rx - 20, y(r.rightDifference) - 22),
      bold: true,
      align: TextAlign.right,
    );
    final base = size.height - bottom + 24;
    _text(
      canvas,
      '← ${fixed(left.distance, 2)} m · ${fixed(left.slopePercent.abs(), 2)} %',
      Offset((lx + cx) / 2, base),
    );
    _text(
      canvas,
      '${fixed(right.distance, 2)} m · ${fixed(right.slopePercent.abs(), 2)} % →',
      Offset((cx + rx) / 2, base),
    );
    _text(
      canvas,
      'Heights exaggerated',
      Offset(size.width - pad, size.height - 10),
      align: TextAlign.right,
      small: true,
    );
  }

  void _text(
    Canvas canvas,
    String s,
    Offset at, {
    bool bold = false,
    TextAlign align = TextAlign.center,
    bool small = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: textFont,
          fontSize: small ? 10.5 : 12.5,
          color: bold ? c.ink : c.muted,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          fontFeatures: tabular,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.left => at.dx,
      TextAlign.right => at.dx - tp.width,
      _ => at.dx - tp.width / 2,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_CrossSectionPainter old) =>
      old.r.leftLevel != r.leftLevel ||
      old.r.rightLevel != r.rightLevel ||
      old.r.centreLevel != r.centreLevel ||
      old.c != c;
}
