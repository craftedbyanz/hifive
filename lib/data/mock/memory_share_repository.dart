import '../../domain/community/community.dart';
import '../../domain/repositories/share_repository.dart';

/// [ShareRepository] in memory, for tests and offline builds, following the
/// server's rules: a deck keeps its code, public decks are listed by adds,
/// three reports hide a deck, and a viewer doesn't see decks they reported
/// or whose owner they blocked. An ID token stands for its account. Codes
/// run AAAAA2, AAAAA3 and so on; [failWith] makes every call fail.
class MemoryShareRepository implements ShareRepository {
  final decks = <String, SharedDeck>{};
  final _owners = <String, (String, String)>{};
  final public = <String, String>{};
  final adds = <String, Set<String>>{};
  final reports = <String, Map<String, ReportReason>>{};
  final blocks = <String, Set<String>>{};
  final _order = <String>[];
  ShareError? failWith;
  var _next = 0;

  @override
  Uri linkFor(String code) => Uri.parse('https://hifive.test/s/$code');

  void _check() {
    if (failWith case final e?) throw ShareException(e);
  }

  @override
  Future<String> publish(
    String idToken,
    String deckId,
    SharedDeck deck, {
    bool public = false,
    String author = '',
  }) async {
    _check();
    final code =
        _owners.entries
            .where((e) => e.value == (idToken, deckId))
            .map((e) => e.key)
            .firstOrNull ??
        'AAAAA${'23456789'[_next++ % 8]}';
    _owners[code] = (idToken, deckId);
    decks[code] = SharedDeck.fromJson({'code': code, ...deck.toJson()});
    if (public) {
      this.public[code] = author;
      if (!_order.contains(code)) _order.add(code);
    } else {
      this.public.remove(code);
      _order.remove(code);
    }
    return code;
  }

  @override
  Future<SharedDeck> open(String code) async {
    _check();
    return decks[code] ?? (throw const ShareException(ShareError.notFound));
  }

  @override
  Future<void> unpublish(String idToken, String code) async {
    _check();
    if (_owners[code]?.$1 != idToken) {
      throw const ShareException(ShareError.notFound);
    }
    _owners.remove(code);
    decks.remove(code);
    public.remove(code);
    _order.remove(code);
  }

  @override
  Future<ExplorePage> explore({
    required String language,
    ExploreSort sort = ExploreSort.popular,
    String query = '',
    int offset = 0,
    String? idToken,
  }) async {
    _check();
    final q = query.toLowerCase();
    final shown = [
      for (final code in _order.reversed)
        if (decks[code] case final d?)
          if (d.language == language &&
              (reports[code]?.length ?? 0) < 3 &&
              (q.isEmpty || d.title.toLowerCase().contains(q)) &&
              (idToken == null ||
                  (!(reports[code]?.containsKey(idToken) ?? false) &&
                      !(blocks[idToken]?.contains(_owners[code]!.$1) ??
                          false))))
            PublicDeck(
              code: code,
              title: d.title,
              description: d.description,
              author: public[code] ?? '',
              icon: d.icon,
              wordCount: d.words.length,
              adds: adds[code]?.length ?? 0,
            ),
    ];
    if (sort == ExploreSort.popular) {
      // Stable: equal adds keep newest first.
      final ranked = [...shown.indexed]
        ..sort((a, b) {
          final c = b.$2.adds.compareTo(a.$2.adds);
          return c != 0 ? c : a.$1.compareTo(b.$1);
        });
      shown
        ..clear()
        ..addAll(ranked.map((e) => e.$2));
    }
    final page = shown.skip(offset).take(20).toList();
    return ExplorePage(
      page,
      shown.length > offset + 20 ? offset + page.length : null,
    );
  }

  @override
  Future<int> countAdd(String idToken, String code) async {
    _check();
    if (!decks.containsKey(code)) {
      throw const ShareException(ShareError.notFound);
    }
    if (_owners[code]?.$1 != idToken) (adds[code] ??= {}).add(idToken);
    return adds[code]?.length ?? 0;
  }

  @override
  Future<void> report(String idToken, String code, ReportReason reason) async {
    _check();
    if (!decks.containsKey(code)) {
      throw const ShareException(ShareError.notFound);
    }
    (reports[code] ??= {})[idToken] = reason;
  }

  @override
  Future<void> blockOwner(String idToken, String code) async {
    _check();
    final owner = _owners[code]?.$1;
    if (owner == null) throw const ShareException(ShareError.notFound);
    if (owner != idToken) (blocks[idToken] ??= {}).add(owner);
  }

  @override
  Future<void> unblockAll(String idToken) async {
    _check();
    blocks.remove(idToken);
  }
}
