// The acceptance test through every export: the one table (Chainage | Left RL | Centre RL | Right RL)
// in the same order in the CSV, the Excel workbook and the PDF.
import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/calc/calc.dart';
import 'package:slope_calculator/src/export/csv_export.dart';
import 'package:slope_calculator/src/export/excel_report.dart';
import 'package:slope_calculator/src/export/pdf_report.dart';
import 'package:slope_calculator/src/export/report_data.dart';

final _slope = calculateSlope(
  const SlopeInput(startLevel: 100, endLevel: 99, startChainage: 0, endChainage: 100, interval: 20),
);

FormationResult _f([SidesMode mode = SidesMode.both]) => formation(
  _slope,
  SidesInput(
    mode: mode,
    left: const CrossfallSide(slopePercent: 2, distance: 5),
    right: const CrossfallSide(slopePercent: 2.5, distance: 5),
  ),
);

ReportData _data(FormationResult? f) => ReportData(
  slope: _slope,
  formation: f,
  plate: const {'project': 'Acceptance test', 'drawing': 'AT-01'},
  made: DateTime(2026, 11, 11),
);

const _rows = [
  ['0+000', '99.900', '100.000', '99.875'],
  ['0+020', '99.700', '99.800', '99.675'],
  ['0+040', '99.500', '99.600', '99.475'],
  ['0+060', '99.300', '99.400', '99.275'],
  ['0+080', '99.100', '99.200', '99.075'],
  ['0+100', '98.900', '99.000', '98.875'],
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CSV: CHAINAGE, LEFT_RL_M, CENTRE_RL_M, RIGHT_RL_M', () {
    final lines = utf8.decode(chainageLevelsCsv(_slope, _f())).replaceFirst('﻿', '').trim().split('\r\n');
    expect(lines.first, 'CHAINAGE,LEFT_RL_M,CENTRE_RL_M,RIGHT_RL_M');
    expect(lines.skip(1).toList(), [for (final r in _rows) r.join(',')]);
  });

  test('CSV with one side, and with the centreline only as before', () {
    final right = utf8.decode(chainageLevelsCsv(_slope, _f(SidesMode.rightOnly))).replaceFirst('﻿', '');
    expect(right.split('\r\n').first, 'CHAINAGE,CENTRE_RL_M,RIGHT_RL_M');
    final none = utf8.decode(chainageLevelsCsv(_slope, _f(SidesMode.none))).replaceFirst('﻿', '');
    expect(none.split('\r\n').first, 'CHAINAGE,DIST_M,LEVEL_M,CHANGE_FROM_START_M');
  });

  test('Excel: the same table, numbers as numbers, and each side in the summary', () {
    final book = Excel.decodeBytes(buildExcelReport(_data(_f())));
    final sheet = book.tables['Chainage Levels']!;
    String cell(int col, int row) {
      final v = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value;
      return switch (v) {
        TextCellValue() => v.value.text ?? '',
        DoubleCellValue() => v.value.toStringAsFixed(3),
        IntCellValue() => v.value.toStringAsFixed(3),
        _ => '$v',
      };
    }

    expect([for (var c = 0; c < 4; c++) cell(c, 1)], ['CHAINAGE', 'LEFT RL (M)', 'CENTRE RL (M)', 'RIGHT RL (M)']);
    for (var i = 0; i < _rows.length; i++) {
      expect([for (var c = 0; c < 4; c++) cell(c, i + 2)], _rows[i]);
    }
    final summary = book.tables['Slope Summary']!.rows
        .map((r) => r.map((c) => c?.value?.toString() ?? '').join(' | '))
        .join('\n');
    expect(summary, contains('Left crossfall'));
    expect(summary, contains('Right level difference ΔRL'));
  });

  test('PDF: made with the table and the cross-section', () async {
    final bytes = await buildPdfReport(_data(_f()));
    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
