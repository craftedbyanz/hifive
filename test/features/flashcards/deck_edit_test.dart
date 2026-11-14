import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';

Deck _mine(AppState s, String title) => Deck(
  id: s.newId(),
  title: title,
  description: '',
  words: [FlashWord(id: s.newId(), word: 'ticket', meaning: 'vé')],
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a deck the learner made is renamed and given a new icon', (
    tester,
  ) async {
    final store = MemoryRecordStore();
    final state = fresh(store: store);
    await state.load();
    final first = _mine(state, 'Trip');
    final second = _mine(state, 'Later');
    state
      ..addDeck(first)
      ..addDeck(second);
    await mount(tester, state, DeckScreen(deck: first));
    await tester.tap(find.byTooltip('Tùy chọn bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('deck-edit-title')),
      ' Du lịch Nhật ',
    );
    await tester.tap(find.byKey(const ValueKey('deck-icon-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('deck-edit-save')));
    await tester.pumpAndSettle();

    expect(first.title, 'Du lịch Nhật');
    expect(first.icon, 2);
    expect(find.text('Du lịch Nhật'), findsWidgets);
    expect(find.byIcon(CupertinoIcons.airplane), findsOneWidget);

    // It survives a restart, and keeps its place before the later deck.
    await state.flush();
    final again = fresh(store: store);
    await again.load();
    final titles = again.decks.map((d) => d.title).toList();
    expect(titles.indexOf('Du lịch Nhật'), lessThan(titles.indexOf('Later')));
    expect(again.decks.singleWhere((d) => d.id == first.id).icon, 2);
  });

  testWidgets('tapping the deck icon opens the same editor', (tester) async {
    final state = fresh();
    final deck = _mine(state, 'Trip');
    state.addDeck(deck);
    await mount(tester, state, DeckScreen(deck: deck));
    await tester.tap(find.byKey(const ValueKey('deck-header-icon')));
    await tester.pumpAndSettle();
    expect(find.byType(EditDeckSheet), findsOneWidget);
  });

  testWidgets('a deck hifive provides is renamed over its own words', (
    tester,
  ) async {
    final store = MemoryRecordStore();
    final state = fresh(store: store);
    await state.load();
    final deck = state.decks.first;
    final words = deck.words.map((w) => w.word).toList();
    state.rate(deck.words.first, 2);
    await mount(tester, state, DeckScreen(deck: deck));
    await tester.tap(find.byKey(const ValueKey('deck-header-icon')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('deck-edit-title')),
      'Đi làm',
    );
    await tester.enterText(
      find.byKey(const ValueKey('deck-edit-description')),
      'Từ cho công việc của tôi',
    );
    await tester.tap(find.byKey(const ValueKey('deck-icon-11')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('deck-edit-save')));
    await tester.pumpAndSettle();
    await state.flush();

    final again = fresh(store: store);
    await again.load();
    final same = again.decks.singleWhere((d) => d.id == deck.id);
    expect(
      (same.title, same.description, same.icon),
      ('Đi làm', 'Từ cho công việc của tôi', 11),
    );
    // Still one deck, with hifive's words and the progress made on them.
    expect(again.decks.where((d) => d.id == deck.id), hasLength(1));
    expect(same.words.map((w) => w.word), words);
    expect(same.words.first.reviews, 1);
  });

  testWidgets('Saved words shows a bookmark until given another icon', (
    tester,
  ) async {
    final state = fresh();
    state.saveWord('gate', 'cổng');
    final saved = state.decks.singleWhere((d) => d.id == 'saved');
    expect(deckIcon(saved), CupertinoIcons.bookmark_fill);
    state.editDeck(saved, title: 'Từ của tôi', icon: 4);
    expect(deckIcon(saved), CupertinoIcons.heart_fill);
    expect(saved.title, 'Từ của tôi');
  });

  testWidgets('a deck is made with a name and icon, then filled by hand', (
    tester,
  ) async {
    final state = fresh();
    final before = state.decks.length;
    await mount(tester, state, const DeckListScreen());
    await tester.tap(find.byTooltip('Thêm bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-form-icon')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-icon-5')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('deck-topic')), 'Books');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('deck-create')));
    await tester.pumpAndSettle();

    expect(state.decks, hasLength(before + 1));
    final deck = state.decks.last;
    expect((deck.title, deck.icon), ('Books', 5));
    expect(deck.words, isEmpty);
    // The new deck opens, ready for words.
    expect(find.byType(DeckScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Tùy chọn bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm từ'));
    await tester.pumpAndSettle();
    Future<void> add(String word, String meaning) async {
      await tester.enterText(find.byKey(const ValueKey('add-word-word')), word);
      await tester.enterText(
        find.byKey(const ValueKey('add-word-meaning')),
        meaning,
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('add-word-save')));
      await tester.pump();
    }

    await add('novel', 'tiểu thuyết');
    await add('chapter', 'chương');
    expect(find.text('Đã thêm 2 từ'), findsOneWidget);
    // The same word twice is refused.
    await add('Novel', 'x');
    expect(find.text('Từ này đã có trong bộ thẻ.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-word-done')));
    await tester.pumpAndSettle();
    expect(deck.words.map((w) => w.word), ['novel', 'chapter']);
    expect(find.text('chapter'), findsOneWidget);
  });
}
