import 'dart:js_interop';
import 'package:firebase_core/firebase_core.dart';

@JS('prepareAttendanceLocalFirebase')
external JSPromise<JSAny?> _prepare(JSObject options, JSString host);
Future<void> prepareLocalWebFirebase(
  FirebaseOptions options,
  String host,
) async {
  await _prepare(options.asMap.jsify() as JSObject, host.toJS).toDart;
}
