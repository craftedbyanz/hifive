import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/domain/vocab/vocab.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/insights/insights.dart';
import 'package:hifive/l10n/l10n.dart';
import 'package:hifive/state/state.dart';
import 'package:hifive/widgets/reminder_sync.dart';

import '../../helpers.dart';

final _t = DateTime(2026, 11, 1, 9);

void main() {
  setUpAll(loadAppFonts);

  test('insight counts levels, retention, the forecast and skills', () {
    final words = [
      for (final w in ['a', 'b', 'c']) FlashWord(id: w, word: w, meaning: w),
    ];
    final log = <Rated>[];
    for (var day = 0; day < 12; day++) {
      final e = ReviewEvent(
        id: '$day',
        wordId: 'a',
        at: _t.add(Duration(days: day)),
        rating: day == 5 ? 0 : 2,
        mode: 'typing',
        skill: 'recall',
      );
      log.add(Rated(e, day == 0 ? 'new' : 'review'));
    }
    applyRating(words[0], _t, 2);
    final m = MemoryInsight.of(words, log, _t.add(const Duration(days: 12)));
    expect(m.levels[MemoryLevel.fresh], 2);
    expect(m.retentionReviews, 11);
    expect(m.retention, closeTo(10 / 11, 1e-9));
    expect(m.forecast.first, 1);
    expect(m.skills['recall'], closeTo(11 / 12, 1e-9));
  });

  testWidgets('the memory screen shows levels and opens a hard word', (
    tester,
  ) async {
    final state = fresh();
    final word = state.decks.first.words.first;
    var at = state.now().subtract(const Duration(days: 40));
    for (var i = 0; i < 4; i++) {
      applyRating(word, at, 2);
      at = at.add(const Duration(days: 4));
      applyRating(word, at, 0);
      at = at.add(const Duration(days: 1));
    }
    await mount(tester, state, const MemoryScreen());
    expect(find.byKey(const ValueKey('memory-retention-wait')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('memory-level-learning')))
          .data,
      '1',
    );
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('memory-hard-${word.id}')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(ValueKey('memory-hard-${word.id}')));
    await tester.pumpAndSettle();
    expect(find.byType(WordScreen), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('a word page lists its meetings, newest first', (tester) async {
    final state = fresh();
    final word = state.decks.first.words.first;
    state
      ..rate(word, 2)
      ..rate(word, 3, mode: 'typing', skill: 'recall', source: 'today');
    await mount(tester, state, WordScreen(word: word));
    expect(find.textContaining('Nhớ ra từ'), findsOneWidget);
    expect(find.textContaining('Hiểu nghĩa'), findsOneWidget);
    expect(find.byKey(const ValueKey('word-level')), findsOneWidget);
  });

  testWidgets('the reminder is scheduled only when words will be due', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('hifive/screen'),
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('hifive/screen'),
        null,
      ),
    );
    final state = fresh()..setReminder(on: true, time: '20:00');
    final word = state.decks.first.words.first;
    applyRating(word, state.now().subtract(const Duration(days: 5)), 2);
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => ReminderSync(child: child!),
          home: const SizedBox(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    final scheduled = calls.lastWhere((c) => c.method == 'scheduleReminders');
    final list = (scheduled.arguments as List).cast<Map<Object?, Object?>>();
    // One for each of the coming week's days, so reminders keep coming while
    // the app stays closed; the word stays due, so every day has one.
    expect(list, hasLength(ReminderSync.days));
    expect(list.first['title'], '1 từ sắp quên');
    DateTime at(Map<Object?, Object?> m) =>
        DateTime.fromMillisecondsSinceEpoch((m['at']! as double).round());
    expect(at(list.first), state.nextReminder);
    expect(at(list[1]), state.nextReminder.add(const Duration(days: 1)));

    state.setReminder(on: false);
    await tester.pump(const Duration(seconds: 3));
    expect(calls.last.method, 'cancelReminder');
  });

  test('the reminder fires today if its time is still ahead', () {
    final state = fresh()..setReminder(time: '20:00');
    // fresh() pins the clock to 1 November at 01:43.
    expect(state.nextReminder, DateTime(2026, 11, 1, 20));
    state.setReminder(time: '01:00');
    expect(state.nextReminder, DateTime(2026, 11, 2, 1));
  });
}
