import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/domain/vocab/vocab.dart';

final _t = DateTime(2026, 11, 13, 9);

FlashWord _w(String word, {String example = ''}) => FlashWord(
  id: word,
  word: word,
  meaning: 'nghĩa của $word',
  example: example,
);

void main() {
  group('today', () {
    test('new words slow down while reviews pile up', () {
      expect(newWordsLeft(perDay: 10, metToday: 0, dueCount: 5), 10);
      expect(newWordsLeft(perDay: 10, metToday: 4, dueCount: 5), 6);
      expect(newWordsLeft(perDay: 10, metToday: 0, dueCount: 35), 5);
      expect(newWordsLeft(perDay: 10, metToday: 0, dueCount: 60), 0);
    });

    test('due words come lowest recall first; new ones follow deck order', () {
      final soon = _w('soon'), late = _w('late');
      applyRating(soon, _t.subtract(const Duration(days: 5)), 2);
      applyRating(late, _t.subtract(const Duration(days: 30)), 2);
      final saved = Deck(
        id: 'saved',
        title: '',
        description: '',
        words: [_w('mine')],
      );
      final builtIn = Deck(
        id: 'b',
        title: '',
        description: '',
        words: [_w('one'), _w('Mine'), soon, late],
      );
      final words = {
        for (final w in [...saved.words, ...builtIn.words]) wordKey(w.word): w,
      };
      final plan = planToday(
        words: words,
        decks: [saved, builtIn],
        now: _t,
        perDay: 2,
      );
      expect(plan.due.map((w) => w.word), ['late', 'soon']);
      expect(plan.fresh.map((w) => w.word), ['mine', 'one']);
    });

    test('a leg weaves one new word after every two reviews', () {
      final plan = TodayPlan(
        due: [_w('a'), _w('b'), _w('c'), _w('d')],
        fresh: [_w('x'), _w('y'), _w('z')],
        newLeft: 3,
      );
      expect(plan.leg().map((w) => w.word), [
        'a',
        'b',
        'x',
        'c',
        'd',
        'y',
        'z',
      ]);
      expect(plan.leg(5), hasLength(5));
    });
  });

  group('exercises', () {
    test('effort rises with the memory', () {
      final w = _w('resilient', example: 'The team is resilient.');
      expect(pickExercise(w, _t), ExerciseKind.intro);
      applyRating(w, _t, 0);
      expect(pickExercise(w, _t), ExerciseKind.choice);
      applyRating(w, _t, 2);
      expect(pickExercise(w, _t), ExerciseKind.typing);
      expect(pickExercise(w, _t, typing: false), ExerciseKind.choice);
      w
        ..stability = 40
        ..reviews = 4;
      expect(pickExercise(w, _t), ExerciseKind.cloze);
      w.reviews = 5;
      expect(pickExercise(w, _t), ExerciseKind.listening);
    });

    test('typed answers forgive case and one slip, not more', () {
      expect(gradeTyped(' Resilient! ', 'resilient'), Answer.correct);
      expect(gradeTyped('resilent', 'resilient'), Answer.almost);
      expect(gradeTyped('resistant', 'resilient'), Answer.wrong);
      expect(gradeTyped('', 'resilient'), Answer.wrong);
      expect(ratingFor(Answer.correct), 2);
      expect(ratingFor(Answer.correct, hints: 1), 1);
      expect(ratingFor(Answer.almost), 1);
      expect(ratingFor(Answer.wrong), 0);
    });

    test('a cloze blanks the word; hints reveal it step by step', () {
      final w = _w('resilient', example: 'The team is Resilient.');
      expect(clozeOf(w), 'The team is _____.');
      expect(clozeOf(_w('x', example: 'No match here.')), isNull);
      expect(hintFor('resilient', 0), 'r…');
      expect(hintFor('make it', 1), 'm _ _ _   _ _');
    });

    test('choices hold the answer and three others, the same each time', () {
      final w = _w('a');
      final others = [for (final x in 'bcdef'.split('')) _w(x)];
      final c = choicesFor(w, others);
      expect(c, hasLength(4));
      expect(c, contains(w.meaning));
      expect(choicesFor(w, others), c);
    });
  });
}
