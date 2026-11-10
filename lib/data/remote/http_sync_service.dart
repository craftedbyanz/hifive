import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/repositories/sync_service.dart';

/// [SyncService] over HTTPS to the Worker at [baseUrl].
class HttpSyncService implements SyncService {
  final Uri baseUrl;
  final http.Client _client;
  final Duration timeout;
  HttpSyncService(
    this.baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  @override
  Future<SyncResponse> exchange(String idToken, SyncRequest request) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            baseUrl.resolve('/v1/sync'),
            headers: {
              'authorization': 'Bearer $idToken',
              'content-type': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const SyncException(SyncError.unavailable, 'timeout');
    } on SocketException catch (e) {
      throw SyncException(SyncError.unavailable, e.message);
    } on http.ClientException catch (e) {
      throw SyncException(SyncError.unavailable, e.message);
    }
    switch (res.statusCode) {
      case 200:
        try {
          return SyncResponse.fromJson(
            Map<String, dynamic>.from(jsonDecode(res.body) as Map),
          );
        } catch (e) {
          throw SyncException(SyncError.unknown, 'bad response: $e');
        }
      case 401:
        throw const SyncException(SyncError.unauthorized);
      case 400 || 413:
        throw SyncException(SyncError.rejected, res.body);
      case 429 || >= 500:
        throw SyncException(SyncError.unavailable, '${res.statusCode}');
      default:
        throw SyncException(SyncError.unknown, '${res.statusCode}');
    }
  }
}
