import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/sync/sync.dart';

FlashWord _word(String id) => FlashWord(id: id, word: id, meaning: id);

void main() {
  group('HLC', () {
    test('stamps keep rising when the wall clock goes backwards', () {
      var wall = DateTime(2026, 11, 6, 10);
      final clock = HlcClock(node: 'a', now: () => wall);
      final first = clock.tick();
      wall = wall.subtract(const Duration(minutes: 5));
      final second = clock.tick();
      expect(second > first, isTrue);
      expect(second.millis, first.millis);
      expect(second.counter, 1);
    });

    test('a device moves past stamps it receives', () {
      final behind = HlcClock(node: 'ipad', now: () => DateTime(2026, 11, 1));
      final ahead = HlcClock(node: 'iphone', now: () => DateTime(2026, 11, 6));
      final remote = ahead.tick();
      behind.receive(remote);
      expect(behind.tick() > remote, isTrue);
    });

    test('the string form sorts like the stamps and parses back', () {
      final stamps = [
        const Hlc(5, 0, 'b'),
        const Hlc(5, 1, 'a'),
        const Hlc(40, 0, 'a'),
        const Hlc(1234567890123, 36, 'z'),
      ];
      final texts = stamps.map((s) => s.toString()).toList();
      expect([...texts]..sort(), texts);
      expect(texts.map(Hlc.parse), stamps);
    });
  });

  group('merge', () {
    test('the later stamp wins whichever side it is on', () {
      const older = SyncRecord('setting', 'voice', {
        'v': 'Aaron',
      }, Hlc(1, 0, 'a'));
      const newer = SyncRecord('setting', 'voice', {
        'v': 'Mia',
      }, Hlc(2, 0, 'b'));
      expect(mergeRecords(older, newer), same(newer));
      expect(mergeRecords(newer, older), same(newer));
    });

    test('a deletion with a later stamp beats an edit', () {
      const edit = SyncRecord('deck', 'd', {'title': 'X'}, Hlc(1, 0, 'a'));
      const delete = SyncRecord('deck', 'd', null, Hlc(2, 0, 'b'));
      expect(mergeRecords(edit, delete).deleted, isTrue);
    });
  });

  group('ids', () {
    test('UUID v7 has the version, variant and time prefix', () {
      final time = DateTime.utc(2026, 11, 6);
      final id = uuidV7(time, random: Random(1));
      expect(
        id,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab]')),
      );
      final ms = int.parse(id.replaceAll('-', '').substring(0, 12), radix: 16);
      expect(ms, time.millisecondsSinceEpoch);
    });

    test('ids made at the same moment differ', () {
      final time = DateTime(2026, 11, 6);
      final ids = {for (var i = 0; i < 1000; i++) uuidV7(time)};
      expect(ids, hasLength(1000));
    });

    test('a saved word has the same id on every device', () {
      expect(savedWordId(' Sorry'), savedWordId('sorry'));
    });
  });

  group('review log', () {
    final t = DateTime(2026, 11, 1, 9);

    test('replay gives the schedule rating one card would get', () {
      final word = _word('w');
      replayReviews(
        [word],
        [ReviewEvent(id: '1', wordId: 'w', at: t, rating: 2)],
      );
      expect(word.status, 'review');
      expect(word.intervalDays, 1);
      expect(word.due, t.add(const Duration(days: 1)));
    });

    test('reviews made on two devices both count, in time order', () {
      final word = _word('w');
      // The iPad's later review arrives first through sync.
      final ipad = ReviewEvent(
        id: 'b',
        wordId: 'w',
        at: t.add(const Duration(days: 1)),
        rating: 2,
      );
      final iphone = ReviewEvent(id: 'a', wordId: 'w', at: t, rating: 2);
      replayReviews([word], [ipad, iphone]);
      // Good after Good: the second review grows the one-day interval.
      expect(word.intervalDays, 3);
      expect(word.due, ipad.at.add(const Duration(days: 3)));
    });

    test('a reset clears earlier reviews but not later ones', () {
      final word = _word('w');
      replayReviews(
        [word],
        [
          ReviewEvent(id: '1', wordId: 'w', at: t, rating: 3),
          ReviewEvent(
            id: '2',
            wordId: 'w',
            at: t.add(const Duration(hours: 1)),
            rating: ReviewEvent.reset,
          ),
        ],
      );
      expect(word.status, 'new');
      expect(word.due, isNull);
    });

    test('events at the same moment follow their record stamps', () {
      final word = _word('w');
      // A rating then a reset in one millisecond, with ids that sort the
      // other way round.
      replayReviews(
        [word],
        [
          ReviewEvent(
            id: 'z',
            wordId: 'w',
            at: t,
            rating: 3,
            stamp: const Hlc(1, 0, 'a'),
          ),
          ReviewEvent(
            id: 'a',
            wordId: 'w',
            at: t,
            rating: ReviewEvent.reset,
            stamp: const Hlc(1, 1, 'a'),
          ),
        ],
      );
      expect(word.status, 'new');
    });

    test('a snapshot carries over a migrated schedule', () {
      final word = _word('w');
      final due = DateTime(2026, 12, 1);
      final event = ReviewEvent(
        id: '1',
        wordId: 'w',
        at: t,
        rating: ReviewEvent.snapshot,
        status: 'review',
        due: due,
        intervalDays: 9,
      );
      final copy = ReviewEvent.fromJson('1', event.toJson());
      replayReviews([word], [copy]);
      expect((word.status, word.due, word.intervalDays), ('review', due, 9));
    });

    test('cards without a log are new', () {
      final word = _word('w')
        ..status = 'review'
        ..intervalDays = 4;
      replayReviews([word], const []);
      expect(word.status, 'new');
    });
  });
}
