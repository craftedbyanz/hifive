import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/garden/garden.dart';

import '../../helpers.dart';

/// A stand-in for the iOS side of the `hifive/shield` channel: `start`
/// answers [answer] and the shield is up until `stop`.
class _FakeShield {
  var answer = 'on';
  var up = false;

  /// When set, `start` fails with this reason, as an iOS error does.
  String? failure;
  final calls = <String>[];

  Future<Object?> handle(MethodCall call) async {
    calls.add(call.method);
    switch (call.method) {
      case 'start':
        if (failure != null) {
          throw PlatformException(code: 'failed', message: failure);
        }
        up = answer == 'on';
        return answer;
      case 'stop':
        up = false;
        return null;
      default:
        throw MissingPluginException();
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

  Future<void> openFocus(WidgetTester tester) async {
    await mount(tester, fresh(), FocusScreen(clock: () => clock));
    await tester.pumpAndSettle();
  }

  testWidgets('there is no switch: Bắt đầu blocks every other app', (
    tester,
  ) async {
    await openFocus(tester);
    expect(find.text('Chặn ứng dụng gây xao nhãng'), findsNothing);
    expect(find.byKey(const ValueKey('shield-switch')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pump();
    expect(shield.calls, ['start']);
    expect(shield.up, isTrue);
    expect(find.byKey(const ValueKey('focus-cancel')), findsOneWidget);
    expect(find.text('Đang chặn ứng dụng khác'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('focus-cancel')));
    await tester.pump();
    expect(shield.calls, ['start', 'stop']);
    expect(shield.up, isFalse);
  });

  testWidgets('the timer sheet has no switch and starts the same way', (
    tester,
  ) async {
    await openFocus(tester);
    await tester.tap(find.byKey(const ValueKey('focus-timer-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shield-switch')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    expect(shield.up, isTrue);
    await tester.tap(find.byKey(const ValueKey('focus-cancel')));
    await tester.pump();
    expect(shield.up, isFalse);
  });

  testWidgets('declining Screen Time still starts, and says how to allow it', (
    tester,
  ) async {
    shield.answer = 'declined';
    await openFocus(tester);
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pump();
    expect(find.byKey(const ValueKey('focus-cancel')), findsOneWidget);
    expect(
      find.text(
        'Hãy cho phép quyền Thời gian sử dụng trong Cài đặt để chặn ứng dụng.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('focus-cancel')));
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('access refused before still says how to allow it', (
    tester,
  ) async {
    shield.answer = 'denied';
    await openFocus(tester);
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pump();
    expect(find.byKey(const ValueKey('focus-cancel')), findsOneWidget);
    expect(find.textContaining('Thời gian sử dụng'), findsOneWidget);
    expect(find.byKey(const ValueKey('focus-shielded')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('focus-cancel')));
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('an error from the phone is shown with its reason', (
    tester,
  ) async {
    shield.failure = 'FamilyControlsError.restricted';
    await openFocus(tester);
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pump();
    expect(find.byKey(const ValueKey('focus-cancel')), findsOneWidget);
    expect(
      find.text('Chưa chặn được ứng dụng khác: FamilyControlsError.restricted'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('focus-shielded')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('focus-cancel')));
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('without blocking (Android) nothing is said about it', (
    tester,
  ) async {
    shield.answer = 'unavailable';
    await openFocus(tester);
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pump();
    expect(find.byKey(const ValueKey('focus-shielded')), findsNothing);
    expect(find.textContaining('chặn'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('focus-cancel')));
    await tester.pump();
  });

  testWidgets('a second tap while waiting starts one session', (tester) async {
    await openFocus(tester);
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pump();
    expect(shield.calls.where((c) => c == 'start'), hasLength(1));
    await tester.tap(find.byKey(const ValueKey('focus-cancel')));
    await tester.pump();
  });
}
