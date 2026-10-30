import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:slope_calculator/src/update/update_check.dart';

void main() {
  test('versions compare by number, not as text', () {
    expect(isNewer('1.0.1', '1.0.0'), isTrue);
    expect(isNewer('1.2.10', '1.2.9'), isTrue);
    expect(isNewer('2.0.0', '1.99.99'), isTrue);
    expect(isNewer('1.0.0', '1.0.0'), isFalse);
    expect(isNewer('1.0.0', '1.0.1'), isFalse);
  });

  test('latest.json is read, and anything else is ignored', () {
    final h = 'a' * 64;
    expect(UpdateInfo.parse('{"version":"1.0.1","sha256":"${h.toUpperCase()}"}')!.sha256, h);
    expect(UpdateInfo.parse('{"version":"1.0","sha256":"$h"}'), isNull);
    expect(UpdateInfo.parse('{"version":"1.0.1","sha256":"abc"}'), isNull);
    expect(UpdateInfo.parse('<html>Not found</html>'), isNull);
    expect(UpdateInfo.parse('[]'), isNull);
  });

  test('the download is checked against its SHA-256', () {
    final bytes = utf8.encode('installer');
    const digest = '9c0d294c05fc1d88d698034609bb81c0c69196327594e4c69d2915c80fd9850c';
    expect(sha256Matches(bytes, digest), isTrue);
    expect(sha256Matches(bytes, digest.toUpperCase()), isTrue);
    expect(sha256Matches(utf8.encode('installer!'), digest), isFalse);
  });

  test('installed copies read from the public repository', () {
    expect(releaseBase, 'https://github.com/Asjad-Mehmood/slope-calculator-/releases/latest/download/');
    expect(installerName, 'SlopeCalculator-Setup.exe');
  });
}
