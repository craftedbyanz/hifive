import '../models/models.dart';

/// AI-generated flashcards for New Deck and Add Cards.
abstract interface class DeckGenerator {
  /// Returns up to [count] new words about [topic], leaving out [exclude].
  Future<List<FlashWord>> generate({
    required String topic,
    required int count,
    List<FlashWord> exclude,
  });
}
