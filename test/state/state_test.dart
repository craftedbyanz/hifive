import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/state/state.dart';

AppState stateWith(Map<String, dynamic> data, MemoryAppRepository repository) =>
    createAppState(
      repository: repository..data = data,
      feedback: SilentFeedback(),
    );

void main() {
  group('load keeps the app usable when saved data is bad', () {
    final cases = <String, Map<String, dynamic>>{
      'wrong field type': {'name': 42},
      'wrong bool type': {'showHints': 'yes'},
      'mode index out of range': {
        'modeOrder': [7, 8, 9],
      },
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
    };
    cases.forEach((name, data) {
      test(name, () async {
        final repository = MemoryAppRepository();
        final state = stateWith(data, repository);
        await state.load();
        expect(state.storageError, isNotNull);
        expect(state.name, 'An');
        expect(state.modeOrder, hasLength(3));
        expect(state.decks, isNotEmpty);
      });
    });

    test('a later field failing does not apply earlier fields', () async {
      final state = stateWith({
        'name': 'Saved',
        'totalXp': 'many',
      }, MemoryAppRepository());
      await state.load();
      expect(state.storageError, isNotNull);
      expect(state.name, 'An');
    });

    test('bad data is not overwritten by later saves', () async {
      final repository = MemoryAppRepository();
      final state = stateWith({'name': 42}, repository);
      await state.load();
      state.commit();
      await state.flush();
      expect(repository.data, {'name': 42});
    });

    test('a repository that throws an error is handled', () async {
      final state = createAppState(
        repository: _ThrowingRepository(),
        feedback: SilentFeedback(),
      );
      await state.load();
      expect(state.storageError, isNotNull);
    });
  });

  group('state changes save through named methods', () {
    late MemoryAppRepository repository;
    late AppState state;
    setUp(() {
      repository = MemoryAppRepository();
      state = createAppState(
        repository: repository,
        feedback: SilentFeedback(),
      );
    });
    Future<Map<String, dynamic>> saved() async {
      await state.flush();
      return repository.data!;
    }

    test('setters persist', () async {
      state
        ..setName('Linh')
        ..setLevel('B2')
        ..setAppearance('Mono')
        ..setInputColor('Blue')
        ..setDifficulty('Khó')
        ..setShowHints(true)
        ..setSound(false)
        ..setHaptic(false);
      final data = await saved();
      expect(data['name'], 'Linh');
      expect(data['level'], 'B2');
      expect(data['appearance'], 'Mono');
      expect(data['inputColor'], 'Blue');
      expect(data['difficulty'], 'Khó');
      expect(data['showHints'], isTrue);
      expect(data['sound'], isFalse);
      expect(data['haptic'], isFalse);
    });

    test('moveMode and resetModeOrder', () async {
      final first = state.modeOrder.first;
      state.moveMode(0, 2);
      expect(state.modeOrder.last, first);
      state.resetModeOrder();
      expect(state.modeOrder, StudyMode.values);
      expect((await saved())['modeOrder'], [0, 1, 2]);
    });

    test('decks can gain cards and reset their schedule', () async {
      final deck = Deck(id: 'd', title: 'T', description: 'D', words: []);
      final word = FlashWord(id: 'w', word: 'a', meaning: 'b');
      state
        ..addDeck(deck)
        ..addWords(deck, [word])
        ..rate(word, 3);
      expect(word.status, 'review');
      state.resetSchedule(deck);
      expect(word.status, 'new');
      expect(word.due, isNull);
      expect((await saved())['decks'], hasLength(state.decks.length));
    });

    test('finishing a game records score and clears only when asked', () {
      state
        ..saveGameProgress({'title': 'T'})
        ..finishGame(10, clearResume: false);
      expect(state.gameResume, isNotNull);
      state.finishGame(5, clearResume: true);
      expect(state.gameResume, isNull);
      expect(state.gamesPlayed, 2);
      expect(state.totalXp, 15);
      expect(state.bestScore, 10);
    });

    test('clearHistory empties saved results', () async {
      state = createAppState(
        repository: repository,
        feedback: SilentFeedback(),
        includeExamples: true,
      )..clearHistory();
      expect((await saved())['history'], isEmpty);
    });
  });

  test('valid saved data still round-trips', () async {
    final repository = MemoryAppRepository();
    final first =
        createAppState(repository: repository, feedback: SilentFeedback())
          ..name = 'Linh'
          ..totalXp = 12
          ..gameResume = {
            'title': 'T',
            'index': 1,
            'score': 2,
            'words': <Object>[],
          };
    first.commit();
    await first.flush();
    final second = createAppState(
      repository: repository,
      feedback: SilentFeedback(),
    );
    await second.load();
    expect(second.storageError, isNull);
    expect(second.name, 'Linh');
    expect(second.totalXp, 12);
    expect(second.gameResume?['index'], 1);
  });

  group('study language', () {
    test('defaults to English for data saved before courses', () async {
      final state = stateWith({'name': 'Lan'}, MemoryAppRepository());
      await state.load();
      expect(state.language, Language.english);
      expect(state.storageError, isNull);
    });

    test('an unknown saved code falls back to English', () async {
      final state = stateWith({'language': 'xx'}, MemoryAppRepository());
      await state.load();
      expect(state.language, Language.english);
    });

    test('is saved by code and restored', () async {
      final repository = MemoryAppRepository();
      final first = createAppState(
        repository: repository,
        feedback: SilentFeedback(),
      )..setLanguage(Language.japanese);
      await first.flush();
      expect(repository.data!['language'], 'ja');
      final second = createAppState(
        repository: repository,
        feedback: SilentFeedback(),
      );
      await second.load();
      expect(second.language, Language.japanese);
    });
  });
}

class _ThrowingRepository implements AppRepository {
  @override
  Future<Map<String, dynamic>?> load() => throw StateError('broken');
  @override
  Future<void> save(Map<String, dynamic> data) async {}
}
