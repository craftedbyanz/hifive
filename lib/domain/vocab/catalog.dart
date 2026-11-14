import 'dart:convert';

import '../models/deck.dart';

/// One video of a listening source, in the playlist's order.
class Episode {
  /// The YouTube video id.
  final String id;

  /// The topic, as hifive names it.
  final String title;
  final int seconds;
  const Episode({required this.id, required this.title, required this.seconds});

  /// YouTube's public thumbnail, 320 × 180.
  String get thumbnail => 'https://i.ytimg.com/vi/$id/mqdefault.jpg';

  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
    id: j['id'] as String,
    title: j['title'] as String,
    seconds: j['seconds'] as int? ?? 0,
  );
}

/// A listening source hifive recommends: a YouTube playlist, played inside
/// the app with YouTube's own player. Packs from version 3 list its
/// [episodes]; without them the whole playlist plays in one player.
/// Subtitles come later.
class ListeningSource {
  final String id, title, channel, level, description, playlistId, coverVideoId;
  final List<Episode> episodes;
  const ListeningSource({
    required this.id,
    required this.title,
    required this.channel,
    required this.level,
    required this.description,
    required this.playlistId,
    required this.coverVideoId,
    this.episodes = const [],
  });

  /// YouTube's public thumbnail of the first video.
  String get cover => 'https://i.ytimg.com/vi/$coverVideoId/hqdefault.jpg';

  /// The length of every episode together.
  int get seconds => episodes.fold(0, (sum, e) => sum + e.seconds);

  factory ListeningSource.fromJson(Map<String, dynamic> j) => ListeningSource(
    id: j['id'] as String,
    title: j['title'] as String,
    channel: j['channel'] as String? ?? '',
    level: j['level'] as String? ?? '',
    description: j['description'] as String? ?? '',
    playlistId: j['playlistId'] as String,
    coverVideoId: j['coverVideoId'] as String,
    episodes: [
      for (final e
          in (j['episodes'] as List? ?? const []).cast<Map<String, dynamic>>())
        Episode.fromJson(e),
    ],
  );
}

/// The listening sources of a catalog pack; none in packs before version 2.
List<ListeningSource> parseListening(String text) {
  final pack = jsonDecode(text) as Map<String, dynamic>;
  return [
    for (final s
        in (pack['listening'] as List? ?? const [])
            .cast<Map<String, dynamic>>())
      ListeningSource.fromJson(s),
  ];
}

/// The decks of a catalog pack (`worker/catalog/<lang>/<version>.json`).
/// Their ids are fixed, so reviews of catalog words survive a new version.
List<Deck> parseCatalog(String text) {
  final pack = jsonDecode(text) as Map<String, dynamic>;
  return [
    for (final d in (pack['decks'] as List).cast<Map<String, dynamic>>())
      Deck(
        id: d['id'] as String,
        title: d['title'] as String,
        description: d['description'] as String? ?? '',
        icon: d['icon'] as int? ?? 0,
        words: [
          for (final w in (d['words'] as List).cast<Map<String, dynamic>>())
            FlashWord(
              id: w['id'] as String,
              word: w['word'] as String,
              meaning: w['meaning'] as String,
              phonetic: w['phonetic'] as String? ?? '',
              example: w['example'] as String? ?? '',
              partOfSpeech: w['partOfSpeech'] as String? ?? 'NOUN',
              definition: w['definition'] as String? ?? '',
            ),
        ],
      ),
  ];
}
