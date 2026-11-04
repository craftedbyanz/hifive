import 'models.dart';
import 'seed_decks.dart';

/// AI-generated flashcards for New Deck and Add Cards.
abstract interface class DeckGenerator {
  /// Returns up to [count] new words about [topic], leaving out [exclude].
  Future<List<FlashWord>> generate({
    required String topic,
    required int count,
    List<FlashWord> exclude,
  });
}

/// Hands out the words already bundled with the app. The reference's
/// generation was never run, so neither its timing nor its output is known.
class MockDeckGenerator implements DeckGenerator {
  final Duration latency;
  final DateTime Function() now;
  const MockDeckGenerator({
    this.latency = const Duration(milliseconds: 900),
    this.now = DateTime.now,
  });

  @override
  Future<List<FlashWord>> generate({
    required String topic,
    required int count,
    List<FlashWord> exclude = const [],
  }) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final unique = <String, FlashWord>{
      for (final w in seedDecks().expand((d) => d.words)) w.word: w,
    };
    final stamp = now().microsecondsSinceEpoch;
    return unique.values
        .where((w) => !exclude.any((v) => v.word == w.word))
        .take(count)
        .map(
          (w) => FlashWord(
            id: 'local-$stamp-${w.id}',
            word: w.word,
            meaning: w.meaning,
            phonetic: w.phonetic,
            example: w.example,
            partOfSpeech: w.partOfSpeech,
            definition: w.definition,
          ),
        )
        .toList();
  }
}
