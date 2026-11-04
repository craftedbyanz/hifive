abstract interface class AppRepository {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> data);
}
