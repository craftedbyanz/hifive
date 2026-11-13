import '../vocab/scheduler.dart';

class FlashWord {
  final String id, word, meaning, phonetic, example, partOfSpeech, definition;
  String status;
  DateTime? due;

  /// Days until the next review once the card is known. Zero while learning.
  int intervalDays;

  // The memory profile below is derived by replaying the review log
  // (`replayReviews`) and never stored. See `docs/memory-plan.md`.

  /// FSRS stability: days until recall falls to 90%. Zero while new.
  double stability = 0;

  /// FSRS difficulty, 1 to 10. Zero while new.
  double difficulty = 0;

  /// Times the card was forgotten after it was known.
  int lapses = 0;

  /// Ratings given, all time.
  int reviews = 0;
  DateTime? firstReview, lastReview;

  /// The last time the learner produced the word (typed or used it) right.
  DateTime? lastRecall;
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

  /// How long each rating 0 (Học lại) to 3 (Dễ) would put the card away.
  List<Duration> nextIntervals(DateTime now) => [
    for (final o in preview(this, now)) o.interval,
  ];

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
