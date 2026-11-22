import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/state/store.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.open();
  runApp(SlopeCalculatorApp(store: store, checkForUpdates: true, signinCode: signinCodeFrom(args)));
}

/// The code after `--signin-code=`, when the Survey Toolkit opened it
String? signinCodeFrom(List<String> args) {
  for (final a in args) {
    if (a.startsWith('--signin-code=')) return a.substring('--signin-code='.length);
  }
  return null;
}
