import 'package:flutter/foundation.dart';

import '../calc/calc.dart';

/// The last level run taken to the end on the Level page, for the reports. Kept while the app is
/// open; a new line on the calculator clears it.
class LevelRunState extends ChangeNotifier {
  LevelRun? _run;
  BookingMethod _method = BookingMethod.heightOfInstrument;

  LevelRun? get run => _run;
  BookingMethod get method => _method;

  void finished(LevelRun run, BookingMethod method) {
    _run = run;
    _method = method;
    notifyListeners();
  }

  void clear() {
    if (_run == null) return;
    _run = null;
    notifyListeners();
  }

  /// The book as the report shows it: reduced by the method chosen on the Level page
  ReducedBook? get book {
    final r = _run;
    if (r == null) return null;
    if (_method == BookingMethod.heightOfInstrument) return r.book;
    return reduceBook([for (final p in r.points) p.reduced.row], openingLevel: r.slope.startLevel, method: _method);
  }
}
