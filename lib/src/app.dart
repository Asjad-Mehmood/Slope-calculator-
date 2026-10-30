import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'account/account.dart';
import 'account/api.dart';
import 'account/http_client.dart';

import 'brand.dart';
import 'export/export_button.dart';
import 'screens/calculator_screen.dart';
import 'screens/crossfall_screen.dart';
import 'screens/level_screen.dart';
import 'screens/project_plate_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sign_in_screen.dart';
import 'state/calculation.dart';
import 'state/level_run_state.dart';
import 'state/project_plate.dart';
import 'state/store.dart';
import 'ui/app_shell.dart';
import 'ui/settings.dart';
import 'ui/theme.dart';
import 'update/updater.dart';

/// The app's frame. Light and dark follow the computer until the user picks one.
class SlopeCalculatorApp extends StatefulWidget {
  const SlopeCalculatorApp({super.key, this.store, this.api, this.checkForUpdates = false});

  /// Look for a newer version once open (the Windows program). Only main() turns it on, so tests
  /// never leave the check's timer and download running.
  final bool checkForUpdates;

  /// The website connection; tests pass one that answers from memory
  final Api? api;

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
  final _levelRun = LevelRunState();
  late final Account _account = Account(
    widget.api ?? Api(base: defaultApiBase(), client: makeClient(), platform: kIsWeb ? 'web' : 'windows'),
    _store,
  );

  // back in front (or online again on a phone): send calculations saved while offline
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_account.signedIn && _account.waiting > 0) _account.refresh();
      },
    );
    _account.restore();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _calculation.dispose();
    _plate.dispose();
    _levelRun.dispose();
    _account.dispose();
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
        home: _SignedInOnly(
          account: _account,
          settings: _settings,
          checkForUpdates: widget.checkForUpdates,
          // the app itself, built once signed in
          app: () => HomeScreen(
            settings: _settings,
            calculation: _calculation,
            plate: _plate,
            store: _store,
            levelRun: _levelRun,
            account: _account,
          ),
        ),
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

/// The app is used signed in: the sign-in screen until the account is known (remembered on this
/// device, or on the web the website's sign-in), then the app. Signing out comes back here. The
/// Windows program looks for a newer version either way.
class _SignedInOnly extends StatefulWidget {
  const _SignedInOnly({
    required this.account,
    required this.settings,
    required this.app,
    required this.checkForUpdates,
  });
  final Account account;
  final AppSettings settings;
  final Widget Function() app;
  final bool checkForUpdates;

  @override
  State<_SignedInOnly> createState() => _SignedInOnlyState();
}

class _SignedInOnlyState extends State<_SignedInOnly> {
  @override
  void initState() {
    super.initState();
    if (widget.checkForUpdates) {
      WidgetsBinding.instance.addPostFrameCallback((_) => checkForUpdate(context));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.account,
    builder: (context, _) =>
        widget.account.signedIn ? widget.app() : SignInScreen(account: widget.account, settings: widget.settings),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.calculation,
    required this.plate,
    required this.store,
    required this.levelRun,
    required this.account,
  });
  final Account account;
  final AppSettings settings;
  final LevelRunState levelRun;
  final Store store;
  final Calculation calculation;
  final ProjectPlate plate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _page = 0;

  late final _exporter = Exporter(
    calculation: widget.calculation,
    plate: widget.plate,
    store: widget.store,
    levelRun: widget.levelRun,
  );

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      CalculatorScreen(calculation: widget.calculation),
      CrossfallScreen(store: widget.store),
      LevelScreen(
        calculation: widget.calculation,
        settings: widget.settings,
        store: widget.store,
        levelRun: widget.levelRun,
      ),
      SavedScreen(
        account: widget.account,
        calculation: widget.calculation,
        plate: widget.plate,
        onOpened: () => setState(() => _page = 0),
      ),
      SettingsScreen(settings: widget.settings),
    ];
    return AppShell(
      destinations: destinations,
      selected: _page,
      onSelect: (i) => setState(() => _page = i),
      settings: widget.settings,
      account: widget.account,
      onAccount: () => setState(() => _page = 3),
      headerActions: [
        if (_page == 0) ...[
          ProjectPlateButton(plate: widget.plate),
          const SizedBox(width: 8),
          ExportButton(exporter: _exporter),
        ],
      ],
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
