import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/core/services/feedback_service.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/features/flashcards/flashcards.dart';

import '../../helpers.dart';

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

  testWidgets('generating a deck is coming soon and adds nothing', (
    tester,
  ) async {
    final state = fresh();
    final count = state.decks.length;
    await mount(tester, state, const DeckListScreen());
    await tester.tap(find.byTooltip('Thêm bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('deck-topic')), 'Du lịch');
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('deck-generate')),
        matching: find.text('Sắp ra mắt'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('deck-generate')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
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
