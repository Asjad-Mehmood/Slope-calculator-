import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/app.dart';
import 'package:slope_calculator/src/calc/calc.dart';
import 'package:slope_calculator/src/export/csv_export.dart';
import 'package:slope_calculator/src/export/excel_report.dart';
import 'package:slope_calculator/src/export/pdf_report.dart';
import 'package:slope_calculator/src/export/report_data.dart';
import 'package:slope_calculator/src/state/level_run_state.dart';
import 'package:slope_calculator/src/state/store.dart';

SlopeResult v28() => calculateSlope(
  const SlopeInput(startLevel: 102.5, endLevel: 98.75, startChainage: 1000, endChainage: 1250, interval: 20),
);

ReportData data({bool withRun = true, BookingMethod method = BookingMethod.heightOfInstrument}) {
  final slope = v28();
  final state = LevelRunState();
  if (withRun) state.finished(simulateLevelRun(slope), method);
  return ReportData(
    slope: slope,
    plate: const {'project': 'Ring Road, Phase 2', 'drawing': 'RR-201', 'preparedBy': 'A. Surveyor'},
    crossfall: CrossfallData.fromStore(Store.memory()),
    run: state.run,
    book: state.book,
    method: method,
    made: DateTime(2026, 10, 30),
  );
}

String? text(Sheet sheet, String cell) {
  final v = sheet.cell(CellIndex.indexByString(cell)).value;
  return switch (v) {
    null => null,
    TextCellValue() => v.value.text,
    DoubleCellValue() => '${v.value}',
    IntCellValue() => '${v.value}',
    _ => '$v',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Excel report', () {
    final book = Excel.decodeBytes(buildExcelReport(data()));

    test('has the template sheets plus the level book', () {
      expect(book.tables.keys, [
        'Project Plate',
        'Slope Summary',
        'Chainage Levels',
        'Crossfall',
        'Level Book',
        'QA QC Checklist',
      ]);
    });

    test('project plate in the template order', () {
      final s = book['Project Plate'];
      expect(text(s, 'A3'), 'Project name');
      expect(text(s, 'B3'), 'Ring Road, Phase 2');
      expect(text(s, 'A9'), 'Drawing number');
      expect(text(s, 'B9'), 'RR-201');
    });

    test('summary values are numbers', () {
      final s = book['Slope Summary'];
      expect(text(s, 'A3'), 'Start level Y1');
      expect(double.parse(text(s, 'B3')!), 102.5);
      expect(text(s, 'A10'), 'Slope percentage');
      expect(double.parse(text(s, 'B10')!), closeTo(-1.5, 1e-12));
    });

    test('every station, as numbers', () {
      final s = book['Chainage Levels'];
      expect(text(s, 'A3'), '1+000');
      expect(double.parse(text(s, 'C4')!), closeTo(102.2, 1e-9));
      expect(text(s, 'A16'), '1+250.000');
      expect(double.parse(text(s, 'C16')!), 98.75);
      expect(text(s, 'A17'), isNull);
    });

    test('crossfall from the Crossfall page', () {
      final s = book['Crossfall'];
      expect(text(s, 'A6'), 'Left level');
      expect(double.parse(text(s, 'B6')!), closeTo(9.93, 1e-9));
    });

    test('the level book with its checks', () {
      final s = book['Level Book'];
      expect(text(s, 'A2'), 'CHAINAGE');
      expect(text(s, 'B3'), '0.8504');
      expect(text(s, 'A16'), '1+250.000');
      final rows = s.rows.map((r) => r.isEmpty ? null : r.first?.value?.toString()).toList();
      expect(rows, contains('Arithmetic check'));
    });

    test('without a finished run the level book sheet says how to add it', () {
      final s = Excel.decodeBytes(buildExcelReport(data(withRun: false)))['Level Book'];
      expect(text(s, 'A2'), contains('Run the digital level'));
    });

    test('Rise & Fall columns when booked that way', () {
      final s = Excel.decodeBytes(buildExcelReport(data(method: BookingMethod.riseAndFall)))['Level Book'];
      expect(text(s, 'E2'), 'RISE');
      expect(text(s, 'F2'), 'FALL');
    });
  });

  group('CSV', () {
    test('chainage levels: the V28 columns, a byte order mark, Windows line ends', () {
      final csv = utf8.decode(chainageLevelsCsv(v28()));
      expect(csv.startsWith('CHAINAGE,DIST_M,LEVEL_M,CHANGE_FROM_START_M\r\n'), isTrue);
      expect(csv, contains('1+020,20.000,102.200,-0.300\r\n'));
      expect(csv.trimRight().split('\r\n'), hasLength(15));
    });

    test('level book with design levels', () {
      final d = data();
      final csv = utf8.decode(levelBookCsv(d.run!, d.book!).skip(3).toList());
      final lines = csv.trimRight().split('\r\n');
      expect(lines.first, 'CHAINAGE,BS,IS,FS,HI,RL,DESIGN_RL,DIFF_MM,ADJUSTED_RL,NOTE');
      expect(lines[1], startsWith('1+000.000,0.8504,,,103.3504,102.5000,102.5000,0.0,'));
      expect(lines.last, endsWith(',End'));
    });
  });

  group('PDF report', () {
    test('is a PDF with the report pages', () async {
      final bytes = await buildPdfReport(data());
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      final pages = RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length;
      expect(pages, greaterThanOrEqualTo(2));
    });

    test('works with an empty project plate and no run', () async {
      final slope = v28();
      final bytes = await buildPdfReport(ReportData(slope: slope, plate: const {}));
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('report details', () {
    test('file names from the project name and date', () {
      expect(data().fileName('Slope_Report'), 'Ring_Road_Phase_2_Slope_Report_2026-10-30');
      expect(
        ReportData(slope: v28(), plate: const {}, made: DateTime(2026, 1, 5)).fileName('Chainage_Levels'),
        'Slope_Chainage_Levels_2026-01-05',
      );
      expect(
        ReportData(slope: v28(), plate: const {}, made: DateTime(2026, 1, 5)).fileName('Slope_Report'),
        'Slope_Report_2026-01-05',
      );
    });

    test('crossfall from the store, or none when it is wrong', () {
      expect(CrossfallData.fromStore(Store.memory())!.result.leftLevel, closeTo(9.93, 1e-9));
      final bad = Store.memory()..writeJson('crossfall', {'cl': 'x'});
      expect(CrossfallData.fromStore(bad), isNull);
    });
  });

  testWidgets('the Export menu lists the four exports', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(SlopeCalculatorApp(store: Store.memory()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    for (final label in ['Excel report (.xlsx)', 'PDF report', 'Print', 'Chainage levels (.csv)']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
