import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/garden/garden.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/state/state.dart';

var _now = DateTime(2026, 11, 13, 9);

AppState _state(RecordStore store) =>
    createAppState(store: store, feedback: SilentFeedback(), now: () => _now);

Future<AppState> _reload(RecordStore store) async {
  final state = _state(store);
  await state.load();
  return state;
}

void main() {
  late MemoryRecordStore store;
  late AppState state;
  setUp(() async {
    _now = DateTime(2026, 11, 13, 9);
    store = MemoryRecordStore();
    state = _state(store);
    await state.load();
  });

  test('rating a new card grows the study tree, once a day', () async {
    final word = state.decks.first.words.first;
    state.rate(word, 2);
    expect(state.countedStudyCredits, hasLength(1));

    // Rated again the same day: the card was new, then is not due.
    state.rate(word, 0);
    expect(state.countedStudyCredits, hasLength(1));
    await state.flush();

    final reviews = store.records.entries
        .where((e) => e.key.$1 == RecordKind.review)
        .map((e) => e.value.data!)
        .toList();
    expect(reviews.where((d) => d['tree'] == 'oak'), hasLength(1));
  });

  test('ten new cards grow a tree that survives a reload', () async {
    final words = state.decks.expand((d) => d.words).take(12).toList();
    for (final w in words) {
      state.rate(w, 2);
    }
    expect(state.gardenStats.studyTrees, 1);
    expect(state.gardenStats.growing, 2);
    await state.flush();

    final next = await _reload(store);
    expect(next.gardenStats.studyTrees, 1);
    expect(
      next.plants(DateTime(2026, 11, 13), DateTime(2026, 11, 14)).single.source,
      PlantSource.study,
    );
  });

  test('a focus session is saved, then blooms without a second row', () async {
    final session = FocusSession(
      id: state.newId(),
      start: _now,
      end: _now.add(const Duration(minutes: 25)),
      plannedMinutes: 25,
      species: 'pine',
      outcome: FocusOutcome.done,
    );
    state.recordFocus(session);
    state.recordFocus(session.copyWith(bloomed: true));
    await state.flush();
    expect(
      store.records.keys.where((k) => k.$1 == RecordKind.focus),
      hasLength(1),
    );

    final next = await _reload(store);
    expect(next.focusSessions.single.bloomed, isTrue);
    expect(next.gardenStats.focusMinutes, 25);
  });

  test('a locked species cannot be chosen; an open one is saved', () async {
    state.setStudySpecies('galaxy');
    expect(state.studySpecies, defaultSpecies);
    state.setStudySpecies('pine');
    await state.flush();
    expect((await _reload(store)).studySpecies, 'pine');
  });

  test(
    'own tags survive a reload; deleting one keeps its time as other',
    () async {
      final id = state.addTag('Đọc sách', 5);
      state.setFocusTag(id);
      state.recordFocus(
        FocusSession(
          id: state.newId(),
          start: _now,
          end: _now.add(const Duration(minutes: 30)),
          plannedMinutes: 30,
          species: 'oak',
          outcome: FocusOutcome.done,
          tag: id,
        ),
      );
      await state.flush();
      final next = await _reload(store);
      expect(next.customTags.single.name, 'Đọc sách');
      expect(next.focusTag, id);
      final day = (DateTime(2026, 11, 13), DateTime(2026, 11, 14));
      expect(next.focusByTag(day.$1, day.$2).single.$1.id, id);

      next.deleteTag(id);
      expect(next.customTags, isEmpty);
      expect(next.focusTag, defaultTag);
      final after = next.focusByTag(day.$1, day.$2).single;
      expect(after.$1.id, 'other');
      expect(after.$2, 30);
    },
  );
}
