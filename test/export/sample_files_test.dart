// Writes the reports for tool/check_exports.sh, which opens them in LibreOffice and the PDF tools
// the way people do: SAMPLE_DIR=/some/folder flutter test test/export/sample_files_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/calc/calc.dart';
import 'package:slope_calculator/src/export/csv_export.dart';
import 'package:slope_calculator/src/export/excel_report.dart';
import 'package:slope_calculator/src/export/pdf_report.dart';

import 'export_test.dart' show data;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Platform.environment['SAMPLE_DIR'];

  test('write the sample reports', () async {
    final out = Directory(dir!)..createSync(recursive: true);
    void write(String name, List<int> bytes) => File('${out.path}/$name').writeAsBytesSync(bytes);
    final hi = data();
    final rf = data(method: BookingMethod.riseAndFall);
    write('report-hi.xlsx', buildExcelReport(hi));
    write('report-rise-and-fall.xlsx', buildExcelReport(rf));
    write('report.pdf', await buildPdfReport(hi));
    write('chainage-levels.csv', chainageLevelsCsv(hi.slope));
    write('level-book.csv', levelBookCsv(hi.run!, hi.book!));
  }, skip: dir == null ? 'only with SAMPLE_DIR set' : false);
}
