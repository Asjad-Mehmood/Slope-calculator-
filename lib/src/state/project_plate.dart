// The project plate: the job's details, printed at the top of every report. Kept on this device.
import 'package:flutter/foundation.dart';

import 'store.dart';

class PlateField {
  const PlateField(
    this.key,
    this.label, {
    this.hint = '',
    this.wide = false,
    this.full = false,
    this.multiline = false,
  });
  final String key;
  final String label;
  final String hint;

  /// Takes two columns on a wide screen
  final bool wide;

  /// Takes the whole row
  final bool full;
  final bool multiline;
}

/// The fields of the Project Plate sheet of the Excel template, arranged so they fill the form's
/// rows of three without gaps (the Excel export keeps the template's order).
const plateFields = [
  PlateField('project', 'Project name', hint: 'e.g. Road / infrastructure project', wide: true),
  PlateField('client', 'Client / owner', hint: 'Client name'),
  PlateField('contractor', 'Contractor / consultant', hint: 'Company name'),
  PlateField('contract', 'Project / contract number', hint: 'Project reference'),
  PlateField('location', 'Location / site', hint: 'Site, country'),
  PlateField('package', 'Work package / area', hint: 'Area, section or package'),
  PlateField('drawing', 'Drawing number', hint: 'DWG reference'),
  PlateField('revision', 'Revision', hint: 'Rev. 0'),
  PlateField('title', 'Drawing title / description', hint: 'Longitudinal profile / road level', wide: true),
  PlateField('scale', 'Drawing scale', hint: 'H 1:1000 / V 1:100'),
  PlateField('zone', 'Plot / zone / chainage range', hint: 'Plot, zone or chainage'),
  PlateField('area', 'Area (m²)', hint: 'If it applies'),
  PlateField('workDate', 'Work date', hint: 'DD/MM/YYYY'),
  PlateField('preparedBy', 'Prepared by', hint: 'Surveyor / engineer'),
  PlateField('checkedBy', 'Checked / approved by', hint: 'Checker / approver', wide: true),
  PlateField(
    'remarks',
    'Remarks / datum / control reference',
    hint: 'Datum, TBM, control point or notes',
    full: true,
    multiline: true,
  ),
];

class ProjectPlate extends ChangeNotifier {
  ProjectPlate(this._store) {
    final j = _store.readJson(_key) ?? const {};
    for (final f in plateFields) {
      final v = j[f.key];
      if (v is String) _values[f.key] = v;
    }
  }

  final Store _store;
  static const _key = 'projectPlate';
  final Map<String, String> _values = {};

  String operator [](String key) => _values[key] ?? '';

  /// Replaces every field at once (the Save button)
  void save(Map<String, String> values) {
    _values
      ..clear()
      ..addEntries(values.entries.where((e) => e.value.trim().isNotEmpty).map((e) => MapEntry(e.key, e.value.trim())));
    _store.writeJson(_key, Map.of(_values));
    notifyListeners();
  }

  Map<String, String> get values => Map.unmodifiable(_values);

  int get filled => _values.length;
  bool get isEmpty => _values.isEmpty;
  String get projectName => this['project'];
}
