// The PDF report: A4, the project plate, the results, the profile, the chainage levels, the
// crossfall, the level book with its checks, and boxes for Surveyed, Checked and Approved by.
// The fonts and logo come from inside the app, so it is made offline.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../brand.dart';
import '../calc/calc.dart';
import 'report_data.dart';

const _navy = PdfColor.fromInt(0xFF0A1A36);
const _gold = PdfColor.fromInt(0xFFE2AE34);
const _goldPale = PdfColor.fromInt(0xFFFBF1D9);
const _soft = PdfColor.fromInt(0xFFF3F5F9);
const _line = PdfColor.fromInt(0xFFD5DCE8);
const _muted = PdfColor.fromInt(0xFF5A6A85);
const _ink = PdfColor.fromInt(0xFF0E1B33);
const _fall = PdfColor.fromInt(0xFFB4442F);
const _rise = PdfColor.fromInt(0xFF1C7C4A);

Future<Uint8List> buildPdfReport(ReportData d) async {
  Future<pw.Font> font(String file) async => pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));
  final regular = await font('Inter_400Regular.ttf');
  final medium = await font('Inter_600SemiBold.ttf');
  final bold = await font('Inter_700Bold.ttf');
  final mono = await font('JetBrainsMono_500Medium.ttf');
  final logo = pw.MemoryImage((await rootBundle.load('assets/brand/icon-512.png')).buffer.asUint8List());

  final s = d.slope;
  final doc = pw.Document(
    title: '${d.projectName} – slope report',
    author: appPublisher,
    creator: '$appName $appVersion',
  );
  final theme = pw.ThemeData.withFont(base: regular, bold: bold, boldItalic: bold, italic: regular);

  pw.Widget heading(String text, {int? step}) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
    child: pw.Row(
      children: [
        if (step != null) ...[
          pw.Container(
            width: 18,
            height: 18,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(color: _gold, shape: pw.BoxShape.circle),
            child: pw.Text(
              '$step',
              style: pw.TextStyle(font: bold, fontSize: 9, color: _navy),
            ),
          ),
          pw.SizedBox(width: 8),
        ],
        pw.Text(
          text.toUpperCase(),
          style: pw.TextStyle(font: bold, fontSize: 10.5, letterSpacing: 1, color: _ink),
        ),
      ],
    ),
  );

  pw.Widget tile(String label, String value, {PdfColor? color, bool hero = false}) => pw.Expanded(
    flex: hero ? 15 : 10,
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 6),
      padding: const pw.EdgeInsets.fromLTRB(9, 7, 9, 8),
      decoration: pw.BoxDecoration(
        color: hero ? _navy : _soft,
        borderRadius: pw.BorderRadius.circular(6),
        border: hero ? null : pw.Border.all(color: _line, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              font: bold,
              fontSize: 6.5,
              letterSpacing: 0.7,
              color: hero ? PdfColors.grey300 : _muted,
            ),
          ),
          pw.SizedBox(height: 3),
          // shrinks rather than wrapping onto a second line
          pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: bold,
                fontSize: hero ? 15 : 12,
                color: hero ? PdfColors.white : (color ?? _ink),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  pw.Widget table(
    List<String> heads,
    List<List<String>> rows, {
    Set<int> numeric = const {},
    Set<int> strong = const {},
  }) => pw.TableHelper.fromTextArray(
    headers: heads,
    data: rows,
    border: pw.TableBorder.all(color: _line, width: 0.5),
    headerStyle: pw.TextStyle(font: bold, fontSize: 7.5, color: _navy),
    headerDecoration: const pw.BoxDecoration(color: _gold),
    cellStyle: pw.TextStyle(font: regular, fontSize: 8, color: _ink),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    oddRowDecoration: const pw.BoxDecoration(color: _soft),
    cellAlignments: {
      for (var i = 0; i < heads.length; i++)
        i: numeric.contains(i) ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    },
    headerAlignments: {
      for (var i = 0; i < heads.length; i++)
        i: numeric.contains(i) ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    },
    rowDecoration: null,
    cellFormat: null,
    textStyleBuilder: (col, data, row) =>
        strong.contains(row) ? pw.TextStyle(font: medium, fontSize: 8, color: _ink) : null,
  );

  // Project plate: the fields that are filled in, two to a row
  final filled = [
    for (final (key, label) in templatePlateOrder)
      if ((d.plate[key] ?? '').trim().isNotEmpty) (label, d.plate[key]!.trim()),
  ];
  pw.Widget plate() {
    if (filled.isEmpty) {
      return pw.Text(
        'No project details entered. Fill in the project plate in the app to show them here.',
        style: const pw.TextStyle(color: _muted, fontSize: 8.5),
      );
    }
    final rows = <pw.TableRow>[];
    for (var i = 0; i < filled.length; i += 2) {
      pw.Widget cell((String, String)? f) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: f == null
            ? pw.SizedBox()
            : pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    f.$1.toUpperCase(),
                    style: pw.TextStyle(font: bold, fontSize: 6.5, color: _muted, letterSpacing: 0.6),
                  ),
                  pw.SizedBox(height: 1.5),
                  pw.Text(f.$2, style: const pw.TextStyle(fontSize: 9, color: _ink)),
                ],
              ),
      );
      rows.add(pw.TableRow(children: [cell(filled[i]), cell(i + 1 < filled.length ? filled[i + 1] : null)]));
    }
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      children: rows,
    );
  }

  final dir = switch (s.direction) {
    SlopeDirection.falling => 'Falling',
    SlopeDirection.rising => 'Rising',
    SlopeDirection.level => 'Level',
  };
  final riseColor = s.rise < 0 ? _fall : (s.rise > 0 ? _rise : null);

  final cf = d.crossfall;
  final run = d.run, book = d.book;

  doc.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4.copyWith(marginLeft: 36, marginRight: 36, marginTop: 30, marginBottom: 30),
      header: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        margin: const pw.EdgeInsets.only(bottom: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 1.5)),
        ),
        child: pw.Row(
          children: [
            pw.Image(logo, width: 26, height: 26),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    d.projectName,
                    style: pw.TextStyle(font: bold, fontSize: 12, color: _ink),
                  ),
                  pw.Text(
                    [
                      'Slope calculation report',
                      if ((d.plate['drawing'] ?? '').isNotEmpty) 'Drawing ${d.plate['drawing']}',
                      if ((d.plate['revision'] ?? '').isNotEmpty) d.plate['revision']!,
                    ].join(' · '),
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  d.date,
                  style: pw.TextStyle(font: medium, fontSize: 8.5, color: _ink),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: _muted),
                ),
              ],
            ),
          ],
        ),
      ),
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'Made with $appName $appVersion by $appPublisher (${websiteUrl.replaceFirst('https://', '')}). '
                'Check results against an approved example before construction use.',
                style: const pw.TextStyle(fontSize: 6.8, color: _muted),
              ),
            ),
          ],
        ),
      ),
      build: (context) => [
        heading('Project plate'),
        plate(),
        heading('Results', step: 2),
        pw.Row(
          children: [
            tile('Slope', '${signed(s.percent, 3)} %', hero: true),
            tile('ΔH rise / fall', '${signed(s.rise, s.decimals)} m', color: riseColor),
            tile('Length ΔX', '${fixed(s.length, 3)} m'),
            tile('Slope per metre', signed(s.slopePerMetre, 5)),
            tile('Gradient', s.gradient == null ? 'Level' : '1 in ${fixed(s.gradient!, 1)}'),
            tile('Direction', dir),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(color: _goldPale, borderRadius: pw.BorderRadius.circular(5)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Y1 ${fixed(s.startLevel, 3)} m at ${formatChainage(s.startChainage)}  ·  Y2 ${fixed(s.endLevel, 3)} m at '
                '${formatChainage(s.endChainage)}  ·  interval ${fixed(s.input.interval, s.input.interval % 1 == 0 ? 0 : 3)} m',
                style: pw.TextStyle(font: medium, fontSize: 8.5, color: _ink),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'M = (Y2 − Y1) ÷ (X2 − X1) = (${fixed(s.endLevel, 3)} − ${fixed(s.startLevel, 3)}) ÷ '
                '(${fixed(s.endChainage, 3)} − ${fixed(s.startChainage, 3)}) = ${signed(s.slopePerMetre, 5)} per metre = '
                '${signed(s.percent, 3)} %',
                style: pw.TextStyle(font: mono, fontSize: 7.5, color: _ink),
              ),
              pw.SizedBox(height: 3),
              pw.Text(s.summary, style: const pw.TextStyle(fontSize: 8.5, color: _ink)),
            ],
          ),
        ),
        heading('Profile'),
        _profile(s, PdfFont.helvetica(doc.document)),
        heading('Chainage levels', step: 3),
        table(
          ['Chainage', 'Distance from start (m)', 'Level (m)', 'Change from start (m)'],
          [
            for (final st in s.stations)
              [
                st.label,
                fixed(st.distanceFromStart, 3),
                fixed(st.level, s.decimals),
                signed(st.changeFromStart, s.decimals),
              ],
          ],
          numeric: {1, 2, 3},
          strong: {1, s.stations.length},
        ),
        if (cf != null) ...[
          heading('Crossfall', step: 4),
          table(
            ['Side', 'Slope', 'Offset (m)', 'Direction', 'Level (m)', 'Difference (m)'],
            [
              ['Centreline', '', '', '', fixed(cf.centre, 3), ''],
              for (final (name, side, level, diff) in [
                ('Left', cf.left, cf.result.leftLevel, cf.result.leftDifference),
                ('Right', cf.right, cf.result.rightLevel, cf.result.rightDifference),
              ])
                [
                  name,
                  '${fixed(side.slopePercent.abs(), 2)} %',
                  fixed(side.distance, 3),
                  side.direction == CrossfallDirection.fallAway ? 'Falls away' : 'Rises away',
                  fixed(level, 4),
                  signed(diff, 4),
                ],
            ],
            numeric: {1, 2, 4, 5},
          ),
        ],
        if (run != null && book != null) ..._levelBook(run, book, heading, table, regular),
        heading('Sign-off'),
        pw.Row(
          children: [
            for (final (role, name) in [
              ('Surveyed by', d.plate['preparedBy'] ?? ''),
              ('Checked by', d.plate['checkedBy'] ?? ''),
              ('Approved by', ''),
            ])
              pw.Expanded(
                child: pw.Container(
                  height: 78,
                  margin: const pw.EdgeInsets.only(right: 6),
                  padding: const pw.EdgeInsets.all(7),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _line, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        role.toUpperCase(),
                        style: pw.TextStyle(font: bold, fontSize: 7, color: _muted, letterSpacing: 0.7),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Name: $name', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Spacer(),
                      pw.Text('Signature: ____________________', style: const pw.TextStyle(fontSize: 8, color: _muted)),
                      pw.SizedBox(height: 5),
                      pw.Text('Date: ______________', style: const pw.TextStyle(fontSize: 8, color: _muted)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}

List<pw.Widget> _levelBook(
  LevelRun run,
  ReducedBook book,
  pw.Widget Function(String, {int? step}) heading,
  pw.Widget Function(List<String>, List<List<String>>, {Set<int> numeric, Set<int> strong}) table,
  pw.Font regular,
) {
  final rf = book.method == BookingMethod.riseAndFall;
  String n(double? v) => v == null ? '' : fixed(v, 4);
  final m = run.closing;
  final heads = [
    'Chainage',
    'BS',
    'IS',
    'FS',
    if (rf) ...['Rise', 'Fall'] else 'HI',
    'RL',
    'Design RL',
    'Diff (mm)',
    'Note',
  ];
  return [
    heading('Level book · ${rf ? 'Rise & Fall' : 'Height of Instrument'}', step: 5),
    table(
      heads,
      [
        for (var i = 0; i < run.points.length; i++)
          [
            formatChainage(run.points[i].chainage),
            n(book.rows[i].row.backsight),
            n(book.rows[i].row.intermediate),
            n(book.rows[i].row.foresight),
            if (rf) ...[n(book.rows[i].rise), n(book.rows[i].fall)] else n(book.rows[i].heightOfInstrument),
            fixed(book.rows[i].level, 4),
            fixed(run.points[i].designLevel, 4),
            signed((book.rows[i].level - run.points[i].designLevel) * 1000, 1),
            run.points[i].isStation ? book.rows[i].row.remark : 'CP added',
          ],
      ],
      numeric: {for (var i = 1; i < heads.length - 1; i++) i},
    ),
    pw.SizedBox(height: 6),
    pw.Text(
      'ΣBS ${fixed(book.sumBacksights, 4)} − ΣFS ${fixed(book.sumForesights, 4)} = ${signed(book.sumBacksights - book.sumForesights, 4)}; '
      'last RL − first RL = ${signed(book.lastLevel - book.firstLevel, 4)}: arithmetic check '
      '${book.arithmeticCheckPasses ? 'passed' : 'FAILED'}. Closing error ${signed(m.error * 1000, 1)} mm against the design end '
      'level, allowable ${fixed(run.options.allowableC, 0)}√K = ${fixed(m.allowable * 1000, 1)} mm: '
      '${m.withinTolerance ? 'within' : 'OUTSIDE'} tolerance. ${run.setups} setups, ${run.readings.length} readings. '
      'A simulated run for training and checking, not field measurements.',
      style: const pw.TextStyle(fontSize: 8, color: _ink),
    ),
  ];
}

/// The long section drawn into the PDF: the slope line, its stations and the level axis.
pw.Widget _profile(SlopeResult s, PdfFont labels) {
  const height = 150.0;
  return pw.Container(
    height: height,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line, width: 0.6),
      borderRadius: pw.BorderRadius.circular(5),
    ),
    child: pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.CustomPaint(
            painter: (canvas, size) {
              const left = 46.0, right = 14.0, top = 12.0, bottom = 22.0;
              final w = size.x - left - right, h = size.y - top - bottom;
              final lo = math.min(s.startLevel, s.endLevel), hi = math.max(s.startLevel, s.endLevel);
              // the level axis on round numbers: steps of 1, 2, 2.5 or 5 × 10ⁿ
              final raw = math.max(hi - lo, 0.5) / 3;
              final p10 = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
              final step = [1.0, 2.0, 2.5, 5.0, 10.0].map((m) => m * p10).firstWhere((v) => v >= raw);
              final yMin = (lo / step).floor() * step - (lo % step == 0 ? step : 0);
              final yMax = (hi / step).ceil() * step + (hi % step == 0 ? step : 0);
              final ticks = ((yMax - yMin) / step).round();
              final tickDecimals = step >= 1 ? 0 : (step >= 0.1 ? 1 : 2);
              // PDF y runs upwards from the bottom
              double x(double ch) => left + (ch - s.startChainage) / s.length * w;
              double y(double lv) => bottom + (lv - yMin) / (yMax - yMin) * h;
              canvas
                ..setStrokeColor(_line)
                ..setLineWidth(0.5);
              for (var i = 0; i <= ticks; i++) {
                final gy = y(yMin + step * i);
                canvas
                  ..moveTo(left, gy)
                  ..lineTo(left + w, gy)
                  ..strokePath();
              }
              canvas
                ..setFillColor(_goldPale)
                ..moveTo(x(s.startChainage), bottom)
                ..lineTo(x(s.startChainage), y(s.startLevel))
                ..lineTo(x(s.endChainage), y(s.endLevel))
                ..lineTo(x(s.endChainage), bottom)
                ..closePath()
                ..fillPath()
                ..setStrokeColor(_gold)
                ..setLineWidth(2)
                ..moveTo(x(s.startChainage), y(s.startLevel))
                ..lineTo(x(s.endChainage), y(s.endLevel))
                ..strokePath();
              for (final st in s.stations) {
                canvas
                  ..setFillColor(PdfColors.white)
                  ..setStrokeColor(_navy)
                  ..setLineWidth(0.8)
                  ..drawEllipse(x(st.chainage), y(st.level), 2.2, 2.2)
                  ..fillAndStrokePath();
              }
              void text(String t, double tx, double ty) {
                canvas
                  ..setFillColor(_muted)
                  ..drawString(labels, 6.5, t, tx, ty);
              }

              for (var i = 0; i <= ticks; i++) {
                final lv = yMin + step * i;
                text(fixed(lv, tickDecimals), 10, y(lv) - 2);
              }
              text(formatChainage(s.startChainage), left - 10, 6);
              text(formatChainage(s.endChainage), left + w - 40, 6);
            },
          ),
        ),
      ],
    ),
  );
}
