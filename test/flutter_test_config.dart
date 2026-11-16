import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests read the Vietnamese copy, so the test device speaks Vietnamese;
/// a test that checks another language sets its own.
///
/// Starting a focus session waits for the `hifive/shield` channel, and an
/// unanswered channel never replies under the test clock, so it answers
/// "unavailable" as Android does; a test of blocking sets its own handler.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher.localesTestValue = const [Locale('vi')];
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('hifive/shield'),
    (call) async => call.method == 'start' ? 'unavailable' : null,
  );
  await testMain();
}
