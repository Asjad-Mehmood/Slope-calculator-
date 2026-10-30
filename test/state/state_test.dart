import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slope_calculator/src/calc/calc.dart';
import 'package:slope_calculator/src/state/calculation.dart';
import 'package:slope_calculator/src/state/project_plate.dart';
import 'package:slope_calculator/src/state/store.dart';
import 'package:slope_calculator/src/ui/settings.dart';

void main() {
  group('settings', () {
    test('are remembered by the store', () {
      final store = Store.memory();
      AppSettings(store)
        ..themeMode = ThemeMode.dark
        ..textScale = 1.15
        ..decimals = 4
        ..interval = 25
        ..spacing = StationSpacing.fromStart
        ..allowableC = 8;
      final again = AppSettings(store);
      expect(again.themeMode, ThemeMode.dark);
      expect(again.textScale, 1.15);
      expect(again.decimals, 4);
      expect(again.interval, 25);
      expect(again.spacing, StationSpacing.fromStart);
      expect(again.allowableC, 8);
    });

    test('bad stored values fall back to the defaults', () {
      final store = Store.memory()
        ..write('settings', '{"theme":"purple","textScale":9,"decimals":0,"interval":-5,"allowableC":0}');
      final s = AppSettings(store);
      expect(s.themeMode, ThemeMode.system);
      expect(s.textScale, 1.3);
      expect(s.decimals, 1);
      expect(s.interval, 20);
      expect(s.allowableC, 12);
    });

    test('broken storage is ignored', () {
      final store = Store.memory()..write('settings', 'not json');
      expect(AppSettings(store).decimals, 3);
    });

    test('reset puts everything back', () {
      final s = AppSettings(Store.memory())
        ..decimals = 5
        ..themeMode = ThemeMode.light;
      s.reset();
      expect(s.decimals, 3);
      expect(s.themeMode, ThemeMode.system);
    });

    test('the theme switch goes from what is showing to the other', () {
      final s = AppSettings(Store.memory());
      s.cycleTheme(Brightness.light);
      expect(s.themeMode, ThemeMode.dark);
      s.cycleTheme(Brightness.dark);
      expect(s.themeMode, ThemeMode.light);
    });
  });

  group('the calculation', () {
    test('starts with the V28 example, and the interval from settings', () {
      final store = Store.memory();
      final settings = AppSettings(store)..interval = 25;
      final c = Calculation(store, settings);
      expect(c.text('y1'), '102.500');
      expect(c.text('interval'), '25');
      expect(c.result, isNotNull);
    });

    test('is remembered as typed', () {
      final store = Store.memory();
      final settings = AppSettings(store);
      Calculation(store, settings)
        ..setText('y1', '5')
        ..decimals = 2;
      final again = Calculation(store, settings);
      expect(again.text('y1'), '5');
      expect(again.decimals, 2);
    });

    test('reads chainages typed either way and follows the station setting', () {
      final store = Store.memory();
      final settings = AppSettings(store);
      final c = Calculation(store, settings)
        ..load({'y1': '10', 'y2': '11', 'x1': '1+013', 'x2': '1100', 'interval': '20'});
      expect(c.result!.stations[1].label, '1+020');
      settings.spacing = StationSpacing.fromStart;
      expect(c.result!.stations[1].label, '1+033');
    });

    test('a problem instead of a result', () {
      final store = Store.memory();
      final c = Calculation(store, AppSettings(store))..setText('x2', 'abc');
      expect(c.result, isNull);
      expect(c.problem, 'Enter all values.');
    });

    test('clear keeps the interval', () {
      final store = Store.memory();
      final c = Calculation(store, AppSettings(store))..clear();
      expect(c.text('y1'), '');
      expect(c.text('interval'), '20');
    });
  });

  group('the project plate', () {
    test('saves the filled fields and forgets the empty ones', () {
      final store = Store.memory();
      ProjectPlate(store).save({'project': '  Ring Road  ', 'client': '', 'revision': 'Rev. 1'});
      final again = ProjectPlate(store);
      expect(again.projectName, 'Ring Road');
      expect(again['revision'], 'Rev. 1');
      expect(again['client'], '');
      expect(again.filled, 2);
    });

    test('has the Excel template fields, each once', () {
      final keys = plateFields.map((f) => f.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      expect(keys, hasLength(16));
    });
  });

  test('the device store keeps values between starts', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await Store.open();
    first.write('x', '1');
    final second = await Store.open();
    expect(second.read('x'), '1');
  });
}
