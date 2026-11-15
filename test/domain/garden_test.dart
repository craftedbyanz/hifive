import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/garden/garden.dart';

final _day = DateTime(2026, 11, 10, 9);

/// A day under the garden's second rules.
final _new = DateTime(2026, 11, 17, 9);

StudyCredit _credit(String word, DateTime at, [String tree = 'oak']) =>
    StudyCredit(word, at, tree);

FocusSession _focus(
  String id,
  DateTime start,
  int minutes, {
  FocusOutcome outcome = FocusOutcome.done,
  bool bloomed = false,
}) => FocusSession(
  id: id,
  start: start,
  end: start.add(Duration(minutes: minutes)),
  plannedMinutes: minutes,
  species: 'pine',
  outcome: outcome,
  bloomed: bloomed,
);

void main() {
  group('study credits', () {
    test('a card counts once a day, again the next day', () {
      final counted = countedCredits([
        _credit('a', _day),
        _credit('a', _day.add(const Duration(hours: 3))),
        _credit('b', _day.add(const Duration(minutes: 1))),
        _credit('a', _day.add(const Duration(days: 1))),
      ]);
      expect(counted.map((c) => c.wordId), ['a', 'b', 'a']);
    });

    test('ten counted reviews grow one tree of the first review species', () {
      final counted = [
        for (var i = 0; i < 23; i++)
          _credit(
            'w$i',
            _day.add(Duration(minutes: i)),
            i < 1 ? 'cherry' : 'oak',
          ),
      ];
      final trees = growStudyTrees(counted).trees;
      expect(trees, hasLength(2));
      expect(trees[0].species, 'cherry');
      expect(trees[0].at, counted[9].at);
      expect(trees[1].species, 'oak');
      expect(
        GardenStats.from(
          counted: counted,
          sessions: const [],
          reviews: 23,
          wordsKnown: 0,
          streak: 0,
        ).growing,
        3,
      );
    });
  });

  group('focus trees', () {
    test('a cancelled session plants nothing, a withered one a dead tree', () {
      expect(
        focusTree(_focus('c', _day, 0, outcome: FocusOutcome.cancelled)),
        isNull,
      );
      final dead = focusTree(
        _focus('w', _day, 6, outcome: FocusOutcome.withered),
      )!;
      expect(dead.withered, isTrue);
    });

    test('longer sessions grow bigger trees, up to fully grown', () {
      final short = focusTree(_focus('s', _day, 10))!.growth;
      final long = focusTree(_focus('l', _day, 45))!.growth;
      final full = focusTree(_focus('f', _day, 120))!.growth;
      expect(short, lessThan(long));
      expect(full, 1);
    });

    test('plants are picked by date, oldest first', () {
      final plants = plantsBetween(
        const [],
        [
          _focus('b', _day.add(const Duration(days: 1)), 25),
          _focus('a', _day, 25),
          _focus('old', _day.subtract(const Duration(days: 3)), 25),
        ],
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 16),
      );
      expect(plants.map((p) => p.at.day), [10, 11]);
    });

    test('a session survives a round trip through JSON', () {
      final s = _focus('x', _day, 25, bloomed: true);
      final back = FocusSession.fromJson('x', s.toJson());
      expect(back.minutes, 25);
      expect(back.bloomed, isTrue);
      expect(back.outcome, FocusOutcome.done);
      expect(back.tag, defaultTag);
    });
  });

  group('unlocking', () {
    GardenStats stats({
      List<StudyCredit> counted = const [],
      List<FocusSession> sessions = const [],
    }) => GardenStats.from(
      counted: counted,
      sessions: sessions,
      reviews: counted.length,
      wordsKnown: 0,
      streak: 0,
    );

    test('starter species are open from the first day', () {
      final s = stats();
      expect(species.where(s.unlocks).map((x) => x.id), ['oak', 'pine']);
    });

    test('a comeback counts finished sessions after a withered one', () {
      final s = stats(
        sessions: [
          _focus('1', _day, 25),
          _focus(
            '2',
            _day.add(const Duration(hours: 1)),
            6,
            outcome: FocusOutcome.withered,
          ),
          for (var i = 0; i < 5; i++)
            _focus('r$i', _day.add(Duration(hours: 2 + i)), 25),
        ],
      );
      expect(s.comeback, 5);
      expect(s.unlocks(speciesById('cactus')), isTrue);
    });

    test('weeks in a row, evenings and months come from study days', () {
      final s = stats(
        counted: [
          for (var w = 0; w < 4; w++)
            _credit('x', DateTime(2026, 11, 2 + w * 7, 20)),
        ],
      );
      expect(s.weeksInRow, 4);
      expect(s.eveningDays, 4);
      expect(s.unlocks(speciesById('bang')), isTrue);
      expect(s.unlocks(speciesById('snowpine')), isFalse);
      expect(s.months, {11});
    });

    test('focus hours count finished sessions only', () {
      final s = stats(
        sessions: [
          for (var i = 0; i < 10; i++)
            _focus('$i', _day.add(Duration(hours: i)), 60),
          _focus('w', _day, 600, outcome: FocusOutcome.withered),
        ],
      );
      expect(s.focusMinutes, 600);
      expect(s.unlocks(speciesById('maple')), isTrue);
      expect(s.unlocks(speciesById('banana')), isFalse);
    });

    test('an unknown stored species falls back to the first one', () {
      expect(speciesById('nope').id, defaultSpecies);
      expect(species.map((s) => s.id).toSet(), hasLength(30));
    });

    test('the collection sections hold every species once, easiest first', () {
      final listed = [
        for (final g in SpeciesGroup.values) ...speciesInGroup(g),
      ];
      expect(listed.map((s) => s.id).toSet(), hasLength(species.length));
      expect(speciesInGroup(SpeciesGroup.memory).map((s) => s.id), [
        'cherry',
        'bonsai',
        'birch',
        'olive',
        'ginkgo',
      ]);
      expect(speciesInGroup(SpeciesGroup.season).map((s) => s.id), [
        'dao',
        'mai',
        'snowpine',
      ]);
      expect(speciesInGroup(SpeciesGroup.legend).map((s) => s.id), [
        'baobab',
        'banyan',
        'galaxy',
      ]);
    });

    test('Vietnamese and foreign species are both in the garden', () {
      final home = species.where((s) => s.origin == Origin.vietnam);
      expect(home.map((s) => s.id), containsAll(['mai', 'dao', 'lotus']));
      expect(species.where((s) => s.origin == null).single.id, 'galaxy');
      expect(
        species.map((s) => s.origin).whereType<Origin>().toSet().length,
        greaterThan(12),
      );
    });
  });

  group('second rules', () {
    test('a session grows a plant by its length', () {
      final young = focusTree(_focus('y', _new, 10))!;
      final small = focusTree(_focus('s', _new, 25))!;
      final large = focusTree(_focus('l', _new, 50))!;
      final old = focusTree(_focus('o', _new, 95))!;
      expect(young.size, PlantSize.young);
      expect(young.mature, isFalse);
      expect(small.mature, isTrue);
      expect(young.growth, lessThan(small.growth));
      expect(small.growth, lessThan(large.growth));
      expect(old.ancient, isTrue);
      // Under the first rules a short session still made a tree.
      expect(focusTree(_focus('f', _day, 10))!.mature, isTrue);
    });

    test('a bloomed tree turns ancient after a month in the garden', () {
      final s = _focus('b', _new, 30, bloomed: true);
      expect(
        focusTree(s, now: _new.add(const Duration(days: 29)))!.ancient,
        isFalse,
      );
      expect(
        focusTree(s, now: _new.add(const Duration(days: 31)))!.ancient,
        isTrue,
      );
    });

    test('a withered tree comes back after a mature session within 48 h', () {
      final dead = _focus('w', _new, 8, outcome: FocusOutcome.withered);
      final soon = _focus('s', _new.add(const Duration(hours: 20)), 25);
      final late = _focus('l', _new.add(const Duration(days: 3)), 25);
      final short = _focus('t', _new.add(const Duration(hours: 2)), 15);
      expect(focusTree(dead, sessions: [dead, soon])!.revived, isTrue);
      expect(focusTree(dead, sessions: [dead, late])!.withered, isTrue);
      expect(focusTree(dead, sessions: [dead, short])!.withered, isTrue);
    });

    test('a study tree needs water on three days, five drops a day', () {
      List<StudyCredit> day(int d, int n) => [
        for (var i = 0; i < n; i++)
          _credit('d$d-$i', _new.add(Duration(days: d, minutes: i))),
      ];
      // Twelve drops in one sitting grow nothing yet.
      var g = growStudyTrees(day(0, 12));
      expect(g.trees, isEmpty);
      expect(g.water, 5);
      expect(g.days, 1);
      g = growStudyTrees([...day(0, 5), ...day(1, 5)]);
      expect(g.trees, isEmpty);
      expect(g.days, 2);
      g = growStudyTrees([...day(0, 5), ...day(1, 5), ...day(2, 1)]);
      expect(g.trees, hasLength(1));
    });

    test('a study tree droops after three days without water', () {
      final g = growStudyTrees([_credit('a', _new)]);
      expect(g.wilting(_new.add(const Duration(days: 2))), isFalse);
      expect(g.wilting(_new.add(const Duration(days: 4))), isTrue);
    });

    test('a study tree watered on a sunny day blooms', () {
      final credits = [
        for (var d = 0; d < 3; d++)
          for (var i = 0; i < 4; i++)
            _credit('w$d$i', _new.add(Duration(days: d, minutes: i))),
      ];
      final sun = sunDays([_focus('f', _new.add(const Duration(days: 1)), 30)]);
      expect(growStudyTrees(credits).trees.single.bloomed, isFalse);
      expect(growStudyTrees(credits, sun: sun).trees.single.bloomed, isTrue);
    });

    test('focus milestones count only mature sessions', () {
      final sessions = [
        for (var i = 0; i < 4; i++)
          _focus('s$i', _new.add(Duration(hours: i)), 10, bloomed: true),
        _focus('m', _new.add(const Duration(hours: 5)), 25, bloomed: true),
        _focus('old', _day, 10, bloomed: true),
      ];
      final stats = GardenStats.from(
        counted: const [],
        sessions: sessions,
        reviews: 0,
        wordsKnown: 0,
        streak: 0,
      );
      expect(stats.focusSessions, 2);
      expect(stats.blooms, 2);
    });

    test('a comeback counts mature sessions within a week', () {
      final sessions = [
        _focus('w', _new, 5, outcome: FocusOutcome.withered),
        _focus('a', _new.add(const Duration(hours: 1)), 10),
        _focus('b', _new.add(const Duration(hours: 2)), 25),
        _focus('c', _new.add(const Duration(days: 2)), 30),
        _focus('d', _new.add(const Duration(days: 9)), 30),
      ];
      final stats = GardenStats.from(
        counted: const [],
        sessions: sessions,
        reviews: 0,
        wordsKnown: 0,
        streak: 0,
      );
      expect(stats.comeback, 2);
    });

    test('weather: rain after watering, clouds while words wait', () {
      expect(
        gardenWeather(overdue: 40, lastWater: _new, now: _new),
        GardenWeather.rain,
      );
      // The rain stops after ten minutes and the sky clears within the hour.
      expect(
        gardenWeather(
          overdue: 40,
          lastWater: _new,
          now: _new.add(const Duration(minutes: 10)),
        ),
        GardenWeather.clearing,
      );
      expect(
        gardenWeather(
          overdue: 40,
          lastWater: _new,
          now: _new.add(const Duration(hours: 1)),
        ),
        GardenWeather.cloudy,
      );
      expect(
        gardenWeather(overdue: cloudyAt, lastWater: null, now: _new),
        GardenWeather.cloudy,
      );
      expect(
        gardenWeather(overdue: 2, lastWater: null, now: _new),
        GardenWeather.sunny,
      );
    });

    test('a week with every quest done earns a decoration', () {
      final monday = DateTime(2026, 11, 16);
      final credits = [
        for (var d = 0; d < 5; d++)
          _credit('w$d', monday.add(Duration(days: d, hours: 9))),
      ];
      final sessions = [
        for (var d = 0; d < 3; d++)
          _focus(
            'f$d',
            monday.add(Duration(days: d, hours: 14)),
            25,
            bloomed: d == 0,
          ),
      ];
      final quests = questsFor(monday, credits, sessions);
      expect(quests.done, isTrue);
      expect(questWeeks(credits, sessions, DateTime(2026, 11, 30)), 1);
      expect(questsFor(monday, credits, sessions.take(2)).done, isFalse);
    });
  });
}
