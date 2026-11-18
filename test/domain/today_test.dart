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
    test('a word learned in the evening is due all of its day', () {
      final w = _w('evening');
      applyRating(w, DateTime(2026, 11, 1, 21), 2);
      expect(w.intervalDays, 3);
      expect(w.due, DateTime(2026, 11, 4, 4));
      final morning = DateTime(2026, 11, 4, 8);
      final plan = planToday(
        words: {'evening': w},
        decks: const [],
        now: morning,
        perDay: 10,
      );
      expect(plan.due, [w]);
      // Learning steps stay to the minute.
      final step = _w('step');
      applyRating(step, DateTime(2026, 11, 1, 21), 0);
      expect(step.due, DateTime(2026, 11, 1, 21, 1));
    });

    test('new words met before 04:00 count for the day before', () {
      final words = {for (final w in 'a b c d'.split(' ')) w: _w(w)};
      final deck = Deck(
        id: 'd',
        title: 'd',
        description: '',
        words: words.values.toList(),
      );
      // Two new words at 23:00, then the learner goes on past midnight.
      applyRating(words['a']!, DateTime(2026, 11, 1, 23), 2);
      applyRating(words['b']!, DateTime(2026, 11, 1, 23), 2);
      TodayPlan at(DateTime now) =>
          planToday(words: words, decks: [deck], now: now, perDay: 2);
      expect(at(DateTime(2026, 11, 2, 0, 30)).newLeft, 0);
      expect(at(DateTime(2026, 11, 2, 0, 30)).fresh, isEmpty);
      // The next study day starts at 04:00.
      expect(at(DateTime(2026, 11, 2, 4)).newLeft, 2);
    });

    test('work past midnight counts for the day before', () {
      final w = _w('late');
      applyRating(w, DateTime(2026, 11, 2, 1, 30), 2);
      expect(w.due, DateTime(2026, 11, 4, 4));
    });

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
}
