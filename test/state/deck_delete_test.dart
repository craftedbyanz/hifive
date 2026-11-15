import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/state/state.dart';

void main() {
  late MemoryRecordStore store;
  AppState make() => createAppState(
    store: store,
    feedback: SilentFeedback(),
    now: () => DateTime(2026, 11, 16, 9),
  );

  setUp(() => store = MemoryRecordStore());

  Deck mine(AppState s) {
    final deck = Deck(id: 'trip', title: 'Du lịch', description: '', words: []);
    s
      ..addDeck(deck)
      ..addWords(deck, [
        FlashWord(id: 'w1', word: 'ticket', meaning: 'vé'),
        FlashWord(id: 'w2', word: 'gate', meaning: 'cổng'),
      ]);
    return deck;
  }

  test("a learner's deck and its cards are deleted for good", () async {
    final s = make();
    await s.load();
    final deck = mine(s);
    s.rate(deck.words.first, 2);
    await s.deleteDeck(deck);
    expect(s.decks.where((d) => d.id == 'trip'), isEmpty);
    await s.flush();

    final again = make();
    await again.load();
    expect(again.decks.where((d) => d.id == 'trip'), isEmpty);
    expect(again.uniqueWords.containsKey('ticket'), isFalse);
    // The review log stays: the word keeps its memory if added again.
    final back = Deck(id: 'b', title: 'B', description: '', words: []);
    again
      ..addDeck(back)
      ..addWords(back, [FlashWord(id: 'w3', word: 'ticket', meaning: 'vé')]);
    expect(again.uniqueWords['ticket']!.status, isNot('new'));
  });

  test("hifive's own decks cannot be deleted", () async {
    final s = make();
    await s.load();
    final builtIn = s.decks.first;
    expect(s.canDelete(builtIn), isFalse);
    await s.deleteDeck(builtIn);
    expect(s.decks.first.id, builtIn.id);
    s.saveWord('cat', 'mèo');
    expect(s.canDelete(s.decks.firstWhere((d) => d.id == 'saved')), isTrue);
  });
}
