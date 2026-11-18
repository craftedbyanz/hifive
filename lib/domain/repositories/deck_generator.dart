import '../models/models.dart';

/// Why a deck couldn't be made with AI.
enum GenerateError {
  /// The account used today's decks made with AI.
  dailyLimit,

  /// Offline, the server or its model is down, or the answer was empty.
  unavailable,

  /// Signed out, or the account's token was refused.
  unauthorized,

  /// None of the words found has a meaning in the dictionary.
  noWords,
}

class GenerateException implements Exception {
  final GenerateError error;
  const GenerateException(this.error);
  @override
  String toString() => 'GenerateException(${error.name})';
}

/// Words for a deck made with AI (New Deck's "Generate Deck"). It only
/// names words; the app gives them meanings from its dictionary, so a
/// made-up word or meaning never becomes a card. docs/memory-plan.md.
abstract interface class DeckGenerator {
  /// About [count] words or short phrases in [language] about [topic] for a
  /// learner at [level] (A1 to C2), leaving out [exclude], most useful
  /// first. Throws [GenerateException].
  Future<List<String>> suggest({
    required String? idToken,
    required Language language,
    required String topic,
    required String level,
    required int count,
    List<String> exclude,
  });
}
