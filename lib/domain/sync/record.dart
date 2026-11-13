import 'hlc.dart';

/// The kinds of record the app stores. See `docs/backend-plan.md`.
abstract final class RecordKind {
  static const setting = 'setting',
      session = 'session',
      historyCleared = 'historyCleared',
      deck = 'deck',
      word = 'word',
      review = 'review',
      game = 'game',
      focus = 'focus',
      legacyStats = 'legacyStats',
      device = 'device';

  /// Kinds that stay on this device and are never synced.
  static const local = {device};
}

/// One stored row. A null [data] marks a deletion, kept so it can sync.
class SyncRecord {
  final String kind, id;
  final Map<String, dynamic>? data;
  final Hlc hlc;
  const SyncRecord(this.kind, this.id, this.data, this.hlc);

  bool get deleted => data == null;
  (String, String) get key => (kind, id);
}

/// The merge rule shared by every device and the server: the record with
/// the greater stamp wins.
SyncRecord mergeRecords(SyncRecord a, SyncRecord b) => b.hlc > a.hlc ? b : a;
