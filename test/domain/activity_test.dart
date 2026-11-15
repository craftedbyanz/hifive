import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/activity/activity.dart';
import 'package:hifive/domain/listening/listening.dart';
import 'package:hifive/domain/sync/reviews.dart';
import 'package:hifive/domain/vocab/catalog.dart';

ReviewEvent answer(
  String word,
  DateTime at,
  int rating, {
  String source = 'today',
}) => ReviewEvent(
  id: '$word-${at.millisecondsSinceEpoch}',
  wordId: word,
  word: word,
  at: at,
  rating: rating,
  source: source,
);

void main() {
  final t = DateTime(2026, 11, 15, 9);

  test('answers within half an hour are one session, newest first', () {
    final sessions = wordSessions([
      answer('cat', t, 0),
      answer('dog', t.add(const Duration(minutes: 1)), 2),
      // Asked again later in the same session: the last answer counts.
      answer('cat', t.add(const Duration(minutes: 3)), 2),
      answer('sun', t.add(const Duration(hours: 2)), 0, source: 'flashcard'),
      ReviewEvent(
        id: 'r',
        wordId: 'sun',
        word: 'sun',
        at: t,
        rating: ReviewEvent.reset,
      ),
    ]);
    expect(sessions, hasLength(2));
    expect(sessions.first.source, 'flashcard');
    expect(sessions.first.words, ['sun']);
    expect(sessions.first.forgot, 1);
    final first = sessions.last;
    expect(first.words, ['cat', 'dog']);
    expect(first.known, 2);
    expect(first.source, 'today');
    expect(first.end, t.add(const Duration(minutes: 3)));
  });

  test('listening is named from the catalog and short plays are left out', () {
    const source = ListeningSource(
      id: 's',
      title: 'Podcast A1',
      channel: 'REACH',
      level: 'A1',
      description: '',
      playlistId: 'p',
      coverVideoId: 'v1',
      episodes: [
        Episode(id: 'v1', title: 'Ăn chay', seconds: 600),
        Episode(id: 'v2', title: 'Thói quen', seconds: 700),
      ],
    );
    final log = ListenLog([
      ListenDay(
        video: 'v2',
        day: '2026-11-14',
        position: 300,
        heard: 300,
        done: false,
        at: t.subtract(const Duration(days: 1)),
      ),
      ListenDay(
        video: 'v1',
        day: '2026-11-15',
        position: 600,
        heard: 590,
        done: true,
        at: t,
      ),
      ListenDay(
        video: 'v1',
        day: '2026-11-13',
        position: 5,
        heard: 5,
        done: false,
        at: t.subtract(const Duration(days: 2)),
      ),
      ListenDay(
        video: 'gone',
        day: '2026-11-15',
        position: 60,
        heard: 60,
        done: false,
        at: t.subtract(const Duration(hours: 1)),
      ),
    ]);
    final sessions = listenSessions(log, [source]);
    expect(sessions.map((s) => s.title), ['Ăn chay', '', 'Thói quen']);
    expect(sessions.first.index, 0);
    expect(sessions.first.day.done, isTrue);
    expect(sessions[1].source, isNull);
    expect(sessions.last.index, 1);
  });
}
