import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

  /// The phone answers [status] about notifications and records each call.
  List<String> answer(String status) {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'notificationStatus' => status,
            'prepareWarning' => true,
            _ => null,
          };
        });
    return calls;
  }

  testWidgets('notifications off in Settings show the reminder as blocked', (
    tester,
  ) async {
    answer('denied');
    final state = fresh()..setReminder(on: true);
    await mount(tester, state, const NotificationScreen());
    await tester.pumpAndSettle();
    final toggle = tester.widget<CupertinoSwitch>(
      find.byKey(const ValueKey('reminder-toggle')),
    );
    expect(toggle.value, isFalse);
    expect(find.byKey(const ValueKey('reminder-blocked')), findsOneWidget);
    expect(find.text('Chưa bật trong Cài đặt'), findsOneWidget);
    // The learner's choice stays, for when they turn notifications back on.
    expect(state.reminderOn, isTrue);
  });

  testWidgets('allowed notifications read as on', (tester) async {
    answer('allowed');
    final state = fresh()..setReminder(on: true);
    await mount(tester, state, const NotificationScreen());
    await tester.pumpAndSettle();
    expect(find.text('Đang bật'), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder-blocked')), findsNothing);
  });

  testWidgets('a phone never asked offers to allow instead of Settings', (
    tester,
  ) async {
    final calls = answer('unasked');
    final state = fresh();
    await mount(tester, state, const NotificationScreen());
    await tester.pumpAndSettle();
    expect(find.text('Chưa cấp quyền cho hifive'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('notification-settings')));
    await tester.pumpAndSettle();
    expect(calls, contains('prepareWarning'));
  });
}
