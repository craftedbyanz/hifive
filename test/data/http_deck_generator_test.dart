import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late http.Request sent;
  HttpDeckGenerator answering(int status, Object body) => HttpDeckGenerator(
    Uri.parse('https://api.test'),
    client: MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode(body), status);
    }),
  );

  Future<List<String>> ask(HttpDeckGenerator g, {String? token = 't1'}) =>
      g.suggest(
        idToken: token,
        language: Language.english,
        topic: 'Du lịch',
        level: 'A2',
        count: 10,
      );

  test('asks the Worker with the token and reads the words', () async {
    final g = answering(200, {
      'words': ['airport', 'ticket'],
      'left': 4,
    });
    expect(await ask(g), ['airport', 'ticket']);
    expect(sent.url.path, '/v1/decks/generate');
    expect(sent.headers['authorization'], 'Bearer t1');
    expect(jsonDecode(sent.body), {
      'language': 'en',
      'topic': 'Du lịch',
      'level': 'A2',
      'count': 10,
      'exclude': <String>[],
    });
  });

  test('says why it failed', () async {
    Future<GenerateError?> error(HttpDeckGenerator g, {String? token = 't'}) =>
        ask(g, token: token).then<GenerateError?>(
          (_) => null,
          onError: (Object e) => (e as GenerateException).error,
        );
    expect(
      await error(answering(429, {'error': 'daily_limit'})),
      GenerateError.dailyLimit,
    );
    expect(await error(answering(401, {})), GenerateError.unauthorized);
    expect(await error(answering(503, {})), GenerateError.unavailable);
    expect(await error(answering(502, {})), GenerateError.unavailable);
    expect(
      await error(answering(200, {}), token: null),
      GenerateError.unauthorized,
    );
    final offline = HttpDeckGenerator(
      Uri.parse('https://api.test'),
      client: MockClient((_) => throw const SocketException('offline')),
    );
    expect(await error(offline), GenerateError.unavailable);
  });
}
