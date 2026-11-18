import '../../domain/models/models.dart';
import '../../domain/repositories/deck_generator.dart';
import '../content/en/decks.dart';

/// Names the words already bundled with the app, whatever the topic: a
/// stand-in for builds without the Worker, and for tests. Only English has
/// bundled words; other languages get none.
class MockDeckGenerator implements DeckGenerator {
  final Duration latency;
  const MockDeckGenerator({this.latency = const Duration(milliseconds: 900)});

  @override
  Future<List<String>> suggest({
    required String? idToken,
    required Language language,
    required String topic,
    required String level,
    required int count,
    List<String> exclude = const [],
  }) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (language != Language.english) return const [];
    final skip = {for (final w in exclude) w.trim().toLowerCase()};
    return {
      for (final w in seedDecks().expand((d) => d.words))
        w.word.trim().toLowerCase(),
    }.where((w) => !skip.contains(w)).take(count).toList();
  }
}
