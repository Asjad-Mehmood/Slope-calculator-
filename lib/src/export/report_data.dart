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

class ReportData {
  ReportData({
    required this.slope,
    required this.plate,
    this.crossfall,
    this.run,
    this.book,
    this.method = BookingMethod.heightOfInstrument,
    DateTime? made,
  }) : made = made ?? DateTime.now();

  final SlopeResult slope;

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
