import '../models/models.dart';
import '../repositories/dictionary_repository.dart';
import 'entry.dart';
import 'lookup.dart';

/// hifive's own words (catalog and bundled decks) as a [DictionaryIndex],
/// so they are found, and preferred, before the pack is installed.
class DeckDictionaryIndex implements DictionaryIndex {
  final Map<String, List<DictEntry>> _byKey = {};
  late final List<String> _keys;

  /// [levels] gives a deck's CEFR level by deck id, when known.
  DeckDictionaryIndex(
    Iterable<Deck> decks, {
    Map<String, String> levels = const {},
  }) {
    final seen = <String>{};
    for (final deck in decks) {
      for (final w in deck.words) {
        final key = dictKey(w.word);
        if (w.meaning.trim().isEmpty || !seen.add('$key|${w.partOfSpeech}')) {
          continue;
        }
        (_byKey[key] ??= []).add(DictEntry.fromCard(w, level: levels[deck.id]));
      }
    }
    _keys = _byKey.keys.toList()..sort();
  }

  @override
  Future<List<DictEntry>> entries(String key) async => _byKey[key] ?? const [];

  @override
  Future<List<DictForm>> forms(String key) async => const [];

  @override
  Future<List<String>> variants(String key) async => const [];

  @override
  Future<List<DictEntry>> startingWith(String key, {int limit = 8}) async => [
    for (final k in _keys.where((k) => k.startsWith(key)).take(limit))
      ..._byKey[k]!,
  ];

  @override
  Future<List<(String, int?)>> commonKeys(
    String first, {
    required int minLength,
    required int maxLength,
  }) async => [
    for (final k in _keys)
      if (k.startsWith(first) && k.length >= minLength && k.length <= maxLength)
        (k, null),
  ];

  @override
  Future<List<DictEntry>> withMeaning(String text, {int limit = 60}) async {
    final q = foldVietnamese(text);
    return [
      for (final list in _byKey.values)
        for (final e in list)
          if (e.senses.any((s) => foldVietnamese(s.meaning).contains(q))) e,
    ].take(limit).toList();
  }

  @override
  Future<List<DictEntry>> atLevel(String level, {int limit = 60}) async =>
      const [];

  @override
  void close() {}
}
