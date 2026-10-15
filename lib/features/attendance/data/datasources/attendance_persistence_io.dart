import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:attendance_tracker/core/config/app_environment.dart';

Future<File> _file() async {
  final directory = await getApplicationDocumentsDirectory();
  return File('${directory.path}/${AppConfig.queueFile}');
}

Future<String?> readPayload() async {
  final file = await _file();
  return await file.exists() ? file.readAsString() : null;
}

Future<void> writePayload(String payload) async {
  final file = await _file();
  final temporary = File('${file.path}.tmp');
  await temporary.writeAsString(payload, flush: true);
  await temporary.rename(file.path);
}

Future<T> withPersistenceLock<T>(Future<T> Function() action) => action();
