import '../models/deck.dart';
import '../vocab/scheduler.dart';
import 'hlc.dart';

/// One entry in a card's review log. Replaying a card's log in time order
/// gives its schedule, so reviews made on two devices both count.
class ReviewEvent {
  final String id, wordId;
  final DateTime at;

  /// 0 to 3 for a rating, [reset] for "Đặt lại lịch", [snapshot] for a state
  /// carried over from data saved before the log existed.
  final int rating;
  final String status;
  final DateTime? due;
  final int intervalDays;

  /// The study-tree species chosen when this rating was made, written only
  /// when the card was new or due, so the rating grows the garden.
  final String? tree;

  /// The word itself ([wordKey]), so the same word in several decks shares
  /// one memory. Older events lack it and are matched through [wordId].
  final String? word;

  /// How the word was asked: `flip`, `choice`, `typing`, `listening`,
  /// `cloze`, `spelling` or `sentence`.
  final String mode;

  /// What was practised: `meaning` (see the word, know the meaning),
  /// `recall` (have the meaning, produce the word), `form` (spelling or
  /// sound) or `use`.
  final String skill;

  /// Where it happened: `flashcard`, `today`, `focusBreak`, `flowLetter`,
  /// `dictionary`, `writing` or `conversation`.
  final String source;

  /// Milliseconds to answer, when measured.
  final int? ms;

  /// Hints used before answering.
  final int hints;

  /// The stamp of the record holding this event. It orders events made at
  /// the same moment the way they were written.
  final Hlc stamp;
  const ReviewEvent({
    required this.id,
    required this.wordId,
    required this.at,
    required this.rating,
    this.status = 'new',
    this.due,
    this.intervalDays = 0,
    this.tree,
    this.word,
    this.mode = 'flip',
    this.skill = 'meaning',
    this.source = 'flashcard',
    this.ms,
    this.hints = 0,
    this.stamp = Hlc.zero,
  });

  static const reset = -1, snapshot = -2;

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'at': at.toIso8601String(),
    'rating': rating,
    if (tree != null) 'tree': tree,
    if (word != null) 'word': word,
    if (mode != 'flip') 'mode': mode,
    if (skill != 'meaning') 'skill': skill,
    if (source != 'flashcard') 'source': source,
    if (ms != null) 'ms': ms,
    if (hints > 0) 'hints': hints,
    if (rating == snapshot) ...{
      'status': status,
      'due': due?.toIso8601String(),
      'intervalDays': intervalDays,
    },
  };

  factory ReviewEvent.fromJson(
    String id,
    Map<String, dynamic> j, {
    Hlc stamp = Hlc.zero,
  }) => ReviewEvent(
    id: id,
    wordId: j['wordId'] as String,
    at: DateTime.parse(j['at'] as String),
    rating: j['rating'] as int,
    status: j['status'] as String? ?? 'new',
    due: j['due'] == null ? null : DateTime.parse(j['due'] as String),
    intervalDays: j['intervalDays'] as int? ?? 0,
    tree: j['tree'] as String?,
    word: j['word'] as String?,
    mode: j['mode'] as String? ?? 'flip',
    skill: j['skill'] as String? ?? 'meaning',
    source: j['source'] as String? ?? 'flashcard',
    ms: j['ms'] as int?,
    hints: j['hints'] as int? ?? 0,
    stamp: stamp,
  );
}

/// The key one word's memory is kept under: its text, trimmed and in lower
/// case, so the same word in two decks is one memory.
String wordKey(String text) => text.trim().toLowerCase();

/// Skills that show the learner can produce the word, for mastery.
const productionSkills = {'recall', 'use'};

/// Applies one event to [word]'s schedule.
void applyReview(FlashWord word, ReviewEvent event) {
  switch (event.rating) {
    case ReviewEvent.reset:
      resetCard(word);
    case ReviewEvent.snapshot:
      applySnapshot(word, event.status, event.due, event.intervalDays);
    default:
      applyRating(word, event.at, event.rating);
      if (event.rating >= 2 && productionSkills.contains(event.skill)) {
        word.lastRecall = event.at;
      }
  }
}

/// Rebuilds every card's schedule from [events], in time order; events at
/// the same moment follow their record stamps, then their ids. Cards that
/// hold the same word share one replay. Cards without events are left new.
/// [onDue] hears every rating given to a card that was new or due at that
/// moment; [onRated] hears every rating with the card's status just before
/// it, for measuring retention.
void replayReviews(
  Iterable<FlashWord> words,
  Iterable<ReviewEvent> events, {
  void Function(ReviewEvent event)? onDue,
  void Function(ReviewEvent event, String statusBefore)? onRated,
}) {
  final keyOf = <String, String>{};
  final byKey = <String, List<FlashWord>>{};
  for (final w in words) {
    resetCard(w);
    final key = wordKey(w.word);
    keyOf[w.id] = key;
    (byKey[key] ??= []).add(w);
  }
  final log = <String, List<ReviewEvent>>{};
  for (final e in events) {
    final key = e.word ?? keyOf[e.wordId];
    if (key != null) (log[key] ??= []).add(e);
  }
  for (final MapEntry(:key, value: cards) in byKey.entries) {
    final list = log[key];
    if (list == null) continue;
    list.sort((a, b) {
      final t = a.at.compareTo(b.at);
      if (t != 0) return t;
      final s = a.stamp.compareTo(b.stamp);
      return s != 0 ? s : a.id.compareTo(b.id);
    });
    final first = cards.first;
    for (final e in list) {
      if (onDue != null && e.rating >= 0 && first.isDue(e.at)) onDue(e);
      if (onRated != null && e.rating >= 0) onRated(e, first.status);
      applyReview(first, e);
    }
    for (final other in cards.skip(1)) {
      other
        ..status = first.status
        ..due = first.due
        ..intervalDays = first.intervalDays
        ..stability = first.stability
        ..difficulty = first.difficulty
        ..lapses = first.lapses
        ..reviews = first.reviews
        ..firstReview = first.firstReview
        ..lastReview = first.lastReview
        ..lastRecall = first.lastRecall;
    }
  }
}
