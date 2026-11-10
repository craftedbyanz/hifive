import '../domain/models/models.dart';
import '../domain/sync/sync.dart';

/// Kinds that only [AppState] uses. Shared kinds are in [RecordKind].
abstract final class AppKinds {
  /// When this device was first used; the app shows the earliest of all.
  static const firstUse = 'firstUse';
}

/// Settings stored as `setting` records, one per name. String settings keep
/// their value; [boolSettings] are booleans; `modeOrder` is a list of
/// [StudyMode] indexes; `language` is a [Language] code; `goals` is a list
/// of [learningGoals] ids.
const stringSettings = {
  'name',
  'level',
  'appearance',
  'inputColor',
  'voice',
  'difficulty',
  'chatTone',
};
const boolSettings = {'chatFree', 'showHints', 'chatTipSeen', 'onboarded'};

/// Learning goals offered during onboarding, stored by id in the `goals`
/// setting. Only append; an id never changes meaning.
const learningGoals = [
  'daily',
  'travel',
  'work',
  'exam',
  'study',
  'writing',
  'media',
  'family',
];

/// What [restore] reads back from the records.
class RestoredState {
  /// Only settings the learner changed, already type-checked.
  final Map<String, Object> settings;
  final Language? language;
  final List<StudyMode>? modeOrder;
  final bool? sound, haptic;
  final Map<String, dynamic>? gameResume;
  final List<Deck> decks;
  final List<StudySession> history;
  final int gamesPlayed, totalXp, bestScore;
  final DateTime? firstUse;

  /// Whether this device already stored its first-use time.
  final bool hasOwnFirstUse;
  final Hlc latest;
  const RestoredState({
    required this.settings,
    required this.language,
    required this.modeOrder,
    required this.sound,
    required this.haptic,
    required this.gameResume,
    required this.decks,
    required this.history,
    required this.gamesPlayed,
    required this.totalXp,
    required this.bestScore,
    required this.firstUse,
    required this.hasOwnFirstUse,
    required this.latest,
  });
}

List<StudyMode>? _modeOrder(Object? value) {
  final list = (value as List).cast<int>();
  return list.toSet().length == 3
      ? list.map((i) => StudyMode.values[i]).toList()
      : null;
}

/// A copy of [deck] whose words have fresh schedules, so replaying reviews
/// never changes the built-in content.
Deck _copyDeck(Deck deck, List<FlashWord> extra) => Deck(
  id: deck.id,
  title: deck.title,
  description: deck.description,
  icon: deck.icon,
  words: [for (final w in deck.words) _copyWord(w), ...extra],
);

FlashWord _copyWord(FlashWord w) => FlashWord(
  id: w.id,
  word: w.word,
  meaning: w.meaning,
  phonetic: w.phonetic,
  example: w.example,
  partOfSpeech: w.partOfSpeech,
  definition: w.definition,
);

Map<String, dynamic> wordData(FlashWord w, String deckId, DateTime createdAt) =>
    {
      'deckId': deckId,
      'word': w.word,
      'meaning': w.meaning,
      'phonetic': w.phonetic,
      'example': w.example,
      'partOfSpeech': w.partOfSpeech,
      'definition': w.definition,
      'createdAt': createdAt.toIso8601String(),
    };

Map<String, dynamic> deckData(Deck d, DateTime createdAt) => {
  'title': d.title,
  'description': d.description,
  'icon': d.icon,
  'createdAt': createdAt.toIso8601String(),
};

Map<String, dynamic> sessionData(StudySession s) => s.toJson()..remove('id');

/// Sorts by [key] descending, keeping the original order for ties.
List<T> _newestFirst<T>(List<T> items, DateTime Function(T) key) {
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  indexed.sort((a, b) {
    final t = key(b.$2).compareTo(key(a.$2));
    return t != 0 ? t : a.$1.compareTo(b.$1);
  });
  return [for (final (_, item) in indexed) item];
}

/// Rebuilds the app's data from [records]. Built-in decks come from
/// [builtIn] with the learner's added words and replayed reviews; [examples]
/// join the history unless "Xoá lịch sử" came after them. Throws on
/// mistyped data, so the caller can keep its defaults.
RestoredState restore(
  List<SyncRecord> records, {
  required List<Deck> builtIn,
  required List<StudySession> examples,
  required String deviceId,
}) {
  final settings = <String, Object>{};
  Language? language;
  List<StudyMode>? modeOrder;
  bool? sound, haptic;
  Map<String, dynamic>? gameResume;
  final userDecks = <(DateTime, Deck)>[];
  final words = <String, List<(DateTime, FlashWord)>>{};
  final reviews = <ReviewEvent>[];
  final sessions = <(Hlc, StudySession)>[];
  DateTime? clearedAt, firstUse;
  var hasOwnFirstUse = false;
  var played = 0, xp = 0, best = 0;
  var latest = Hlc.zero;

  for (final r in records) {
    if (r.hlc > latest) latest = r.hlc;
    final d = r.data;
    if (d == null) continue;
    switch (r.kind) {
      case RecordKind.setting:
        final v = d['v'];
        if (stringSettings.contains(r.id)) {
          settings[r.id] = v as String;
        } else if (boolSettings.contains(r.id)) {
          settings[r.id] = v as bool;
        } else if (r.id == 'language') {
          language = Language.fromCode(v as String);
        } else if (r.id == 'modeOrder') {
          modeOrder = _modeOrder(v);
        } else if (r.id == 'goals') {
          settings['goals'] = [
            for (final g in (v as List).cast<String>())
              if (learningGoals.contains(g)) g,
          ];
        }
      case RecordKind.device:
        final v = d['v'];
        switch (r.id) {
          case 'sound':
            sound = v as bool;
          case 'haptic':
            haptic = v as bool;
          case 'gameResume':
            gameResume = v == null ? null : Map<String, dynamic>.from(v as Map);
        }
      case RecordKind.session:
        sessions.add((r.hlc, StudySession.fromJson({...d, 'id': r.id})));
      case RecordKind.historyCleared:
        clearedAt = DateTime.parse(d['at'] as String);
      case RecordKind.deck:
        userDecks.add((
          DateTime.parse(d['createdAt'] as String),
          Deck(
            id: r.id,
            title: d['title'] as String,
            description: d['description'] as String,
            icon: d['icon'] as int? ?? 0,
            words: [],
          ),
        ));
      case RecordKind.word:
        (words[d['deckId'] as String] ??= []).add((
          DateTime.parse(d['createdAt'] as String),
          FlashWord(
            id: r.id,
            word: d['word'] as String,
            meaning: d['meaning'] as String,
            phonetic: d['phonetic'] as String? ?? '',
            example: d['example'] as String? ?? '',
            partOfSpeech: d['partOfSpeech'] as String? ?? 'NOUN',
            definition: d['definition'] as String? ?? '',
          ),
        ));
      case RecordKind.review:
        reviews.add(ReviewEvent.fromJson(r.id, d, stamp: r.hlc));
      case RecordKind.game:
        final score = d['score'] as int;
        played++;
        xp += score;
        if (score > best) best = score;
      case RecordKind.legacyStats:
        played += d['gamesPlayed'] as int? ?? 0;
        xp += d['totalXp'] as int? ?? 0;
        final b = d['bestScore'] as int? ?? 0;
        if (b > best) best = b;
      case AppKinds.firstUse:
        final at = DateTime.parse(d['at'] as String);
        if (firstUse == null || at.isBefore(firstUse)) firstUse = at;
        if (r.id == deviceId) hasOwnFirstUse = true;
    }
  }

  List<FlashWord> added(String deckId) {
    final list = words[deckId] ?? const [];
    final sorted = [...list]..sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, w) in sorted) w];
  }

  userDecks.sort((a, b) => a.$1.compareTo(b.$1));
  final decks = [
    for (final deck in builtIn) _copyDeck(deck, added(deck.id)),
    for (final (_, deck) in userDecks) deck..words.addAll(added(deck.id)),
  ];
  replayReviews(decks.expand((d) => d.words), reviews);

  // Results finished at the same moment show the last one saved first.
  sessions.sort((a, b) => b.$1.compareTo(a.$1));
  final ids = {for (final (_, s) in sessions) s.id};
  final history = _newestFirst(
    [
      for (final (_, s) in sessions) s,
      for (final s in examples)
        if (!ids.contains(s.id)) s,
    ],
    (s) => s.date,
  ).where((s) => clearedAt == null || !s.date.isBefore(clearedAt)).toList();

  return RestoredState(
    settings: settings,
    language: language,
    modeOrder: modeOrder,
    sound: sound,
    haptic: haptic,
    gameResume: gameResume,
    decks: decks,
    history: history,
    gamesPlayed: played,
    totalXp: xp,
    bestScore: best,
    firstUse: firstUse,
    hasOwnFirstUse: hasOwnFirstUse,
    latest: latest,
  );
}

/// Converts the JSON blob saved before records into records, checking every
/// field first so a bad blob throws before anything is written. Built-in
/// decks keep their ids; their schedules become snapshot reviews.
List<SyncRecord> importLegacy(
  Map<String, dynamic> j, {
  required List<Deck> builtIn,
  required String deviceId,
  required Hlc Function() stamp,
  required DateTime now,
}) {
  final out = <SyncRecord>[];
  void put(String kind, String id, Map<String, dynamic> data) =>
      out.add(SyncRecord(kind, id, data, stamp()));

  for (final key in stringSettings) {
    final v = j[key] as String?;
    // "System" was saved before voices were selectable.
    if (v != null && !(key == 'voice' && v == 'System')) {
      put(RecordKind.setting, key, {'v': v});
    }
  }
  for (final key in boolSettings) {
    final v = j[key] as bool?;
    if (v != null && (key != 'chatTipSeen' || v)) {
      put(RecordKind.setting, key, {'v': v});
    }
  }
  final language = Language.fromCode(j['language'] as String?);
  if (language != null) {
    put(RecordKind.setting, 'language', {'v': language.code});
  }
  if (j['modeOrder'] != null && _modeOrder(j['modeOrder']) != null) {
    put(RecordKind.setting, 'modeOrder', {'v': j['modeOrder']});
  }
  for (final key in ['sound', 'haptic']) {
    final v = j[key] as bool?;
    if (v != null) put(RecordKind.device, key, {'v': v});
  }
  if (j['gameResume'] != null) {
    put(RecordKind.device, 'gameResume', {
      'v': Map<String, dynamic>.from(j['gameResume'] as Map),
    });
  }
  if (j['firstUse'] != null) {
    put(AppKinds.firstUse, deviceId, {
      'at': DateTime.parse(j['firstUse'] as String).toIso8601String(),
    });
  }
  for (final h in j['history'] as List? ?? const []) {
    final s = StudySession.fromJson(Map<String, dynamic>.from(h as Map));
    put(RecordKind.session, s.id, sessionData(s));
  }
  final played = j['gamesPlayed'] as int? ?? 0,
      xp = j['totalXp'] as int? ?? 0,
      best = j['bestScore'] as int? ?? 0;
  if (played != 0 || xp != 0 || best != 0) {
    put(RecordKind.legacyStats, deviceId, {
      'gamesPlayed': played,
      'totalXp': xp,
      'bestScore': best,
    });
  }

  final builtInWords = {
    for (final d in builtIn)
      for (final w in d.words) w.id,
  };
  final builtInDecks = {for (final d in builtIn) d.id};
  var order = 0;
  // Spaced a millisecond apart so decks and cards keep their saved order.
  DateTime next() => now.add(Duration(milliseconds: order++));
  for (final raw in j['decks'] as List? ?? const []) {
    final deck = Deck.fromJson(Map<String, dynamic>.from(raw as Map));
    if (!builtInDecks.contains(deck.id)) {
      put(RecordKind.deck, deck.id, deckData(deck, next()));
    }
    for (final w in deck.words) {
      // Saved words take their word-based id, so devices share them.
      final id = deck.id == 'saved' ? savedWordId(w.word) : w.id;
      if (!builtInWords.contains(w.id)) {
        put(RecordKind.word, id, wordData(w, deck.id, next()));
      }
      if (w.status != 'new' || w.due != null || w.intervalDays != 0) {
        final review = ReviewEvent(
          id: '$id:legacy',
          wordId: id,
          at: now,
          rating: ReviewEvent.snapshot,
          status: w.status,
          due: w.due,
          intervalDays: w.intervalDays,
        );
        put(RecordKind.review, review.id, review.toJson());
      }
    }
  }
  return out;
}
