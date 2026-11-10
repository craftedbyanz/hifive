import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/sync/sync.dart';

/// The sync Worker's rules in memory (`worker/src/sync.ts`): the greater
/// stamp wins, every winning write takes the account's next number, pulls
/// page by cursor, and device-only records are refused.
class FakeSyncServer implements SyncService {
  final int pageSize;
  FakeSyncServer({this.pageSize = 500});

  final _records = <String, Map<(String, String), (SyncRecord, int)>>{};
  final _seq = <String, int>{};
  int requests = 0;

  /// Fails the next call before anything is stored.
  SyncError? failBefore;

  /// Stores the next call's records, then loses the response.
  bool dropResponse = false;

  /// Runs while a request is in flight, after its records were read.
  Future<void> Function()? during;

  List<SyncRecord> recordsOf(String uid) => [
    for (final (r, _) in (_records[uid] ?? {}).values) r,
  ];

  @override
  Future<SyncResponse> exchange(String idToken, SyncRequest request) async {
    requests++;
    if (!idToken.startsWith('token-')) {
      throw const SyncException(SyncError.unauthorized);
    }
    await during?.call();
    final failure = failBefore;
    if (failure != null) {
      failBefore = null;
      throw SyncException(failure);
    }
    final uid = idToken.substring('token-'.length);
    final rows = _records.putIfAbsent(uid, () => {});
    if (request.records.any((r) => RecordKind.local.contains(r.kind))) {
      throw const SyncException(SyncError.rejected, 'device record');
    }
    for (final r in request.records) {
      final old = rows[r.key];
      if (old != null && !(r.hlc > old.$1.hlc)) continue;
      final seq = (_seq[uid] ?? 0) + 1;
      _seq[uid] = seq;
      rows[r.key] = (r, seq);
    }
    if (dropResponse) {
      dropResponse = false;
      throw const SyncException(SyncError.unavailable, 'response lost');
    }
    final latest = _seq[uid] ?? 0;
    final cursor = request.cursor > latest ? 0 : request.cursor;
    final changed = rows.values.where((e) => e.$2 > cursor).toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
    final page = changed.take(pageSize).toList();
    return SyncResponse(
      cursor: page.isEmpty ? cursor : page.last.$2,
      hasMore: changed.length > pageSize,
      records: [for (final (r, _) in page) r],
    );
  }
}
