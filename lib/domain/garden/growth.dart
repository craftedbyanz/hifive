import 'focus_session.dart';
import 'species.dart';

/// A rating of a card that was new or due, found while replaying reviews.
/// Each grows the learner's study tree.
class StudyCredit {
  final String wordId, species;
  final DateTime at;
  const StudyCredit(this.wordId, this.at, this.species);
}

/// Valid reviews needed to grow one study tree.
const reviewsPerTree = 10;

/// A finished focus session's tree counts as fully grown at this length.
const fullGrownMinutes = 60;

String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// [credits] in time order, keeping only the first per card per local day,
/// so reviewing one card again and again grows nothing more.
List<StudyCredit> countedCredits(Iterable<StudyCredit> credits) {
  final sorted = [...credits]..sort((a, b) => a.at.compareTo(b.at));
  final seen = <String>{};
  return [
    for (final c in sorted)
      if (seen.add('${c.wordId}|${_day(c.at)}')) c,
  ];
}

enum PlantSource { study, focus }

/// One tree in the garden.
class Plant {
  final PlantSource source;
  final String species;

  /// When it was planted: a study tree's last review or a session's end.
  final DateTime at;

  /// How grown it is, from 0 (a seed) to 1 (fully grown).
  final double growth;
  final bool withered, bloomed;
  const Plant({
    required this.source,
    required this.species,
    required this.at,
    this.growth = 1,
    this.withered = false,
    this.bloomed = false,
  });
}

/// Every finished study tree, from counted credits. A tree takes the species
/// chosen when its first review counted.
List<Plant> studyTrees(List<StudyCredit> counted) => [
  for (var i = reviewsPerTree - 1; i < counted.length; i += reviewsPerTree)
    Plant(
      source: PlantSource.study,
      species: counted[i - reviewsPerTree + 1].species,
      at: counted[i].at,
    ),
];

/// The tree a focus session leaves, or null for a cancelled one.
Plant? focusTree(FocusSession s) => s.planted
    ? Plant(
        source: PlantSource.focus,
        species: s.species,
        at: s.end,
        growth: s.outcome == FocusOutcome.done
            ? (.55 + .45 * s.minutes / fullGrownMinutes).clamp(.55, 1.0)
            : .3,
        withered: s.outcome == FocusOutcome.withered,
        bloomed: s.bloomed,
      )
    : null;

/// Plants dated from [from] (inclusive) to [to] (exclusive), oldest first.
List<Plant> plantsBetween(
  List<StudyCredit> counted,
  Iterable<FocusSession> sessions,
  DateTime from,
  DateTime to,
) {
  final all = [...studyTrees(counted), for (final s in sessions) ?focusTree(s)];
  return all.where((p) => !p.at.isBefore(from) && p.at.isBefore(to)).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
}

/// What the learner has reached, for unlocking species.
class GardenStats {
  final int studyTrees, wordsKnown, streak, focusMinutes, focusSessions;
  final int longestSession, reviews, studyDays, blooms, eveningDays;
  final int comeback, weeksInRow;
  final Set<int> months;

  /// Valid reviews counted towards the tree growing now.
  final int growing;
  const GardenStats({
    this.studyTrees = 0,
    this.wordsKnown = 0,
    this.streak = 0,
    this.focusMinutes = 0,
    this.focusSessions = 0,
    this.longestSession = 0,
    this.reviews = 0,
    this.studyDays = 0,
    this.blooms = 0,
    this.eveningDays = 0,
    this.comeback = 0,
    this.weeksInRow = 0,
    this.months = const {},
    this.growing = 0,
  });

  /// [counted] from [countedCredits]; [reviews] counts every rating;
  /// [wordsKnown] and [streak] come from the cards and the study history.
  factory GardenStats.from({
    required List<StudyCredit> counted,
    required Iterable<FocusSession> sessions,
    required int reviews,
    required int wordsKnown,
    required int streak,
  }) {
    final done = [
      for (final s in sessions)
        if (s.outcome == FocusOutcome.done) s,
    ];
    final days = <String>{}, evenings = <String>{};
    final months = <int>{};
    final weeks = <int>{};
    for (final c in counted) {
      days.add(_day(c.at));
      if (c.at.hour >= 18) evenings.add(_day(c.at));
      months.add(c.at.month);
      final monday = DateTime(
        c.at.year,
        c.at.month,
        c.at.day - c.at.weekday + 1,
      );
      weeks.add(monday.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay);
    }
    return GardenStats(
      studyTrees: counted.length ~/ reviewsPerTree,
      growing: counted.length % reviewsPerTree,
      wordsKnown: wordsKnown,
      streak: streak,
      focusMinutes: done.fold(0, (sum, s) => sum + s.minutes),
      focusSessions: done.length,
      longestSession: done.fold(0, (m, s) => s.minutes > m ? s.minutes : m),
      reviews: reviews,
      studyDays: days.length,
      blooms: sessions.where((s) => s.bloomed).length,
      eveningDays: evenings.length,
      comeback: _comeback(sessions),
      weeksInRow: _longestRun(weeks, 7),
      months: months,
    );
  }

  bool unlocks(Species s) {
    final n = s.unlock.value;
    return switch (s.unlock.kind) {
      UnlockKind.always => true,
      UnlockKind.studyTrees => studyTrees >= n,
      UnlockKind.wordsKnown => wordsKnown >= n,
      UnlockKind.streak => streak >= n,
      UnlockKind.focusHours => focusMinutes >= n * 60,
      UnlockKind.focusSessions => focusSessions >= n,
      UnlockKind.longSession => longestSession >= n,
      UnlockKind.reviews => reviews >= n,
      UnlockKind.studyDays => studyDays >= n,
      UnlockKind.blooms => blooms >= n,
      UnlockKind.eveningDays => eveningDays >= n,
      UnlockKind.comeback => comeback >= n,
      UnlockKind.weeksInRow => weeksInRow >= n,
      UnlockKind.month => months.contains(n),
    };
  }
}

/// The longest run of finished sessions that started right after a withered
/// one.
int _comeback(Iterable<FocusSession> sessions) {
  final sorted = [
    for (final s in sessions)
      if (s.planted) s,
  ]..sort((a, b) => a.start.compareTo(b.start));
  var best = 0, run = 0;
  var afterWither = false;
  for (final s in sorted) {
    if (s.outcome == FocusOutcome.withered) {
      afterWither = true;
      run = 0;
    } else if (afterWither) {
      run++;
      if (run > best) best = run;
    }
  }
  return best;
}

/// The longest run of [values] that are [step] apart.
int _longestRun(Set<int> values, int step) {
  final sorted = values.toList()..sort();
  var best = 0, run = 0;
  int? previous;
  for (final v in sorted) {
    run = previous != null && v - previous == step ? run + 1 : 1;
    if (run > best) best = run;
    previous = v;
  }
  return best;
}
