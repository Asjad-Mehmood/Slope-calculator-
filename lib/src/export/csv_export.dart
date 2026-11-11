// CSV files that open straight in Excel: a byte order mark so Excel reads UTF-8, Windows line
// endings, and values that need it quoted.
import 'dart:convert';

import '../calc/calc.dart';
import 'report_data.dart' show LevelsTable;

String _cell(String v) => RegExp(r'[",\r\n]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;

List<int> _csv(List<List<String>> rows) => utf8.encode('﻿${rows.map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n');

/// The table as the screen shows it: CHAINAGE, LEFT_RL_M, CENTRE_RL_M, RIGHT_RL_M with the sides;
/// with the centreline only, V28's columns CHAINAGE, DIST_M, LEVEL_M, CHANGE_FROM_START_M
List<int> chainageLevelsCsv(SlopeResult r, [FormationResult? f]) {
  final t = LevelsTable(r, f);
  return _csv([
    t.csvHeads,
    for (var i = 0; i < t.labels.length; i++)
      [t.labels[i], for (var j = 0; j < t.numbers[i].length; j++) fixed(t.numbers[i][j], t.decimals[j])],
  ]);
}

/// The level book with the design levels and differences
List<int> levelBookCsv(LevelRun run, ReducedBook book) {
  final rf = book.method == BookingMethod.riseAndFall;
  String n(double? v) => v == null ? '' : fixed(v, 4);
  return _csv([
    [
      'CHAINAGE',
      'BS',
      'IS',
      'FS',
      if (rf) ...['RISE', 'FALL'] else 'HI',
      'RL',
      'DESIGN_RL',
      'DIFF_MM',
      'ADJUSTED_RL',
      'NOTE',
    ],
    for (var i = 0; i < run.points.length; i++)
      [
        formatChainage(run.points[i].chainage),
        n(book.rows[i].row.backsight),
        n(book.rows[i].row.intermediate),
        n(book.rows[i].row.foresight),
        if (rf) ...[n(book.rows[i].rise), n(book.rows[i].fall)] else n(book.rows[i].heightOfInstrument),
        fixed(book.rows[i].level, 4),
        fixed(run.points[i].designLevel, 4),
        fixed((book.rows[i].level - run.points[i].designLevel) * 1000, 1),
        fixed(run.points[i].adjustedLevel, 4),
        run.points[i].isStation ? book.rows[i].row.remark : 'CP added',
      ],
  ]);
}
