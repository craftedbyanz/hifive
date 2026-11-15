import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/garden/garden.dart';

import '../../helpers.dart';

/// A stand-in for the iOS side of the `hifive/shield` channel.
class _FakeShield {
  var available = true, enabled = false, picked = 3;
  String? enableError;
  final calls = <String>[];

  Map<String, Object?> get status => {
    'available': available,
    'enabled': enabled,
    'picked': picked,
  };

  Future<Object?> handle(MethodCall call) async {
    calls.add(call.method);
    switch (call.method) {
      case 'enable':
        final on = (call.arguments as Map)['on'] == true;
        if (on && enableError != null) {
          throw PlatformException(code: enableError!);
        }
        enabled = on;
        return status;
      case 'status' || 'pick':
        return status;
      default:
        return null;
    }
  }
}

void main() {
  setUpAll(loadAppFonts);
  const channel = MethodChannel('hifive/shield');
  late _FakeShield shield;
  late DateTime clock;

  setUp(() {
    shield = _FakeShield();
    clock = DateTime(2026, 11, 15, 9);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, shield.handle);
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Future<void> openTimer(WidgetTester tester) async {
    await mount(tester, fresh(), FocusScreen(clock: () => clock));
    await tester.tap(find.byKey(const ValueKey('focus-timer-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('the timer sheet offers app blocking where the phone can', (
    tester,
  ) async {
    await openTimer(tester);
    expect(find.text('Chặn ứng dụng gây xao nhãng'), findsOneWidget);
    expect(find.text('Đang tắt'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shield-switch')));
    await tester.pumpAndSettle();
    expect(shield.calls, contains('enable'));
    expect(find.text('Đã chọn 3 mục · Đổi'), findsOneWidget);
  });

  testWidgets('no switch where blocking is not possible', (tester) async {
    shield.available = false;
    await openTimer(tester);
    expect(find.byKey(const ValueKey('shield-switch')), findsNothing);
  });

  testWidgets('a build without the entitlement says why', (tester) async {
    shield.enableError = 'unavailable';
    await openTimer(tester);
    await tester.tap(find.byKey(const ValueKey('shield-switch')));
    await tester.pump();
    expect(
      find.text('Bản cài này chưa được Apple cho phép chặn ứng dụng.'),
      findsOneWidget,
    );
    expect(find.text('Đang tắt'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('a session shields apps while it runs and lifts the shield', (
    tester,
  ) async {
    shield.enabled = true;
    await openTimer(tester);
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    expect(shield.calls.last, 'start');

    await tester.tap(find.byKey(const ValueKey('focus-cancel')));
    await tester.pump();
    expect(shield.calls.last, 'stop');
  });
}
