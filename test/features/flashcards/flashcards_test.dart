import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/core/services/feedback_service.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/features/flashcards/flashcards.dart';

import '../../helpers.dart';

/// Names [words], or fails with [error], and records what it was asked.
class _Generator implements DeckGenerator {
  List<String> words;
  GenerateError? error;
  final topics = <String>[], levels = <String>[];
  _Generator(this.words);

  @override
  Future<List<String>> suggest({
    required String? idToken,
    required Language language,
    required String topic,
    required String level,
    required int count,
    List<String> exclude = const [],
  }) async {
    topics.add(topic);
    levels.add(level);
    if (error case final e?) throw GenerateException(e);
    return words;
  }
}

/// Serves the starter pack, or fails like a phone offline.
class _Catalog implements CatalogRepository {
  var fail = true;
  @override
  Future<int?> latestVersion(String language) async {
    if (fail) throw const SocketException('offline');
    return 1;
  }

  @override
  Future<String> pack(String language, int version) async =>
      File('worker/catalog/en/1.json').readAsStringSync();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('no decks because the catalog failed: Thử lại loads them', (
    tester,
  ) async {
    final catalog = _Catalog();
    final state = createAppState(
      store: MemoryRecordStore(),
      catalog: catalog,
      feedback: SilentFeedback(),
      sampleDecks: false,
      now: () => DateTime(2026, 11, 18, 9),
    )..onboarded = true;
    await state.load();
    await mount(tester, state, const DeckListScreen());
    expect(find.text('Chưa có bộ thẻ'), findsOneWidget);
    expect(find.textContaining('kiểm tra kết nối mạng'), findsOneWidget);
    catalog.fail = false;
    await tester.tap(find.byKey(const ValueKey('deck-catalog-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có bộ thẻ'), findsNothing);
    expect(state.decks, hasLength(3));
  });

  testWidgets('Generate Deck makes a deck with dictionary meanings', (
    tester,
  ) async {
    final generator = _Generator([
      'deadline',
      'zzzblorp',
      'Deadline',
      'rotate',
    ]);
    final state = fresh(deckGenerator: generator)..setLevel('B1');
    final count = state.decks.length;
    await mount(tester, state, const DeckListScreen());
    await tester.tap(find.byTooltip('Thêm bộ thẻ'));
    await tester.pumpAndSettle();
    // Nothing to make without a topic.
    await tester.tap(find.byKey(const ValueKey('deck-generate')));
    await tester.pump();
    expect(generator.topics, isEmpty);
    await tester.enterText(find.byKey(const ValueKey('deck-topic')), 'Bếp');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('deck-generate')));
    await tester.pumpAndSettle();

    expect(generator.topics, ['Bếp']);
    expect(generator.levels, ['B1']);
    expect(state.decks, hasLength(count + 1));
    final deck = state.decks.last;
    expect(deck.title, 'Bếp');
    // A made-up word is dropped and a repeat kept once; meanings come from
    // hifive's own words.
    expect(deck.words.map((w) => w.word), ['Deadline', 'Rotate']);
    expect(deck.words.every((w) => w.meaning.isNotEmpty), isTrue);
    expect(find.byType(DeckScreen), findsOneWidget);
    expect(find.text('Đã tạo 2 thẻ'), findsOneWidget);
  });

  testWidgets('a failed generation keeps the sheet open and says why', (
    tester,
  ) async {
    final generator = _Generator(const [])..error = GenerateError.dailyLimit;
    final state = fresh(deckGenerator: generator);
    final count = state.decks.length;
    await mount(tester, state, const DeckListScreen());
    await tester.tap(find.byTooltip('Thêm bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('deck-topic')), 'Bếp');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('deck-generate')));
    await tester.pumpAndSettle();
    expect(find.textContaining('hết 5 lượt'), findsOneWidget);
    expect(find.byKey(const ValueKey('deck-generate')), findsOneWidget);
    expect(state.decks, hasLength(count));

    // Words the dictionary doesn't know make no deck either.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    generator
      ..error = null
      ..words = ['zzzblorp'];
    await tester.tap(find.byKey(const ValueKey('deck-generate')));
    await tester.pumpAndSettle();
    expect(find.textContaining('chủ đề khác'), findsOneWidget);
    expect(state.decks, hasLength(count));
  });

  testWidgets('resetting a deck schedule asks first', (tester) async {
    final state = fresh();
    final deck = state.decks.first;
    state.rate(deck.words.first, 3);
    await mount(tester, state, DeckScreen(deck: deck));
    await tester.tap(find.byTooltip('Tùy chọn bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Học lại từ đầu'));
    await tester.pumpAndSettle();
    expect(deck.words.first.status, 'review');
    await tester.tap(find.text('Đặt lại').last);
    await tester.pumpAndSettle();
    expect(deck.words.first.status, 'new');
    expect(deck.words.first.due, isNull);
  });
}
