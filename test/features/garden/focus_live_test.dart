import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/core/services/focus_live.dart';
import 'package:hifive/domain/garden/garden.dart';
import 'package:hifive/features/garden/garden.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);
  const channel = MethodChannel('hifive/live');
  late List<MethodCall> calls;
  late DateTime clock;
  late AppState state;

  setUp(() {
    calls = [];
    clock = DateTime(2026, 11, 15, 9);
    state = fresh();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Future<void> startSession(WidgetTester tester) async {
    await mount(tester, state, FocusScreen(clock: () => clock));
    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pump();
  }

  /// The ✕ on the lock screen, as the iOS side sends it.
  Future<void> tapCross(WidgetTester tester) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'hifive/live',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('stop'),
          ),
          (_) {},
        );
    await tester.pump();
  }

  testWidgets('a session shows on the lock screen until it ends', (
    tester,
  ) async {
    await startSession(tester);
    final start = calls.firstWhere((c) => c.method == 'start');
    final args = start.arguments as Map;
    expect(args['start'], clock.millisecondsSinceEpoch.toDouble());
    expect(
      args['end'],
      clock.add(const Duration(minutes: 25)).millisecondsSinceEpoch.toDouble(),
    );
    expect(args['tag'], isNotEmpty);
    expect(args['color'], matches(RegExp(r'^#[0-9A-F]{6}$')));

    await tester.tap(find.byKey(const ValueKey('focus-cancel')));
    await tester.pump();
    expect(calls.last.method, 'end');
  });

  testWidgets('the cross cancels in the first seconds', (tester) async {
    await startSession(tester);
    clock = clock.add(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    await tapCross(tester);
    expect(state.focusSessions, isEmpty);
    expect(find.byKey(const ValueKey('focus-start')), findsOneWidget);
    expect(calls.last.method, 'end');
  });

  testWidgets('the cross gives up after the first seconds', (tester) async {
    await startSession(tester);
    clock = clock.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 1));
    await tapCross(tester);
    expect(state.focusSessions.single.outcome, FocusOutcome.withered);
    expect(state.focusSessions.single.minutes, 3);
  });

  test('colours go to the widget as #RRGGBB', () {
    expect(FocusLive.hex(const Color(0xFF4C52D2)), '#4C52D2');
    expect(FocusLive.hex(const Color(0x80FFD166)), '#FFD166');
  });
}
