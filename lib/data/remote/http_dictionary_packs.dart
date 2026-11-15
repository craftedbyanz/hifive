import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/repositories/dictionary_repository.dart';

/// [DictionaryPacks] from the Worker at [baseUrl]: the manifest's
/// `dictionaries` names each pack, served under `/v1/catalog/`. Public, no
/// sign-in.
class HttpDictionaryPacks implements DictionaryPacks {
  final Uri baseUrl;
  final http.Client _client;
  HttpDictionaryPacks(this.baseUrl, {http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<DictionaryPackInfo?> latest(String pair) async {
    final res = await _client
        .get(baseUrl.resolve('/v1/catalog/manifest'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw http.ClientException('${res.statusCode}');
    final manifest =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final pack =
        (manifest['dictionaries'] as Map<String, dynamic>?)?[pair]
            as Map<String, dynamic>?;
    if (pack == null) return null;
    return DictionaryPackInfo(
      pair: pair,
      version: pack['version'] as int,
      path: pack['path'] as String,
      bytes: pack['bytes'] as int,
      sha256: pack['sha256'] as String,
    );
  }

  @override
  Future<List<int>> download(DictionaryPackInfo pack) async {
    final res = await _client
        .get(baseUrl.resolve('/v1/catalog/${pack.path}'))
        .timeout(const Duration(minutes: 3));
    if (res.statusCode != 200) throw http.ClientException('${res.statusCode}');
    return res.bodyBytes;
  }
}
