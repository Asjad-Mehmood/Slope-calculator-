import 'package:flutter/material.dart';

import '../calc/calc.dart';
import '../state/store.dart';

/// The user's settings, remembered on this device.
class AppSettings extends ChangeNotifier {
  AppSettings([Store? store]) : _store = store ?? Store.memory() {
    final j = _store.readJson(_key) ?? const {};
    _themeMode = ThemeMode.values.asNameMap()[j['theme']] ?? ThemeMode.system;
    _textScale = _clampScale((j['textScale'] as num?)?.toDouble() ?? 1);
    _decimals = ((j['decimals'] as num?)?.toInt() ?? 3).clamp(1, 5);
    _interval = (j['interval'] as num?)?.toDouble() ?? 20;
    if (!(_interval > 0)) _interval = 20;
    _spacing = StationSpacing.values.asNameMap()[j['spacing']] ?? StationSpacing.roundChainages;
    _allowableC = (j['allowableC'] as num?)?.toDouble() ?? 12;
    if (!(_allowableC > 0)) _allowableC = 12;
  }

  final Store _store;
  static const _key = 'settings';

  late ThemeMode _themeMode;
  late double _textScale;
  late int _decimals;
  late double _interval;
  late StationSpacing _spacing;
  late double _allowableC;

  void _changed() {
    _store.writeJson(_key, {
      'theme': _themeMode.name,
      'textScale': _textScale,
      'decimals': _decimals,
      'interval': _interval,
      'spacing': _spacing.name,
      'allowableC': _allowableC,
    });
    notifyListeners();
  }

  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (value == _themeMode) return;
    _themeMode = value;
    _changed();
  }

  static const minTextScale = 0.85;
  static const maxTextScale = 1.3;
  static double _clampScale(double v) => (v * 100).round().clamp(minTextScale * 100, maxTextScale * 100) / 100;

  /// 85 % to 130 %
  double get textScale => _textScale;
  set textScale(double value) {
    final v = _clampScale(value);
    if (v == _textScale) return;
    _textScale = v;
    _changed();
  }

  bool get canShrinkText => _textScale > minTextScale;
  bool get canGrowText => _textScale < maxTextScale;
  void shrinkText() => textScale = _textScale - 0.05;
  void growText() => textScale = _textScale + 0.05;

  /// Light ↔ dark, from whatever is showing now
  void cycleTheme(Brightness current) {
    themeMode = current == Brightness.light ? ThemeMode.dark : ThemeMode.light;
  }

  /// Decimals for levels in a new calculation
  int get decimals => _decimals;
  set decimals(int value) {
    final v = value.clamp(1, 5);
    if (v == _decimals) return;
    _decimals = v;
    _changed();
  }

  /// The interval a new calculation starts with
  double get interval => _interval;
  set interval(double value) {
    if (!(value > 0) || value == _interval) return;
    _interval = value;
    _changed();
  }

  StationSpacing get spacing => _spacing;
  set spacing(StationSpacing value) {
    if (value == _spacing) return;
    _spacing = value;
    _changed();
  }

  /// C in the allowable misclosure C√K mm for level runs
  double get allowableC => _allowableC;
  set allowableC(double value) {
    if (!(value > 0) || value == _allowableC) return;
    _allowableC = value;
    _changed();
  }

  void reset() {
    _themeMode = ThemeMode.system;
    _textScale = 1;
    _decimals = 3;
    _interval = 20;
    _spacing = StationSpacing.roundChainages;
    _allowableC = 12;
    _changed();
  }
}
