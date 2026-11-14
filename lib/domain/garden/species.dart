/// The sections the species collection is shown in, by how a species is
/// unlocked: the first steps, words remembered, study kept up, focus, the
/// month of the year, and the hardest milestones.
enum SpeciesGroup { start, memory, diligence, focus, season, legend }

/// Where a species is at home, shown under its name.
enum Origin {
  vietnam,
  japan,
  korea,
  china,
  india,
  germany,
  england,
  netherlands,
  france,
  spain,
  greece,
  norway,
  finland,
  russia,
  kazakhstan,
  canada,
  usa,
  mexico,
  madagascar,
}

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
/// changes; new species are only appended. Names live in the ARB files.
/// [origin] is null for the legendary galaxy tree.
class Species {
  final String id;
  final SpeciesGroup group;
  final Unlock unlock;
  final Origin? origin;
  const Species(this.id, this.group, this.unlock, this.origin);
}

const species = [
  Species('oak', SpeciesGroup.start, Unlock(UnlockKind.always), Origin.germany),
  Species(
    'pine',
    SpeciesGroup.start,
    Unlock(UnlockKind.always),
    Origin.vietnam,
  ),
  Species(
    'sunflower',
    SpeciesGroup.start,
    Unlock(UnlockKind.studyTrees, 1),
    Origin.usa,
  ),
  Species(
    'tulip',
    SpeciesGroup.start,
    Unlock(UnlockKind.reviews, 1),
    Origin.netherlands,
  ),
  Species(
    'cherry',
    SpeciesGroup.memory,
    Unlock(UnlockKind.wordsKnown, 50),
    Origin.japan,
  ),
  Species(
    'apple',
    SpeciesGroup.diligence,
    Unlock(UnlockKind.streak, 7),
    Origin.kazakhstan,
  ),
  Species(
    'orange',
    SpeciesGroup.diligence,
    Unlock(UnlockKind.streak, 14),
    Origin.spain,
  ),
  Species(
    'maple',
    SpeciesGroup.focus,
    Unlock(UnlockKind.focusHours, 10),
    Origin.canada,
  ),
  Species(
    'birch',
    SpeciesGroup.memory,
    Unlock(UnlockKind.wordsKnown, 200),
    Origin.russia,
  ),
  Species(
    'ginkgo',
    SpeciesGroup.memory,
    Unlock(UnlockKind.wordsKnown, 500),
    Origin.china,
  ),
  Species(
    'willow',
    SpeciesGroup.focus,
    Unlock(UnlockKind.focusSessions, 20),
    Origin.england,
  ),
  Species(
    'lavender',
    SpeciesGroup.focus,
    Unlock(UnlockKind.blooms, 10),
    Origin.france,
  ),
  Species(
    'mushroom',
    SpeciesGroup.diligence,
    Unlock(UnlockKind.eveningDays, 5),
    Origin.finland,
  ),
  Species(
    'cactus',
    SpeciesGroup.focus,
    Unlock(UnlockKind.comeback, 5),
    Origin.mexico,
  ),
  Species(
    'bonsai',
    SpeciesGroup.memory,
    Unlock(UnlockKind.wordsKnown, 100),
    Origin.japan,
  ),
  Species(
    'baobab',
    SpeciesGroup.legend,
    Unlock(UnlockKind.wordsKnown, 1000),
    Origin.madagascar,
  ),
  Species(
    'wisteria',
    SpeciesGroup.diligence,
    Unlock(UnlockKind.studyTrees, 30),
    Origin.china,
  ),
  Species(
    'bamboo',
    SpeciesGroup.diligence,
    Unlock(UnlockKind.reviews, 500),
    Origin.vietnam,
  ),
  Species(
    'coconut',
    SpeciesGroup.diligence,
    Unlock(UnlockKind.streak, 30),
    Origin.vietnam,
  ),
  Species(
    'banana',
    SpeciesGroup.focus,
    Unlock(UnlockKind.focusHours, 25),
    Origin.vietnam,
  ),
  Species(
    'phuong',
    SpeciesGroup.diligence,
    Unlock(UnlockKind.studyDays, 30),
    Origin.vietnam,
  ),
  Species(
    'bang',
    SpeciesGroup.diligence,
    Unlock(UnlockKind.weeksInRow, 4),
    Origin.vietnam,
  ),
  Species(
    'mai',
    SpeciesGroup.season,
    Unlock(UnlockKind.month, 2),
    Origin.vietnam,
  ),
  Species(
    'dao',
    SpeciesGroup.season,
    Unlock(UnlockKind.month, 1),
    Origin.vietnam,
  ),
  Species(
    'lotus',
    SpeciesGroup.focus,
    Unlock(UnlockKind.longSession, 60),
    Origin.vietnam,
  ),
  Species(
    'banyan',
    SpeciesGroup.legend,
    Unlock(UnlockKind.focusHours, 100),
    Origin.india,
  ),
  Species(
    'snowpine',
    SpeciesGroup.season,
    Unlock(UnlockKind.month, 12),
    Origin.norway,
  ),
  Species('galaxy', SpeciesGroup.legend, Unlock(UnlockKind.streak, 365), null),
  Species(
    'olive',
    SpeciesGroup.memory,
    Unlock(UnlockKind.wordsKnown, 300),
    Origin.greece,
  ),
  Species(
    'mugunghwa',
    SpeciesGroup.diligence,
    Unlock(UnlockKind.streak, 21),
    Origin.korea,
  ),
];

/// [species] in collection order: by section, then easiest first.
List<Species> speciesInGroup(SpeciesGroup g) =>
    [
      for (final s in species)
        if (s.group == g) s,
    ]..sort((a, b) {
      final k = _rank(a).compareTo(_rank(b));
      return k != 0 ? k : species.indexOf(a).compareTo(species.indexOf(b));
    });

// Rough effort of an unlock, so a section lists its species easiest first.
int _rank(Species s) => switch (s.unlock.kind) {
  UnlockKind.always => 0,
  UnlockKind.studyTrees => s.unlock.value * 20,
  UnlockKind.reviews => s.unlock.value,
  UnlockKind.wordsKnown => s.unlock.value,
  UnlockKind.streak => s.unlock.value * 20,
  UnlockKind.focusHours => s.unlock.value * 30,
  UnlockKind.focusSessions => s.unlock.value * 12,
  UnlockKind.longSession => 200,
  UnlockKind.studyDays => s.unlock.value * 20,
  UnlockKind.blooms => s.unlock.value * 20,
  UnlockKind.eveningDays => s.unlock.value * 20,
  UnlockKind.comeback => s.unlock.value * 10,
  UnlockKind.weeksInRow => s.unlock.value * 140,
  UnlockKind.month => s.unlock.value,
};

/// The species planted when none was chosen, or when a stored id is unknown.
const defaultSpecies = 'oak';

Species speciesById(String id) =>
    species.firstWhere((s) => s.id == id, orElse: () => species.first);
