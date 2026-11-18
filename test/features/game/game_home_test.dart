import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/game/game.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the deck picker leaves out decks without words', (tester) async {
    final state = fresh()
      ..addDeck(Deck(id: 'empty', title: 'Rỗng', description: '', words: []));
    await mount(tester, state, const GameHomeScreen());
    await tester.tap(find.byKey(const ValueKey('play-flowletter')));
    await tester.pumpAndSettle();
    expect(find.text(state.decks.first.title), findsOneWidget);
    expect(find.text('Rỗng'), findsNothing);
    expect(find.byKey(const ValueKey('game-no-decks')), findsNothing);
  });

  testWidgets('with no words anywhere the picker says there is no deck', (
    tester,
  ) async {
    final state = fresh();
    for (final d in [...state.decks]) {
      d.words.clear();
    }
    await mount(tester, state, const GameHomeScreen());
    await tester.tap(find.byKey(const ValueKey('play-flowletter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('game-no-decks')), findsOneWidget);
  });
}
