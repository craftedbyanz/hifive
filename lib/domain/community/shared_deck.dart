import '../models/deck.dart';

/// A deck someone shared by link or code (Community, step 1): a snapshot of
/// its title and words, read from the server under a six-character code.
/// Learning progress is never shared.
class SharedDeck {
  final String code, title, description, language;
  final int icon;

  /// The words, without ids: copying the deck gives them new ones.
  final List<FlashWord> words;
  const SharedDeck({
    this.code = '',
    required this.title,
    this.description = '',
    this.icon = 0,
    required this.language,
    required this.words,
  });

  /// A snapshot of [deck] to publish.
  factory SharedDeck.of(Deck deck, String language) => SharedDeck(
    title: deck.title,
    description: deck.description,
    icon: deck.icon,
    language: language,
    words: deck.words,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'icon': icon,
    'language': language,
    'words': [
      for (final w in words)
        {
          'word': w.word,
          'meaning': w.meaning,
          'phonetic': w.phonetic,
          'example': w.example,
          'partOfSpeech': w.partOfSpeech,
          'definition': w.definition,
        },
    ],
  };

  factory SharedDeck.fromJson(Map<String, dynamic> j) => SharedDeck(
    code: j['code'] as String? ?? '',
    title: j['title'] as String,
    description: j['description'] as String? ?? '',
    icon: j['icon'] as int? ?? 0,
    language: j['language'] as String? ?? 'en',
    words: [
      for (final w in (j['words'] as List).cast<Map<String, dynamic>>())
        FlashWord(
          id: '',
          word: w['word'] as String,
          meaning: w['meaning'] as String,
          phonetic: w['phonetic'] as String? ?? '',
          example: w['example'] as String? ?? '',
          partOfSpeech: w['partOfSpeech'] as String? ?? 'NOUN',
          definition: w['definition'] as String? ?? '',
        ),
    ],
  );
}

/// The letters a share code uses: no 0/O or 1/I/L, which look alike.
final _code = RegExp(r'^[A-HJ-NP-Z2-9]{6}$');

/// The share code in what the learner typed or pasted: the code itself, in
/// any case and with spaces or dashes, or a link ending in `/s/<code>`.
/// Null when there is none.
String? shareCodeIn(String input) {
  final link = RegExp(r'/s/([A-Za-z0-9]{6})\b').firstMatch(input);
  final raw = (link?.group(1) ?? input).toUpperCase().replaceAll(
    RegExp(r'[\s-]'),
    '',
  );
  return _code.hasMatch(raw) ? raw : null;
}
