import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/core/services/screen_lock.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/garden/garden.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/garden/garden.dart';
import 'package:hifive/l10n/l10n.dart';
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

  testWidgets('the tree is changed by tapping it, only before starting', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Đổi cây'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('focus-change-tree')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('focus-species-pine')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-tree-pine')), findsOneWidget);

    await start(tester);
    await wait(tester, const Duration(minutes: 1));
    await tester.tap(find.byKey(const ValueKey('focus-change-tree')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-species-pine')), findsNothing);
    // After the first seconds the quiet text button gives up instead.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('focus-give-up')),
        matching: find.text('Bỏ cuộc'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('every species has its own name', (tester) async {
    await open(tester);
    final t = lookupAppLocalizations(const Locale('vi'));
    final names = species.map((s) => speciesName(t, s.id)).toList();
    expect(names.toSet(), hasLength(species.length));
    expect(speciesName(t, 'olive'), 'Ô liu');
    expect(speciesName(t, 'mugunghwa'), 'Mộc cận');
  });

  testWidgets('a locked species cannot be chosen', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('focus-change-tree')));
    await tester.pumpAndSettle();
    // A locked species keeps its name, faded under a lock. Cherry opens at
    // 50 known words, so it is locked in a new garden.
    expect(find.text('Anh đào'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('focus-species-lock-cherry')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('focus-species-lock-pine')), findsNothing);
    expect(find.text('Chưa mở'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('focus-species-cherry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-species-cherry')), findsOneWidget);

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

  testWidgets('a short session leaves a young plant and offers no bloom', (
    tester,
  ) async {
    // A session under the garden's second rules.
    clock = DateTime(2026, 11, 17, 9);
    state = createAppState(
      store: MemoryRecordStore(),
      feedback: SilentFeedback(),
      now: () => clock,
    );
    await open(tester);
    await start(tester, minutes: 10);
    await wait(tester, const Duration(minutes: 10));
    expect(state.focusSessions.single.outcome, FocusOutcome.done);
    expect(
      find.text(
        'Phiên ngắn mọc một cây non. Tập trung từ 25 phút để cây trưởng thành và nở hoa được.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('focus-review')), findsNothing);
  });

  testWidgets('the break offers due words first, each once, within the day', (
    tester,
  ) async {
    clock = DateTime(2026, 11, 10, 9);
    state = createAppState(
      store: MemoryRecordStore(),
      feedback: SilentFeedback(),
      now: () => clock,
    );
    final cooking = state.decks.firstWhere((d) => d.id == 'cooking');
    final learned = cooking.words[5];
    state
      ..rate(learned, 2)
      // The same word in a deck of the learner's own.
      ..addDeck(
        Deck(
          id: 'mine',
          title: 'Mine',
          description: '',
          words: [FlashWord(id: 'copy', word: learned.word, meaning: '')],
        ),
      )
      ..setNewPerDay(2);
    // A week later the word is due.
    clock = DateTime(2026, 11, 17, 9);
    await open(tester);
    await start(tester, minutes: 25);
    await wait(tester, const Duration(minutes: 25));
    await tester.tap(find.byKey(const ValueKey('focus-review')));
    await tester.pumpAndSettle();
    final words = tester.widget<ReviewScreen>(find.byType(ReviewScreen)).words;
    expect(words.first.word, learned.word);
    expect(words.map((w) => w.word.toLowerCase()).toSet(), hasLength(3));
    // One word due and the day's two new words, not eight from deck order.
    expect(words, hasLength(3));
  });

  testWidgets('the timer sheet says when a length grows only a young plant', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('focus-timer-button')));
    await tester.pumpAndSettle();
    await tester.timedDrag(
      find.byKey(const ValueKey('timer-ruler')),
      const Offset(2 * MinuteRuler.spacing, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dưới 25 phút chỉ mọc cây non'), findsOneWidget);
  });
}

class _Knocks extends SilentFeedback {
  var taps = 0;
  @override
  void tap() => taps++;
}
