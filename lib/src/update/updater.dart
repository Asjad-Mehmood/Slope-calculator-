// Self-update, on Windows only: export 'updater_io.dart' where there is a file system.
export 'updater_stub.dart' if (dart.library.io) 'updater_io.dart';
