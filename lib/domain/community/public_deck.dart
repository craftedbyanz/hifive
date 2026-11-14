/// A deck its owner made public (Community, step 2), as Explore lists it:
/// enough to choose it; its words load when it is opened by [code].
class PublicDeck {
  final String code, title, description, author;
  final int icon, wordCount, adds;
  const PublicDeck({
    required this.code,
    required this.title,
    this.description = '',
    this.author = '',
    this.icon = 0,
    required this.wordCount,
    this.adds = 0,
  });

  factory PublicDeck.fromJson(Map<String, dynamic> j) => PublicDeck(
    code: j['code'] as String,
    title: j['title'] as String,
    description: j['description'] as String? ?? '',
    author: j['author'] as String? ?? '',
    icon: j['icon'] as int? ?? 0,
    wordCount: j['wordCount'] as int? ?? 0,
    adds: j['adds'] as int? ?? 0,
  );
}

/// One page of Explore; [next] is the offset of the page after, if any.
class ExplorePage {
  final List<PublicDeck> decks;
  final int? next;
  const ExplorePage(this.decks, this.next);
}

enum ExploreSort {
  /// Most added first.
  popular,

  /// Newest first.
  newest,
}

/// Why a learner reports a public deck. The names are sent to the server.
enum ReportReason { offensive, spam, wrong, copyright, other }
