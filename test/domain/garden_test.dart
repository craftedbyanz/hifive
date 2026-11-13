import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/garden/garden.dart';

final _day = DateTime(2026, 11, 10, 9);

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
      final trees = studyTrees(counted);
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
      expect(species.map((s) => s.id).toSet(), hasLength(28));
    });
  });
}
