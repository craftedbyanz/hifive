import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/profile/profile.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);
  const channel = MethodChannel('hifive/screen');

  void allow(bool granted) => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'prepareWarning' ? granted : null,
      );
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets('the reminder turns on when notifications are allowed', (
    tester,
  ) async {
    allow(true);
    final state = fresh();
    await mount(tester, state, const NotificationScreen());
    await tester.tap(find.byKey(const ValueKey('reminder-toggle')));
    await tester.pumpAndSettle();
    expect(state.reminderOn, isTrue);
  });

  testWidgets('a refused permission says where to turn it on', (tester) async {
    allow(false);
    final state = fresh();
    await mount(tester, state, const NotificationScreen());
    await tester.tap(find.byKey(const ValueKey('reminder-toggle')));
    await tester.pump();
    expect(state.reminderOn, isFalse);
    expect(
      find.text(
        'hifive chưa được phép gửi thông báo. Bật trong Cài đặt → hifive → Thông báo.',
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
