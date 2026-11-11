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
    _readSides(j ?? const {});
    _settings.addListener(notifyListeners);
  }

  final Store _store;
  final AppSettings _settings;
  static const _key = 'calculation';

  static const fields = ['y1', 'y2', 'x1', 'x2', 'interval'];

  /// The offset and crossfall on each side of the centreline (left offset, left %, right …)
  static const sideFields = ['lo', 'lc', 'ro', 'rc'];

  /// What a first start shows: the V28 example
  static const _example = {'y1': '102.500', 'y2': '98.750', 'x1': '1+000', 'x2': '1+250', 'interval': '20'};

  /// The Excel template example, for "Load example"
  static const templateExample = {'y1': '1.900', 'y2': '0.600', 'x1': '0+000', 'x2': '0+379.290', 'interval': '20'};

  late Map<String, String> _texts;
  late int _decimals;

  String text(String field) => _texts[field] ?? _sides[field] ?? '';

  // ---------- the sides: offset, crossfall and direction, left and right ----------
  late Map<String, String> _sides;
  late SidesMode _mode;
  late CrossfallDirection _leftDir, _rightDir;

  SidesMode get mode => _mode;
  CrossfallDirection get leftDirection => _leftDir;
  CrossfallDirection get rightDirection => _rightDir;

  set mode(SidesMode v) {
    _mode = v;
    _save();
  }

  set leftDirection(CrossfallDirection v) {
    _leftDir = v;
    _save();
  }

  set rightDirection(CrossfallDirection v) {
    _rightDir = v;
    _save();
  }

  /// From a saved calculation; a first start takes the Crossfall page's sides, if it was used,
  /// or 5 m at 2 % and 2.5 %, both falling away
  void _readSides(Map<String, Object?> j) {
    final page = _store.readJson('crossfall') ?? const {};
    String pick(String key, String pageKey, String fallback) =>
        (j[key] as String?) ?? (page[pageKey] as String?) ?? fallback;
    _sides = {
      'lo': pick('lo', 'ld', '5'),
      'lc': pick('lc', 'ls', '2'),
      'ro': pick('ro', 'rd', '5'),
      'rc': pick('rc', 'rs', '2.5'),
    };
    CrossfallDirection dir(Object? v) => CrossfallDirection.values.asNameMap()[v] ?? CrossfallDirection.fallAway;
    _leftDir = dir(j['ldir'] ?? page['ldir']);
    _rightDir = dir(j['rdir'] ?? page['rdir']);
    _mode = SidesMode.values.asNameMap()[j['sides']] ?? SidesMode.both;
  }

  Map<String, Object?> get _sidesJson => {
    ..._sides,
    'ldir': _leftDir.name,
    'rdir': _rightDir.name,
    'sides': _mode.name,
  };

  SidesInput get sides => SidesInput(
    mode: _mode,
    left: CrossfallSide(slopePercent: _number(text('lc')), distance: _number(text('lo')), direction: _leftDir),
    right: CrossfallSide(slopePercent: _number(text('rc')), distance: _number(text('ro')), direction: _rightDir),
  );
  int get decimals => _decimals;

  void setText(String field, String value) {
    final into = sideFields.contains(field) ? _sides : _texts;
    if (into[field] == value) return;
    into[field] = value;
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
  Map<String, Object?> toJson() => {..._texts, ..._sidesJson, 'decimals': _decimals, 'spacing': _settings.spacing.name};

  /// Opens a saved calculation
  void loadJson(Map<String, Object?> j) {
    _texts = {for (final f in fields) f: (j[f] as String?) ?? ''};
    _decimals = ((j['decimals'] as num?)?.toInt() ?? _decimals).clamp(1, 5);
    // a calculation saved before the sides came keeps the sides set now
    if (j.containsKey('sides')) _readSides(j);
    final spacing = StationSpacing.values.asNameMap()[j['spacing']];
    if (spacing != null) _settings.spacing = spacing;
    _save();
  }

  void clear() {
    _texts = {for (final f in fields) f: f == 'interval' ? _texts['interval']! : ''};
    _save();
  }

  void _save() {
    _store.writeJson(_key, {..._texts, ..._sidesJson, 'decimals': _decimals});
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

  /// The centreline with the sides, or null with [sidesProblem] (or [problem]) saying why
  FormationResult? get formationResult {
    final r = result;
    return r == null || sides.problem != null ? null : formation(r, sides);
  }

  String? get sidesProblem => sides.problem;

  @override
  void dispose() {
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}
