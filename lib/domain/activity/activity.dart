import '../listening/listening.dart';
import '../sync/reviews.dart';
import '../vocab/catalog.dart';

/// What the learner did besides lessons, as Ôn tập lists it: vocabulary
/// sessions from the review log, listening by video and day, games and
/// focus sessions. Derived from records already kept; nothing new is
/// stored except each game's score and time (`game` records always had
/// them).

/// One finished game.
class GameResult {
  final DateTime at;
  final int score;
  const GameResult(this.at, this.score);
}

/// A run of vocabulary answers with no gap longer than
/// [WordSession.gap]: when, where from, which words, and how many were
/// known (the last answer for each word was not "Chưa nhớ").
class WordSession {
  /// Answers further apart than this start a new session.
  static const gap = Duration(minutes: 30);

  final DateTime start, end;

  /// Where it was studied (`ReviewEvent.source`) at its first answer.
  final String source;

  /// The words answered, as [wordKey]s, in the order first met.
  final List<String> words;

  /// Words whose last answer in the session was a pass.
  final int known;
  const WordSession({
    required this.start,
    required this.end,
    required this.source,
    required this.words,
    required this.known,
  });

  /// Words whose last answer was "Chưa nhớ" (Again).
  int get forgot => words.length - known;
}

/// The vocabulary sessions in [events], newest first. Resets and carried-over
/// snapshots are not answers and are left out.
List<WordSession> wordSessions(Iterable<ReviewEvent> events) {
  final answers = [
    for (final e in events)
      if (e.rating >= 0) e,
  ]..sort((a, b) => a.at.compareTo(b.at));
  final sessions = <WordSession>[];
  var run = <ReviewEvent>[];
  void close() {
    if (run.isEmpty) return;
    final last = <String, int>{};
    for (final e in run) {
      last[e.word ?? e.wordId] = e.rating;
    }
    sessions.add(
      WordSession(
        start: run.first.at,
        end: run.last.at,
        source: run.first.source,
        words: last.keys.toList(),
        known: last.values.where((r) => r > 0).length,
      ),
    );
    run = [];
  }

  for (final e in answers) {
    if (run.isNotEmpty && e.at.difference(run.last.at) > WordSession.gap) {
      close();
    }
    run.add(e);
  }
  close();
  return sessions.reversed.toList();
}

/// One video heard on one day.
class ListenSession {
  final ListeningSource? source;

  /// The episode's place in [source], or -1 when the catalog no longer
  /// lists it.
  final int index;
  final String title;
  final ListenDay day;
  const ListenSession(this.source, this.index, this.title, this.day);
}

/// Listening by video and day, newest first, named from [sources]. Days with
/// under ten seconds heard are left out.
List<ListenSession> listenSessions(
  ListenLog log,
  List<ListeningSource> sources,
) {
  final out = <ListenSession>[];
  for (final d in log.days) {
    if (d.heard < 10) continue;
    ListeningSource? source;
    var index = -1;
    for (final s in sources) {
      final i = s.episodes.indexWhere((e) => e.id == d.video);
      if (i >= 0) {
        source = s;
        index = i;
        break;
      }
    }
    final title = index >= 0 ? source!.episodes[index].title : '';
    out.add(ListenSession(source, index, title, d));
  }
  out.sort((a, b) => b.day.at.compareTo(a.day.at));
  return out;
}
