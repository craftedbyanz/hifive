import '../models/deck.dart';
import '../sync/reviews.dart';
import 'memory.dart';

/// One rating with the card's status just before it.
class Rated {
  final ReviewEvent event;
  final String before;
  const Rated(this.event, this.before);
}

/// What the learner's memory looks like now, from the cards and the log.
class MemoryInsight {
  final Map<MemoryLevel, int> levels;

  /// Share of reviews of known cards answered from memory in the last
  /// [window], or null with fewer than [minReviews] of them.
  final double? retention;
  final int retentionReviews;

  /// Words due on each of the next seven days; today includes overdue ones.
  final List<int> forecast;

  /// Share right per skill, for skills practised with app-graded exercises.
  final Map<String, double> skills;
  final List<FlashWord> hard;

  const MemoryInsight({
    required this.levels,
    required this.retention,
    required this.retentionReviews,
    required this.forecast,
    required this.skills,
    required this.hard,
  });

  static const window = Duration(days: 30);
  static const minReviews = 10;

  factory MemoryInsight.of(
    Iterable<FlashWord> words,
    List<Rated> log,
    DateTime now,
  ) {
    final levels = {for (final l in MemoryLevel.values) l: 0};
    for (final w in words) {
      levels[levelOf(w, now)] = levels[levelOf(w, now)]! + 1;
    }
    final since = now.subtract(window);
    final known = [
      for (final r in log)
        if (r.before == 'review' && !r.event.at.isBefore(since)) r.event,
    ];
    final kept = known.where((e) => e.rating >= 1).length;

    final today = DateTime(now.year, now.month, now.day);
    final forecast = List<int>.filled(7, 0);
    for (final w in words) {
      final due = w.due;
      if (w.status == 'new' || due == null) continue;
      final day = DateTime(
        due.year,
        due.month,
        due.day,
      ).difference(today).inDays;
      if (day < 7) forecast[day < 0 ? 0 : day]++;
    }

    final tries = <String, int>{}, right = <String, int>{};
    for (final r in log) {
      final e = r.event;
      if (e.mode == 'flip' || e.at.isBefore(since)) continue;
      tries[e.skill] = (tries[e.skill] ?? 0) + 1;
      if (e.rating >= 1) right[e.skill] = (right[e.skill] ?? 0) + 1;
    }

    return MemoryInsight(
      levels: levels,
      retention: known.length < minReviews ? null : kept / known.length,
      retentionReviews: known.length,
      forecast: forecast,
      skills: {
        for (final MapEntry(:key, :value) in tries.entries)
          key: (right[key] ?? 0) / value,
      },
      hard: [
        for (final w in words)
          if (isHard(w)) w,
      ]..sort((a, b) => b.lapses.compareTo(a.lapses)),
    );
  }
}
