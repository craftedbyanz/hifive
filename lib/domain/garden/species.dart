/// The groups the species collection is shown in.
enum SpeciesGroup { start, study, vietnam, legend }

/// What a learner must reach to unlock a species. Each is measured by
/// [GardenStats].
enum UnlockKind {
  always,

  /// Study trees grown.
  studyTrees,

  /// Cards whose memory lasts three weeks or more.
  wordsKnown,

  /// Study days in a row.
  streak,

  /// Hours of finished focus sessions.
  focusHours,

  /// Finished focus sessions.
  focusSessions,

  /// One finished focus session of at least this many minutes.
  longSession,

  /// Ratings of new or due cards, all time.
  reviews,

  /// Days with at least one valid review.
  studyDays,

  /// Focus trees that bloomed from a break review.
  blooms,

  /// Days with a valid review after 6 p.m.
  eveningDays,

  /// Finished focus sessions in a row after a withered one.
  comeback,

  /// Weeks in a row with at least one study day.
  weeksInRow,

  /// Studied in this month of the year (1 to 12).
  month,
}

class Unlock {
  final UnlockKind kind;
  final int value;
  const Unlock(this.kind, [this.value = 0]);
}

/// A tree species. [id] is stored in focus records and reviews, so it never
/// changes. Names and descriptions live in the ARB files.
class Species {
  final String id;
  final SpeciesGroup group;
  final Unlock unlock;
  const Species(this.id, this.group, this.unlock);
}

const species = [
  Species('oak', SpeciesGroup.start, Unlock(UnlockKind.always)),
  Species('pine', SpeciesGroup.start, Unlock(UnlockKind.always)),
  Species('sunflower', SpeciesGroup.start, Unlock(UnlockKind.studyTrees, 1)),
  Species('tulip', SpeciesGroup.start, Unlock(UnlockKind.reviews, 1)),
  Species('cherry', SpeciesGroup.study, Unlock(UnlockKind.wordsKnown, 50)),
  Species('apple', SpeciesGroup.study, Unlock(UnlockKind.streak, 7)),
  Species('orange', SpeciesGroup.study, Unlock(UnlockKind.streak, 14)),
  Species('maple', SpeciesGroup.study, Unlock(UnlockKind.focusHours, 10)),
  Species('birch', SpeciesGroup.study, Unlock(UnlockKind.wordsKnown, 200)),
  Species('ginkgo', SpeciesGroup.study, Unlock(UnlockKind.wordsKnown, 500)),
  Species('willow', SpeciesGroup.study, Unlock(UnlockKind.focusSessions, 20)),
  Species('lavender', SpeciesGroup.study, Unlock(UnlockKind.blooms, 10)),
  Species('mushroom', SpeciesGroup.study, Unlock(UnlockKind.eveningDays, 5)),
  Species('cactus', SpeciesGroup.study, Unlock(UnlockKind.comeback, 5)),
  Species('bonsai', SpeciesGroup.study, Unlock(UnlockKind.wordsKnown, 100)),
  Species('baobab', SpeciesGroup.study, Unlock(UnlockKind.wordsKnown, 1000)),
  Species('wisteria', SpeciesGroup.study, Unlock(UnlockKind.studyTrees, 30)),
  Species('bamboo', SpeciesGroup.vietnam, Unlock(UnlockKind.reviews, 500)),
  Species('coconut', SpeciesGroup.vietnam, Unlock(UnlockKind.streak, 30)),
  Species('banana', SpeciesGroup.vietnam, Unlock(UnlockKind.focusHours, 25)),
  Species('phuong', SpeciesGroup.vietnam, Unlock(UnlockKind.studyDays, 30)),
  Species('bang', SpeciesGroup.vietnam, Unlock(UnlockKind.weeksInRow, 4)),
  Species('mai', SpeciesGroup.vietnam, Unlock(UnlockKind.month, 2)),
  Species('dao', SpeciesGroup.vietnam, Unlock(UnlockKind.month, 1)),
  Species('lotus', SpeciesGroup.vietnam, Unlock(UnlockKind.longSession, 60)),
  Species('banyan', SpeciesGroup.vietnam, Unlock(UnlockKind.focusHours, 100)),
  Species('snowpine', SpeciesGroup.legend, Unlock(UnlockKind.month, 12)),
  Species('galaxy', SpeciesGroup.legend, Unlock(UnlockKind.streak, 365)),
];

/// The species planted when none was chosen, or when a stored id is unknown.
const defaultSpecies = 'oak';

Species speciesById(String id) =>
    species.firstWhere((s) => s.id == id, orElse: () => species.first);
