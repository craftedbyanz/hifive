import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/domain/vocab/vocab.dart';

final _t = DateTime(2026, 11, 1, 9);

FlashWord _word(String id, [String text = 'resilient']) =>
    FlashWord(id: id, word: text, meaning: 'kiên cường');

ReviewEvent _rate(String wordId, Duration after, int rating, {String? skill}) =>
    ReviewEvent(
      id: '$wordId-${after.inMinutes}-$rating',
      wordId: wordId,
      at: _t.add(after),
      rating: rating,
      skill: skill ?? 'meaning',
    );

void main() {
  group('FSRS', () {
    test('recall is 90% after one stability of days', () {
      expect(Fsrs.recall(10, 10), closeTo(.9, 1e-9));
      expect(Fsrs.interval(10), closeTo(10, 1e-9));
      expect(Fsrs.recall(30, 10), lessThan(.9));
    });

    test('a first rating sets the published starting stability', () {
      for (var g = 1; g <= 4; g++) {
        expect(Fsrs.initialStability(g), Fsrs.w[g - 1]);
      }
      expect(
        Fsrs.initialDifficulty(Fsrs.again),
        greaterThan(Fsrs.initialDifficulty(Fsrs.easy)),
      );
    });

    test('remembering a nearly forgotten card raises stability more', () {
      const d = 5.0, s = 10.0;
      final fresh = Fsrs.recallStability(d, s, .97, Fsrs.good);
      final nearlyGone = Fsrs.recallStability(d, s, .8, Fsrs.good);
      expect(nearlyGone, greaterThan(fresh));
      expect(fresh, greaterThan(s));
    });

    test('a lapse lowers stability but never to zero', () {
      final after = Fsrs.forgetStability(5, 40, .85);
      expect(after, lessThan(40));
      expect(after, greaterThan(0));
    });
  });

  group('scheduling', () {
    test('Khó on a new card keeps it in learning', () {
      final w = _word('a');
      applyRating(w, _t, 1);
      expect(w.status, 'learning');
      expect(w.due, _t.add(hardStep));
    });

    test('forgetting a known card is a lapse, not a fresh start', () {
      final w = _word('a');
      applyRating(w, _t, 2);
      applyRating(w, _t.add(const Duration(days: 3)), 2);
      final before = w.stability;
      applyRating(w, _t.add(const Duration(days: 20)), 0);
      expect(w.lapses, 1);
      expect(w.status, 'learning');
      expect(w.stability, greaterThan(.5));
      expect(w.stability, lessThan(before));
    });

    test('a late review that is still remembered earns a longer gap', () {
      final onTime = _word('a'), late = _word('b');
      for (final w in [onTime, late]) {
        applyRating(w, _t, 2);
      }
      applyRating(onTime, _t.add(const Duration(days: 3)), 2);
      applyRating(late, _t.add(const Duration(days: 9)), 2);
      expect(late.stability, greaterThan(onTime.stability));
    });
  });

  group('replay', () {
    test('the same word in two decks shares one memory', () {
      final mine = _word('mine'), saved = _word('saved', ' Resilient ');
      replayReviews(
        [mine, saved],
        [
          _rate('mine', Duration.zero, 2),
          _rate('saved', const Duration(days: 3), 2),
        ],
      );
      expect(mine.reviews, 2);
      expect(saved.reviews, 2);
      expect(saved.due, mine.due);
    });

    test('events with the word key reach a card with another id', () {
      final card = _word('new-id');
      replayReviews(
        [card],
        [
          ReviewEvent(
            id: 'e',
            wordId: 'old-id',
            at: _t,
            rating: 2,
            word: wordKey('Resilient'),
          ),
        ],
      );
      expect(card.status, 'review');
    });

    test('new fields survive the record round trip; old records default', () {
      final e = ReviewEvent(
        id: 'e',
        wordId: 'w',
        at: _t,
        rating: 2,
        word: 'resilient',
        mode: 'typing',
        skill: 'recall',
        source: 'today',
        ms: 2400,
        hints: 1,
      );
      final back = ReviewEvent.fromJson('e', e.toJson());
      expect(
        (back.word, back.mode, back.skill, back.source, back.ms, back.hints),
        ('resilient', 'typing', 'recall', 'today', 2400, 1),
      );
      final old = ReviewEvent.fromJson('o', {
        'wordId': 'w',
        'at': _t.toIso8601String(),
        'rating': 2,
      });
      expect(
        (old.mode, old.skill, old.source),
        ('flip', 'meaning', 'flashcard'),
      );
    });
  });

  group('levels', () {
    test('a word moves from new to known, and to mastered once produced', () {
      final w = _word('a');
      expect(levelOf(w, _t), MemoryLevel.fresh);
      replayReviews([w], [_rate('a', Duration.zero, 0)]);
      expect(levelOf(w, _t), MemoryLevel.learning);

      final events = [
        _rate('a', Duration.zero, 2),
        _rate('a', const Duration(days: 3), 2),
        _rate('a', const Duration(days: 12), 3),
        _rate('a', const Duration(days: 60), 2),
      ];
      replayReviews([w], events);
      final at = _t.add(const Duration(days: 61));
      expect(w.stability, greaterThanOrEqualTo(knownDays));
      expect(levelOf(w, at), MemoryLevel.known);

      replayReviews(
        [w],
        [...events, _rate('a', const Duration(days: 61), 2, skill: 'recall')],
      );
      expect(levelOf(w, at.add(const Duration(days: 1))), MemoryLevel.mastered);
    });

    test('recall now falls with time since the last review', () {
      final w = _word('a');
      applyRating(w, _t, 2);
      expect(recallNow(w, _t), closeTo(1, 1e-9));
      expect(
        recallNow(w, _t.add(const Duration(days: 30))),
        lessThan(recallNow(w, _t.add(const Duration(days: 3)))),
      );
    });

    test('a word forgotten four times is hard', () {
      final w = _word('a');
      var at = _t;
      for (var i = 0; i < 4; i++) {
        applyRating(w, at, 2);
        at = at.add(const Duration(days: 4));
        applyRating(w, at, 0);
        at = at.add(const Duration(days: 1));
      }
      expect(isHard(w), isTrue);
    });
  });
}
