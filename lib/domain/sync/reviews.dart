import '../models/deck.dart';
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
    this.stamp = Hlc.zero,
  });

  static const reset = -1, snapshot = -2;

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'at': at.toIso8601String(),
    'rating': rating,
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
    stamp: stamp,
  );
}

/// Applies one event to [word]'s schedule.
void applyReview(FlashWord word, ReviewEvent event) {
  switch (event.rating) {
    case ReviewEvent.reset:
      word
        ..status = 'new'
        ..due = null
        ..intervalDays = 0;
    case ReviewEvent.snapshot:
      word
        ..status = event.status
        ..due = event.due
        ..intervalDays = event.intervalDays;
    default:
      final interval = word.nextIntervals[event.rating];
      word
        ..status = event.rating == 0 ? 'learning' : 'review'
        ..intervalDays = interval.inDays
        ..due = event.at.add(interval);
  }
}

/// Rebuilds every card's schedule from [events], in time order; events at
/// the same moment follow their record stamps, then their ids.
/// Cards without events are left new.
void replayReviews(Iterable<FlashWord> words, Iterable<ReviewEvent> events) {
  final byWord = <String, List<ReviewEvent>>{};
  for (final e in events) {
    (byWord[e.wordId] ??= []).add(e);
  }
  for (final word in words) {
    word
      ..status = 'new'
      ..due = null
      ..intervalDays = 0;
    final log = byWord[word.id];
    if (log == null) continue;
    log.sort((a, b) {
      final t = a.at.compareTo(b.at);
      if (t != 0) return t;
      final s = a.stamp.compareTo(b.stamp);
      return s != 0 ? s : a.id.compareTo(b.id);
    });
    for (final e in log) {
      applyReview(word, e);
    }
  }
}
