// The long section: the slope line over its chainage, with its stations.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../calc/calc.dart';
import 'theme.dart';

/// The profile. With [onProbe], pressing or dragging on it moves the probe to that chainage.
class ProfileChart extends StatelessWidget {
  const ProfileChart({super.key, required this.result, this.height = 240, this.probe, this.onProbe});
  final SlopeResult result;
  final double height;

  /// The chainage the probe stands on, drawn as a line with its level
  final double? probe;
  final ValueChanged<double>? onProbe;

  static const _left = 64.0, _right = 18.0;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Semantics(
      label:
          'Profile from ${formatChainage(r.startChainage)} at ${fixed(r.startLevel, 3)} m '
          'to ${formatChainage(r.endChainage)} at ${fixed(r.endLevel, 3)} m',
      child: LayoutBuilder(
        builder: (context, box) {
          void at(Offset p) {
            final w = box.maxWidth - _left - _right;
            final t = ((p.dx - _left) / w).clamp(0.0, 1.0);
            onProbe?.call(r.startChainage + t * r.length);
          }

          return GestureDetector(
            onTapDown: onProbe == null ? null : (d) => at(d.localPosition),
            onHorizontalDragUpdate: onProbe == null ? null : (d) => at(d.localPosition),
            child: MouseRegion(
              cursor: onProbe == null ? MouseCursor.defer : SystemMouseCursors.precise,
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: CustomPaint(painter: _ProfilePainter(r, context.colors, probe)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter(this.r, this.c, this.probe);
  final SlopeResult r;
  final SlopeColors c;
  final double? probe;

  @override
  void paint(Canvas canvas, Size size) {
    const left = ProfileChart._left, right = ProfileChart._right, top = 18.0, bottom = 34.0;
    final w = size.width - left - right, h = size.height - top - bottom;
    final lo = math.min(r.startLevel, r.endLevel), hi = math.max(r.startLevel, r.endLevel);
    // the level axis on round numbers: steps of 1, 2, 2.5 or 5 × 10ⁿ
    final step = _niceStep(math.max(hi - lo, 0.5) / 3);
    final yMin = (lo / step).floor() * step - (lo % step == 0 ? step : 0);
    final yMax = (hi / step).ceil() * step + (hi % step == 0 ? step : 0);
    final ticks = ((yMax - yMin) / step).round();
    final tickDecimals = step >= 1 ? 0 : (step >= 0.1 ? (step * 10 % 1 == 0 ? 1 : 2) : 3);
    double x(double ch) => left + (ch - r.startChainage) / r.length * w;
    double y(double lv) => top + (yMax - lv) / (yMax - yMin) * h;

    final grid = Paint()
      ..color = c.line
      ..strokeWidth = 1;
    // level grid with labels
    for (var i = 0; i <= ticks; i++) {
      final lv = yMin + step * i;
      final gy = y(lv);
      canvas.drawLine(Offset(left, gy), Offset(left + w, gy), grid);
      _label(canvas, fixed(lv, tickDecimals), Offset(left - 8, gy), align: TextAlign.right);
    }

    final a = Offset(x(r.startChainage), y(r.startLevel)), b = Offset(x(r.endChainage), y(r.endLevel));
    final fill = Path()
      ..moveTo(a.dx, top + h)
      ..lineTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(b.dx, top + h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.accent.withValues(alpha: 0.32), c.accent.withValues(alpha: 0.04)],
        ).createShader(Rect.fromLTWH(left, top, w, h)),
    );
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = c.accent
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // stations, and chainage labels that don't crowd each other
    final every = math.max(1, (r.stations.length / (w / 90)).ceil());
    for (var i = 0; i < r.stations.length; i++) {
      final s = r.stations[i];
      final p = Offset(x(s.chainage), y(s.level));
      final end = i == 0 || i == r.stations.length - 1;
      canvas.drawCircle(p, end ? 6 : 3.5, Paint()..color = c.card);
      canvas.drawCircle(
        p,
        end ? 6 : 3.5,
        Paint()
          ..color = end ? c.ink : c.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      final lastRoom = i == r.stations.length - 1 || r.stations.length - 1 - i >= every;
      if ((i % every == 0 && lastRoom) || i == r.stations.length - 1) {
        _label(canvas, s.label, Offset(p.dx, top + h + 16), align: TextAlign.center);
      }
    }
    _probe(canvas, x, y, top, h);
  }

  void _probe(Canvas canvas, double Function(double) x, double Function(double) y, double top, double h) {
    final ch = probe;
    if (ch == null || !r.covers(ch)) return;
    final px = x(ch), lv = r.levelAt(ch), py = y(lv);
    canvas.drawLine(
      Offset(px, top),
      Offset(px, top + h),
      Paint()
        ..color = c.ink.withValues(alpha: 0.55)
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(py.isFinite ? Offset(px, py) : Offset(px, top), 7, Paint()..color = c.ink);
    canvas.drawCircle(Offset(px, py), 3.5, Paint()..color = c.accent);
  }

  static double _niceStep(double raw) {
    final p = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (m * p >= raw) return m * p;
    }
    return 10 * p;
  }

  void _label(Canvas canvas, String s, Offset at, {TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: textFont,
          fontSize: 11,
          color: c.muted,
          fontWeight: FontWeight.w600,
          fontFeatures: tabular,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_ProfilePainter old) => old.r != r || old.c != c || old.probe != probe;
}
