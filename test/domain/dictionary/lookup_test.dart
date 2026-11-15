import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/dictionary/dictionary.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';

/// The real pack from `worker/catalog`, as the manifest names it.
DictionaryPackInfo packInfo() {
  final manifest = jsonDecode(
    File('worker/catalog/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final p = (manifest['dictionaries'] as Map)['en-vi'] as Map<String, dynamic>;
  return DictionaryPackInfo(
    pair: 'en-vi',
    version: p['version'] as int,
    path: p['path'] as String,
    bytes: p['bytes'] as int,
    sha256: p['sha256'] as String,
  );
}

List<int> packBytes() =>
    File('worker/catalog/${packInfo().path}').readAsBytesSync();

void main() {
  late Directory dir;
  late DictionaryIndex pack;
  late DictionaryLookup lookup;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('hifive-dict');
    final store = SqliteDictionaryStore(dir.path);
    await store.install(packInfo(), packBytes());
    pack = (await store.open('en-vi'))!;
    lookup = DictionaryLookup([pack]);
  });
  tearDownAll(() {
    pack.close();
    dir.deleteSync(recursive: true);
  });

  Future<List<DictHit>> hits(String q) async => (await lookup.lookup(q)).hits;
  Future<List<String>> words(String q) async => [
    for (final h in await hits(q)) h.entry.word,
  ];

  test('keys collapse case, hyphens and typographic apostrophes', () {
    expect(dictKey('Face-to-face'), 'face to face');
    expect(dictKey('  o’clock '), "o'clock");
    expect(foldVietnamese('Đẹp'), 'dep');
    expect(hasVietnamese('con mèo'), isTrue);
    expect(hasVietnamese('con meo'), isFalse);
  });

  test('editDistance counts a swap as one edit', () {
    expect(editDistance('recieve', 'receive'), 1);
    expect(editDistance('cat', 'cut'), 1);
    expect(editDistance('cat', 'elephant'), 3);
  });

  test(
    'bank leads with its money sense and keeps the river as its own entry',
    () async {
      final h = await hits('bank');
      expect(h.first.entry.senses.first.meaning, contains('ngân hàng'));
      expect(h.first.entry.ipa(), '/ˈbæŋk/');
      expect(
        h.any((x) => x.entry.senses.any((s) => s.meaning == 'bờ')),
        isTrue,
      );
    },
  );

  test('heteronyms keep their own pronunciation', () async {
    final h = await hits('lead');
    final metal = h.firstWhere((x) => x.entry.senses.first.meaning == 'chì');
    final guide = h.firstWhere(
      (x) => x.entry.senses.first.meaning.startsWith('dẫn'),
    );
    expect(metal.entry.ipa(), '/lɛd/');
    expect(guide.entry.ipa(), '/ˈliːd/');
    expect(guide.entry.partOfSpeech, 'VERB');
  });

  test('an inflection links to its lemma in the same part of speech', () async {
    final went = await hits('went');
    final go = went.firstWhere((h) => h.match == DictMatch.form);
    expect(go.entry.word, 'go');
    expect(go.entry.partOfSpeech, 'VERB');
    expect(go.formLabel, 'past');
    // *saw* keeps its own "cái cưa" and never links to the noun *see*.
    final saw = await hits('saw');
    expect(saw.first.entry.word, 'saw');
    expect(
      saw
          .where((h) => h.match == DictMatch.form)
          .map((h) => h.entry.partOfSpeech),
      everyElement('VERB'),
    );
  });

  test('phrases are found inflected, with an object or a possessive', () async {
    expect(await words('looked after'), contains('look after'));
    expect(await words('turn it off'), contains('turn off'));
    expect(await words('make up my mind'), contains("make up one's mind"));
    expect((await hits('to give up')).first.entry.word, 'give up');
  });

  test('a phrase no source translates asks for a meaning', () async {
    final h = (await hits('find out')).first.entry;
    expect(h.needsMeaning, isTrue);
    expect(h.definition, isNotEmpty);
    expect(h.senses, isEmpty);
  });

  test('spellings, joined forms and contractions find the word', () async {
    expect(await words('colour'), contains('colour'));
    expect(await words('face-to-face'), isNotEmpty);
    expect(await words('ice-cream'), contains('ice cream'));
    final im = await lookup.lookup("I'm");
    expect(im.outcome, DictOutcome.found);
    expect(im.hits.first.expansion, 'i am');
  });

  test('the typed case ranks first', () async {
    expect((await hits('Polish')).first.entry.word, 'Polish');
    expect((await hits('polish')).first.entry.word, 'polish');
  });

  test('typos get corrections among common words only', () async {
    final r = await lookup.lookup('recieve');
    expect(r.outcome, DictOutcome.suggestions);
    expect(r.hits.first.entry.word, 'receive');
    expect(r.hits.first.match, DictMatch.suggestion);
    expect(await words('acommodate'), contains('accommodate'));
  });

  test('Vietnamese finds English words, with or without diacritics', () async {
    final cat = await lookup.lookup('con mèo');
    expect(cat.outcome, DictOutcome.meaning);
    expect(cat.hits.first.entry.word, 'cat');
    expect((await lookup.lookup('con meo')).hits.first.entry.word, 'cat');
    expect((await hits('xin lỗi')).first.entry.word, 'sorry');
    expect(await words('đẹp'), contains('beautiful'));
  });

  test('vulgar senses are gone but neutral ones stay', () async {
    final cock = await hits('cock');
    expect(cock.first.entry.senses.first.meaning, contains('gà trống'));
  });

  test('empty, symbol-only and pasted sentences are not looked up', () async {
    expect((await lookup.lookup('   ')).outcome, DictOutcome.empty);
    expect((await lookup.lookup('123 !!!')).outcome, DictOutcome.empty);
    expect(
      (await lookup.lookup('I would like to order a cup of coffee please'))
          .outcome,
      DictOutcome.tooLong,
    );
    expect((await lookup.lookup('qzxqzx')).outcome, DictOutcome.none);
  });

  test("hifive's own word wins over the pack's", () async {
    final curated = DeckDictionaryIndex([
      Deck(
        id: 'd',
        title: 'Gia đình',
        description: '',
        words: [FlashWord(id: 'w', word: 'mother', meaning: 'mẹ (hifive)')],
      ),
    ]);
    final h = await DictionaryLookup([curated, pack]).lookup('mother');
    expect(h.hits.first.entry.curated, isTrue);
    expect(h.hits.first.entry.senses.first.meaning, 'mẹ (hifive)');
    expect(
      h.hits.where((x) => x.entry.partOfSpeech == 'NOUN' && !x.entry.curated),
      isEmpty,
    );
  });

  test('a card takes the chosen meanings, IPA and example', () async {
    final bank = (await hits('bank')).first.entry;
    final card = bank.toCard(id: 'id', picked: const [0, 1]);
    expect(
      card.meaning,
      '${bank.senses[0].meaning}; ${bank.senses[1].meaning}',
    );
    expect(card.phonetic, bank.uk);
    expect(card.partOfSpeech, 'NOUN');
    expect(card.example, bank.example);
  });

  test(
    'a damaged or mismatched pack is refused and the old one stays',
    () async {
      final store = SqliteDictionaryStore(dir.path);
      final bad = [...packBytes()]..[100] ^= 0xff;
      await expectLater(store.install(packInfo(), bad), throwsFormatException);
      expect(await store.version('en-vi'), packInfo().version);
      expect(
        File('${dir.path}/dictionary-en-vi.db.part').existsSync(),
        isFalse,
      );
    },
  );
}
