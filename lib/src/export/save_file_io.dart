import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

/// Asks where to save [bytes] as [name]; returns the path, or null if the dialog was cancelled.
Future<String?> saveFile(String name, Uint8List bytes, {required String mime, required String extension}) async {
  final location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: [
      XTypeGroup(label: extension.toUpperCase(), extensions: [extension], mimeTypes: [mime]),
    ],
  );
  if (location == null) return null;
  var path = location.path;
  if (!path.toLowerCase().endsWith('.$extension')) path = '$path.$extension';
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}
