import 'package:flutter/material.dart';

import 'brand.dart';
import 'screens/calculator_screen.dart';
import 'screens/coming_soon_screen.dart';
import 'screens/crossfall_screen.dart';
import 'screens/level_screen.dart';
import 'screens/project_plate_screen.dart';
import 'screens/settings_screen.dart';
import 'state/calculation.dart';
import 'state/project_plate.dart';
import 'state/store.dart';
import 'ui/app_shell.dart';
import 'ui/settings.dart';
import 'ui/theme.dart';

/// The app's frame. Light and dark follow the computer until the user picks one.
class SlopeCalculatorApp extends StatefulWidget {
  const SlopeCalculatorApp({super.key, this.store});

  /// Where settings and inputs are remembered; tests pass [Store.memory]
  final Store? store;

  @override
  State<SlopeCalculatorApp> createState() => _SlopeCalculatorAppState();
}

class _SlopeCalculatorAppState extends State<SlopeCalculatorApp> {
  late final Store _store = widget.store ?? Store.memory();
  late final AppSettings _settings = AppSettings(_store);
  late final Calculation _calculation = Calculation(_store, _settings);
  late final ProjectPlate _plate = ProjectPlate(_store);

  @override
  void dispose() {
    _calculation.dispose();
    _plate.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: _settings.themeMode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_settings.textScale)),
          child: child!,
        ),
        home: HomeScreen(settings: _settings, calculation: _calculation, plate: _plate, store: _store),
      ),
    );
  }
}

const destinations = [
  Destination(
    label: 'Calculator',
    icon: Icons.calculate_outlined,
    title: 'Slope calculator',
    subtitle: 'Slope, gradient and the level at every chainage',
  ),
  Destination(
    label: 'Crossfall',
    icon: Icons.add_road_outlined,
    title: 'Crossfall',
    subtitle: 'Levels left and right of the centreline',
  ),
  Destination(
    label: 'Level',
    icon: Icons.straighten_outlined,
    title: 'Digital level',
    subtitle: 'A level run along your slope, booked and checked',
  ),
  Destination(
    label: 'Saved',
    icon: Icons.folder_open_outlined,
    title: 'Saved calculations',
    subtitle: 'Your calculations in your Excel to KML account',
  ),
  Destination(label: 'Settings', icon: Icons.tune_outlined, title: 'Settings', subtitle: 'Units, decimals and display'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.calculation,
    required this.plate,
    required this.store,
  });
  final AppSettings settings;
  final Store store;
  final Calculation calculation;
  final ProjectPlate plate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      CalculatorScreen(calculation: widget.calculation),
      CrossfallScreen(store: widget.store),
      LevelScreen(calculation: widget.calculation, settings: widget.settings, store: widget.store),
      const ComingSoonScreen(
        icon: Icons.folder_open_outlined,
        phase: 6,
        text: 'Sign in with your Excel to KML account to save calculations and open them on any device.',
      ),
      SettingsScreen(settings: widget.settings),
    ];
    return AppShell(
      destinations: destinations,
      selected: _page,
      onSelect: (i) => setState(() => _page = i),
      settings: widget.settings,
      headerActions: [if (_page == 0) ProjectPlateButton(plate: widget.plate)],
      child: IndexedStack(
        index: _page,
        children: [
          // only the page on screen runs its animations
          for (var i = 0; i < pages.length; i++) TickerMode(enabled: i == _page, child: pages[i]),
        ],
      ),
    );
  }
}
