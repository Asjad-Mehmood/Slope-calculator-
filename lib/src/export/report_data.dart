// Everything a report holds, gathered once so the Excel, PDF and CSV files agree.
import '../brand.dart';
import '../calc/calc.dart';
import '../state/project_plate.dart';
import '../state/store.dart';

class CrossfallData {
  const CrossfallData({required this.centre, required this.left, required this.right, required this.result});
  final double centre;
  final CrossfallSide left;
  final CrossfallSide right;
  final CrossfallResult result;

  /// The crossfall as last entered on the Crossfall page, or null if it can't be calculated
  static CrossfallData? fromStore(Store store) {
    final j = store.readJson('crossfall') ?? const {'cl': '10.000', 'ls': '2', 'ld': '3.5', 'rs': '2.5', 'rd': '3.5'};
    double n(String k) => double.tryParse(((j[k] as String?) ?? '').trim()) ?? double.nan;
    CrossfallDirection d(String k) => CrossfallDirection.values.asNameMap()[j[k]] ?? CrossfallDirection.fallAway;
    final left = CrossfallSide(slopePercent: n('ls'), distance: n('ld'), direction: d('ldir'));
    final right = CrossfallSide(slopePercent: n('rs'), distance: n('rd'), direction: d('rdir'));
    if (crossfallProblem(n('cl'), left, right) != null) return null;
    return CrossfallData(
      centre: n('cl'),
      left: left,
      right: right,
      result: crossfall(n('cl'), left: left, right: right),
    );
  }
}

/// The one table of levels every export writes, in the screen's order: Chainage | Left RL |
/// Centre RL | Right RL (the sides that are on). With the centreline only it is Chainage |
/// Distance | Level | Change, as before the sides came.
class LevelsTable {
  LevelsTable(SlopeResult slope, FormationResult? f) {
    final d = slope.decimals;
    if (f == null || f.sides.mode == SidesMode.none) {
      heads = const ['Chainage', 'Distance from start (m)', 'Level (m)', 'Change from start (m)'];
      csvHeads = const ['CHAINAGE', 'DIST_M', 'LEVEL_M', 'CHANGE_FROM_START_M'];
      numbers = [
        for (final s in slope.stations) [s.distanceFromStart, s.level, s.changeFromStart],
      ];
      decimals = [3, d, d];
      centreColumn = 2;
      labels = [for (final s in slope.stations) s.label];
      text = [
        for (final s in slope.stations)
          [s.label, fixed(s.distanceFromStart, 3), fixed(s.level, d), signed(s.changeFromStart, d)],
      ];
      return;
    }
    final left = f.sides.mode.left, right = f.sides.mode.right;
    heads = ['Chainage', if (left) 'Left RL (m)', 'Centre RL (m)', if (right) 'Right RL (m)'];
    csvHeads = ['CHAINAGE', if (left) 'LEFT_RL_M', 'CENTRE_RL_M', if (right) 'RIGHT_RL_M'];
    numbers = [
      for (final r in f.rows) [if (left) r.left!, r.centre, if (right) r.right!],
    ];
    decimals = [for (var i = 0; i < numbers.first.length; i++) d];
    centreColumn = left ? 2 : 1;
    labels = [for (final r in f.rows) r.station.label];
    text = [
      for (var i = 0; i < labels.length; i++) [labels[i], for (final v in numbers[i]) fixed(v, d)],
    ];
  }

  late final List<String> heads;
  late final List<String> csvHeads;

  /// The station's chainage as the table writes it
  late final List<String> labels;

  /// The numbers after the chainage, row by row, with each column's decimals
  late final List<List<double>> numbers;
  late final List<int> decimals;

  /// Every cell as text
  late final List<List<String>> text;

  /// The centreline column (counting the chainage as 0), shaded in the reports
  late final int centreColumn;
}

class ReportData {
  ReportData({
    required this.slope,
    this.formation,
    required this.plate,
    this.crossfall,
    this.run,
    this.book,
    this.method = BookingMethod.heightOfInstrument,
    DateTime? made,
  }) : made = made ?? DateTime.now();

  final SlopeResult slope;

  /// The sides worked out with the centreline, or null (centreline only, or a side not filled in)
  final FormationResult? formation;

  LevelsTable get levels => LevelsTable(slope, formation);

  /// The project plate's fields by key (see [plateFields])
  final Map<String, String> plate;
  final CrossfallData? crossfall;
  final LevelRun? run;
  final ReducedBook? book;
  final BookingMethod method;
  final DateTime made;

  String get version => appVersion;

  String get projectName =>
      plate['project']?.trim().isNotEmpty == true ? plate['project']!.trim() : 'Slope calculation';

  /// 2026-10-30
  String get date => '${made.year}-${made.month.toString().padLeft(2, '0')}-${made.day.toString().padLeft(2, '0')}';

  /// A file name from the project name and date: Ring_Road_Slope_Report_2026-10-30
  /// Without a project name: Slope_Report_2026-10-30, Slope_Chainage_Levels_2026-10-30
  String fileName(String what) {
    final safe = projectName == 'Slope calculation'
        ? ''
        : projectName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    final short = safe.length > 40 ? safe.substring(0, 40) : safe;
    if (short.isNotEmpty) return '${short}_${what}_$date';
    return what.startsWith('Slope') ? '${what}_$date' : 'Slope_${what}_$date';
  }

  static Map<String, String> plateOf(ProjectPlate plate) => {for (final f in plateFields) f.key: plate[f.key]};
}

/// The Project Plate sheet's rows, in the Excel template's order
const templatePlateOrder = [
  ('project', 'Project name'),
  ('client', 'Client / owner'),
  ('contractor', 'Contractor / consultant'),
  ('contract', 'Project / contract number'),
  ('location', 'Location / site'),
  ('package', 'Work package / area'),
  ('drawing', 'Drawing number'),
  ('title', 'Drawing title / description'),
  ('revision', 'Revision'),
  ('scale', 'Drawing scale'),
  ('zone', 'Plot / zone / chainage range'),
  ('area', 'Area (m²)'),
  ('preparedBy', 'Prepared by'),
  ('checkedBy', 'Checked / approved by'),
  ('remarks', 'Remarks / datum / control reference'),
  ('workDate', 'Work date'),
];
