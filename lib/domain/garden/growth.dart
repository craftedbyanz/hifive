import 'focus_session.dart';
import 'species.dart';

/// A rating of a card that was new or due, found while replaying reviews.
/// Each is a drop of water for the learner's study trees.
class StudyCredit {
  final String wordId, species;
  final DateTime at;
  const StudyCredit(this.wordId, this.at, this.species);
}

/// Waterings one study tree needs.
const reviewsPerTree = 10;

/// A finished focus session's tree counted as fully grown at this length
/// under the first rules.
const fullGrownMinutes = 60;

/// The garden's second rules start on this local day. Sessions and
/// waterings before it keep the first rules, so nothing already planted
/// shrinks and no species locks again.
final gardenRulesSince = DateTime(2026, 11, 16);

bool _newRules(DateTime at) => !at.isBefore(gardenRulesSince);

/// Minutes for a mature focus tree, a large one and an ancient one.
const matureMinutes = 25, largeMinutes = 45, ancientMinutes = 90;

/// A study tree needs water on this many different days, at most
/// [waterPerDay] drops a day, so it grows with spaced reviews rather than
/// one long sitting.
const waterDays = 3, waterPerDay = 5;

/// A study tree left this long without water droops until watered again.
const wiltAfter = Duration(days: 3);

/// A withered focus tree comes back as a sprout if a mature session follows
/// within this time.
const reviveWithin = Duration(hours: 48);

/// A bloomed tree this old in the garden becomes an ancient tree.
const ancientAge = Duration(days: 30);

/// Least words a focus break must review for the tree to bloom (or all of
/// them if fewer are due).
const bloomWords = 5;

/// The local day of [d] as a key.
String gardenDay(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// [credits] in time order, keeping only the first per card per local day,
/// so reviewing one card again and again grows nothing more.
List<StudyCredit> countedCredits(Iterable<StudyCredit> credits) {
  final sorted = [...credits]..sort((a, b) => a.at.compareTo(b.at));
  final seen = <String>{};
  return [
    for (final c in sorted)
      if (seen.add('${c.wordId}|${gardenDay(c.at)}')) c,
  ];
}

enum PlantSource { study, focus }

/// How big a plant is: a young plant from a short session, then small,
/// large and ancient trees.
enum PlantSize { young, small, large, ancient }

/// The size a focus session of [minutes] grows.
PlantSize sizeFor(int minutes) => minutes >= ancientMinutes
    ? PlantSize.ancient
    : minutes >= largeMinutes
    ? PlantSize.large
    : minutes >= matureMinutes
    ? PlantSize.small
    : PlantSize.young;

double growthOf(PlantSize s) => switch (s) {
  PlantSize.young => .32,
  PlantSize.small => .66,
  PlantSize.large => .88,
  PlantSize.ancient => 1,
};

/// One plant in the garden.
class Plant {
  final PlantSource source;
  final String species;

  /// When it was planted: a study tree's last watering or a session's end.
  final DateTime at;

  /// How grown it is, from 0 (a seed) to 1 (fully grown).
  final double growth;
  final PlantSize size;
  final bool withered, bloomed;

  /// A withered tree brought back as a sprout by a mature session.
  final bool revived;
  const Plant({
    required this.source,
    required this.species,
    required this.at,
    this.growth = 1,
    this.size = PlantSize.large,
    this.withered = false,
    this.bloomed = false,
    this.revived = false,
  });

  bool get ancient => size == PlantSize.ancient;

  /// Counts as a tree: not a young plant from a short session, not dead.
  bool get mature => !withered && !revived && size != PlantSize.young;
}

/// Local days with at least [matureMinutes] of finished focus: the days the
/// sun shone on the garden.
Set<String> sunDays(Iterable<FocusSession> sessions) {
  final minutes = <String, int>{};
  for (final s in sessions) {
    if (s.outcome == FocusOutcome.done) {
      final day = gardenDay(s.end);
      minutes[day] = (minutes[day] ?? 0) + s.minutes;
    }
  }
  return {
    for (final e in minutes.entries)
      if (e.value >= matureMinutes) e.key,
  };
}

/// The study trees grown so far, and the one growing now.
class StudyGrowth {
  final List<Plant> trees;

  /// Water and days of water the tree growing now has had.
  final int water, days;
  final DateTime? lastWater;
  const StudyGrowth(this.trees, this.water, this.days, this.lastWater);

  /// Whether the growing tree has gone [wiltAfter] without water.
  bool wilting(DateTime now) =>
      water > 0 && lastWater != null && now.difference(lastWater!) > wiltAfter;
}

class _Growing {
  final String species;
  final perDay = <String, int>{};
  var water = 0;
  DateTime? last;
  _Growing(this.species);
}

/// Grows study trees from [counted] waterings. Under the first rules every
/// [reviewsPerTree] waterings made a tree. Under the second a tree takes at
/// most [waterPerDay] drops a day and is grown once it has had
/// [reviewsPerTree] on [waterDays] different days; more water that day
/// starts the next tree. A tree watered on a day the sun shone ([sun], from
/// [sunDays]) blooms, and a bloomed tree [ancientAge] old turns ancient.
StudyGrowth growStudyTrees(
  List<StudyCredit> counted, {
  Set<String> sun = const {},
  DateTime? now,
}) {
  final trees = <Plant>[];
  final open = <_Growing>[];
  void finish(_Growing g, DateTime at) {
    final bloomed = g.perDay.keys.any(sun.contains);
    final aged = bloomed && now != null && now.difference(at) >= ancientAge;
    trees.add(
      Plant(
        source: PlantSource.study,
        species: g.species,
        at: at,
        bloomed: bloomed,
        size: aged ? PlantSize.ancient : PlantSize.large,
      ),
    );
    open.remove(g);
  }

  for (final c in counted) {
    final day = gardenDay(c.at);
    if (!_newRules(c.at)) {
      if (open.isEmpty) open.add(_Growing(c.species));
      final g = open.first;
      g
        ..water += 1
        ..perDay[day] = (g.perDay[day] ?? 0) + 1
        ..last = c.at;
      if (g.water >= reviewsPerTree) finish(g, c.at);
      continue;
    }
    var g = open.where((o) => (o.perDay[day] ?? 0) < waterPerDay).firstOrNull;
    if (g == null) open.add(g = _Growing(c.species));
    g
      ..water += 1
      ..perDay[day] = (g.perDay[day] ?? 0) + 1
      ..last = c.at;
    if (g.water >= reviewsPerTree && g.perDay.length >= waterDays) {
      finish(g, c.at);
    }
  }
  final growing = open.firstOrNull;
  return StudyGrowth(
    trees,
    growing?.water ?? 0,
    growing?.perDay.length ?? 0,
    growing?.last,
  );
}

/// The plant a focus session leaves, or null for a cancelled one. Under the
/// second rules its size follows its minutes, and a withered tree followed
/// within [reviveWithin] by a mature session (from [sessions]) comes back as
/// a sprout. A bloomed tree [ancientAge] old by [now] turns ancient.
Plant? focusTree(
  FocusSession s, {
  Iterable<FocusSession> sessions = const [],
  DateTime? now,
}) {
  if (!s.planted) return null;
  final fresh = _newRules(s.start);
  if (s.outcome == FocusOutcome.withered) {
    final revived =
        fresh &&
        sessions.any(
          (o) =>
              o.outcome == FocusOutcome.done &&
              o.minutes >= matureMinutes &&
              !o.start.isBefore(s.end) &&
              o.start.difference(s.end) <= reviveWithin,
        );
    return Plant(
      source: PlantSource.focus,
      species: s.species,
      at: s.end,
      growth: revived ? .06 : .3,
      size: PlantSize.young,
      withered: !revived,
      revived: revived,
    );
  }
  var size = sizeFor(s.minutes);
  // Under the first rules every finished session made a tree.
  if (!fresh && size == PlantSize.young) size = PlantSize.small;
  final aged = s.bloomed && now != null && now.difference(s.end) >= ancientAge;
  if (aged) size = PlantSize.ancient;
  return Plant(
    source: PlantSource.focus,
    species: s.species,
    at: s.end,
    growth: size == PlantSize.ancient
        ? 1
        : fresh
        ? growthOf(size)
        : (.55 + .45 * s.minutes / fullGrownMinutes).clamp(.55, 1.0),
    size: size,
    bloomed: s.bloomed,
  );
}

/// Plants dated from [from] (inclusive) to [to] (exclusive), oldest first.
List<Plant> plantsBetween(
  List<StudyCredit> counted,
  Iterable<FocusSession> sessions,
  DateTime from,
  DateTime to, {
  DateTime? now,
}) {
  final all = [
    ...growStudyTrees(counted, sun: sunDays(sessions), now: now).trees,
    for (final s in sessions) ?focusTree(s, sessions: sessions, now: now),
  ];
  return all.where((p) => !p.at.isBefore(from) && p.at.isBefore(to)).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
}

/// Whether [s] counts towards focus milestones: any finished session under
/// the first rules, a mature one under the second.
bool _counts(FocusSession s) =>
    !_newRules(s.start) || s.minutes >= matureMinutes;

/// The garden's weather, from how the learner's memory is doing: rain just
/// after watering, clouds while many words wait, sun otherwise.
enum GardenWeather { sunny, cloudy, rain }

/// Words waiting that bring clouds.
const cloudyAt = 10;

GardenWeather gardenWeather({
  required int overdue,
  required DateTime? lastWater,
  required DateTime now,
}) => lastWater != null && now.difference(lastWater) < const Duration(hours: 1)
    ? GardenWeather.rain
    : overdue >= cloudyAt
    ? GardenWeather.cloudy
    : GardenWeather.sunny;

/// A week's quests: mature focus sessions, study days and blooms.
class WeekQuests {
  static const focusGoal = 3, studyGoal = 5, bloomGoal = 1;
  final int focus, studyDays, blooms;
  const WeekQuests(this.focus, this.studyDays, this.blooms);
  bool get done =>
      focus >= focusGoal && studyDays >= studyGoal && blooms >= bloomGoal;
}

DateTime _monday(DateTime d) =>
    DateTime(d.year, d.month, d.day - d.weekday + 1);

/// The quests of the week starting on [monday].
WeekQuests questsFor(
  DateTime monday,
  List<StudyCredit> counted,
  Iterable<FocusSession> sessions,
) {
  final end = DateTime(monday.year, monday.month, monday.day + 7);
  bool inWeek(DateTime at) => !at.isBefore(monday) && at.isBefore(end);
  final done = [
    for (final s in sessions)
      if (s.outcome == FocusOutcome.done &&
          s.minutes >= matureMinutes &&
          inWeek(s.end))
        s,
  ];
  return WeekQuests(
    done.length,
    {
      for (final c in counted)
        if (inWeek(c.at)) gardenDay(c.at),
    }.length,
    done.where((s) => s.bloomed).length,
  );
}

/// The decorations a learner can earn, one per week whose quests were all
/// done, in this order. Ids are stable.
const decorations = [
  'stoneLantern',
  'bench',
  'pond',
  'birdhouse',
  'redLantern',
  'flowerBed',
];

/// Weeks since the second rules whose quests were all done, up to [now].
int questWeeks(
  List<StudyCredit> counted,
  Iterable<FocusSession> sessions,
  DateTime now,
) {
  var weeks = 0;
  for (
    var m = _monday(gardenRulesSince);
    !m.isAfter(now);
    m = DateTime(m.year, m.month, m.day + 7)
  ) {
    if (questsFor(m, counted, sessions).done) weeks++;
  }
  return weeks;
}

/// What the learner has reached, for unlocking species.
class GardenStats {
  final int studyTrees, wordsKnown, streak, focusMinutes, focusSessions;
  final int longestSession, reviews, studyDays, blooms, eveningDays;
  final int comeback, weeksInRow;
  final Set<int> months;

  /// Water and days of water for the study tree growing now.
  final int growing, growingDays;

  /// Whether the growing study tree droops for want of water.
  final bool wilting;
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
    this.growingDays = 0,
    this.wilting = false,
  });

  /// [counted] from [countedCredits]; [reviews] counts every rating;
  /// [wordsKnown] and [streak] come from the cards and the study history.
  factory GardenStats.from({
    required List<StudyCredit> counted,
    required Iterable<FocusSession> sessions,
    required int reviews,
    required int wordsKnown,
    required int streak,
    DateTime? now,
  }) {
    final done = [
      for (final s in sessions)
        if (s.outcome == FocusOutcome.done) s,
    ];
    final days = <String>{}, evenings = <String>{};
    final months = <int>{};
    final weeks = <int>{};
    for (final c in counted) {
      days.add(gardenDay(c.at));
      if (c.at.hour >= 18) evenings.add(gardenDay(c.at));
      months.add(c.at.month);
      weeks.add(
        _monday(c.at).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay,
      );
    }
    final growth = growStudyTrees(counted, sun: sunDays(sessions), now: now);
    return GardenStats(
      studyTrees: growth.trees.length,
      growing: growth.water.clamp(0, reviewsPerTree),
      growingDays: growth.days.clamp(0, waterDays),
      wilting: now != null && growth.wilting(now),
      wordsKnown: wordsKnown,
      streak: streak,
      focusMinutes: done.fold(0, (sum, s) => sum + s.minutes),
      focusSessions: done.where(_counts).length,
      longestSession: done.fold(0, (m, s) => s.minutes > m ? s.minutes : m),
      reviews: reviews,
      studyDays: days.length,
      blooms: sessions.where((s) => s.bloomed && _counts(s)).length,
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

/// The most finished sessions after a withered one, before the next. Under
/// the second rules only mature sessions within a week of the withered tree
/// count.
int _comeback(Iterable<FocusSession> sessions) {
  final sorted = [
    for (final s in sessions)
      if (s.planted) s,
  ]..sort((a, b) => a.start.compareTo(b.start));
  var best = 0, run = 0;
  DateTime? witheredAt;
  for (final s in sorted) {
    if (s.outcome == FocusOutcome.withered) {
      witheredAt = s.end;
      run = 0;
    } else if (witheredAt != null) {
      final fresh = _newRules(s.start);
      if (fresh &&
          (s.minutes < matureMinutes ||
              s.start.difference(witheredAt) > const Duration(days: 7))) {
        continue;
      }
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
