// The Excel report, laid out like the professional template: Project Plate, Slope Summary,
// Chainage Levels, Crossfall, Level Book (new: V28 only had it as a CSV) and the QA / QC
// checklist. Numbers are written as numbers, so they can be worked with in Excel.
import 'package:excel/excel.dart';

import '../calc/calc.dart';
import 'report_data.dart';

final _navy = ExcelColor.fromHexString('FF0A1A36');
final _gold = ExcelColor.fromHexString('FFE9B949');
final _soft = ExcelColor.fromHexString('FFF3F5F9');
final _line = ExcelColor.fromHexString('FFD5DCE8');

Border get _thin => Border(borderStyle: BorderStyle.Thin, borderColorHex: _line);

CellStyle _title() => CellStyle(bold: true, fontSize: 14, fontColorHex: ExcelColor.white, backgroundColorHex: _navy);
CellStyle _head() => CellStyle(
  bold: true,
  fontColorHex: _navy,
  backgroundColorHex: _gold,
  leftBorder: _thin,
  rightBorder: _thin,
  topBorder: _thin,
  bottomBorder: _thin,
);
CellStyle _cell({bool bold = false, bool shade = false, String? format, bool right = false}) => CellStyle(
  bold: bold,
  backgroundColorHex: shade ? _soft : ExcelColor.none,
  horizontalAlign: right ? HorizontalAlign.Right : HorizontalAlign.Left,
  numberFormat: format == null ? NumFormat.standard_0 : CustomNumericNumFormat(formatCode: format),
  leftBorder: _thin,
  rightBorder: _thin,
  topBorder: _thin,
  bottomBorder: _thin,
);

String _decimals(int d) => '0.${'0' * d}';

class _Sheet {
  _Sheet(this.sheet);
  final Sheet sheet;
  int row = 0;

  void title(String text, int width) {
    for (var c = 0; c < width; c++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
        c == 0 ? TextCellValue(text) : null,
        cellStyle: _title(),
      );
    }
    sheet.setRowHeight(row, 26);
    row++;
  }

  void heads(List<String> names) {
    for (var c = 0; c < names.length; c++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
        TextCellValue(names[c]),
        cellStyle: _head(),
      );
    }
    row++;
  }

  /// A row of values: strings as text, doubles as numbers in [formats] (by column)
  void values(List<Object?> cells, {Map<int, String> formats = const {}, bool bold = false}) {
    final shade = row.isEven;
    for (var c = 0; c < cells.length; c++) {
      final v = cells[c];
      final value = switch (v) {
        null => null,
        // to 9 decimals, so a cell holds −0.3 and not −0.299999999999997 when copied or used in
        // a formula (the column's format still decides what is shown)
        final double d => DoubleCellValue(d.isFinite ? double.parse(d.toStringAsFixed(9)) : d),
        final int i => IntCellValue(i),
        _ => TextCellValue('$v'),
      };
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
        value,
        cellStyle: _cell(bold: bold || c == 0, shade: shade, format: formats[c], right: v is num),
      );
    }
    row++;
  }

  void gap() => row++;

  void widths(List<double> w) {
    for (var c = 0; c < w.length; c++) {
      sheet.setColumnWidth(c, w[c]);
    }
  }
}

/// The workbook's bytes (.xlsx)
List<int> buildExcelReport(ReportData d) {
  final excel = Excel.createExcel();
  final first = excel.getDefaultSheet()!;
  final s = d.slope;
  final dec = _decimals(s.decimals);

  // Project Plate
  excel.rename(first, 'Project Plate');
  final plate = _Sheet(excel['Project Plate'])
    ..widths([34, 60])
    ..title('SLOPE CALCULATOR · PROJECT PLATE', 2)
    ..heads(['FIELD', 'PROJECT INFORMATION']);
  for (final (key, label) in templatePlateOrder) {
    plate.values([label, d.plate[key] ?? '']);
  }
  plate
    ..values(['Units', 'Metres (m), unless noted'])
    ..values(['Report made', '${d.date} with Slope Calculator ${d.version} (Excel to KML)']);

  // Slope Summary
  final sum = _Sheet(excel['Slope Summary'])
    ..widths([30, 22, 44])
    ..title('SLOPE CALCULATION · SUMMARY & INPUTS', 3)
    ..heads(['PARAMETER', 'VALUE', 'UNIT / NOTES']);
  sum
    ..values(['Start level Y1', s.startLevel, 'm'], formats: {1: dec})
    ..values(['End level Y2', s.endLevel, 'm'], formats: {1: dec})
    ..values(['Start chainage X1', s.startChainage, 'm (${formatChainage(s.startChainage)})'], formats: {1: '0.000'})
    ..values(['End chainage X2', s.endChainage, 'm (${formatChainage(s.endChainage)})'], formats: {1: '0.000'})
    ..values(['Height difference ΔH', s.rise, 'm'], formats: {1: dec})
    ..values(['Horizontal distance ΔX', s.length, 'm'], formats: {1: '0.000'})
    ..values(['Slope per metre', s.slopePerMetre, 'm/m'], formats: {1: '0.00000'})
    ..values(['Slope percentage', s.percent, '%'], formats: {1: '0.000'})
    ..values(['Gradient', s.gradient == null ? 'LEVEL' : '1 in ${fixed(s.gradient!, 3)}', 'Ratio'])
    ..values(['Direction', s.direction.name.toUpperCase(), 'Start to end'])
    ..values(['Chainage interval', s.input.interval, 'm'], formats: {1: '0.###'})
    ..values([
      'Stations',
      s.input.spacing == StationSpacing.roundChainages ? 'On round chainages' : 'Counted from the start',
      '${s.stations.length} stations',
    ])
    ..values(['Display decimals', s.decimals, 'decimal places'])
    ..values(['Calculation formula', '(Y2 − Y1) ÷ (X2 − X1)', 'Verify input datum and units'])
    ..values(['Summary', s.summary, ''])
    ..values(['Review note', 'Confirm design criteria and an independent check before construction use.', '']);

  // Chainage Levels
  final levels = _Sheet(excel['Chainage Levels'])
    ..widths([18, 24, 16, 24])
    ..title('CHAINAGE LEVELS', 4)
    ..heads(['CHAINAGE', 'DISTANCE FROM START (m)', 'LEVEL (m)', 'CHANGE FROM START (m)']);
  for (final st in s.stations) {
    levels.values(
      [st.label, st.distanceFromStart, st.level, st.changeFromStart],
      formats: {1: '0.000', 2: dec, 3: dec},
    );
  }

  // Crossfall
  final cf = d.crossfall;
  final cross = _Sheet(excel['Crossfall'])
    ..widths([30, 18, 40])
    ..title('CROSSFALL / CENTRELINE OFFSET', 3)
    ..heads(['PARAMETER', 'VALUE', 'UNIT / NOTES']);
  if (cf == null) {
    cross.values(['No crossfall entered', '', 'Fill in the Crossfall page to include it']);
  } else {
    String dir(CrossfallSide side) => side.direction == CrossfallDirection.fallAway ? 'falls away' : 'rises away';
    cross
      ..values(['Centreline level', cf.centre, 'm'], formats: {1: '0.000'})
      ..values(['Left slope', cf.left.slopePercent.abs(), '% · ${dir(cf.left)}'], formats: {1: '0.00'})
      ..values(['Left offset distance', cf.left.distance, 'm'], formats: {1: '0.000'})
      ..values(['Left level', cf.result.leftLevel, 'm'], formats: {1: '0.0000'})
      ..values(['Left level difference', cf.result.leftDifference, 'm'], formats: {1: '0.0000'})
      ..values(['Right slope', cf.right.slopePercent.abs(), '% · ${dir(cf.right)}'], formats: {1: '0.00'})
      ..values(['Right offset distance', cf.right.distance, 'm'], formats: {1: '0.000'})
      ..values(['Right level', cf.result.rightLevel, 'm'], formats: {1: '0.0000'})
      ..values(['Right level difference', cf.result.rightDifference, 'm'], formats: {1: '0.0000'})
      ..values(['Formula', 'Level = CL ± distance × |slope %| ÷ 100', '']);
  }

  // Level Book
  final run = d.run, book = d.book;
  final lb = _Sheet(excel['Level Book']);
  if (run == null || book == null) {
    lb
      ..widths([60])
      ..title('LEVEL BOOK', 1)
      ..values(['Run the digital level to the end on the Level page to include its level book here.']);
  } else {
    final rf = book.method == BookingMethod.riseAndFall;
    final heads = [
      'CHAINAGE',
      'BS',
      'IS',
      'FS',
      if (rf) ...['RISE', 'FALL'] else 'HI',
      'RL',
      'DESIGN RL',
      'DIFF (mm)',
      'ADJUSTED RL',
      'NOTE',
    ];
    lb
      ..widths([
        16,
        11,
        11,
        11,
        if (rf) ...[11, 11] else 12,
        12,
        12,
        11,
        13,
        12,
      ])
      ..title('LEVEL BOOK · ${rf ? 'RISE & FALL' : 'HEIGHT OF INSTRUMENT'}', heads.length)
      ..heads(heads);
    const r4 = '0.0000';
    for (var i = 0; i < run.points.length; i++) {
      final p = run.points[i], b = book.rows[i];
      final cells = <Object?>[
        formatChainage(p.chainage),
        b.row.backsight,
        b.row.intermediate,
        b.row.foresight,
        if (rf) ...[b.rise, b.fall] else b.heightOfInstrument,
        b.level,
        p.designLevel,
        (b.level - p.designLevel) * 1000,
        p.adjustedLevel,
        p.isStation ? b.row.remark : 'CP added',
      ];
      lb.values(cells, formats: {for (var c = 1; c < cells.length - 1; c++) c: c == cells.length - 3 ? '0.0' : r4});
    }
    final m = run.closing;
    lb
      ..gap()
      ..values(['Setups', run.setups])
      ..values(['ΣBS', book.sumBacksights], formats: {1: r4})
      ..values(['ΣFS', book.sumForesights], formats: {1: r4})
      ..values(['ΣBS − ΣFS', book.sumBacksights - book.sumForesights], formats: {1: r4})
      ..values(['Last RL − first RL', book.lastLevel - book.firstLevel], formats: {1: r4})
      ..values(['Arithmetic check', book.arithmeticCheckPasses ? 'Passed' : 'Failed'])
      ..values(['Closing error (mm)', m.error * 1000], formats: {1: '0.0'})
      ..values(
        ['Allowable (mm)', m.allowable * 1000, '${fixed(run.options.allowableC, 0)}√K, K = ${fixed(m.lengthKm, 3)} km'],
        formats: {1: '0.0'},
      )
      ..values(['Tolerance', m.withinTolerance ? 'Within' : 'Outside'])
      ..values(['Note', 'Simulated run for training and checking; not field measurements.']);
  }

  // QA / QC
  final qa = _Sheet(excel['QA QC Checklist'])
    ..widths([58, 16, 40])
    ..title('SURVEY CALCULATION · QA / QC REVIEW', 3)
    ..heads(['CHECK ITEM', 'STATUS', 'REVIEW NOTES / EVIDENCE']);
  for (final item in const [
    'Project name, drawing number and revision confirmed',
    'Start and end levels checked against approved source',
    'Units and vertical datum confirmed',
    'Start and end distances / chainages verified',
    'Slope direction and percentage checked independently',
    'Station interval and end station checked',
    'Crossfall left/right directions verified',
    'Project area / zone information confirmed if applicable',
    'Excel results compared with an independent calculation',
    'Prepared / checked fields completed',
    'Report reviewed and approved before construction use',
  ]) {
    qa.values([item, 'Not checked', '']);
  }

  excel.setDefaultSheet('Project Plate');
  return excel.encode()!;
}
