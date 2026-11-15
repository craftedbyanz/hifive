import '../repositories/dictionary_repository.dart';
import 'entry.dart';

/// The key a word is stored and searched under: lower case, typographic
/// apostrophes made plain, and spaces, hyphens and underscores collapsed
/// to one space (*Face-to-face* → `face to face`).
String dictKey(String text) => text
    .replaceAll('’', "'")
    .replaceAll('‘', "'")
    .toLowerCase()
    .replaceAll(RegExp(r'[\s\-_]+'), ' ')
    .trim();

const _vietnamese =
    'àáảãạăằắẳẵặâầấẩẫậđèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ';
const _plain =
    'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
final _vietnameseLetter = RegExp('[$_vietnamese]');

/// Whether [text] has a Vietnamese letter (*mèo*, *đẹp*).
bool hasVietnamese(String text) =>
    _vietnameseLetter.hasMatch(text.toLowerCase());

/// [text] in lower case without Vietnamese diacritics (*Đẹp* → `dep`).
String foldVietnamese(String text) {
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final c = String.fromCharCode(rune);
    final i = _vietnamese.indexOf(c);
    out.write(i < 0 ? c : _plain[i]);
  }
  return out.toString();
}

/// Contractions learners type, by key, with their expansion.
const contractions = {
  "i'm": 'i am',
  "you're": 'you are',
  "we're": 'we are',
  "they're": 'they are',
  "he's": 'he is',
  "she's": 'she is',
  "it's": 'it is',
  "that's": 'that is',
  "there's": 'there is',
  "what's": 'what is',
  "let's": 'let us',
  "i've": 'i have',
  "you've": 'you have',
  "we've": 'we have',
  "i'll": 'i will',
  "you'll": 'you will',
  "i'd": 'i would',
  "don't": 'do not',
  "doesn't": 'does not',
  "didn't": 'did not',
  "isn't": 'is not',
  "aren't": 'are not',
  "wasn't": 'was not',
  "weren't": 'were not',
  "can't": 'cannot',
  "couldn't": 'could not',
  "won't": 'will not',
  "wouldn't": 'would not',
  "shouldn't": 'should not',
  "haven't": 'have not',
  "hasn't": 'has not',
};

const _objects = {
  'it',
  'him',
  'her',
  'them',
  'me',
  'us',
  'you',
  'this',
  'that',
  'something',
  'someone',
  'somebody',
  'sth',
  'sb',
};
const _possessives = {'my', 'your', 'his', 'her', 'our', 'their', 'its'};
const _particles = {'of', 'to', 'with', 'for', 'on', 'at', 'in', 'from'};
const _demoted = {'ABBREVIATION', 'NAME', 'OTHER', 'CONTRACTION'};

/// Vietnamese classifiers and nominalisers, folded, dropped for a second
/// meaning search.
const _classifiers = {
  'con',
  'cai',
  'chiec',
  'qua',
  'su',
  'viec',
  'cuoc',
  'nguoi',
  'bai',
  'tam',
  'to',
  'cay',
};

/// The longest phrase looked up, in words and characters.
const maxLookupWords = 6, maxLookupLength = 60;

/// Looks words up across [indexes], the curated one first, following
/// docs/dictionary-plan.md: exact entries, inflections, spellings, phrases
/// and contractions; then prefixes and spelling corrections; then
/// Vietnamese meanings.
class DictionaryLookup {
  final List<DictionaryIndex> indexes;
  const DictionaryLookup(this.indexes);

  Future<DictResult> lookup(String raw) async {
    final typed = raw.trim();
    var key = dictKey(typed)
        .replaceAll(RegExp(r'''^["'(]+|["'),!?;:]+$'''), '');
    if (key.endsWith('.') && '.'.allMatches(key).length == 1) {
      key = key.substring(0, key.length - 1);
    }
    key = key.trim();
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(key)) {
      return DictResult(typed, DictOutcome.empty);
    }
    if (key.length > maxLookupLength ||
        key.split(' ').length > maxLookupWords) {
      return DictResult(typed, DictOutcome.tooLong);
    }
    if (hasVietnamese(key)) {
      final hits = await _byMeaning(key);
      return DictResult(
        typed,
        hits.isEmpty ? DictOutcome.none : DictOutcome.meaning,
        hits,
      );
    }
    if (key.startsWith('to ') && key.length > 3) key = key.substring(3);

    final found = await _english(key, typed);
    if (found.isNotEmpty) return DictResult(typed, DictOutcome.found, found);

    final suggestions = [
      ...await _corrections(key),
      if (key.length >= 2)
        for (final e in await _all((i) => i.startingWith(key)))
          DictHit(e, DictMatch.prefix),
    ];
    final unique = _unique(suggestions, byWord: true);
    if (unique.isNotEmpty) {
      return DictResult(typed, DictOutcome.suggestions, unique);
    }
    // Vietnamese typed without diacritics, as "con meo".
    final meaning = await _byMeaning(key);
    if (meaning.isNotEmpty) {
      return DictResult(typed, DictOutcome.meaning, meaning);
    }
    return DictResult(typed, DictOutcome.none);
  }

  Future<List<DictHit>> _english(String key, String typed) async {
    final hits = <DictHit>[];
    Future<void> exact(String k, DictMatch match) async {
      for (final e in await _all((i) => i.entries(k))) {
        hits.add(DictHit(e, match));
      }
    }

    await exact(key, DictMatch.exact);
    if (key.contains(' ')) {
      await exact(key.replaceAll(' ', ''), DictMatch.variant);
    }
    if (contractions[key] case final expansion?) {
      for (final part in expansion.split(' ')) {
        final best = _ranked([
          for (final e in await _all((i) => i.entries(part)))
            DictHit(e, DictMatch.contraction, expansion: expansion),
        ], part);
        if (best.isNotEmpty) hits.add(best.first);
      }
    }
    for (final f in await _allForms(key)) {
      for (final e in await _all((i) => i.entries(f.lemma))) {
        if (e.partOfSpeech == f.partOfSpeech) {
          hits.add(DictHit(e, DictMatch.form, form: key, formLabel: f.label));
        }
      }
    }
    for (final i in indexes) {
      for (final canonical in await i.variants(key)) {
        for (final e in await i.entries(canonical)) {
          hits.add(DictHit(e, DictMatch.variant));
        }
      }
    }
    final words = key.split(' ');
    if (words.length >= 2) {
      final heads = {
        words.first,
        for (final f in await _allForms(words.first)) f.lemma,
      };
      final rest = words.skip(1).toList();
      final tries = <String>{};
      for (final head in heads) {
        final noObject = rest.where((w) => !_objects.contains(w)).toList();
        final owned = [
          for (final w in rest) _possessives.contains(w) ? "one's" : w,
        ];
        final ownedNoObject = [
          for (final w in noObject) _possessives.contains(w) ? "one's" : w,
        ];
        for (final r in [rest, noObject, owned, ownedNoObject]) {
          tries.add([head, ...r].join(' '));
          if (r.length > 1 && _particles.contains(r.last)) {
            tries.add([head, ...r.take(r.length - 1)].join(' '));
          }
        }
      }
      tries.remove(key);
      for (final t in tries) {
        await exact(t, DictMatch.phrase);
      }
    }
    return _ranked(_unique(hits), typed);
  }

  Future<List<DictForm>> _allForms(String key) async => [
    for (final i in indexes) ...await i.forms(key),
  ];

  Future<List<DictEntry>> _all(
    Future<List<DictEntry>> Function(DictionaryIndex) get,
  ) async => [for (final i in indexes) ...await get(i)];

  /// Spelling corrections among common words: Damerau-Levenshtein distance
  /// 1 for words of up to five letters, 2 for longer ones.
  Future<List<DictHit>> _corrections(String key) async {
    if (key.length < 3 || key.contains(' ')) return const [];
    final limit = key.length <= 5 ? 1 : 2;
    final scored = <(int, int, String)>[];
    final seen = <String>{};
    for (final i in indexes) {
      final keys = await i.commonKeys(
        key[0],
        minLength: key.length - limit,
        maxLength: key.length + limit,
      );
      for (final (k, rank) in keys) {
        if (!seen.add(k)) continue;
        final d = editDistance(key, k, limit);
        if (d > 0 && d <= limit) scored.add((d, rank ?? 1 << 30, k));
      }
    }
    scored.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    final out = <DictHit>[];
    for (final (_, _, k) in scored.take(3)) {
      final best = _ranked([
        for (final e in await _all((i) => i.entries(k)))
          DictHit(e, DictMatch.suggestion),
      ], k);
      if (best.isNotEmpty) out.add(best.first);
    }
    return out;
  }

  Future<List<DictHit>> _byMeaning(String text) async {
    // "con mèo" is also looked up as "mèo": the classifier is often left
    // out of a meaning.
    final words = text.split(' ');
    final bare =
        words.length > 1 && _classifiers.contains(foldVietnamese(words.first))
        ? words.skip(1).join(' ')
        : null;
    final wanted = {
      foldVietnamese(text),
      if (bare != null) foldVietnamese(bare),
    };
    final q = foldVietnamese(bare ?? text);
    // Typed with diacritics, a meaning must carry them too: "mèo" is not
    // "méo" or "mẹo", though the index matches all three.
    final marked = hasVietnamese(text);
    final exactWords = {
      for (final t in [text, ?bare]) t.toLowerCase(),
    };
    bool spelled(DictEntry e) =>
        !marked ||
        e.senses.any(
          (s) => exactWords.any(
            (w) => RegExp(
              '(^|[^\\p{L}])${RegExp.escape(w)}(\$|[^\\p{L}])',
              unicode: true,
            ).hasMatch(s.meaning.toLowerCase()),
          ),
        );
    final entries = _unique([
      for (final t in [text, ?bare])
        for (final e in await _all((i) => i.withMeaning(t)))
          if (spelled(e)) DictHit(e, DictMatch.meaning),
    ]);
    int place(DictEntry e) {
      for (var i = 0; i < e.senses.length; i++) {
        if (foldVietnamese(e.senses[i].meaning).contains(q)) return i;
      }
      return 9;
    }

    bool whole(DictEntry e) => e.senses.any(
      (s) => s.meaning
          .split(RegExp(r'[,;/]'))
          .any(
            (part) => wanted.contains(
              foldVietnamese(part).replaceAll(RegExp(r'[().]'), '').trim(),
            ),
          ),
    );
    final scored = [
      for (final h in entries)
        (
          h,
          [
            h.entry.curated ? 0 : 1,
            whole(h.entry) && place(h.entry) == 0 ? 0 : 1,
            h.entry.common ? 0 : 1,
            place(h.entry) == 0 ? 0 : 1,
            whole(h.entry) ? 0 : 1,
            h.entry.rank ?? 1 << 30,
          ],
        ),
    ]..sort((a, b) => _compare(a.$2, b.$2));
    return [for (final (h, _) in scored.take(12)) h];
  }

  /// Best first: entries with a Vietnamese meaning, hifive's own, the typed
  /// case, the word itself before links to it, main part of speech, common
  /// words, and names or abbreviations last unless typed with a capital.
  List<DictHit> _ranked(List<DictHit> hits, String typed) {
    final capital = typed.isNotEmpty && typed[0] != typed[0].toLowerCase();
    List<int> score(DictHit h) {
      final e = h.entry;
      final w = e.word;
      return [
        e.needsMeaning ? 1 : 0,
        w == typed ? 0 : (w == w.toLowerCase() ? 1 : 2),
        _demoted.contains(e.partOfSpeech) && !capital ? 1 : 0,
        e.curated ? 0 : 1,
        switch (h.match) {
          DictMatch.exact || DictMatch.phrase || DictMatch.contraction => 0,
          DictMatch.variant => 1,
          _ => 2,
        },
        e.posRank,
        e.common ? 0 : 1,
        e.rank ?? 1 << 30,
      ];
    }

    final scored = [for (final h in hits) (h, score(h))]
      ..sort((a, b) => _compare(a.$2, b.$2));
    return [for (final (h, _) in scored) h];
  }

  /// Drops repeats: the same entry, and a curated card that repeats a pack
  /// entry's word and part of speech (the curated one is kept). With
  /// [byWord], one row per word.
  List<DictHit> _unique(List<DictHit> hits, {bool byWord = false}) {
    final curated = {
      for (final h in hits)
        if (h.entry.curated) '${dictKey(h.entry.word)}|${h.entry.partOfSpeech}',
    };
    final seen = <String>{};
    return [
      for (final h in hits)
        if (!(!h.entry.curated &&
                curated.contains(
                  '${dictKey(h.entry.word)}|${h.entry.partOfSpeech}',
                )) &&
            seen.add(byWord ? dictKey(h.entry.word) : h.entry.id))
          h,
    ];
  }
}

int _compare(List<int> a, List<int> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return 0;
}

/// Damerau-Levenshtein (optimal string alignment) distance between [a] and
/// [b], or [cap] + 1 once it is certainly over [cap].
int editDistance(String a, String b, [int cap = 2]) {
  if ((a.length - b.length).abs() > cap) return cap + 1;
  var before = List<int>.filled(b.length + 1, 0);
  var prev = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    var best = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var v = [
        prev[j] + 1,
        cur[j - 1] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
      if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
        final t = before[j - 2] + 1;
        if (t < v) v = t;
      }
      cur[j] = v;
      if (v < best) best = v;
    }
    if (best > cap) return cap + 1;
    before = prev;
    prev = cur;
  }
  return prev[b.length];
}
