import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../domain/repositories/record_store.dart';
import '../../domain/sync/hlc.dart';
import '../../domain/sync/record.dart';

/// Stores records in a SQLite file on the device. [open] creates or
/// upgrades the schema; `user_version` tracks it.
class SqliteRecordStore implements RecordStore {
  final Database _db;
  SqliteRecordStore._(this._db);

  static const _version = 1;

  /// Opens the database at [path], or an in-memory one when it is null.
  factory SqliteRecordStore.open([String? path]) {
    final db = path == null ? sqlite3.openInMemory() : sqlite3.open(path);
    db.execute('PRAGMA journal_mode = WAL');
    final version = db.select('PRAGMA user_version').first.values.first as int;
    if (version < 1) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS records (
          kind TEXT NOT NULL,
          id TEXT NOT NULL,
          data TEXT,
          hlc TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (kind, id)
        ) WITHOUT ROWID''');
      db.execute('''
        CREATE TABLE IF NOT EXISTS meta (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        ) WITHOUT ROWID''');
    }
    db.execute('PRAGMA user_version = $_version');
    return SqliteRecordStore._(db);
  }

  @override
  Future<List<SyncRecord>> loadAll() async => [
    for (final row in _db.select('SELECT kind, id, data, hlc FROM records'))
      SyncRecord(
        row['kind'] as String,
        row['id'] as String,
        row['data'] == null
            ? null
            : Map<String, dynamic>.from(
                jsonDecode(row['data'] as String) as Map,
              ),
        Hlc.parse(row['hlc'] as String),
      ),
  ];

  @override
  Future<void> write(List<SyncRecord> records) async {
    if (records.isEmpty) return;
    final insert = _db.prepare('''
      INSERT INTO records (kind, id, data, hlc, dirty) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT (kind, id) DO UPDATE SET
        data = excluded.data, hlc = excluded.hlc, dirty = excluded.dirty
      WHERE excluded.hlc > records.hlc''');
    _db.execute('BEGIN');
    try {
      for (final r in records) {
        insert.execute([
          r.kind,
          r.id,
          r.data == null ? null : jsonEncode(r.data),
          r.hlc.toString(),
          RecordKind.local.contains(r.kind) ? 0 : 1,
        ]);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      insert.close();
    }
  }

  /// Keys of records not yet synced.
  List<(String, String)> dirtyKeys() => [
    for (final row in _db.select(
      'SELECT kind, id FROM records WHERE dirty = 1',
    ))
      (row['kind'] as String, row['id'] as String),
  ];

  @override
  Future<String?> meta(String key) async {
    final rows = _db.select('SELECT value FROM meta WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  @override
  Future<void> setMeta(String key, String value) async => _db.execute(
    'INSERT INTO meta (key, value) VALUES (?, ?) '
    'ON CONFLICT (key) DO UPDATE SET value = excluded.value',
    [key, value],
  );

  void close() => _db.close();
}
