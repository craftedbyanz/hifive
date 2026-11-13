import 'dart:convert';

import '../models/deck.dart';

/// A listening source hifive recommends: a YouTube playlist, played inside
/// the app with YouTube's own player. Subtitles come later.
class ListeningSource {
  final String id, title, channel, level, description, playlistId, coverVideoId;
  const ListeningSource({
    required this.id,
    required this.title,
    required this.channel,
    required this.level,
    required this.description,
    required this.playlistId,
    required this.coverVideoId,
  });

  /// YouTube's public thumbnail of the first video.
  String get cover => 'https://i.ytimg.com/vi/$coverVideoId/hqdefault.jpg';

  factory ListeningSource.fromJson(Map<String, dynamic> j) => ListeningSource(
    id: j['id'] as String,
    title: j['title'] as String,
    channel: j['channel'] as String? ?? '',
    level: j['level'] as String? ?? '',
    description: j['description'] as String? ?? '',
    playlistId: j['playlistId'] as String,
    coverVideoId: j['coverVideoId'] as String,
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
