import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/history/history.dart';
import 'package:hifive/features/home/home.dart';
import 'package:hifive/state/state.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  test('the app starts with no sample decks or results', () async {
    final state = createAppState(
      store: MemoryRecordStore(),
      sampleDecks: false,
      feedback: SilentFeedback(),
    );
    await state.load();
    expect(state.decks, isEmpty);
    expect(state.history, isEmpty);
    expect(state.today.leg(), isEmpty);
    // The learner's own decks and saved words still work.
    state.addDeck(Deck(id: 'd', title: 'Du lịch', description: '', words: []));
    state.saveWord('ticket', 'vé');
    expect(state.decks.map((d) => d.id), ['d', 'saved']);
  });

  for (final (name, page) in [
    ('Home', const HomeScreen(animateAmbient: false) as Widget),
    ('the deck list', const DeckListScreen()),
    ('Ôn tập', const HistoryScreen()),
  ]) {
    testWidgets('$name opens with no decks', (tester) async {
      final state = createAppState(
        store: MemoryRecordStore(),
        sampleDecks: false,
        feedback: SilentFeedback(),
        now: () => DateTime(2026, 11, 16, 9),
      )..onboarded = true;
      await tester.runAsync(state.load);
      await mount(tester, state, page);
      expect(tester.takeException(), isNull);
    });
  }
}
