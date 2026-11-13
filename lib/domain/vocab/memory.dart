import '../models/deck.dart';
import 'fsrs.dart';

/// How well a word is known, from its memory profile.
enum MemoryLevel {
  /// Never reviewed.
  fresh,

  /// In its first steps, or relearning after a lapse.
  learning,

  /// Remembered, but for less than [knownDays].
  remembering,

  /// Remembered for [knownDays] or more.
  known,

  /// Known, and produced (typed or used) right in the last [masteryWindow].
  mastered,
}

const knownDays = 21.0;
const masteryWindow = Duration(days: 60);

MemoryLevel levelOf(FlashWord w, DateTime now) {
  if (w.status == 'new') return MemoryLevel.fresh;
  if (w.status == 'learning') return MemoryLevel.learning;
  if (w.stability < knownDays) return MemoryLevel.remembering;
  final recall = w.lastRecall;
  return recall != null && now.difference(recall) <= masteryWindow
      ? MemoryLevel.mastered
      : MemoryLevel.known;
}

/// The chance the learner remembers [w] now, 0 for a new card.
double recallNow(FlashWord w, DateTime now) {
  final last = w.lastReview;
  if (w.status == 'new' || last == null || w.stability <= 0) return 0;
  final days = now.difference(last).inSeconds / Duration.secondsPerDay;
  return Fsrs.recall(days < 0 ? 0 : days, w.stability);
}

/// A word is hard for this learner after this many lapses, or when its
/// difficulty is this high.
const hardLapses = 4, hardDifficulty = 8.0;

bool isHard(FlashWord w) =>
    w.lapses >= hardLapses ||
    (w.reviews >= 3 && w.difficulty >= hardDifficulty);
