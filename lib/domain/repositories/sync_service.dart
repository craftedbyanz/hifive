import '../sync/hlc.dart';
import '../sync/record.dart';

/// One `POST /v1/sync` call: records to push and where to pull from.
class SyncRequest {
  final String deviceId;
  final int cursor;
  final List<SyncRecord> records;
  const SyncRequest({
    required this.deviceId,
    required this.cursor,
    required this.records,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'cursor': cursor,
    'records': [for (final r in records) recordToJson(r)],
  };
}

/// What changed on the server after the cursor, a page at a time.
class SyncResponse {
  final int cursor;
  final List<SyncRecord> records;
  final bool hasMore;
  const SyncResponse({
    required this.cursor,
    required this.records,
    required this.hasMore,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> j) => SyncResponse(
    cursor: j['cursor'] as int,
    hasMore: j['hasMore'] as bool,
    records: [
      for (final r in j['records'] as List)
        recordFromJson(Map<String, dynamic>.from(r as Map)),
    ],
  );
}

Map<String, dynamic> recordToJson(SyncRecord r) => {
  'kind': r.kind,
  'id': r.id,
  'data': r.data,
  'hlc': r.hlc.toString(),
};

SyncRecord recordFromJson(Map<String, dynamic> j) => SyncRecord(
  j['kind'] as String,
  j['id'] as String,
  j['data'] == null ? null : Map<String, dynamic>.from(j['data'] as Map),
  Hlc.parse(j['hlc'] as String),
);

/// Why a sync failed. [unavailable] is worth retrying later; [unauthorized]
/// needs a fresh token; [rejected] means the app sent something invalid.
enum SyncError { unauthorized, unavailable, rejected, unknown }

class SyncException implements Exception {
  final SyncError error;
  final String? detail;
  const SyncException(this.error, [this.detail]);
  @override
  String toString() =>
      'SyncException(${error.name}${detail == null ? '' : ': $detail'})';
}

/// The sync API (`worker/`). Throws [SyncException] on failure.
abstract interface class SyncService {
  Future<SyncResponse> exchange(String idToken, SyncRequest request);
}
