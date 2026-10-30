import 'package:flutter/material.dart';

import 'brand.dart';
import 'screens/calculator_screen.dart';
import 'screens/coming_soon_screen.dart';
import 'ui/app_shell.dart';
import 'ui/settings.dart';
import 'ui/theme.dart';

/// The app's frame. Light and dark follow the computer until the user picks one.
class SlopeCalculatorApp extends StatefulWidget {
  const SlopeCalculatorApp({super.key, this.settings});

  /// Passed in by tests; the app makes its own otherwise
  final AppSettings? settings;

  @override
  State<SlopeCalculatorApp> createState() => _SlopeCalculatorAppState();
}

class _SlopeCalculatorAppState extends State<SlopeCalculatorApp> {
  late final AppSettings _settings = widget.settings ?? AppSettings();

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
        home: HomeScreen(settings: _settings),
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
  const HomeScreen({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const CalculatorScreen(),
      const ComingSoonScreen(
        icon: Icons.add_road_outlined,
        phase: 4,
        text: 'Crossfall from the centreline, with a cross-section drawing.',
      ),
      const ComingSoonScreen(
        icon: Icons.straighten_outlined,
        phase: 4,
        text: 'The digital level simulator: a level run along your slope, booked by HI or Rise & Fall and checked.',
      ),
      const ComingSoonScreen(
        icon: Icons.folder_open_outlined,
        phase: 6,
        text: 'Sign in with your Excel to KML account to save calculations and open them on any device.',
      ),
      const ComingSoonScreen(
        icon: Icons.tune_outlined,
        phase: 3,
        text: 'Theme, text size, default decimals and interval, and the allowable misclosure.',
      ),
    ];
    return AppShell(
      destinations: destinations,
      selected: _page,
      onSelect: (i) => setState(() => _page = i),
      settings: widget.settings,
      headerActions: [
        if (_page == 0)
          OutlinedButton.icon(
            onPressed: () =>
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('The project plate comes in phase 3.'))),
            icon: const Icon(Icons.badge_outlined, size: 19),
            label: const Text('Project plate'),
          ),
      ],
      child: IndexedStack(index: _page, children: pages),
    );
  }
}
