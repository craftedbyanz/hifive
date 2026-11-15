import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/information/information.dart';
import 'package:hifive/state/state.dart';

import '../../domain/dictionary/lookup_test.dart' show packBytes, packInfo;
import '../../helpers.dart';

void main() {
  late Directory dir;
  setUpAll(() async {
    await loadAppFonts();
    dir = Directory.systemTemp.createTempSync('hifive-dict-ui');
    await SqliteDictionaryStore(dir.path).install(packInfo(), packBytes());
  });
  tearDownAll(() => dir.deleteSync(recursive: true));

  Future<AppState> withPack(WidgetTester tester) async {
    final state = fresh(dictionaryStore: SqliteDictionaryStore(dir.path));
    await tester.runAsync(state.load);
    expect(state.dictionaryReady, isTrue);
    return state;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(
      find.byKey(const ValueKey('dict-search-field')),
      text,
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
  }

  Finder addButtonFor(String meaning) => find.descendant(
    of: find.ancestor(
      of: find.textContaining(meaning).first,
      matching: find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('dict-result-'),
      ),
    ),
    matching: find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('dict-add-'),
    ),
  );

  testWidgets(
    'typing a word and tapping + adds it to saved words, and ✓ takes it back',
    (tester) async {
      final state = await withPack(tester);
      await mount(tester, state, const DictionaryScreen());
      expect(find.text('Thêm vào: Từ đã lưu'), findsOneWidget);

      await type(tester, 'bank');
      expect(find.textContaining('ngân hàng, nhà băng'), findsOneWidget);
      expect(find.text('/ˈbæŋk/'), findsWidgets);
      await tester.tap(addButtonFor('ngân hàng, nhà băng'));
      await tester.pumpAndSettle();

      final saved = state.decks.firstWhere((d) => d.id == 'saved');
      expect(saved.words.single.word, 'bank');
      expect(saved.words.single.meaning, 'ngân hàng, nhà băng');
      expect(find.text('Đã thêm 1'), findsOneWidget);
      expect(state.recentLookups, ['bank']);
      // The text is selected, so the next word replaces it.
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('dict-search-field')),
      );
      expect(field.controller!.selection.extentOffset, 4);
      expect(field.controller!.selection.baseOffset, 0);

      await tester.tap(addButtonFor('ngân hàng, nhà băng'));
      await tester.pumpAndSettle();
      expect(saved.words, isEmpty);
    },
  );

  testWidgets(
    'from a deck, words go to that deck and its own words show as added',
    (tester) async {
      final state = await withPack(tester);
      final deck = Deck(
        id: 'mine',
        title: 'Du lịch',
        description: '',
        words: [],
      );
      state.addDeck(deck);
      state.addWords(deck, [
        FlashWord(id: 'w1', word: 'airport', meaning: 'sân bay'),
      ]);
      await mount(tester, state, DictionaryScreen(deck: deck));
      expect(find.text('Thêm vào: Du lịch'), findsOneWidget);

      await type(tester, 'airport');
      expect(find.byTooltip('Đã có trong bộ này'), findsWidgets);
      await type(tester, 'ticket');
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('dict-add-'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(deck.words.map((w) => w.word), ['airport', 'ticket']);
      expect(state.decks.where((d) => d.id == 'saved'), isEmpty);
    },
  );

  testWidgets('a typo offers the word it meant', (tester) async {
    final state = await withPack(tester);
    await mount(tester, state, const DictionaryScreen());
    await type(tester, 'recieve');
    expect(find.text('CÓ PHẢI BẠN MUỐN TÌM'), findsOneWidget);
    expect(find.text('receive'), findsOneWidget);
  });

  testWidgets('Vietnamese finds the English word', (tester) async {
    final state = await withPack(tester);
    await mount(tester, state, const DictionaryScreen());
    await type(tester, 'con mèo');
    expect(find.text('TIẾNG VIỆT → TIẾNG ANH'), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);
  });

  testWidgets('an inflection shows what it is a form of', (tester) async {
    final state = await withPack(tester);
    await mount(tester, state, const DictionaryScreen());
    await type(tester, 'went');
    expect(find.text('quá khứ của go'), findsOneWidget);
  });

  testWidgets('a word nowhere is entered by hand with the word filled in', (
    tester,
  ) async {
    final state = await withPack(tester);
    await mount(tester, state, const DictionaryScreen());
    await type(tester, 'qzxqzx');
    expect(find.text('Không tìm thấy "qzxqzx"'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dict-manual')));
    await tester.pumpAndSettle();
    final word = tester.widget<TextField>(
      find.byKey(const ValueKey('add-word-word')),
    );
    expect(word.controller!.text, 'qzxqzx');
    await tester.enterText(
      find.byKey(const ValueKey('add-word-meaning')),
      'từ thử',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('add-word-save')));
    await tester.pumpAndSettle();
    final saved = state.decks.firstWhere((d) => d.id == 'saved');
    expect(saved.words.single.meaning, 'từ thử');
    expect(find.byType(DictionaryScreen), findsOneWidget);
  });

  testWidgets('a phrase without a Vietnamese meaning asks for one', (
    tester,
  ) async {
    final state = await withPack(tester);
    await mount(tester, state, const DictionaryScreen());
    await type(tester, 'find out');
    expect(find.text('Chưa có nghĩa tiếng Việt'), findsWidgets);
    await tester.tap(find.byTooltip('Thêm nghĩa').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add-word-definition')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('add-word-meaning')),
      'tìm ra',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('add-word-save')));
    await tester.pumpAndSettle();
    final card = state.decks.firstWhere((d) => d.id == 'saved').words.single;
    expect((card.word, card.meaning), ('find out', 'tìm ra'));
    expect(card.definition, isNotEmpty);
    expect(find.text('Đã thêm 1'), findsOneWidget);
  });

  testWidgets('the entry page puts the chosen meanings on the card', (
    tester,
  ) async {
    final state = await withPack(tester);
    await mount(tester, state, const DictionaryScreen());
    await type(tester, 'bank');
    await tester.tap(find.textContaining('ngân hàng, nhà băng'));
    await tester.pumpAndSettle();
    expect(find.byType(DictionaryEntryScreen), findsOneWidget);
    expect(find.text('Taro drew 10,000 yen from the bank.'), findsOneWidget);
    expect(find.textContaining('Tatoeba'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dict-sense-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('dict-entry-add')));
    await tester.pumpAndSettle();
    final card = state.decks.firstWhere((d) => d.id == 'saved').words.single;
    expect(card.meaning, 'ngân hàng, nhà băng; Đê, gờ, ụ (đất, đá)');
    expect(find.byType(DictionaryScreen), findsOneWidget);
    expect(find.text('Đã thêm 1'), findsOneWidget);
  });

  testWidgets('without the pack, a notice shows and hifive words are found', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, const DictionaryScreen());
    expect(find.byKey(const ValueKey('dict-notice')), findsOneWidget);
    final word = state.decks.first.words.first;
    await type(tester, word.word);
    expect(find.text(word.meaning), findsWidgets);
  });

  testWidgets('recent lookups open again with one tap', (tester) async {
    final state = await withPack(tester);
    state.rememberLookup('cat');
    await mount(tester, state, const DictionaryScreen());
    expect(find.text('GẦN ĐÂY'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dict-recent-cat')));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.text('mèo'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('dict-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dict-clear-recent')));
    await tester.pumpAndSettle();
    expect(state.recentLookups, isEmpty);
  });

  testWidgets('the deck list opens the dictionary', (tester) async {
    final state = fresh();
    await mount(tester, state, const DeckListScreen());
    await tester.tap(find.byKey(const ValueKey('deck-dictionary')));
    await tester.pumpAndSettle();
    expect(find.byType(DictionaryScreen), findsOneWidget);
  });

  testWidgets('the sources page credits the data and opens the licence', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, const DictionarySourcesScreen());
    expect(find.textContaining('Hồ Ngọc Đức'), findsOneWidget);
    expect(find.textContaining('Tatoeba'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dict-license')));
    await tester.pump();
    expect(
      (state.system as RecordingSystemActions).calls,
      contains('dictionaryLicense'),
    );
  });
}
