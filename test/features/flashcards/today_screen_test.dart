import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/domain/vocab/vocab.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/home/home.dart';

import '../../helpers.dart';

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('ex-next')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a new word is met, revealed and self-rated', (tester) async {
    final state = fresh();
    final word = state.decks.first.words.first;
    await mount(tester, state, TodayScreen(words: [word]));
    expect(find.byKey(const ValueKey('ex-kind-intro')), findsOneWidget);
    expect(find.text(word.meaning), findsNothing);
    await tester.tap(find.byKey(const ValueKey('ex-reveal')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ex-meaning')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ex-rate-2')));
    await tester.pumpAndSettle();

    expect(word.status, 'review');
    expect(find.byKey(const ValueKey('today-complete')), findsOneWidget);
  });

  testWidgets('typing the word right logs a recall from today', (tester) async {
    final store = MemoryRecordStore();
    final state = fresh(store: store);
    final word = state.decks.first.words.first;
    applyRating(word, state.now().subtract(const Duration(days: 4)), 2);
    await mount(tester, state, TodayScreen(words: [word]));
    expect(find.byKey(const ValueKey('ex-kind-typing')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('ex-input')), word.word);
    await tester.tap(find.byKey(const ValueKey('ex-check')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ex-verdict-correct')), findsOneWidget);
    await _next(tester);

    await state.flush();
    final events = [
      for (final e in store.records.entries)
        if (e.key.$1 == RecordKind.review) e.value.data!,
    ];
    expect(events.single['mode'], 'typing');
    expect(events.single['skill'], 'recall');
    expect(events.single['source'], 'today');
    expect(word.lastRecall, state.now());
  });

  testWidgets('a wrong answer brings the word back as a choice', (
    tester,
  ) async {
    final state = fresh();
    final word = state.decks.first.words.first;
    applyRating(word, state.now().subtract(const Duration(days: 4)), 2);
    await mount(tester, state, TodayScreen(words: [word]));
    await tester.tap(find.byKey(const ValueKey('ex-dont-know')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ex-verdict-wrong')), findsOneWidget);
    await _next(tester);

    expect(word.lapses, 1);
    expect(find.byKey(const ValueKey('ex-kind-choice')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('ex-choice-${word.meaning}')));
    await tester.pumpAndSettle();
    await _next(tester);
    expect(find.byKey(const ValueKey('today-complete')), findsOneWidget);
  });

  testWidgets('Home shows today and opens it as a flashcard session', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, const HomeScreen(animateAmbient: false));
    expect(find.text('10 từ mới'), findsOneWidget);
    expect(find.text('HÔM NAY · KHOẢNG 2 PHÚT'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-today')));
    await tester.pumpAndSettle();
    final review = tester.widget<ReviewScreen>(find.byType(ReviewScreen));
    expect(review.words, hasLength(10));
    expect(review.source, 'today');

    // Swiping a card rates it, logged as today's review.
    await tester.drag(
      find.byKey(const ValueKey('review-card')),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(review.words.first.status, 'review');
  });

  test('the seed decks give a full first day', () {
    final state = fresh();
    final plan = state.today;
    expect(plan.due, isEmpty);
    expect(plan.fresh, hasLength(state.newPerDay));
    expect(plan.fresh.every((FlashWord w) => w.status == 'new'), isTrue);
  });
}
