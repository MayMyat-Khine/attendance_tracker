import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:attendance_tracker/core/config/app_environment.dart';

Future<String?> readPayload() async =>
    web.window.localStorage.getItem(AppConfig.queueFile);
Future<void> writePayload(String payload) async =>
    web.window.localStorage.setItem(AppConfig.queueFile, payload);
Future<T> withPersistenceLock<T>(Future<T> Function() action) async {
  late T result;
  Object? failure;
  StackTrace? failureStack;
  Future<JSAny?> run() async {
    try {
      result = await action();
    } catch (error, stack) {
      failure = error;
      failureStack = stack;
    }
    return null;
  }

  await web.window.navigator.locks
      .request(
        'attendance:${AppConfig.queueFile}',
        ((JSAny? _) => run().toJS).toJS,
      )
      .toDart;
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
  return result;
}
