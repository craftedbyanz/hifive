import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/core/services/screen_lock.dart';
import 'package:hifive/domain/garden/garden.dart';
import 'package:hifive/features/garden/garden.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  late DateTime clock;
  late AppState state;

  setUp(() {
    clock = DateTime(2026, 11, 13, 9);
    state = fresh();
    ScreenLock.locked.value = false;
  });

  Future<void> open(WidgetTester tester) =>
      mount(tester, state, FocusScreen(clock: () => clock));

  /// Sets the timer by dragging the ruler from 25 minutes, then starts.
  Future<void> start(WidgetTester tester, {int minutes = 10}) async {
    await tester.tap(find.byKey(const ValueKey('focus-timer-button')));
    await tester.pumpAndSettle();
    final marks = (25 - minutes) ~/ minuteStep;
    await tester.timedDrag(
      find.byKey(const ValueKey('timer-ruler')),
      Offset(marks * MinuteRuler.spacing, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
  }

  Future<void> wait(WidgetTester tester, Duration d) async {
    clock = clock.add(d);
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> lifecycle(
    WidgetTester tester,
    List<AppLifecycleState> states,
  ) async {
    for (final s in states) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
  }

  const away = [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ];
  const back = [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ];

  testWidgets('a session that runs to the end plants a tree', (tester) async {
    await open(tester);
    await start(tester);
    await wait(tester, const Duration(minutes: 4));
    expect(find.text('06:00'), findsOneWidget);
    await wait(tester, const Duration(minutes: 6));

    final s = state.focusSessions.single;
    expect(s.outcome, FocusOutcome.done);
    expect(s.minutes, 10);
    expect(find.text('Hoàn thành 10 phút'), findsOneWidget);
  });

  testWidgets('the first seconds can be cancelled without a tree', (
    tester,
  ) async {
    await open(tester);
    await start(tester);
    await wait(tester, const Duration(seconds: 3));
    expect(find.text('Huỷ (7)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('focus-cancel')));
    await tester.pump();

    expect(state.focusSessions, isEmpty);
    expect(find.byKey(const ValueKey('focus-start')), findsOneWidget);
  });

  testWidgets('giving up after the first seconds withers the tree', (
    tester,
  ) async {
    await open(tester);
    await start(tester);
    await wait(tester, const Duration(minutes: 3));
    await tester.tap(find.byKey(const ValueKey('focus-give-up')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ cuộc').last);
    await tester.pumpAndSettle();

    final s = state.focusSessions.single;
    expect(s.outcome, FocusOutcome.withered);
    expect(s.minutes, 3);
    expect(find.text('Không sao, thử lại nhé'), findsOneWidget);
  });

  testWidgets('leaving the app for more than 30 seconds withers the tree', (
    tester,
  ) async {
    await open(tester);
    await start(tester);
    await wait(tester, const Duration(minutes: 2));
    await lifecycle(tester, away);
    clock = clock.add(const Duration(seconds: 45));
    await lifecycle(tester, back);

    expect(state.focusSessions.single.outcome, FocusOutcome.withered);
  });

  testWidgets('a short look at another app keeps the session', (tester) async {
    await open(tester);
    await start(tester);
    await wait(tester, const Duration(minutes: 2));
    await lifecycle(tester, away);
    clock = clock.add(const Duration(seconds: 20));
    await lifecycle(tester, back);

    expect(state.focusSessions, isEmpty);
    expect(find.byKey(const ValueKey('focus-give-up')), findsOneWidget);
  });

  testWidgets('a locked phone keeps growing the tree', (tester) async {
    await open(tester);
    await start(tester);
    await wait(tester, const Duration(minutes: 2));
    await lifecycle(tester, away);
    ScreenLock.locked.value = true;
    clock = clock.add(const Duration(minutes: 9));
    ScreenLock.locked.value = false;
    await lifecycle(tester, back);
    await tester.pump(const Duration(seconds: 1));

    expect(state.focusSessions.single.outcome, FocusOutcome.done);
  });

  testWidgets('a locked species cannot be chosen', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('focus-change-tree')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('focus-species-galaxy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-species-galaxy')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('focus-species-pine')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-tree-pine')), findsOneWidget);
  });

  testWidgets('dragging the ruler knocks once per mark it crosses', (
    tester,
  ) async {
    final knocks = _Knocks();
    state = fresh(feedback: knocks);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('focus-timer-button')));
    await tester.pumpAndSettle();
    await tester.timedDrag(
      find.byKey(const ValueKey('timer-ruler')),
      const Offset(-4 * MinuteRuler.spacing, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(find.text('45 phút'), findsOneWidget);
    expect(knocks.taps, 4);
  });

  testWidgets('the stopwatch counts up and plants a tree after 10 minutes', (
    tester,
  ) async {
    await open(tester);
    await start(tester, minutes: 0);
    await wait(tester, const Duration(minutes: 12));
    expect(find.text('12:00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('focus-stop')));
    await tester.pumpAndSettle();

    final s = state.focusSessions.single;
    expect(s.outcome, FocusOutcome.done);
    expect(s.plannedMinutes, 0);
    expect(s.minutes, 12);
  });

  testWidgets('the session title is saved with the session', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('focus-title')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('session-title-field')),
      'Ôn IELTS',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Ôn IELTS'), findsOneWidget);

    await start(tester);
    await wait(tester, const Duration(minutes: 10));
    expect(state.focusSessions.single.title, 'Ôn IELTS');
  });
}

class _Knocks extends SilentFeedback {
  var taps = 0;
  @override
  void tap() => taps++;
}
