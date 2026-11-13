import 'dart:math' as math;

import '../models/deck.dart';
import 'memory.dart';

/// How a word is asked. Effort rises as the memory strengthens: a new word
/// is met, a learning word recognised, a remembered word produced, a known
/// word heard or used in a sentence.
enum ExerciseKind {
  /// Meet the word, guess its meaning, then rate yourself.
  intro('flip', 'meaning'),

  /// Pick the meaning from four.
  choice('choice', 'meaning'),

  /// See the meaning, type the word.
  typing('typing', 'recall'),

  /// Hear the word, type it.
  listening('listening', 'form'),

  /// Fill the word into its example sentence.
  cloze('cloze', 'use');

  /// The `mode` and `skill` its reviews are logged with.
  final String mode, skill;
  const ExerciseKind(this.mode, this.skill);
}

/// The exercise for [w] now. [typing] and [listening] can be turned off in
/// the lesson settings; then a word that would need them is asked as a
/// choice.
ExerciseKind pickExercise(
  FlashWord w,
  DateTime now, {
  bool typing = true,
  bool listening = true,
}) {
  const fallback = ExerciseKind.choice;
  switch (levelOf(w, now)) {
    case MemoryLevel.fresh:
      return ExerciseKind.intro;
    case MemoryLevel.learning:
      return ExerciseKind.choice;
    case MemoryLevel.remembering:
      return typing ? ExerciseKind.typing : fallback;
    case MemoryLevel.known || MemoryLevel.mastered:
      // Alternate, so a known word is used in context one time and heard
      // the next.
      if (w.reviews.isEven && typing && clozeOf(w) != null) {
        return ExerciseKind.cloze;
      }
      if (listening && typing) return ExerciseKind.listening;
      return typing ? ExerciseKind.typing : fallback;
  }
}

String _normal(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r"[^\p{L}\p{N}' ]", unicode: true), '')
    .trim();

/// [w]'s example with the word blanked out, or null when the example does
/// not contain it.
String? clozeOf(FlashWord w) {
  final word = w.word.trim();
  if (word.isEmpty || w.example.isEmpty) return null;
  final re = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
  if (!re.hasMatch(w.example)) return null;
  return w.example.replaceAll(re, '_____');
}

enum Answer { correct, almost, wrong }

/// Grades a typed answer: exact (ignoring case and punctuation), one letter
/// off in a word of four or more letters, or wrong.
Answer gradeTyped(String typed, String word) {
  final a = _normal(typed), b = _normal(word);
  if (a.isEmpty) return Answer.wrong;
  if (a == b) return Answer.correct;
  if (b.length >= 4 && _distance(a, b) <= 1) return Answer.almost;
  return Answer.wrong;
}

/// The rating an app-graded answer gives: wrong is Học lại, right after a
/// hint or with a slip is Khó, right is Tốt. The learner may raise a right
/// answer to Dễ.
int ratingFor(Answer answer, {int hints = 0}) => switch (answer) {
  Answer.wrong => 0,
  Answer.almost => 1,
  Answer.correct => hints > 0 ? 1 : 2,
};

/// The hint after [hints] earlier ones: the first letter, then the length
/// with the first letter, as "r _ _ _ _ _ _ _ _".
String hintFor(String word, int hints) {
  final w = word.trim();
  if (w.isEmpty) return '';
  if (hints <= 0) return '${w[0]}…';
  return [
    w[0],
    for (var i = 1; i < w.length; i++) w[i] == ' ' ? ' ' : '_',
  ].join(' ');
}

/// Four meanings: [w]'s and three from [others], in an order fixed by the
/// word, so a redraw does not reshuffle them.
List<String> choicesFor(FlashWord w, Iterable<FlashWord> others) {
  final pool = <String>{};
  for (final o in others) {
    if (o.meaning != w.meaning && o.word != w.word) pool.add(o.meaning);
  }
  final rnd = math.Random(w.id.hashCode);
  final picked = (pool.toList()..shuffle(rnd)).take(3).toList();
  return [w.meaning, ...picked]..shuffle(rnd);
}

int _distance(String a, String b) {
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = math.min(
        math.min(cur[j - 1] + 1, prev[j] + 1),
        prev[j - 1] + cost,
      );
    }
    prev = cur;
  }
  return prev[b.length];
}
