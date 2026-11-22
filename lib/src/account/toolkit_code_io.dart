// Opened some other way than from the Survey Toolkit (a desktop shortcut, the Start menu) and not
// signed in yet: the Toolkit on this PC, when there is one and it is signed in, gives a one-use
// sign-in code for its account (SurveyToolkit.exe --app-code=<id> --result=<file>), so the user
// signs in once, in the Toolkit.
import 'dart:convert';
import 'dart:io';

/// A one-use sign-in code for [app] from the Survey Toolkit on this PC; null when there is no
/// Toolkit, it isn't signed in, or it doesn't answer in time
Future<String?> askToolkitForCode(String app) async {
  // Not on Windows, or under `flutter test` (where no real Toolkit should be asked)
  if (!Platform.isWindows || Platform.environment.containsKey('FLUTTER_TEST')) return null;
  final exe = await _toolkitExe();
  if (exe == null) return null;
  Directory? dir;
  try {
    dir = await Directory.systemTemp.createTemp('toolkit-signin');
    final out = File('${dir.path}${Platform.pathSeparator}code.json');
    final p = await Process.start(exe, ['--app-code=$app', '--result=${out.path}']);
    await p.exitCode.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        p.kill();
        return -1;
      },
    );
    if (!out.existsSync()) return null;
    final code = (jsonDecode(await out.readAsString()) as Map)['code'];
    return code is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(code) ? code : null;
  } catch (_) {
    return null;
  } finally {
    try {
      dir?.deleteSync(recursive: true);
    } catch (_) {}
  }
}

/// Where the Toolkit is: as its installer recorded it, or its usual folder
Future<String?> _toolkitExe() async {
  final places = <String>[];
  try {
    final r = await Process.run('reg', ['query', r'HKCU\Software\SurveyToolkit', '/v', 'InstallDir']);
    final m = RegExp(r'InstallDir\s+REG_\w+\s+(.+)').firstMatch('${r.stdout}');
    if (m != null) places.add('${m.group(1)!.trim()}\\SurveyToolkit.exe');
  } catch (_) {}
  final local = Platform.environment['LOCALAPPDATA'];
  if (local != null) places.add('$local\\Survey Toolkit\\Program\\SurveyToolkit.exe');
  for (final p in places) {
    if (File(p).existsSync()) return p;
  }
  return null;
}
