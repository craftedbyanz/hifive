import 'dart:math' as math;

import '../models/deck.dart';
import 'fsrs.dart';

/// What one rating would do to a card.
class Outcome {
  final String status;
  final double stability, difficulty;
  final Duration interval;
  final int lapses;
  const Outcome({
    required this.status,
    required this.stability,
    required this.difficulty,
    required this.interval,
    required this.lapses,
  });
}

/// Learning steps: "Học lại" brings a card back in a minute, "Khó" on a
/// card still being learned in six.
const againStep = Duration(minutes: 1), hardStep = Duration(minutes: 6);

const _day = Duration(days: 1);

double _days(Duration d) => d.inSeconds / Duration.secondsPerDay;

Duration _toDays(double s) =>
    Duration(days: Fsrs.interval(s).round().clamp(1, Fsrs.maxDays));

/// The four outcomes of rating [word] now, indexed by rating 0 (Học lại) to
/// 3 (Dễ). Longer answers never get shorter intervals than shorter ones.
List<Outcome> preview(FlashWord word, DateTime now) {
  final out = <Outcome>[];
  if (word.status == 'new') {
    for (var g = Fsrs.again; g <= Fsrs.easy; g++) {
      final s = Fsrs.initialStability(g), d = Fsrs.initialDifficulty(g);
      out.add(
        Outcome(
          status: g <= Fsrs.hard ? 'learning' : 'review',
          stability: s,
          difficulty: d,
          interval: g == Fsrs.again
              ? againStep
              : g == Fsrs.hard
              ? hardStep
              : _toDays(s),
          lapses: 0,
        ),
      );
    }
  } else {
    final last = word.lastReview ?? now;
    final elapsed = math.max(0.0, _days(now.difference(last)));
    final sameDay = elapsed < 1;
    final r = Fsrs.recall(elapsed, word.stability);
    final learning = word.status == 'learning';
    for (var g = Fsrs.again; g <= Fsrs.easy; g++) {
      final d = Fsrs.nextDifficulty(word.difficulty, g);
      final double s;
      if (sameDay || learning) {
        s = Fsrs.shortTermStability(word.stability, g);
      } else if (g == Fsrs.again) {
        s = Fsrs.forgetStability(word.difficulty, word.stability, r);
      } else {
        s = Fsrs.recallStability(word.difficulty, word.stability, r, g);
      }
      final lapse = g == Fsrs.again && !learning;
      out.add(
        Outcome(
          status: g == Fsrs.again || (learning && g == Fsrs.hard)
              ? 'learning'
              : 'review',
          stability: math.max(.1, s),
          difficulty: d,
          interval: g == Fsrs.again
              ? againStep
              : learning && g == Fsrs.hard
              ? hardStep
              : _toDays(math.max(.1, s)),
          lapses: word.lapses + (lapse ? 1 : 0),
        ),
      );
    }
  }
  // Keep the day intervals in order: Khó < Tốt < Dễ.
  for (var i = 2; i < 4; i++) {
    final before = out[i - 1].interval;
    if (before >= _day && out[i].interval <= before) {
      final o = out[i];
      out[i] = Outcome(
        status: o.status,
        stability: o.stability,
        difficulty: o.difficulty,
        interval: before + _day,
        lapses: o.lapses,
      );
    }
  }
  return out;
}

/// Applies a rating 0 (Học lại) to 3 (Dễ) given at [at].
void applyRating(FlashWord word, DateTime at, int rating) {
  final o = preview(word, at)[rating];
  word
    ..status = o.status
    ..stability = o.stability
    ..difficulty = o.difficulty
    ..lapses = o.lapses
    ..intervalDays = o.interval.inDays
    ..due = at.add(o.interval)
    ..firstReview ??= at
    ..lastReview = at
    ..reviews += 1;
}

/// Seeds a card from a schedule saved before the review log existed.
void applySnapshot(
  FlashWord word,
  String status,
  DateTime? due,
  int intervalDays,
) {
  word
    ..status = status
    ..due = due
    ..intervalDays = intervalDays
    ..stability = status == 'new' ? 0 : math.max(1.0, intervalDays.toDouble())
    ..difficulty = status == 'new' ? 0 : 5
    ..lastReview = due?.subtract(Duration(days: intervalDays));
}

/// Clears a card's memory, as "Đặt lại lịch" does.
void resetCard(FlashWord word) => word
  ..status = 'new'
  ..due = null
  ..intervalDays = 0
  ..stability = 0
  ..difficulty = 0
  ..lapses = 0
  ..lastReview = null
  ..firstReview = null
  ..reviews = 0
  ..lastRecall = null;
