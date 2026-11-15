import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../domain/dictionary/entry.dart';
import '../../domain/repositories/dictionary_repository.dart';

/// Dictionary packs installed as SQLite files in [directory], one per pair
/// (`dictionary-en-vi.db`). A pack is reference data, not the learner's: it
/// is never synced and losing it only means downloading it again.
class SqliteDictionaryStore implements DictionaryStore {
  final String directory;
  SqliteDictionaryStore(this.directory);

  String _path(String pair) => '$directory/dictionary-$pair.db';

  @override
  Future<int?> version(String pair) async {
    final index = await open(pair);
    final v = index?.version;
    index?.close();
    return v;
  }

  @override
  Future<SqliteDictionaryIndex?> open(String pair) async {
    final file = File(_path(pair));
    if (!file.existsSync()) return null;
    try {
      return SqliteDictionaryIndex(
        sqlite3.open(file.path, mode: OpenMode.readOnly),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> install(DictionaryPackInfo pack, List<int> bytes) async {
    if (bytes.length != pack.bytes ||
        sha256.convert(bytes).toString() != pack.sha256) {
      throw const FormatException('The dictionary pack does not match.');
    }
    // The file is gzipped; a client that already inflated it hands over
    // the SQLite file itself.
    final raw = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b
        ? gzip.decode(bytes)
        : bytes;
    Directory(directory).createSync(recursive: true);
    final part = File('${_path(pack.pair)}.part');
    await part.writeAsBytes(raw, flush: true);
    try {
      final db = sqlite3.open(part.path, mode: OpenMode.readOnly);
      try {
        final check = db.select('PRAGMA quick_check').first.values.first;
        final version = SqliteDictionaryIndex(db).version;
        if (check != 'ok' || version != pack.version) {
          throw const FormatException('The dictionary pack is damaged.');
        }
      } finally {
        db.close();
      }
      await part.rename(_path(pack.pair));
    } catch (_) {
      if (part.existsSync()) part.deleteSync();
      rethrow;
    }
  }
}

/// A pack written by `tool/dictionary/build.py`: tables `entry`, `form`,
/// `alt`, `meta` and the full-text table `vi_index` over the meanings.
class SqliteDictionaryIndex implements DictionaryIndex {
  final Database _db;
  SqliteDictionaryIndex(this._db);

  /// The pack's version, from its `meta` table.
  int? get version {
    final rows = _db.select("SELECT value FROM meta WHERE key = 'version'");
    return rows.isEmpty ? null : int.tryParse(rows.first['value'] as String);
  }

  static const _columns =
      'id, word, pos, pos_rank, level, rank, uk, us, senses, en, ex, ex_vi, ex_src, needs';

  List<DictEntry> _entries(String where, List<Object?> args) => [
    for (final r in _db.select(
      'SELECT $_columns FROM entry WHERE $where',
      args,
    ))
      _entry(r),
  ];

  DictEntry _entry(Row r) {
    final senses = (jsonDecode(r['senses'] as String) as List)
        .cast<List<dynamic>>()
        .where((s) => (s.first as String).isNotEmpty)
        .map(
          (s) =>
              DictSense(s.first as String, s.skip(1).cast<String>().toList()),
        )
        .toList();
    return DictEntry(
      id: 'pack:${r['id']}',
      word: r['word'] as String,
      partOfSpeech: r['pos'] as String,
      posRank: r['pos_rank'] as int,
      level: r['level'] as String?,
      rank: r['rank'] as int?,
      uk: r['uk'] as String,
      us: r['us'] as String,
      senses: senses,
      definition: r['en'] as String,
      example: r['ex'] as String,
      exampleMeaning: r['ex_vi'] as String,
      exampleSource: r['ex_src'] as String,
      needsMeaning: r['needs'] == 1,
    );
  }

  @override
  Future<List<DictEntry>> entries(String key) async =>
      _entries('norm = ? ORDER BY id', [key]);

  @override
  Future<List<DictForm>> forms(String key) async => [
    for (final r in _db.select(
      'SELECT lemma, label, pos FROM form WHERE form = ?',
      [key],
    ))
      DictForm(r['lemma'] as String, r['label'] as String, r['pos'] as String),
  ];

  @override
  Future<List<String>> variants(String key) async => [
    for (final r in _db.select('SELECT canonical FROM alt WHERE variant = ?', [
      key,
    ]))
      r['canonical'] as String,
  ];

  @override
  Future<List<DictEntry>> startingWith(String key, {int limit = 8}) async =>
      _entries(
        'norm > ? AND norm < ? ORDER BY needs, coalesce(rank, 1000000000), '
        'length(norm) LIMIT ?',
        [key, '$key\u{FFFF}', limit],
      );

  @override
  Future<List<(String, int?)>> commonKeys(
    String first, {
    required int minLength,
    required int maxLength,
  }) async => [
    for (final r in _db.select(
      'SELECT norm, min(rank) AS rank FROM entry WHERE norm >= ? AND norm < ? '
      'AND length(norm) BETWEEN ? AND ? AND instr(norm, \' \') = 0 '
      'AND (level IS NOT NULL OR rank <= 30000) GROUP BY norm',
      [first, '$first\u{FFFF}', minLength, maxLength],
    ))
      (r['norm'] as String, r['rank'] as int?),
  ];

  @override
  Future<List<DictEntry>> withMeaning(String text, {int limit = 60}) async {
    final phrase = '"${text.replaceAll('"', ' ').trim()}"';
    final ids = [
      for (final r in _db.select(
        'SELECT rowid FROM vi_index WHERE vi_index MATCH ? LIMIT 400',
        [phrase],
      ))
        r['rowid'] as int,
    ];
    if (ids.isEmpty) return const [];
    return _entries(
      'id IN (${ids.join(',')}) ORDER BY level IS NULL, '
      'coalesce(rank, 1000000000) LIMIT ?',
      [limit],
    );
  }

  @override
  Future<List<DictEntry>> atLevel(String level, {int limit = 60}) async =>
      _entries(
        // Content words beyond the very commonest, which learners at any
        // level already meet everywhere.
        "level = ? AND needs = 0 AND pos_rank = 0 AND pos IN ('NOUN', 'VERB', "
        "'ADJECTIVE', 'ADVERB') AND coalesce(rank, 1000000000) > 300 "
        'ORDER BY coalesce(rank, 1000000000) LIMIT ?',
        [level, limit],
      );

  @override
  void close() => _db.close();
}
