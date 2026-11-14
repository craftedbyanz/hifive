import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/community/community.dart';
import '../../domain/repositories/share_repository.dart';

/// [ShareRepository] over HTTPS to the Worker at [baseUrl].
class HttpShareRepository implements ShareRepository {
  final Uri baseUrl;
  final http.Client _client;
  final Duration timeout;
  HttpShareRepository(
    this.baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  @override
  Uri linkFor(String code) => baseUrl.resolve('/s/$code');

  Future<http.Response> _send(Future<http.Response> request) async {
    final http.Response res;
    try {
      res = await request.timeout(timeout);
    } on TimeoutException {
      throw const ShareException(ShareError.unavailable);
    } on SocketException {
      throw const ShareException(ShareError.unavailable);
    } on http.ClientException {
      throw const ShareException(ShareError.unavailable);
    }
    return switch (res.statusCode) {
      200 => res,
      404 => throw const ShareException(ShareError.notFound),
      401 => throw const ShareException(ShareError.unauthorized),
      429 => throw const ShareException(ShareError.tooMany),
      400 || 413 => throw const ShareException(ShareError.rejected),
      _ => throw const ShareException(ShareError.unavailable),
    };
  }

  Map<String, dynamic> _json(http.Response res) =>
      Map<String, dynamic>.from(jsonDecode(utf8.decode(res.bodyBytes)) as Map);

  @override
  Future<String> publish(
    String idToken,
    String deckId,
    SharedDeck deck, {
    bool public = false,
    String author = '',
  }) async {
    final res = await _send(
      _client.post(
        baseUrl.resolve('/v1/shares'),
        headers: {
          'authorization': 'Bearer $idToken',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'deckId': deckId,
          ...deck.toJson(),
          'public': public,
          'author': author,
        }),
      ),
    );
    return _json(res)['code'] as String;
  }

  @override
  Future<SharedDeck> open(String code) async => SharedDeck.fromJson(
    _json(await _send(_client.get(baseUrl.resolve('/v1/shares/$code')))),
  );

  @override
  Future<void> unpublish(String idToken, String code) async {
    await _send(
      _client.delete(
        baseUrl.resolve('/v1/shares/$code'),
        headers: {'authorization': 'Bearer $idToken'},
      ),
    );
  }

  Map<String, String> _auth(String idToken) => {
    'authorization': 'Bearer $idToken',
    'content-type': 'application/json',
  };

  @override
  Future<ExplorePage> explore({
    required String language,
    ExploreSort sort = ExploreSort.popular,
    String query = '',
    int offset = 0,
    String? idToken,
  }) async {
    final url = baseUrl
        .resolve('/v1/explore')
        .replace(
          queryParameters: {
            'lang': language,
            'sort': sort == ExploreSort.newest ? 'new' : 'popular',
            if (query.isNotEmpty) 'q': query,
            if (offset > 0) 'offset': '$offset',
          },
        );
    final j = _json(
      await _send(
        _client.get(
          url,
          headers: idToken == null
              ? null
              : {'authorization': 'Bearer $idToken'},
        ),
      ),
    );
    return ExplorePage([
      for (final d in (j['decks'] as List).cast<Map<String, dynamic>>())
        PublicDeck.fromJson(d),
    ], j['next'] as int?);
  }

  @override
  Future<int> countAdd(String idToken, String code) async =>
      _json(
            await _send(
              _client.post(
                baseUrl.resolve('/v1/shares/$code/adds'),
                headers: _auth(idToken),
              ),
            ),
          )['adds']
          as int;

  @override
  Future<void> report(String idToken, String code, ReportReason reason) async {
    await _send(
      _client.post(
        baseUrl.resolve('/v1/shares/$code/reports'),
        headers: _auth(idToken),
        body: jsonEncode({'reason': reason.name}),
      ),
    );
  }

  @override
  Future<void> blockOwner(String idToken, String code) async {
    await _send(
      _client.post(
        baseUrl.resolve('/v1/shares/$code/block'),
        headers: _auth(idToken),
      ),
    );
  }

  @override
  Future<void> unblockAll(String idToken) async {
    await _send(
      _client.delete(baseUrl.resolve('/v1/blocks'), headers: _auth(idToken)),
    );
  }
}
