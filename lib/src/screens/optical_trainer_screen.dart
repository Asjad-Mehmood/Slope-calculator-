// Step 6: the optical level trainer. The view through the telescope onto an E-pattern staff, with
// the cross hairs. Watch the reading, or practise: read the staff, type the reading and see how
// close it was. A drawing for training: an optical level has no beam and isn't connected to
// anything.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../calc/calc.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class OpticalTrainerScreen extends StatefulWidget {
  const OpticalTrainerScreen({super.key});

  @override
  State<OpticalTrainerScreen> createState() => _OpticalTrainerScreenState();
}

enum _Mode { watch, practise }

class _OpticalTrainerScreenState extends State<OpticalTrainerScreen> with SingleTickerProviderStateMixin {
  _Mode _mode = _Mode.watch;
  double _reading = 1.450;
  final _random = math.Random();
  final _answer = TextEditingController();
  String? _feedback;
  bool? _right;
  int _tries = 0, _good = 0;

  /// Moves the staff gently while watching; it runs only while this screen is shown
  late final AnimationController _drift = AnimationController(vsync: this, duration: const Duration(seconds: 9))
    ..addListener(() {
      if (_mode == _Mode.watch) setState(() => _reading = 1.45 + 0.18 * math.sin(_drift.value * 2 * math.pi));
    });

  @override
  void initState() {
    super.initState();
    _drift.repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    _answer.dispose();
    super.dispose();
  }

  void _newStaff() {
    setState(() {
      _reading = (400 + _random.nextInt(3200)) / 1000;
      _answer.clear();
      _feedback = null;
      _right = null;
    });
  }

  void _check() {
    final typed = double.tryParse(_answer.text.trim().replaceAll(',', '.'));
    if (typed == null) {
      setState(() {
        _feedback = 'Type the reading in metres, like 1.465.';
        _right = false;
      });
      return;
    }
    final off = (typed - _reading) * 1000;
    final good = off.abs() <= 2;
    setState(() {
      _tries++;
      if (good) _good++;
      _right = good;
      _feedback = good
          ? 'Right: ${fixed(_reading, 3)} m (you were ${off.abs() < 0.5 ? 'exact' : '${fixed(off.abs(), 0)} mm off'}).'
          : 'Not quite: the reading is ${fixed(_reading, 3)} m, you were ${signed(off, 0)} mm out. '
                'Find the E below the hair and its number, then count the 1 cm bars and gaps up to the hair.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final practising = _mode == _Mode.practise;
    if (practising && _drift.isAnimating) _drift.stop();
    if (!practising && !_drift.isAnimating && TickerMode.valuesOf(context).enabled) _drift.repeat();

    return LayoutBuilder(
      builder: (context, box) {
        final pad = box.maxWidth < 720 ? 14.0 : 28.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: SectionCard(
                step: 6,
                title: 'Optical level trainer',
                trailing: SegmentedButton<_Mode>(
                  segments: const [
                    ButtonSegment(value: _Mode.watch, icon: Icon(Icons.visibility_outlined), label: Text('Watch')),
                    ButtonSegment(value: _Mode.practise, icon: Icon(Icons.school_outlined), label: Text('Practise')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (v) {
                    setState(() => _mode = v.first);
                    if (v.first == _Mode.practise) _newStaff();
                  },
                ),
                child: ResponsiveRow(
                  breakpoint: 820,
                  flex: const [5, 6],
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Semantics(
                            label: practising
                                ? 'View through the telescope onto the staff. Read it and type the reading.'
                                : 'View through the telescope. The horizontal hair reads ${fixed(_reading, 3)} metres.',
                            child: CustomPaint(painter: _TelescopePainter(_reading, c)),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: practising ? _practice(c) : _watch(c),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _watch(SlopeColors c) => [
    ResultTile(label: 'Staff reading at the horizontal hair', value: '${fixed(_reading, 3)} m'),
    const SizedBox(height: 14),
    const Notice(
      'How to read an E-pattern staff: each E is 5 cm tall and stands on its decimetre; the number '
      'beside it is that decimetre (dots above it count the metres, so 6 with one dot is 1.6 m). '
      'The three bars and two gaps of an E are 1 cm each. Count centimetres up from the bottom of '
      'the E to the horizontal hair, then estimate the millimetres.',
    ),
    const SizedBox(height: 12),
    Text(
      'A training drawing. An automatic optical level has no beam; the red line only shows where the '
      'horizontal hair falls.',
      style: TextStyle(color: c.muted, fontSize: 12.5, height: 1.4),
    ),
  ];

  List<Widget> _practice(SlopeColors c) => [
    Text(
      'Read the staff at the horizontal hair and type the reading in metres.',
      style: TextStyle(color: c.ink, fontWeight: FontWeight.w600, fontSize: 15),
    ),
    const SizedBox(height: 12),
    NumberField(
      controller: _answer,
      label: 'Your reading',
      unit: 'm',
      signed: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _check(),
    ),
    const SizedBox(height: 12),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(onPressed: _check, icon: const Icon(Icons.check_rounded), label: const Text('Check')),
        OutlinedButton.icon(
          onPressed: _newStaff,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Next staff'),
        ),
      ],
    ),
    if (_feedback != null) ...[
      const SizedBox(height: 14),
      Notice(_feedback!, kind: _right == true ? NoticeKind.success : NoticeKind.problem),
    ],
    const SizedBox(height: 14),
    Text(
      _tries == 0 ? 'Within 2 mm counts as right.' : 'Right $_good of $_tries. Within 2 mm counts as right.',
      style: TextStyle(color: c.muted, fontSize: 13),
    ),
  ];
}

/// The round view through the telescope: about 0.3 m of an E-pattern staff, the cross hairs and
/// the two stadia hairs.
class _TelescopePainter extends CustomPainter {
  _TelescopePainter(this.reading, this.c);
  final double reading;
  final SlopeColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final circle = Rect.fromCircle(center: centre, radius: radius);
    canvas.drawCircle(centre, radius, Paint()..color = const Color(0xFF0B0F18));
    canvas.save();
    canvas.clipPath(Path()..addOval(circle.deflate(10)));
    canvas.drawRect(circle, Paint()..color = const Color(0xFFDCE6D2));

    const window = 0.24; // metres of staff seen
    final pxPerM = (radius * 2) / window;
    final staffW = radius * 0.9;
    final left = centre.dx - staffW / 2;
    // y on screen for a staff height: the hair (centre) is at [reading], higher readings go up
    double y(double h) => centre.dy - (h - reading) * pxPerM;
    canvas.drawRect(Rect.fromLTRB(left, 0, left + staffW, size.height), Paint()..color = const Color(0xFFFBFAF4));

    final black = Paint()..color = const Color(0xFF111111);
    final red = Paint()..color = const Color(0xFFC62828);
    // One E per decimetre, 5 cm tall, on alternate sides: three 1 cm bars joined by a spine, with
    // the decimetre's number beside it. Black for the first metre, red for the next, and so on.
    final first = ((reading - window) * 10).floor(), last = ((reading + window) * 10).ceil();
    for (var dm = first; dm <= last; dm++) {
      final paint = (dm ~/ 10).isEven ? black : red;
      final onLeft = dm.isEven;
      final x0 = onLeft ? left + staffW * 0.06 : left + staffW * 0.54;
      final x1 = onLeft ? left + staffW * 0.46 : left + staffW * 0.94;
      final spine = onLeft ? Rect.fromLTRB(x0, 0, x0 + staffW * 0.08, 0) : Rect.fromLTRB(x1 - staffW * 0.08, 0, x1, 0);
      final base = dm / 10;
      canvas.drawRect(Rect.fromLTRB(spine.left, y(base + 0.05), spine.right, y(base)), paint);
      for (final bar in const [0, 2, 4]) {
        canvas.drawRect(Rect.fromLTRB(x0, y(base + (bar + 1) / 100), x1, y(base + bar / 100)), paint);
      }
      final label = TextPainter(
        text: TextSpan(
          text: '${dm % 10 == 0 ? dm ~/ 10 : dm % 10}',
          style: TextStyle(
            fontFamily: textFont,
            fontSize: pxPerM * 0.045,
            fontWeight: FontWeight.w800,
            color: paint.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = onLeft ? left + staffW * 0.74 - label.width / 2 : left + staffW * 0.26 - label.width / 2;
      label.paint(canvas, Offset(lx, y(base + 0.025) - label.height / 2));
      // a dot per whole metre above the number, as staffs mark the metre
      for (var i = 0; i < dm ~/ 10; i++) {
        canvas.drawCircle(Offset(lx + label.width / 2 + (i - (dm ~/ 10 - 1) / 2) * 9, y(base + 0.065)), 2.8, red);
      }
    }

    // cross hairs and stadia hairs
    final hair = Paint()
      ..color = const Color(0xFF101010)
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(circle.left, centre.dy), Offset(circle.right, centre.dy), hair);
    canvas.drawLine(Offset(centre.dx, circle.top), Offset(centre.dx, circle.bottom), hair);
    for (final dy in [-radius * 0.42, radius * 0.42]) {
      canvas.drawLine(
        Offset(centre.dx - radius * 0.25, centre.dy + dy),
        Offset(centre.dx + radius * 0.25, centre.dy + dy),
        hair,
      );
    }
    canvas.drawLine(
      Offset(circle.left, centre.dy),
      Offset(left, centre.dy),
      Paint()
        ..color = const Color(0xCCE53935)
        ..strokeWidth = 2.4,
    );
    canvas.restore();
    canvas.drawCircle(
      centre,
      radius - 5,
      Paint()
        ..color = const Color(0xFF2A3346)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
  }

  @override
  bool shouldRepaint(_TelescopePainter old) => old.reading != reading || old.c != c;
}
