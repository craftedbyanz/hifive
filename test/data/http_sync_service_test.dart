import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _request = SyncRequest(
  deviceId: 'dev-a',
  cursor: 4,
  records: [
    SyncRecord('setting', 'name', {'v': 'Lan'}, Hlc(5, 1, 'dev-a')),
    SyncRecord('deck', 'd1', null, Hlc(6, 0, 'dev-a')),
  ],
);

HttpSyncService _service(MockClientHandler handler) =>
    HttpSyncService(Uri.parse('https://api.test'), client: MockClient(handler));

void main() {
  test('posts the request with the token and parses the reply', () async {
    late http.Request sent;
    final service = _service((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'cursor': 9,
          'hasMore': true,
          'records': [
            {
              'kind': 'setting',
              'id': 'voice',
              'data': {'v': 'Mia'},
              'hlc': const Hlc(7, 0, 'ipad').toString(),
            },
          ],
        }),
        200,
      );
    });
    final res = await service.exchange('tok', _request);
    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'https://api.test/v1/sync');
    expect(sent.headers['authorization'], 'Bearer tok');
    expect(jsonDecode(sent.body), {
      'deviceId': 'dev-a',
      'cursor': 4,
      'records': [
        {
          'kind': 'setting',
          'id': 'name',
          'data': {'v': 'Lan'},
          'hlc': '000000000000005:0001:dev-a',
        },
        {
          'kind': 'deck',
          'id': 'd1',
          'data': null,
          'hlc': '000000000000006:0000:dev-a',
        },
      ],
    });
    expect((res.cursor, res.hasMore), (9, true));
    expect(res.records.single.hlc, const Hlc(7, 0, 'ipad'));
    expect(res.records.single.data, {'v': 'Mia'});
  });

  for (final (status, error) in [
    (401, SyncError.unauthorized),
    (400, SyncError.rejected),
    (413, SyncError.rejected),
    (429, SyncError.unavailable),
    (503, SyncError.unavailable),
    (418, SyncError.unknown),
  ]) {
    test('HTTP $status is ${error.name}', () async {
      final service = _service((_) async => http.Response('{}', status));
      await expectLater(
        service.exchange('tok', _request),
        throwsA(isA<SyncException>().having((e) => e.error, 'error', error)),
      );
    });
  }

  test('no network is unavailable', () async {
    final service = _service((_) async => throw const SocketException('down'));
    await expectLater(
      service.exchange('tok', _request),
      throwsA(
        isA<SyncException>().having(
          (e) => e.error,
          'error',
          SyncError.unavailable,
        ),
      ),
    );
  });

  test('a garbled reply is unknown, not a crash', () async {
    final service = _service((_) async => http.Response('<html>', 200));
    await expectLater(
      service.exchange('tok', _request),
      throwsA(
        isA<SyncException>().having((e) => e.error, 'error', SyncError.unknown),
      ),
    );
  });
}
