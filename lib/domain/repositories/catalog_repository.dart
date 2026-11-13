/// hifive's word catalog on the server (`/v1/catalog`, served from R2).
abstract interface class CatalogRepository {
  /// The newest pack version for [language], or null when the catalog has
  /// none.
  Future<int?> latestVersion(String language);

  /// The pack's JSON text.
  Future<String> pack(String language, int version);
}
