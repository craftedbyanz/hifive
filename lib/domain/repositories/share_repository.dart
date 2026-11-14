import '../community/community.dart';

/// Why sharing failed.
enum ShareError {
  /// No deck is shared under that code.
  notFound,

  /// The server couldn't be reached.
  unavailable,

  /// The account isn't signed in, or its token was refused.
  unauthorized,

  /// The account shares as many decks as it may.
  tooMany,

  /// The server refused the deck, as too large or malformed.
  rejected,
}

class ShareException implements Exception {
  final ShareError error;
  const ShareException(this.error);

  @override
  String toString() => 'ShareException($error)';
}

/// Decks shared by link or code, on the server (`/v1/shares`). Failures
/// throw [ShareException].
abstract interface class ShareRepository {
  /// The link that opens [code]'s page.
  Uri linkFor(String code);

  /// Publishes [deck] as the learner's deck [deckId] and returns its code;
  /// the same deck keeps its code and gets the new snapshot. A [public] deck
  /// is listed in Explore under [author].
  Future<String> publish(
    String idToken,
    String deckId,
    SharedDeck deck, {
    bool public = false,
    String author = '',
  });

  /// The deck shared under [code].
  Future<SharedDeck> open(String code);

  /// Stops sharing [code].
  Future<void> unpublish(String idToken, String code);

  /// A page of public decks in [language]. With an [idToken], decks the
  /// learner reported or whose owners they blocked are left out.
  Future<ExplorePage> explore({
    required String language,
    ExploreSort sort = ExploreSort.popular,
    String query = '',
    int offset = 0,
    String? idToken,
  });

  /// Counts the learner adding [code]; returns its adds.
  Future<int> countAdd(String idToken, String code);

  /// Reports [code]; enough reports hide it from everyone.
  Future<void> report(String idToken, String code, ReportReason reason);

  /// Blocks the owner of [code]: none of their decks show to the learner.
  Future<void> blockOwner(String idToken, String code);

  /// Unblocks everyone the learner blocked.
  Future<void> unblockAll(String idToken);
}
