import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/flashcards/flashcards.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

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
