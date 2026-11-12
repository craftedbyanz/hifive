import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Tests read the Vietnamese copy, so the test device speaks Vietnamese;
/// a test that checks another language sets its own.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .localesTestValue = const [
    Locale('vi'),
  ];
  await testMain();
}
