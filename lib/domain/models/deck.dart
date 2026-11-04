class FlashWord {
  final String id, word, meaning, phonetic, example, partOfSpeech, definition;
  String status;
  DateTime? due;

  /// Days until the next review once the card is known. Zero while learning.
  int intervalDays;
  FlashWord({
    required this.id,
    required this.word,
    required this.meaning,
    this.phonetic = '',
    this.example = '',
    this.partOfSpeech = 'NOUN',
    this.definition = '',
    this.status = 'new',
    this.due,
    this.intervalDays = 0,
  });

  bool isDue(DateTime now) =>
      status == 'new' || due == null || !due!.isAfter(now);

  /// Mock scheduling fitted to the labels seen on the reference, which showed
  /// 1m/6m/1d/4d, 1m/1d/3d/4d and 1m/5d/10d/12d. Its real algorithm is unknown.
  List<Duration> get nextIntervals {
    if (status != 'review') {
      return const [
        Duration(minutes: 1),
        Duration(minutes: 6),
        Duration(days: 1),
        Duration(days: 4),
      ];
    }
    int grow(double factor, int least) =>
        (intervalDays * factor).ceil().clamp(least, 36500);
    return [
      const Duration(minutes: 1),
      Duration(days: grow(1.2, 1)),
      Duration(days: grow(2.5, 3)),
      Duration(days: grow(3, 4)),
    ];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'meaning': meaning,
    'phonetic': phonetic,
    'example': example,
    'partOfSpeech': partOfSpeech,
    'definition': definition,
    'status': status,
    'due': due?.toIso8601String(),
    'intervalDays': intervalDays,
  };
  factory FlashWord.fromJson(Map<String, dynamic> j) => FlashWord(
    id: j['id'] as String,
    word: j['word'] as String,
    meaning: j['meaning'] as String,
    phonetic: j['phonetic'] as String? ?? '',
    example: j['example'] as String? ?? '',
    partOfSpeech: j['partOfSpeech'] as String? ?? 'NOUN',
    definition: j['definition'] as String? ?? '',
    status: j['status'] as String? ?? 'new',
    due: j['due'] == null ? null : DateTime.parse(j['due'] as String),
    intervalDays: j['intervalDays'] as int? ?? 0,
  );
}

class Deck {
  final String id, title, description;
  final int icon;
  final List<FlashWord> words;
  Deck({
    required this.id,
    required this.title,
    required this.description,
    required this.words,
    this.icon = 0,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'words': words.map((w) => w.toJson()).toList(),
  };
  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    icon: j['icon'] as int? ?? 0,
    words: (j['words'] as List)
        .map((w) => FlashWord.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList(),
  );
}
