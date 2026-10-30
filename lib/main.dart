import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/state/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.open();
  runApp(SlopeCalculatorApp(store: store));
}
