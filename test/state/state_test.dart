import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/state/state.dart';

final _now = DateTime(2026, 11, 6, 9);

AppState _state(RecordStore store, {Map<String, dynamic>? blob}) =>
    createAppState(
      store: store,
      legacy: blob == null ? null : (MemoryAppRepository()..data = blob),
      feedback: SilentFeedback(),
      now: () => _now,
    );

Future<AppState> _reload(RecordStore store) async {
  final state = _state(store);
  await state.load();
  return state;
}

void main() {
  group('the old JSON blob', () {
    final cases = <String, Map<String, dynamic>>{
      'wrong field type': {'name': 42},
      'wrong bool type': {'showHints': 'yes'},
      'decks is not a list': {'decks': 'none'},
      'deck entry missing fields': {
        'decks': [
          {'id': 'a'},
        ],
      },
      'history entry is not a map': {
        'history': [1],
      },
      'game resume is not a map': {'gameResume': 3},
      'a later field failing': {'name': 'Saved', 'totalXp': 'many'},
    };
    cases.forEach((name, data) {
      test('with a $name keeps defaults and writes nothing', () async {
        final store = MemoryRecordStore();
        final state = _state(store, blob: data);
        await state.load();
        expect(state.storageError, isNotNull);
        expect(state.name, 'An');
        expect(state.modeOrder, hasLength(3));
        expect(state.decks, isNotEmpty);
        state.setName('Linh');
        await state.flush();
        expect(store.records, isEmpty);
        expect(store.metadata.containsKey('legacyImported'), isFalse);
      });
    });

    test('is imported once, keeping every value', () async {
      final store = MemoryRecordStore();
      final word = seedDecks().first.words.first;
      final blob = {
        'name': 'Linh',
        'language': 'en',
        'voice': 'System',
        'chatTipSeen': true,
        'sound': false,
        'modeOrder': [2, 0, 1],
        'gamesPlayed': 3,
        'totalXp': 40,
        'bestScore': 20,
        'firstUse': '2026-10-01T08:00:00.000',
        'history': [
          StudySession(
            id: 'old',
            lesson: const Lesson(
              id: 'l',
              title: 'Bài cũ',
              description: '',
              mode: StudyMode.grammar,
              questions: [],
            ),
            date: DateTime(2026, 10, 2),
            answers: const [],
            seconds: 5,
          ).toJson(),
        ],
        'decks': [
          {
            ...seedDecks().first.toJson(),
            'words': [
              {
                ...word.toJson(),
                'status': 'review',
                'intervalDays': 4,
                'due': '2026-11-10T00:00:00.000',
              },
            ],
          },
          {
            'id': 'saved',
            'title': 'Từ đã lưu',
            'description': 'Từ vựng của riêng bạn',
            'words': [
              {'id': 'saved-123', 'word': 'Sorry', 'meaning': 'xin lỗi'},
            ],
          },
        ],
      };
      final state = _state(store, blob: blob);
      await state.load();
      expect(state.storageError, isNull);
      expect(state.name, 'Linh');
      expect(state.voice, 'Aaron');
      expect(state.chatTipSeen, isTrue);
      expect(state.sound, isFalse);
      expect(state.modeOrder.first, StudyMode.conversation);
      expect((state.gamesPlayed, state.totalXp, state.bestScore), (3, 40, 20));
      expect(state.firstUse, DateTime(2026, 10, 1, 8));
      expect(state.history.single.id, 'old');
      final migrated = state.decks.first.words.first;
      expect((migrated.status, migrated.intervalDays), ('review', 4));
      final saved = state.decks.singleWhere((d) => d.id == 'saved');
      expect(saved.words.single.id, savedWordId('Sorry'));

      // A second launch reads the records and never imports again.
      final again = _state(store, blob: {'name': 'Other'});
      await again.load();
      expect(again.name, 'Linh');
      expect(again.decks.first.words.first.intervalDays, 4);
    });

    test('a store that throws is reported', () async {
      final state = _state(_ThrowingStore());
      await state.load();
      expect(state.storageError, isNotNull);
    });
  });

  group('named methods write only what changed', () {
    late MemoryRecordStore store;
    late AppState state;
    setUp(() async {
      store = MemoryRecordStore();
      state = _state(store);
      await state.load();
    });

    test('a fresh install stores only its first-use time', () {
      expect(store.records.keys.map((k) => k.$1), ['firstUse']);
    });

    test('settings are one record each and survive reload', () async {
      state
        ..setName('Linh')
        ..setLevel('B2')
        ..setAppearance('Mono')
        ..setShowHints(true)
        ..setSound(false);
      await state.flush();
      expect(store.data(RecordKind.setting, 'name'), {'v': 'Linh'});
      expect(store.data(RecordKind.setting, 'voice'), isNull);
      expect(store.data(RecordKind.device, 'sound'), {'v': false});
      expect(store.dirty, isNot(contains((RecordKind.device, 'sound'))));
      final next = await _reload(store);
      expect((next.name, next.level, next.appearance), ('Linh', 'B2', 'Mono'));
      expect((next.showHints, next.sound), (true, false));
    });

    test('mode order survives reload', () async {
      state.moveMode(0, 2);
      await state.flush();
      expect((await _reload(store)).modeOrder, state.modeOrder);
    });

    test('a learner deck keeps its cards, order and schedule', () async {
      final deck = Deck(id: 'd', title: 'T', description: 'D', words: []);
      final a = FlashWord(id: 'a', word: 'a', meaning: '1');
      final b = FlashWord(id: 'b', word: 'b', meaning: '2');
      state
        ..addDeck(deck)
        ..addWords(deck, [a, b])
        ..rate(b, 3);
      await state.flush();
      final next = await _reload(store);
      final restored = next.decks.singleWhere((d) => d.id == 'd');
      expect(restored.words.map((w) => w.id), ['a', 'b']);
      expect(restored.words.last.status, 'review');
      state.resetSchedule(deck);
      await state.flush();
      final reset = (await _reload(store)).decks
          .singleWhere((d) => d.id == 'd');
      expect(reset.words.last.status, 'new');
    });

    test('games add up from their records', () async {
      state
        ..saveGameProgress({'title': 'T'})
        ..finishGame(10, clearResume: false)
        ..finishGame(5, clearResume: true);
      expect(state.gameResume, isNull);
      await state.flush();
      final next = await _reload(store);
      expect((next.gamesPlayed, next.totalXp, next.bestScore), (2, 15, 10));
      expect(next.gameResume, isNull);
    });

    test('clearing history hides older results, not later ones', () async {
      const lesson = Lesson(
        id: 'l',
        title: 'L',
        description: '',
        mode: StudyMode.grammar,
        questions: [],
      );
      StudySession at(String id, DateTime date) => StudySession(
        id: id,
        lesson: lesson,
        date: date,
        answers: const [],
        seconds: 1,
      );
      state
        ..complete(at('before', _now.subtract(const Duration(hours: 1))))
        ..clearHistory();
      expect(state.history, isEmpty);
      // A lesson another device finished after the clear arrives by sync.
      await store.write([
        SyncRecord(
          RecordKind.session,
          'later',
          at('later', _now.add(const Duration(hours: 1))).toJson()
            ..remove('id'),
          const Hlc(1, 0, 'ipad'),
        ),
      ]);
      await state.flush();
      expect((await _reload(store)).history.map((s) => s.id), ['later']);
    });

    test('the study language is saved by code', () async {
      state.setLanguage(Language.japanese);
      await state.flush();
      expect(store.data(RecordKind.setting, 'language'), {'v': 'ja'});
      expect((await _reload(store)).language, Language.japanese);
    });
  });

  group('records from two devices', () {
    test('settings changed on each device both survive', () async {
      final store = MemoryRecordStore();
      final iphone = _state(store)..setVoice('Mia');
      final ipad = createAppState(
        store: store,
        feedback: SilentFeedback(),
        now: () => _now.add(const Duration(minutes: 1)),
      )..setAppearance('Mono');
      await iphone.flush();
      await ipad.flush();
      final next = await _reload(store);
      expect((next.voice, next.appearance), ('Mia', 'Mono'));
    });

    test('a new device never overwrites real settings with defaults', () async {
      final store = MemoryRecordStore();
      final first = _state(store)..setName('Linh');
      await first.flush();
      // Another install opens later and changes nothing.
      final second = createAppState(
        store: store,
        feedback: SilentFeedback(),
        now: () => _now.add(const Duration(days: 1)),
      );
      await second.load();
      await second.flush();
      expect((await _reload(store)).name, 'Linh');
    });

    test('first use is the earliest of every device', () async {
      final store = MemoryRecordStore();
      await store.write([
        SyncRecord('firstUse', 'ipad', {
          'at': DateTime(2026, 9, 1).toIso8601String(),
        }, const Hlc(1, 0, 'ipad')),
      ]);
      expect((await _reload(store)).firstUse, DateTime(2026, 9, 1));
    });

    test('the same word saved on two devices is one card', () async {
      final store = MemoryRecordStore();
      _state(store).saveWord('Sorry', 'xin lỗi');
      createAppState(
        store: store,
        feedback: SilentFeedback(),
        now: () => _now.add(const Duration(minutes: 5)),
      ).saveWord('sorry', 'xin lỗi');
      await Future<void>.delayed(Duration.zero);
      final saved = (await _reload(store)).decks
          .singleWhere((d) => d.id == 'saved');
      expect(saved.words, hasLength(1));
    });
  });
  test('days with hifive count from first use, not the sample results', () {
    final state = createAppState(
      store: MemoryRecordStore(),
      feedback: SilentFeedback(),
      includeExamples: true,
      now: () => _now,
    );
    // The samples are dated 24 October; the learner started today.
    expect(state.history.any((s) => s.date.isBefore(_now)), isTrue);
    expect(state.daysWithHifive, 0);
  });

  test('reviewing words keeps the streak; samples and focus alone do not', () {
    var now = DateTime(2026, 11, 12, 9);
    final state = createAppState(
      store: MemoryRecordStore(),
      feedback: SilentFeedback(),
      includeExamples: true,
      now: () => now,
    );
    expect(state.studyDays, isEmpty);
    expect(state.streak, 0);

    state.rate(state.decks.first.words.first, 2);
    now = DateTime(2026, 11, 13, 9);
    state.rate(state.decks.first.words[1], 2);
    expect(state.studyDays, {'2026-11-12', '2026-11-13'});
    expect(state.streak, 2);
  });
}

class _ThrowingStore extends MemoryRecordStore {
  @override
  Future<List<SyncRecord>> loadAll() => throw StateError('broken');
}
