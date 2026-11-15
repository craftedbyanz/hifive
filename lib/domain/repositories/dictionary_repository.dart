import '../dictionary/entry.dart';

/// An inflection link: the typed form is the [label] form of [lemma] as
/// [partOfSpeech] (*went* → *go*, `past`, `VERB`).
class DictForm {
  final String lemma, label, partOfSpeech;
  const DictForm(this.lemma, this.label, this.partOfSpeech);
}

/// A dictionary pack the server offers (`/v1/catalog/manifest`).
class DictionaryPackInfo {
  /// Studied language and explanation language, as `en-vi`.
  final String pair;
  final int version;

  /// The pack's path under `/v1/catalog/`.
  final String path;
  final int bytes;

  /// Hex SHA-256 of the gzipped file.
  final String sha256;
  const DictionaryPackInfo({
    required this.pair,
    required this.version,
    required this.path,
    required this.bytes,
    required this.sha256,
  });
}

/// A searchable word list: the installed pack, or hifive's own decks. Keys
/// are lower-case with spaces for hyphens (`dictKey`).
abstract interface class DictionaryIndex {
  /// Entries whose key is [key].
  Future<List<DictEntry>> entries(String key);

  /// What [key] is an inflection of.
  Future<List<DictForm>> forms(String key);

  /// Keys [key] is another spelling of.
  Future<List<String>> variants(String key);

  /// Entries whose key starts with [key], most frequent first.
  Future<List<DictEntry>> startingWith(String key, {int limit = 8});

  /// Keys of common words that start with [first] and have a length in
  /// [minLength]..[maxLength], with their frequency rank: spelling
  /// correction candidates.
  Future<List<(String, int?)>> commonKeys(
    String first, {
    required int minLength,
    required int maxLength,
  });

  /// Entries whose Vietnamese meaning contains [text], diacritics optional.
  Future<List<DictEntry>> withMeaning(String text, {int limit = 60});

  /// Frequent entries at CEFR [level].
  Future<List<DictEntry>> atLevel(String level, {int limit = 60});

  /// Releases the index; it is not used afterwards.
  void close();
}

/// Where dictionary packs come from: the Worker.
abstract interface class DictionaryPacks {
  /// The newest pack for [pair], or null when the server has none.
  Future<DictionaryPackInfo?> latest(String pair);

  /// The gzipped pack.
  Future<List<int>> download(DictionaryPackInfo pack);
}

/// The installed packs on the device.
abstract interface class DictionaryStore {
  /// The installed version of [pair], or null.
  Future<int?> version(String pair);

  /// The installed pack for [pair], or null when none is installed or it
  /// cannot be read.
  Future<DictionaryIndex?> open(String pair);

  /// Checks [bytes] against [pack] and installs them in place of the
  /// current pack. Throws, and keeps the current pack, when they don't match.
  Future<void> install(DictionaryPackInfo pack, List<int> bytes);
}
