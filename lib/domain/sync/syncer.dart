import '../repositories/record_store.dart';
import '../repositories/sync_service.dart';
import 'hlc.dart';
import 'record.dart';

/// What one sync did.
class SyncOutcome {
  final int pushed, pulled;

  /// The greatest stamp pulled, which the device's clock must move past.
  final Hlc latest;
  const SyncOutcome({
    required this.pushed,
    required this.pulled,
    required this.latest,
  });
}

/// Pushes dirty records and pulls changes until both sides are caught up.
/// Each account keeps its own cursor, so signing into another account never
/// reuses one.
class Syncer {
  final RecordStore store;
  final SyncService service;

  /// Stops a sync that keeps finding work, such as a server that always
  /// claims more; the next sync carries on.
  static const maxRounds = 50;
  const Syncer({required this.store, required this.service});

  static String cursorKey(String uid) => 'syncCursor:$uid';

  Future<SyncOutcome> run({
    required String uid,
    required String deviceId,
    required String idToken,
  }) async {
    var cursor = int.tryParse(await store.meta(cursorKey(uid)) ?? '') ?? 0;
    var pushed = 0, pulled = 0;
    var latest = Hlc.zero;
    for (var round = 0; round < maxRounds; round++) {
      final dirty = await store.dirtyRecords();
      final response = await service.exchange(
        idToken,
        SyncRequest(deviceId: deviceId, cursor: cursor, records: dirty),
      );
      // The server has these now; ones changed meanwhile stay dirty.
      await store.markSynced(dirty);
      final remote = [
        for (final r in response.records)
          if (!RecordKind.local.contains(r.kind)) r,
      ];
      await store.applyRemote(remote);
      for (final r in remote) {
        if (r.hlc > latest) latest = r.hlc;
      }
      cursor = response.cursor;
      await store.setMeta(cursorKey(uid), '$cursor');
      pushed += dirty.length;
      pulled += remote.length;
      final morePush = (await store.dirtyRecords(limit: 1)).isNotEmpty;
      if (!response.hasMore && !morePush) break;
    }
    return SyncOutcome(pushed: pushed, pulled: pulled, latest: latest);
  }
}
