/// The JSON blob the app saved before records (`hifive.local.v1`). It is only
/// read once, to import it into the [RecordStore]; nothing writes it any more.
abstract interface class AppRepository {
  Future<Map<String, dynamic>?> load();
}
