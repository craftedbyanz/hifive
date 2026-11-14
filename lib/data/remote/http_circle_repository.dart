import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/community/community.dart';
import '../../domain/repositories/repositories.dart';

/// [CircleRepository] over HTTPS to the Worker at [baseUrl].
class HttpCircleRepository implements CircleRepository {
  final Uri baseUrl;
  final http.Client _client;
  final Duration timeout;
  HttpCircleRepository(
    this.baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _call(
    String method,
    String path,
    String idToken, [
    Object? body,
  ]) async {
    final request = http.Request(method, baseUrl.resolve(path))
      ..headers['authorization'] = 'Bearer $idToken'
      ..headers['content-type'] = 'application/json';
    if (body != null) request.body = jsonEncode(body);
    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      );
    } on TimeoutException {
      throw const ShareException(ShareError.unavailable);
    } on SocketException {
      throw const ShareException(ShareError.unavailable);
    } on http.ClientException {
      throw const ShareException(ShareError.unavailable);
    }
    return switch (res.statusCode) {
      200 => Map<String, dynamic>.from(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map,
      ),
      404 => throw const ShareException(ShareError.notFound),
      401 => throw const ShareException(ShareError.unauthorized),
      429 => throw const ShareException(ShareError.tooMany),
      400 || 413 => throw const ShareException(ShareError.rejected),
      _ => throw const ShareException(ShareError.unavailable),
    };
  }

  @override
  Future<List<Circle>> mine(String idToken) async {
    final j = await _call('GET', '/v1/circles', idToken);
    return [
      for (final c in (j['circles'] as List).cast<Map<String, dynamic>>())
        Circle.fromJson(c),
    ];
  }

  @override
  Future<Circle> create(
    String idToken, {
    required CircleKind kind,
    required String name,
    int goal = 3,
  }) async => Circle.fromJson(
    (await _call('POST', '/v1/circles', idToken, {
          'kind': kind.wire,
          'name': name,
          'goal': goal,
        }))['circle']
        as Map<String, dynamic>,
  );

  @override
  Future<Circle> join(String idToken, String code) async => Circle.fromJson(
    (await _call('POST', '/v1/circles/join', idToken, {'code': code}))['circle']
        as Map<String, dynamic>,
  );

  @override
  Future<CircleDetail> detail(String idToken, String id, String monday) async =>
      CircleDetail.fromJson(
        await _call('GET', '/v1/circles/$id?from=$monday', idToken),
      );

  @override
  Future<void> update(
    String idToken,
    String id, {
    required String name,
    required int goal,
  }) => _call('PUT', '/v1/circles/$id', idToken, {'name': name, 'goal': goal});

  @override
  Future<void> leave(String idToken, String id) =>
      _call('DELETE', '/v1/circles/$id/members/me', idToken);

  @override
  Future<void> remove(String idToken, String id, String member) =>
      _call('DELETE', '/v1/circles/$id/members/$member', idToken);

  @override
  Future<void> assign(
    String idToken,
    String id,
    String shareCode,
    String due,
  ) => _call('POST', '/v1/circles/$id/assignments', idToken, {
    'shareCode': shareCode,
    'due': due,
  });

  @override
  Future<void> unassign(String idToken, String id, String assignment) =>
      _call('DELETE', '/v1/circles/$id/assignments/$assignment', idToken);
}
