import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/dictionary/dictionary.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/state/state.dart';

import '../domain/dictionary/lookup_test.dart' show packBytes, packInfo;

/// A pack that fails on every read, like a damaged file.
class _BrokenIndex implements DictionaryIndex {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(StateError('damaged pack'));
}

class _BrokenStore implements DictionaryStore {
  @override
  Future<DictionaryIndex?> open(String pair) async => _BrokenIndex();
  @override
  Future<int?> version(String pair) async => 1;
  @override
  Future<void> install(DictionaryPackInfo pack, List<int> bytes) async {}
}

class _Packs implements DictionaryPacks {
  var fail = false;
  var downloads = 0;
  DictionaryPackInfo info = packInfo();
  @override
  Future<DictionaryPackInfo?> latest(String pair) async {
    if (fail) throw const SocketException('offline');
    return pair == 'en-vi' ? info : null;
  }

  @override
  Future<List<int>> download(DictionaryPackInfo pack) async {
    downloads++;
    return packBytes();
  }
}

void main() {
  var now = DateTime(2026, 11, 15, 9);
  late Directory dir;
  late MemoryRecordStore store;
  late _Packs packs;

  AppState make() => createAppState(
    store: store,
    dictionaryStore: SqliteDictionaryStore(dir.path),
    dictionaryPacks: packs,
    feedback: SilentFeedback(),
    now: () => now,
  );

  setUp(() {
    now = DateTime(2026, 11, 15, 9);
    dir = Directory.systemTemp.createTempSync('hifive-dict-state');
    store = MemoryRecordStore();
    packs = _Packs();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('the pack downloads once, then opens from the device offline', () async {
    final state = make();
    await state.load();
    expect(state.dictionaryReady, isFalse);
    await state.refreshDictionary();
    expect(state.dictionaryReady, isTrue);
    expect(packs.downloads, 1);
    final bank = await state.lookupWord('bank');
    expect(bank.hits.first.entry.senses.first.meaning, contains('ngân hàng'));

    packs.fail = true;
    final again = make();
    await again.load();
    await again.refreshDictionary();
    expect(again.dictionaryReady, isTrue);
    expect(packs.downloads, 1);
  });

  test('the same version is not downloaded again, a newer one is', () async {
    final state = make();
    await state.load();
    await state.refreshDictionary();
    now = now.add(const Duration(days: 1));
    await state.refreshDictionary();
    expect(packs.downloads, 1);
    // A version the device lacks is fetched; this one fails its check.
    packs.info = DictionaryPackInfo(
      pair: 'en-vi',
      version: packInfo().version + 1,
      path: packInfo().path,
      bytes: packInfo().bytes,
      sha256: packInfo().sha256,
    );
    now = now.add(const Duration(days: 1));
    await state.refreshDictionary();
    expect(packs.downloads, 2);
    // The damaged update is refused and the installed pack keeps working.
    expect(state.dictionaryReady, isTrue);
    expect(state.dictionaryDownloading, isFalse);
    expect((await state.lookupWord('cat')).outcome, DictOutcome.found);
  });

  test("without a pack, hifive's own words are still found", () async {
    packs.fail = true;
    final state = make();
    await state.load();
    await state.refreshDictionary();
    expect(state.dictionaryReady, isFalse);
    final word = state.decks.first.words.first;
    final r = await state.lookupWord(word.word);
    expect(r.hits.first.entry.curated, isTrue);
    expect(r.hits.first.entry.senses.first.meaning, word.meaning);
  });

  test(
    'adding a word makes saved words, skips repeats and can be undone',
    () async {
      final state = make();
      await state.load();
      await state.refreshDictionary();
      final bank = (await state.lookupWord('bank')).hits.first.entry;
      final card = state.addFromDictionary(bank, picked: const [0]);
      final saved = state.decks.firstWhere((d) => d.id == 'saved');
      expect(saved.words, [card]);
      expect(card.meaning, bank.senses.first.meaning);
      expect(state.addFromDictionary(bank), same(card));
      expect(state.deckWith('Bank')?.id, 'saved');

      state.removeWord(saved, card);
      await state.flush();
      expect(saved.words, isEmpty);
      final reloaded = make();
      await reloaded.load();
      expect(
        reloaded.decks.where((d) => d.id == 'saved').expand((d) => d.words),
        isEmpty,
      );
    },
  );

  test('a typed meaning replaces the dictionary one', () async {
    final state = make();
    await state.load();
    await state.refreshDictionary();
    final findOut = (await state.lookupWord('find out')).hits.first.entry;
    expect(findOut.needsMeaning, isTrue);
    final card = state.addFromDictionary(findOut, meaning: 'tìm ra');
    expect(card.meaning, 'tìm ra');
    expect(card.definition, isNotEmpty);
  });

  test(
    'recent lookups stay on the device, newest first, without repeats',
    () async {
      final state = make();
      await state.load();
      state
        ..rememberLookup('bank')
        ..rememberLookup('cat')
        ..rememberLookup('Bank');
      expect(state.recentLookups, ['Bank', 'cat']);
      await Future<void>.delayed(Duration.zero);
      final again = make();
      await again.load();
      expect(again.recentLookups, ['Bank', 'cat']);
    },
  );

  test('words to learn are at the learner level and not in a deck', () async {
    final state = make();
    await state.load();
    await state.refreshDictionary();
    final words = await state.wordsToLearn();
    expect(words, hasLength(6));
    expect(words.every((e) => e.level == state.level), isTrue);
    final have = state.decks
        .expand((d) => d.words)
        .map((w) => w.word.toLowerCase());
    expect(words.any((e) => have.contains(e.word.toLowerCase())), isFalse);
  });

  test('a pack that cannot be read still finds hifive words', () async {
    final state = createAppState(
      store: store,
      dictionaryStore: _BrokenStore(),
      feedback: SilentFeedback(),
      now: () => now,
    );
    await state.load();
    expect(state.dictionaryReady, isTrue);
    final word = state.decks.first.words.first.word;
    final result = await state.lookupWord(word);
    expect(result.hits.map((h) => h.entry.word), contains(word));
    expect(await state.wordsToLearn(), isEmpty);
  });
}
