import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/state/state.dart';
import 'package:hifive/widgets/common.dart';

import '../../helpers.dart';

const _tall = Size(393, 1400);

void main() {
  setUpAll(loadAppFonts);
  wideSearch();

  Future<(AppState, Deck)> open(WidgetTester tester, {int words = 3}) async {
    final state = fresh();
    final deck = state.decks.firstWhere((d) => d.id == 'cooking');
    await mount(
      tester,
      state,
      ReviewScreen(deck: deck, words: deck.words.take(words).toList()),
    );
    return (state, deck);
  }

  Future<void> swipe(WidgetTester tester, Offset by) async {
    await tester.drag(find.byKey(const ValueKey('review-card')), by);
    await tester.pumpAndSettle();
  }

  group('session', () {
    testWidgets('each direction rates like its button, and sets the schedule', (
      tester,
    ) async {
      final (state, deck) = await open(tester, words: 4);
      final words = deck.words.take(4).toList();
      await swipe(tester, const Offset(0, 200));
      expect(words[0].status, 'review');
      expect(words[0].due, state.now().add(const Duration(minutes: 6)));
      await swipe(tester, const Offset(0, -200));
      expect(words[1].due, state.now().add(const Duration(days: 1)));
      await swipe(tester, const Offset(200, 0));
      expect(words[2].due, state.now().add(const Duration(days: 4)));
      await swipe(tester, const Offset(-200, 0));
      expect(words[3].status, 'learning');
      expect(words[3].due, state.now().add(const Duration(minutes: 1)));
    });

    testWidgets('a short drag snaps back and rates nothing', (tester) async {
      final (_, deck) = await open(tester);
      final first = deck.words.first;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('review-card'))),
      );
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(first.status, 'new');
      expect(first.due, isNull);
      expect(find.text(first.word), findsWidgets);
    });

    testWidgets('dragging fades the other ratings and fills the matching one', (
      tester,
    ) async {
      await open(tester);
      double opacity(int i) => tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byKey(ValueKey('rate-$i')),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(opacity(1), 1);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('review-card'))),
      );
      for (var i = 0; i < 3; i++) {
        await gesture.moveBy(const Offset(-60, 0));
      }
      await tester.pump();
      expect(opacity(0), 1);
      expect(opacity(1), 0);
      expect(opacity(3), 0);
      await gesture.moveBy(const Offset(180, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('again sends the card to the end without advancing progress', (
      tester,
    ) async {
      final (_, deck) = await open(tester, words: 2);
      double progress() =>
          tester.getSize(find.byKey(const ValueKey('review-progress'))).width;
      final zero = progress();
      await tester.tap(find.byKey(const ValueKey('rate-0')));
      await tester.pumpAndSettle();
      expect(progress(), zero);
      await tester.tap(find.byKey(const ValueKey('rate-2')));
      await tester.pumpAndSettle();
      expect(progress(), greaterThan(zero));
      expect(find.text(deck.words.first.word), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('rate-2')));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewComplete), findsOneWidget);
      // Two cards seen, both known, one sent back once.
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();
      expect(labels, containsAllInOrder(['2', '2', '1']));
    });

    testWidgets('a known card shows longer intervals, growing with it', (
      tester,
    ) async {
      final word = FlashWord(id: 'x', word: 'x', meaning: 'y');
      String labels() => word.nextIntervals
          .map((d) => d.inDays > 0 ? '${d.inDays}d' : '${d.inMinutes}m')
          .join(' ');
      expect(labels(), '1m 6m 1d 4d');
      word
        ..status = 'review'
        ..intervalDays = 0;
      expect(labels(), '1m 1d 3d 4d');
      word.intervalDays = 4;
      expect(labels(), '1m 5d 10d 12d');
    });

    testWidgets('tapping flips to the meaning and back', (tester) async {
      final (_, deck) = await open(tester);
      final w = deck.words.first;
      expect(find.text(w.meaning), findsNothing);
      await tester.tap(find.byKey(const ValueKey('review-card')));
      await tester.pumpAndSettle();
      expect(find.text(w.meaning), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('review-card')));
      await tester.pumpAndSettle();
      expect(find.text(w.meaning), findsNothing);
    });

    testWidgets('the guide opens from the menu and closes', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Tùy chọn ôn tập'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hướng dẫn'));
      await tester.pumpAndSettle();
      expect(find.text('Cơ chế học thông minh'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('review-guide-close')));
      await tester.pumpAndSettle();
      expect(find.text('Cơ chế học thông minh'), findsNothing);
    });

    testWidgets('the part-of-speech pill hugs its text', (tester) async {
      await open(tester);
      final pill = find
          .ancestor(
            of: find.text('NOUN').first,
            matching: find.byType(Container),
          )
          .first;
      expect(tester.getSize(pill).width, lessThan(100));
    });

    testWidgets(
      'menu text sits on a Material, so it has no warning underline',
      (tester) async {
        await open(tester);
        await tester.tap(find.byTooltip('Tùy chọn ôn tập'));
        await tester.pumpAndSettle();
        final style = DefaultTextStyle.of(
          tester.element(find.text('Hướng dẫn')),
        );
        expect(style.style.decoration, isNot(TextDecoration.underline));
        expect(style.style.decorationColor, isNot(const Color(0xffffff00)));
      },
    );

    testWidgets('the color menu changes the card without leaving', (
      tester,
    ) async {
      final (_, _) = await open(tester);
      await tester.tap(find.byTooltip('Tùy chọn ôn tập'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Màu thẻ'));
      await tester.pumpAndSettle();
      expect(find.text('Đơn sắc'), findsOneWidget);
      await tester.tap(find.text('Màu sắc'));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewScreen), findsOneWidget);
      expect(find.text('Đơn sắc'), findsNothing);
    });
  });

  group('deck', () {
    testWidgets('review counts only due cards, then offers everything', (
      tester,
    ) async {
      final state = fresh();
      final deck = state.decks.firstWhere((d) => d.id == 'cooking');
      await mount(tester, state, DeckScreen(deck: deck), size: _tall);
      expect(find.text('Ôn tập (10)'), findsOneWidget);
      expect(
        find.byKey(ValueKey('due-${deck.words.first.id}')),
        findsOneWidget,
      );
      state.rate(deck.words.first, 3);
      await tester.pump();
      expect(find.text('Ôn tập (9)'), findsOneWidget);
      expect(find.byKey(ValueKey('due-${deck.words.first.id}')), findsNothing);
      for (final w in deck.words) {
        state.rate(w, 3);
      }
      await tester.pump();
      expect(find.text('Ôn tập tất cả'), findsOneWidget);
      await tester.tap(find.text('Ôn tập tất cả'));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewScreen), findsOneWidget);
      expect(
        ModalRoute.of(tester.element(find.byType(ReviewScreen))),
        isA<CoverRoute<void>>(),
      );
    });

    testWidgets('filters show their name and an empty result disables review', (
      tester,
    ) async {
      final state = fresh();
      final deck = state.decks.firstWhere((d) => d.id == 'cooking');
      for (final w in deck.words) {
        state.rate(w, 2);
      }
      await mount(tester, state, DeckScreen(deck: deck), size: _tall);
      await tester.tap(find.byKey(const ValueKey('deck-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not studied'));
      await tester.pumpAndSettle();
      expect(find.text('Ôn tập (0)'), findsOneWidget);
      expect(find.text('Đã hoàn thành bài học hôm nay!'), findsOneWidget);
      await tester.tap(find.text('Ôn tập (0)'));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewScreen), findsNothing);
    });

    testWidgets('search hides the summary, and cancel brings it back', (
      tester,
    ) async {
      final state = fresh();
      final deck = state.decks.firstWhere((d) => d.id == 'cooking');
      await mount(tester, state, DeckScreen(deck: deck), size: _tall);
      await tester.tap(find.byKey(const ValueKey('deck-search-open')));
      await tester.pumpAndSettle();
      expect(find.text('Deck Progress'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('deck-search')),
        'Guava',
      );
      await tester.pumpAndSettle();
      expect(find.text('Guava'), findsWidgets);
      expect(find.text('Blitz'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('deck-search-cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Deck Progress'), findsOneWidget);
      expect(find.text('Blitz'), findsOneWidget);
    });

    testWidgets('add cards shows the slots left and locks the topic', (
      tester,
    ) async {
      final state = fresh();
      final deck = state.decks.firstWhere((d) => d.id == 'cooking');
      await mount(tester, state, DeckScreen(deck: deck), size: _tall);
      await tester.tap(find.byTooltip('Tùy chọn bộ thẻ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Cards'));
      await tester.pumpAndSettle();
      expect(find.text('Còn 90 slot'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('deck-generate')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(deck.words.length, greaterThan(10));
    });

    testWidgets('the slot pill hugs its text and Cancel stays on screen', (
      tester,
    ) async {
      final state = fresh();
      final deck = state.decks.firstWhere((d) => d.id == 'cooking');
      await mount(tester, state, DeckScreen(deck: deck));
      await tester.tap(find.byKey(const ValueKey('deck-search-open')));
      await tester.pumpAndSettle();
      final cancel = tester.getRect(
        find.byKey(const ValueKey('deck-search-cancel')),
      );
      expect(cancel.right, closeTo(377, 2));
      await tester.tap(find.byKey(const ValueKey('deck-search-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tùy chọn bộ thẻ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Cards'));
      await tester.pumpAndSettle();
      final pill = find
          .ancestor(
            of: find.text('Còn 90 slot'),
            matching: find.byType(Container),
          )
          .first;
      expect(tester.getSize(pill).width, lessThan(120));
    });

    testWidgets('a meaning uses the dot\'s space once the card is not due', (
      tester,
    ) async {
      final state = fresh();
      final deck = state.decks.firstWhere((d) => d.id == 'cooking');
      final word = deck.words.first;
      await mount(tester, state, DeckScreen(deck: deck), size: _tall);
      double width() => tester.getSize(find.text(word.meaning)).width;
      final narrow = width();
      state.rate(word, 3);
      await tester.pump();
      expect(width(), greaterThan(narrow));
    });

    testWidgets('dragging the ruler changes the word count', (tester) async {
      await mount(tester, fresh(), const DeckListScreen());
      await tester.tap(find.byTooltip('Thêm bộ thẻ'));
      await tester.pumpAndSettle();
      Text count() =>
          tester.widget<Text>(find.byKey(const ValueKey('deck-word-count')));
      expect(count().data, '10');
      await tester.drag(
        find.byKey(const ValueKey('deck-ruler')),
        const Offset(-77, 0),
      );
      await tester.pumpAndSettle();
      expect(int.parse(count().data!), greaterThan(10));
    });
  });
}

void wideSearch() {
  testWidgets('deck search lays out on a wider Android screen', (tester) async {
    final state = fresh();
    await mount(
      tester,
      state,
      DeckScreen(deck: state.decks.first),
      size: const Size(411, 914),
    );
    await tester.tap(find.byTooltip('Tìm kiếm thẻ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const ValueKey('deck-search')), 'Rotate');
    await tester.pumpAndSettle();
    expect(find.text('Partnership'), findsNothing);
  });
}
