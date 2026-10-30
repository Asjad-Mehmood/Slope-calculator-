// Self-update for the Windows program. A few seconds after it opens, it reads latest.json from
// the newest GitHub release. When that version is higher it asks; on Yes it downloads the
// installer, checks its SHA-256, runs it silently and closes; the installer opens the new version.
// Any network problem is ignored: the program carries on as normal.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../brand.dart';
import 'update_check.dart';

Future<void> checkForUpdate(BuildContext context) async {
  if (!Platform.isWindows || const bool.fromEnvironment('NO_UPDATE_CHECK')) return;
  await Future<void>.delayed(const Duration(seconds: 4));
  UpdateInfo? info;
  try {
    final r = await http.get(Uri.parse('$releaseBase$manifestName')).timeout(const Duration(seconds: 15));
    if (r.statusCode == 200) info = UpdateInfo.parse(r.body);
  } catch (_) {
    return; // offline or blocked: try again next time
  }
  if (info == null || !isNewer(info.version, appVersion) || !context.mounted) return;

  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('A new version is ready'),
      content: Text(
        '$appName ${info!.version} is available (you have $appVersion).\n\n'
        'Update now? The program closes, updates itself and opens again in a few seconds.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update now')),
      ],
    ),
  );
  if (yes != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context)
    ..showSnackBar(const SnackBar(content: Text('Downloading the update…'), duration: Duration(minutes: 5)));
  try {
    final r = await http.get(Uri.parse('$releaseBase$installerName')).timeout(const Duration(minutes: 5));
    if (r.statusCode != 200) throw HttpException('the server answered ${r.statusCode}');
    if (!sha256Matches(r.bodyBytes, info.sha256)) {
      throw const FileSystemException('the download was damaged (checksum)');
    }
    final file = File('${Directory.systemTemp.path}\\SlopeCalculator-Update.exe');
    await file.writeAsBytes(r.bodyBytes, flush: true);
    await Process.start(file.path, ['/S', '/UPDATE'], mode: ProcessStartMode.detached);
    exit(0);
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('The update could not be downloaded. Nothing was changed. ($e)')));
  }
}
