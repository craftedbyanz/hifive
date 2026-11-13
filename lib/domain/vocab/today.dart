import '../models/deck.dart';
import 'memory.dart';

/// Words a session takes at most; a longer day is several legs.
const legSize = 20;

/// Today's work: words due, lowest recall first, and new words to meet.
class TodayPlan {
  final List<FlashWord> due, fresh;

  /// New words still allowed today after the ones already met.
  final int newLeft;
  const TodayPlan({
    required this.due,
    required this.fresh,
    required this.newLeft,
  });

  bool get isEmpty => due.isEmpty && fresh.isEmpty;

  /// The next leg: due words first, then new ones woven in so a session
  /// never starts with a run of unfamiliar words.
  List<FlashWord> leg([int size = legSize]) {
    final reviews = due.take(size).toList();
    final news = fresh.take(size - reviews.length).toList();
    if (reviews.isEmpty) return news;
    final out = <FlashWord>[];
    var n = 0;
    for (var i = 0; i < reviews.length; i++) {
      out.add(reviews[i]);
      // One new word after every two reviews.
      if (i.isOdd && n < news.length) out.add(news[n++]);
    }
    return [...out, ...news.skip(n)];
  }
}

/// How many new words today allows: [perDay], less those already met today,
/// and fewer while reviews pile up, so the backlog never runs away.
int newWordsLeft({
  required int perDay,
  required int metToday,
  required int dueCount,
}) {
  final left = perDay - metToday;
  if (left <= 0) return 0;
  if (dueCount >= perDay * 6) return 0;
  if (dueCount >= perDay * 3) return left ~/ 2;
  return left;
}

/// Plans today from one card per word ([words]), with [decks] in the order
/// new words are offered: the learner's saved words, then their own decks,
/// then hifive's.
TodayPlan planToday({
  required Map<String, FlashWord> words,
  required List<Deck> decks,
  required DateTime now,
  required int perDay,
}) {
  final day = DateTime(now.year, now.month, now.day);
  final due = [
    for (final w in words.values)
      if (w.status != 'new' && w.isDue(now)) w,
  ]..sort((a, b) => recallNow(a, now).compareTo(recallNow(b, now)));
  final metToday = words.values.where((w) {
    final first = w.firstReview;
    return first != null && !first.isBefore(day);
  }).length;
  final left = newWordsLeft(
    perDay: perDay,
    metToday: metToday,
    dueCount: due.length,
  );
  final seen = <String>{};
  final fresh = <FlashWord>[];
  for (final deck in decks) {
    for (final w in deck.words) {
      if (fresh.length >= left) break;
      final key = w.word.trim().toLowerCase();
      if (w.status == 'new' && seen.add(key)) fresh.add(w);
    }
  }
  return TodayPlan(due: due, fresh: fresh, newLeft: left);
}
