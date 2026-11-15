import '../models/deck.dart';
import 'fsrs.dart';

/// Word notes: one word and its meaning on the lock screen, several times a
/// day, so the words a learner is losing come back between reviews. Seeing
/// a note is exposure, not recall, so it never counts as a review.
/// docs/memory-plan.md, "Word notes".
abstract final class WordNotes {
  /// Notes a day.
  static const perDay = 10;

  /// Days scheduled ahead. With the daily reminder's 30 days this stays well
  /// under the 64 notifications iOS keeps pending for an app; the notes are
  /// scheduled again whenever the app goes to the background.
  static const days = 2;

  /// The window notes are spread over, in minutes after midnight: 08:00 to
  /// 21:30, after waking and before winding down.
  static const firstMinute = 8 * 60, lastMinute = 21 * 60 + 30;

  /// Words learned this well are left out: remembered for three weeks and
  /// still likely to be recalled.
  static const settledDays = 21.0, settledRecall = .9;

  /// New words the learner added themselves, at most, each day: a first look
  /// at words they chose, before studying them.
  static const newPerDay = 3;

  /// No note within this long of the daily review reminder.
  static const reminderGap = Duration(minutes: 30);
}

/// One scheduled note.
class WordNote {
  final DateTime at;
  final FlashWord word;
  const WordNote(this.at, this.word);
}

/// The times of [day]'s notes, evenly over the window. A time within
/// [WordNotes.reminderGap] of [reminder] moves before it, so the two never
/// arrive together.
List<DateTime> wordNoteTimes(
  DateTime day, {
  int count = WordNotes.perDay,
  ({int hour, int minute})? reminder,
}) {
  const span = WordNotes.lastMinute - WordNotes.firstMinute;
  final gap = WordNotes.reminderGap.inMinutes;
  final avoid = reminder == null ? null : reminder.hour * 60 + reminder.minute;
  return [
    for (var i = 0; i < count; i++)
      () {
        var minute =
            WordNotes.firstMinute +
            (count == 1 ? 0 : (span * i / (count - 1)).round());
        if (avoid != null && (minute - avoid).abs() < gap) minute = avoid - gap;
        return DateTime(day.year, day.month, day.day, 0, minute);
      }(),
  ];
}

/// The chance [w] is recalled at [at], from its last review; 0 for a word
/// never reviewed.
double recallAt(FlashWord w, DateTime at) {
  final last = w.lastReview;
  if (w.status == 'new' || last == null || w.stability <= 0) return 0;
  final days = at.difference(last).inSeconds / Duration.secondsPerDay;
  return Fsrs.recall(days < 0 ? 0 : days, w.stability);
}

/// The notes for the [WordNotes.days] days from [now]: each day the studied
/// words least likely to be recalled that day, and up to
/// [WordNotes.newPerDay] new words from [chosen] (word keys of the learner's
/// own decks), with no word twice in a day and, while there are enough
/// words, none on both days. The weakest word comes first in the day.
/// Times already past today are skipped. Words without a meaning are left
/// out.
List<WordNote> planWordNotes({
  required Iterable<FlashWord> words,
  required DateTime now,
  Set<String> chosen = const {},
  ({int hour, int minute})? reminder,
  int perDay = WordNotes.perDay,
  int days = WordNotes.days,
}) {
  final pool = [
    for (final w in words)
      if (w.meaning.trim().isNotEmpty) w,
  ];
  final used = <String>{};
  final notes = <WordNote>[];
  for (var d = 0; d < days; d++) {
    final day = DateTime(now.year, now.month, now.day + d);
    final times = [
      for (final t in wordNoteTimes(day, count: perDay, reminder: reminder))
        if (t.isAfter(now)) t,
    ];
    if (times.isEmpty) continue;
    final noon = DateTime(day.year, day.month, day.day, 12);
    double weak(FlashWord w) => recallAt(w, noon);
    final studied =
        [
          for (final w in pool)
            if (w.status != 'new' &&
                !(w.stability >= WordNotes.settledDays &&
                    weak(w) >= WordNotes.settledRecall))
              w,
        ]..sort((a, b) {
          // Fresh words first on a later day, then the weakest.
          final seen = _seen(used, a).compareTo(_seen(used, b));
          return seen != 0 ? seen : weak(a).compareTo(weak(b));
        });
    final fresh = [
      for (final w in pool)
        if (w.status == 'new' && chosen.contains(_key(w))) w,
    ]..sort((a, b) => _seen(used, a).compareTo(_seen(used, b)));
    final picked = <FlashWord>[];
    final today = <String>{};
    void take(FlashWord w) {
      if (picked.length < times.length && today.add(_key(w))) picked.add(w);
    }

    final freshSlots = fresh.length < WordNotes.newPerDay
        ? fresh.length
        : WordNotes.newPerDay;
    for (final w in studied) {
      if (picked.length >= times.length - freshSlots) break;
      take(w);
    }
    for (final w in fresh) {
      if (picked.length >= times.length) break;
      take(w);
    }
    // Too few studied words leave room for more new ones, and the reverse.
    for (final w in [...studied, ...fresh]) {
      take(w);
    }
    for (var i = 0; i < picked.length; i++) {
      notes.add(WordNote(times[i], picked[i]));
      used.add(_key(picked[i]));
    }
  }
  return notes;
}

String _key(FlashWord w) => w.word.trim().toLowerCase();

/// 1 when [w] already had a note on an earlier day, so others go first.
int _seen(Set<String> used, FlashWord w) => used.contains(_key(w)) ? 1 : 0;

/// A part of speech as dictionaries abbreviate it: `NOUN` → `n`.
String posShort(String pos) => switch (pos.toUpperCase()) {
  'NOUN' => 'n',
  'VERB' => 'v',
  'ADJECTIVE' || 'ADJ' => 'adj',
  'ADVERB' || 'ADV' => 'adv',
  'PRONOUN' => 'pron',
  'PREPOSITION' => 'prep',
  'CONJUNCTION' => 'conj',
  'INTERJECTION' => 'interj',
  'DETERMINER' => 'det',
  'PHRASE' => 'phr',
  _ => pos.toLowerCase(),
};

/// A note's title, "catch /kætʃ/ (n)", and its body, the meaning.
({String title, String body}) wordNoteText(FlashWord w) {
  final parts = [
    w.word.trim(),
    if (w.phonetic.trim().isNotEmpty) w.phonetic.trim(),
    if (w.partOfSpeech.trim().isNotEmpty) '(${posShort(w.partOfSpeech)})',
  ];
  final meaning = w.meaning.trim();
  return (
    title: parts.join('  '),
    body: meaning.length > 160 ? '${meaning.substring(0, 157)}…' : meaning,
  );
}
