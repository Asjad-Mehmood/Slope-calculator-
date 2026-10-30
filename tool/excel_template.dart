// The Slope Calculator Excel template: the same calculation as the app, in formulas, for people
// who work in Excel. Type the levels, chainages and interval in the yellow cells; the results,
// every station with its level, and the crossfall follow.
//   dart run tool/excel_template.dart docs/Slope-Calculator-Template.xlsx
// tool/check_exports.sh opens it in LibreOffice and checks its formulas give the app's numbers.
import 'dart:io';

import 'package:excel/excel.dart';

final _navy = ExcelColor.fromHexString('FF0A1A36');
final _gold = ExcelColor.fromHexString('FFE9B949');
final _input = ExcelColor.fromHexString('FFFFF4CC');
final _soft = ExcelColor.fromHexString('FFF3F5F9');
final _line = ExcelColor.fromHexString('FFD5DCE8');
Border get _thin => Border(borderStyle: BorderStyle.Thin, borderColorHex: _line);

CellStyle _style({bool bold = false, ExcelColor? fill, ExcelColor? font, String? format, double size = 11}) =>
    CellStyle(
      bold: bold,
      fontSize: size.round(),
      fontColorHex: font ?? ExcelColor.black,
      backgroundColorHex: fill ?? ExcelColor.none,
      numberFormat: format == null ? NumFormat.standard_0 : CustomNumericNumFormat(formatCode: format),
      leftBorder: _thin,
      rightBorder: _thin,
      topBorder: _thin,
      bottomBorder: _thin,
    );

/// Stations the template has rows for: enough for 1 km at 2 m, or 10 km at 20 m
const stationRows = 501;

void main(List<String> args) {
  final out = args.where((a) => !a.startsWith('--')).firstOrNull ?? 'docs/Slope-Calculator-Template.xlsx';
  // --example2: the V28 Excel template's own example, for tool/check_exports.sh
  final second = args.contains('--example2');
  final book = Excel.createExcel();
  final s = book['Slope Calculator'];
  book.setDefaultSheet('Slope Calculator');
  book.delete('Sheet1');

  void put(String cell, CellValue? v, CellStyle style) =>
      s.updateCell(CellIndex.indexByString(cell), v, cellStyle: style);
  void text(String cell, String v, {CellStyle? style}) => put(cell, TextCellValue(v), style ?? _style());
  void f(String cell, String formula, {String? format, bool bold = false}) =>
      put(cell, FormulaCellValue(formula), _style(format: format, bold: bold, fill: _soft));

  final title = _style(bold: true, fill: _navy, font: ExcelColor.white, size: 15);
  final head = _style(bold: true, fill: _gold, font: _navy);
  final label = _style(bold: true);
  final note = CellStyle(italic: true, fontColorHex: ExcelColor.fromHexString('FF5A6A85'));

  // title
  for (final c in ['A', 'B', 'C', 'D', 'E', 'F']) {
    put('${c}1', c == 'A' ? TextCellValue('SLOPE CALCULATOR · Excel template') : null, title);
  }
  s.updateCell(
    CellIndex.indexByString('A2'),
    TextCellValue(
      'Type in the yellow cells. Same formulas as the Slope Calculator app (exceltokml.com/slope-calculation).',
    ),
    cellStyle: note,
  );

  // project plate
  text('A4', 'PROJECT PLATE', style: head);
  text('B4', '', style: head);
  const plate = ['Project', 'Client', 'Location', 'Drawing number', 'Revision', 'Prepared by', 'Checked by', 'Date'];
  for (var i = 0; i < plate.length; i++) {
    text('A${5 + i}', plate[i], style: label);
    put('B${5 + i}', null, _style(fill: _input));
  }

  // inputs (rows 15–20)
  text('A14', 'YOUR DATA', style: head);
  text('B14', 'VALUE', style: head);
  text('C14', 'UNIT / NOTE', style: head);
  final inputs = [
    ('Start level Y1', second ? 1.9 : 102.5, 'm', '0.000'),
    ('End level Y2', second ? 0.6 : 98.75, 'm', '0.000'),
    ('Start chainage X1', second ? 0.0 : 1000.0, 'm (1+000 is 1000)', '0.000'),
    ('End chainage X2', second ? 379.29 : 1250.0, 'm, more than X1', '0.000'),
    ('Chainage interval', 20.0, 'm', '0.###'),
  ];
  for (var i = 0; i < inputs.length; i++) {
    final (name, value, unit, fmt) = inputs[i];
    text('A${15 + i}', name, style: label);
    put('B${15 + i}', DoubleCellValue(value), _style(fill: _input, format: fmt, bold: true));
    text('C${15 + i}', unit);
  }
  // named by cell: Y1 B15, Y2 B16, X1 B17, X2 B18, I B19

  // results (rows 22–29)
  text('A22', 'RESULTS', style: head);
  text('B22', 'VALUE', style: head);
  text('C22', 'FORMULA', style: head);
  final results = [
    ('Height difference ΔH', r'B16-B15', '0.000', 'ΔH = Y2 − Y1'),
    ('Horizontal distance ΔX', r'B18-B17', '0.000', 'ΔX = X2 − X1'),
    ('Slope per metre M', r'IF(B24=0,"",B23/B24)', '0.00000', 'M = ΔH ÷ ΔX'),
    ('Slope %', r'IF(B24=0,"",B25*100)', '0.000', 'M × 100'),
    ('Gradient 1 in', r'IF(OR(B24=0,B23=0),"level",1/ABS(B25))', '0.0', '1 ÷ |M|'),
    ('Direction', r'IF(B23>0,"Rising",IF(B23<0,"Falling","Level"))', null, 'from Y1 to Y2'),
    ('Stations', r'COUNT(A33:A533)', '0', 'rows in the table below'),
  ];
  for (var i = 0; i < results.length; i++) {
    final (name, formula, fmt, how) = results[i];
    text('A${23 + i}', name, style: label);
    f('B${23 + i}', formula, format: fmt, bold: true);
    text('C${23 + i}', how);
  }
  s.updateCell(
    CellIndex.indexByString('A30'),
    TextCellValue('Check: X2 must be more than X1 and the interval more than 0, or the table stays empty.'),
    cellStyle: note,
  );

  // chainage levels (row 32 heads, stations from row 33)
  for (final (c, h) in [
    ('A', 'CHAINAGE (m)'),
    ('B', 'CHAINAGE'),
    ('C', 'DISTANCE (m)'),
    ('D', 'LEVEL (m)'),
    ('E', 'CHANGE (m)'),
  ]) {
    text('${c}32', h, style: head);
  }
  // first station X1; then the next round chainage (a multiple of the interval) until X2, then X2
  f('A33', r'IF(AND($B$18>$B$17,$B$19>0),$B$17,"")', format: '0.000');
  for (var r = 34; r < 33 + stationRows; r++) {
    final p = r - 1;
    f(
      'A$r',
      'IF(OR(A$p="",A$p>=\$B\$18),"",MIN(\$B\$18,(FLOOR(A$p/\$B\$19+0.000000001,1)+1)*\$B\$19))',
      format: '0.000',
    );
  }
  for (var r = 33; r < 33 + stationRows; r++) {
    f('B$r', 'IF(A$r="","",IF(A$r<0,"-","")&INT(ABS(A$r)/1000)&"+"&TEXT(MOD(ABS(A$r),1000),"000.000"))');
    f('C$r', 'IF(A$r="","",A$r-\$B\$17)', format: '0.000');
    f('D$r', 'IF(A$r="","",ROUND(\$B\$15+\$B\$25*(A$r-\$B\$17),9))', format: '0.000');
    f('E$r', 'IF(A$r="","",ROUND(D$r-\$B\$15,9))', format: '0.000');
  }

  // crossfall, beside the results (columns H–K)
  text('H14', 'CROSSFALL', style: head);
  text('I14', 'LEFT', style: head);
  text('J14', 'RIGHT', style: head);
  text('H15', 'Centreline level', style: label);
  put('I15', const DoubleCellValue(10), _style(fill: _input, format: '0.000', bold: true));
  text('H16', 'Crossfall %', style: label);
  put('I16', const DoubleCellValue(2), _style(fill: _input, format: '0.00'));
  put('J16', const DoubleCellValue(2.5), _style(fill: _input, format: '0.00'));
  text('H17', 'Offset (m)', style: label);
  put('I17', const DoubleCellValue(3.5), _style(fill: _input, format: '0.000'));
  put('J17', const DoubleCellValue(3.5), _style(fill: _input, format: '0.000'));
  text('H18', 'Falls away? (1 yes, 0 rises)', style: label);
  put('I18', const IntCellValue(1), _style(fill: _input));
  put('J18', const IntCellValue(1), _style(fill: _input));
  text('H19', 'Level', style: label);
  f('I19', r'$I$15+IF(I18=1,-1,1)*I17*I16/100', format: '0.000', bold: true);
  f('J19', r'$I$15+IF(J18=1,-1,1)*J17*J16/100', format: '0.000', bold: true);
  text('H20', 'Difference from CL', style: label);
  f('I20', r'ROUND(I19-$I$15,9)', format: '0.000');
  f('J20', r'ROUND(J19-$I$15,9)', format: '0.000');

  for (final (col, w) in [(0, 26.0), (1, 16.0), (2, 22.0), (3, 14.0), (4, 14.0), (7, 28.0), (8, 12.0), (9, 12.0)]) {
    s.setColumnWidth(col, w);
  }

  final bytes = book.save(fileName: out.split('/').last)!;
  File(out)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  stdout.writeln('wrote $out');
}
