import '../../domain/repositories/record_store.dart';
import '../../domain/sync/record.dart';

/// Keeps records in memory, for tests and previews.
class MemoryRecordStore implements RecordStore {
  final records = <(String, String), SyncRecord>{};
  final dirty = <(String, String)>{};
  final metadata = <String, String>{};

  @override
  Future<List<SyncRecord>> loadAll() async => records.values.toList();

  bool _keep(SyncRecord r) {
    final old = records[r.key];
    if (old != null && !(r.hlc > old.hlc)) return false;
    records[r.key] = r;
    return true;
  }

  @override
  Future<void> write(List<SyncRecord> batch) async {
    for (final r in batch) {
      if (_keep(r) && !RecordKind.local.contains(r.kind)) dirty.add(r.key);
    }
  }

  @override
  Future<List<SyncRecord>> dirtyRecords({int limit = 500}) async {
    final list = [for (final k in dirty) records[k]!]
      ..sort((a, b) => a.hlc.compareTo(b.hlc));
    return list.take(limit).toList();
  }

  @override
  Future<void> applyRemote(List<SyncRecord> batch) async {
    for (final r in batch) {
      if (_keep(r)) dirty.remove(r.key);
    }
  }

  @override
  Future<void> markSynced(List<SyncRecord> pushed) async {
    for (final r in pushed) {
      if (records[r.key]?.hlc == r.hlc) dirty.remove(r.key);
    }
  }

  @override
  Future<void> clearRecords() async {
    records.clear();
    dirty.clear();
  }

  @override
  Future<String?> meta(String key) async => metadata[key];

  @override
  Future<void> setMeta(String key, String value) async => metadata[key] = value;

  @override
  Future<void> deleteMeta(String key) async => metadata.remove(key);

  /// The data of the live record [kind]/[id], or null.
  Map<String, dynamic>? data(String kind, String id) =>
      records[(kind, id)]?.data;
}
