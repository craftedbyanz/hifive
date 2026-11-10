import '../sync/record.dart';

/// The device's database of [SyncRecord]s, the app's only source of truth.
/// Writes keep the record with the greater stamp, as sync will.
abstract interface class RecordStore {
  /// Every record, deletions included.
  Future<List<SyncRecord>> loadAll();

  /// Stores local changes in one transaction. Records of a synced kind are
  /// marked dirty, meaning not yet synced.
  Future<void> write(List<SyncRecord> records);

  /// Up to [limit] dirty records, oldest stamp first.
  Future<List<SyncRecord>> dirtyRecords({int limit = 500});

  /// Stores records pulled from the server, keeping the greater stamp, and
  /// never marks them dirty: the server already has them.
  Future<void> applyRemote(List<SyncRecord> records);

  /// Clears the dirty flag of each pushed record that still has the stamp it
  /// was pushed with; one changed while the request ran stays dirty.
  Future<void> markSynced(List<SyncRecord> pushed);

  /// Deletes every record, for signing out. Meta values are kept.
  Future<void> clearRecords();

  /// Small values about this install, such as its device id.
  Future<String?> meta(String key);
  Future<void> setMeta(String key, String value);
  Future<void> deleteMeta(String key);
}
