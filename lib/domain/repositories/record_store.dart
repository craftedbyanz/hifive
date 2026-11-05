import '../sync/record.dart';

/// The device's database of [SyncRecord]s, the app's only source of truth.
/// Writes keep the record with the greater stamp, as sync will.
abstract interface class RecordStore {
  /// Every record, deletions included.
  Future<List<SyncRecord>> loadAll();

  /// Stores [records] in one transaction. Records of a synced kind are marked
  /// as not yet synced.
  Future<void> write(List<SyncRecord> records);

  /// Small values about this install, such as its device id.
  Future<String?> meta(String key);
  Future<void> setMeta(String key, String value);
}
