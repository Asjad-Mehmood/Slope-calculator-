import 'package:flutter/material.dart';

/// Settings the frame needs everywhere: light or dark, and the text size. Kept in memory for
/// now; phase 3 remembers them between sessions.
class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1;

  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (value == _themeMode) return;
    _themeMode = value;
    notifyListeners();
  }

  static const minTextScale = 0.85;
  static const maxTextScale = 1.3;

  /// 85 % to 130 %
  double get textScale => _textScale;
  set textScale(double value) {
    final v = (value * 100).round().clamp(minTextScale * 100, maxTextScale * 100) / 100;
    if (v == _textScale) return;
    _textScale = v;
    notifyListeners();
  }

  bool get canShrinkText => _textScale > minTextScale;
  bool get canGrowText => _textScale < maxTextScale;
  void shrinkText() => textScale = _textScale - 0.05;
  void growText() => textScale = _textScale + 0.05;

  /// Light → dark → following the computer → light
  void cycleTheme(Brightness current) {
    themeMode = switch (_themeMode) {
      ThemeMode.system => current == Brightness.light ? ThemeMode.dark : ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
    };
  }
}
