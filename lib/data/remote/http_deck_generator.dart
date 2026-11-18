import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/models/models.dart';
import '../../domain/repositories/deck_generator.dart';

/// [DeckGenerator] through the Worker's `/v1/decks/generate`, which asks a
/// Workers AI model (`worker/src/generate.ts`).
class HttpDeckGenerator implements DeckGenerator {
  final Uri baseUrl;
  final http.Client _client;
  final Duration timeout;
  HttpDeckGenerator(
    this.baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 40),
  }) : _client = client ?? http.Client();

  @override
  Future<List<String>> suggest({
    required String? idToken,
    required Language language,
    required String topic,
    required String level,
    required int count,
    List<String> exclude = const [],
  }) async {
    if (idToken == null) {
      throw const GenerateException(GenerateError.unauthorized);
    }
    final http.Response res;
    try {
      res = await _client
          .post(
            baseUrl.resolve('/v1/decks/generate'),
            headers: {
              'authorization': 'Bearer $idToken',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'language': language.code,
              'topic': topic,
              'level': level,
              'count': count,
              'exclude': exclude.take(500).toList(),
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const GenerateException(GenerateError.unavailable);
    } on SocketException {
      throw const GenerateException(GenerateError.unavailable);
    } on http.ClientException {
      throw const GenerateException(GenerateError.unavailable);
    }
    switch (res.statusCode) {
      case 200:
        final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map;
        return (body['words'] as List).cast<String>();
      case 401:
        throw const GenerateException(GenerateError.unauthorized);
      case 429:
        throw const GenerateException(GenerateError.dailyLimit);
      default:
        throw const GenerateException(GenerateError.unavailable);
    }
  }
}
