import '../../domain/repositories/record_store.dart';
import '../../domain/sync/record.dart';

/// Keeps records in memory, for tests and previews.
class MemoryRecordStore implements RecordStore {
  final records = <(String, String), SyncRecord>{};
  final dirty = <(String, String)>{};
  final metadata = <String, String>{};

  @override
  Future<List<SyncRecord>> loadAll() async => records.values.toList();

  @override
  Future<void> write(List<SyncRecord> batch) async {
    for (final r in batch) {
      final old = records[r.key];
      if (old != null && !(r.hlc > old.hlc)) continue;
      records[r.key] = r;
      if (!RecordKind.local.contains(r.kind)) dirty.add(r.key);
    }
  }

  @override
  Future<String?> meta(String key) async => metadata[key];

  @override
  Future<void> setMeta(String key, String value) async => metadata[key] = value;

  /// The data of the live record [kind]/[id], or null.
  Map<String, dynamic>? data(String kind, String id) =>
      records[(kind, id)]?.data;
}
