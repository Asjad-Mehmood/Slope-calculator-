// The calculation being worked on: what is typed in the boxes, remembered on this device so the
// app opens where it was left.
import 'package:flutter/foundation.dart';

import '../calc/calc.dart';
import '../ui/settings.dart';
import 'store.dart';

class Calculation extends ChangeNotifier {
  Calculation(this._store, this._settings) {
    final j = _store.readJson(_key);
    if (j == null) {
      _texts = Map.of(_example);
      _texts['interval'] = _trim(_settings.interval);
      _decimals = _settings.decimals;
    } else {
      _texts = {for (final f in fields) f: (j[f] as String?) ?? ''};
      _decimals = ((j['decimals'] as num?)?.toInt() ?? _settings.decimals).clamp(1, 5);
    }
    _settings.addListener(notifyListeners);
  }

  final Store _store;
  final AppSettings _settings;
  static const _key = 'calculation';

  static const fields = ['y1', 'y2', 'x1', 'x2', 'interval'];

  /// What a first start shows: the V28 example
  static const _example = {'y1': '102.500', 'y2': '98.750', 'x1': '1+000', 'x2': '1+250', 'interval': '20'};

  /// The Excel template example, for "Load example"
  static const templateExample = {'y1': '1.900', 'y2': '0.600', 'x1': '0+000', 'x2': '0+379.290', 'interval': '20'};

  late Map<String, String> _texts;
  late int _decimals;

  String text(String field) => _texts[field] ?? '';
  int get decimals => _decimals;

  void setText(String field, String value) {
    if (_texts[field] == value) return;
    _texts[field] = value;
    _save();
  }

  set decimals(int value) {
    _decimals = value.clamp(1, 5);
    _save();
  }

  void load(Map<String, String> values) {
    _texts = {for (final f in fields) f: values[f] ?? ''};
    _save();
  }

  /// What a saved calculation keeps: the boxes as typed, the decimals and the station setting
  Map<String, Object?> toJson() => {..._texts, 'decimals': _decimals, 'spacing': _settings.spacing.name};

  /// Opens a saved calculation
  void loadJson(Map<String, Object?> j) {
    _texts = {for (final f in fields) f: (j[f] as String?) ?? ''};
    _decimals = ((j['decimals'] as num?)?.toInt() ?? _decimals).clamp(1, 5);
    final spacing = StationSpacing.values.asNameMap()[j['spacing']];
    if (spacing != null) _settings.spacing = spacing;
    _save();
  }

  void clear() {
    _texts = {for (final f in fields) f: f == 'interval' ? _texts['interval']! : ''};
    _save();
  }

  void _save() {
    _store.writeJson(_key, {..._texts, 'decimals': _decimals});
    notifyListeners();
  }

  static double _number(String s) => double.tryParse(s.trim()) ?? double.nan;
  static String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  SlopeInput get input => SlopeInput(
    startLevel: _number(text('y1')),
    endLevel: _number(text('y2')),
    startChainage: parseChainage(text('x1')) ?? double.nan,
    endChainage: parseChainage(text('x2')) ?? double.nan,
    interval: _number(text('interval')),
    decimals: _decimals,
    spacing: _settings.spacing,
  );

  /// The result, or null with [problem] saying why
  SlopeResult? get result => input.problem == null ? calculateSlope(input) : null;
  String? get problem => input.problem;

  @override
  void dispose() {
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}
