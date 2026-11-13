import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/repositories/catalog_repository.dart';

/// [CatalogRepository] over HTTPS to the Worker at [baseUrl]. No sign-in:
/// the catalog is public.
class HttpCatalogRepository implements CatalogRepository {
  final Uri baseUrl;
  final http.Client _client;
  final Duration timeout;
  HttpCatalogRepository(
    this.baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  @override
  Future<int?> latestVersion(String language) async {
    final res = await _client
        .get(baseUrl.resolve('/v1/catalog/manifest'))
        .timeout(timeout);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw http.ClientException('${res.statusCode}');
    final manifest =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final lang = (manifest['languages'] as Map<String, dynamic>)[language];
    return lang == null
        ? null
        : (lang as Map<String, dynamic>)['version'] as int;
  }

  @override
  Future<String> pack(String language, int version) async {
    final res = await _client
        .get(baseUrl.resolve('/v1/catalog/$language/$version.json'))
        .timeout(timeout);
    if (res.statusCode != 200) throw http.ClientException('${res.statusCode}');
    return utf8.decode(res.bodyBytes);
  }
}
