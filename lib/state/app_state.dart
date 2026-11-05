import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/services/feedback_service.dart';
import '../core/services/system_actions.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';
import '../domain/sync/sync.dart';
import 'app_records.dart';

class AppState extends ChangeNotifier {
  /// The device database, the app's source of truth.
  final RecordStore store;

  /// The JSON blob saved before records, imported once on first launch.
  final AppRepository? legacy;
  final LessonRepository lessons;
  final GradingRepository grading;
  final ConversationRepository conversation;
  final DeckGenerator deckGenerator;
  final InsightRepository insights;
  final FeedbackService feedback;
  final SystemActions system;
  final DateTime Function() now;
  final List<Deck> _builtIn;
  final List<StudySession> _examples;

  /// Wires the state to its services. `lib/app/app_state_factory.dart` picks
  /// the implementations, so this layer never imports `lib/data`. [decks]
  /// are the built-in decks; [examples] are sample results shown but never
  /// stored.
  AppState({
    required this.store,
    this.legacy,
    required this.lessons,
    required this.grading,
    required this.conversation,
    required this.deckGenerator,
    required this.insights,
    required List<Deck> decks,
    List<StudySession> examples = const [],
    FeedbackService? feedback,
    SystemActions? system,
    DateTime Function()? now,
  }) : _builtIn = decks,
       _examples = examples,
       decks = decks,
       history = [...examples],
       feedback = feedback ?? PlatformFeedback(),
       system = system ?? const PlatformSystemActions(),
       now = now ?? DateTime.now {
    _clock = HlcClock(node: _deviceId, now: this.now);
  }
  // Glass, the look every Home measurement was made with; the reference's
  // default for a new account was not seen.
  String name = 'An',
      level = 'A1',
      appearance = 'Glass',
      inputColor = 'Default',
      voice = 'Aaron',
      difficulty = 'Dễ',
      chatTone = 'Thoải mái';
  bool showHints = false, chatFree = true, sound = true, haptic = true;

  /// The language being studied. Only languages whose course has content
  /// can be chosen; English is the default for data saved before courses.
  Language language = Language.english;

  /// The conversation settings tip showed on the first visit (1 November)
  /// and not on a later one, so it stays dismissed once closed.
  bool chatTipSeen = false;
  int bestScore = 0, gamesPlayed = 0, totalXp = 0;
  List<StudyMode> modeOrder = [
    StudyMode.writing,
    StudyMode.grammar,
    StudyMode.conversation,
  ];
  List<Deck> decks;
  List<StudySession> history;
  late DateTime firstUse = now();
  Map<String, dynamic>? gameResume;
  String? storageError;

  /// This install's id, saved on [load]. It names the device in HLC stamps.
  late String _deviceId = uuidV7(now());
  late HlcClock _clock;
  final _pending = <SyncRecord>[];
  Future<void> _writes = Future.value();

  /// A new id that won't collide with ids made on other devices.
  String newId() => uuidV7(now());

  /// Reads the records, importing the old JSON blob on first launch. Any
  /// failure leaves the defaults whole and stops saving, so unreadable data
  /// is never overwritten.
  Future<void> load() async {
    try {
      final saved = await store.meta('deviceId');
      if (saved == null) {
        await store.setMeta('deviceId', _deviceId);
      } else {
        _deviceId = saved;
        _clock = HlcClock(node: _deviceId, now: now, last: _clock.last);
      }
      var records = await store.loadAll();
      if (records.isEmpty && await store.meta('legacyImported') == null) {
        final blob = await legacy?.load();
        if (blob != null) {
          records = importLegacy(
            blob,
            builtIn: _builtIn,
            deviceId: _deviceId,
            stamp: _clock.tick,
            now: now(),
          );
          await store.write(records);
        }
        await store.setMeta('legacyImported', '1');
      }
      final restored = restore(
        records,
        builtIn: _builtIn,
        examples: _examples,
        deviceId: _deviceId,
      );
      _clock.receive(restored.latest);
      _apply(restored);
      if (!restored.hasOwnFirstUse) {
        _put(AppKinds.firstUse, _deviceId, {'at': firstUse.toIso8601String()});
        await store.write(_takePending());
      }
    } catch (_) {
      // Unreadable or mistyped data must not stop the app from opening.
      _pending.clear();
      storageError =
          'Không thể đọc dữ liệu đã lưu. Dữ liệu gốc chưa bị ghi đè.';
    }
    _syncFeedback();
  }

  void _apply(RestoredState r) {
    final s = r.settings;
    name = s['name'] as String? ?? name;
    level = s['level'] as String? ?? level;
    appearance = s['appearance'] as String? ?? appearance;
    inputColor = s['inputColor'] as String? ?? inputColor;
    voice = s['voice'] as String? ?? voice;
    difficulty = s['difficulty'] as String? ?? difficulty;
    chatTone = s['chatTone'] as String? ?? chatTone;
    chatFree = s['chatFree'] as bool? ?? chatFree;
    showHints = s['showHints'] as bool? ?? showHints;
    chatTipSeen = s['chatTipSeen'] as bool? ?? chatTipSeen;
    language = r.language ?? language;
    modeOrder = r.modeOrder ?? modeOrder;
    sound = r.sound ?? sound;
    haptic = r.haptic ?? haptic;
    gameResume = r.gameResume;
    decks = r.decks;
    history = r.history;
    gamesPlayed = r.gamesPlayed;
    totalXp = r.totalXp;
    bestScore = r.bestScore;
    if (r.firstUse != null) firstUse = r.firstUse!;
  }

  void _syncFeedback() {
    if (feedback case final PlatformFeedback f) {
      f.sound = sound;
      f.haptic = haptic;
    }
  }

  /// Queues a record for the next [commit], stamped now.
  void _put(String kind, String id, Map<String, dynamic>? data) =>
      _pending.add(SyncRecord(kind, id, data, _clock.tick()));

  void _setting(String key, Object value) =>
      _put(RecordKind.setting, key, {'v': value});

  void _device(String key, Object? value) =>
      _put(RecordKind.device, key, {'v': value});

  List<SyncRecord> _takePending() {
    final batch = [..._pending];
    _pending.clear();
    return batch;
  }

  /// Notifies listeners and writes the records queued since the last commit
  /// in one transaction.
  void commit() {
    _syncFeedback();
    notifyListeners();
    if (storageError != null) {
      _pending.clear();
      return;
    }
    final batch = _takePending();
    if (batch.isEmpty) return;
    _writes = _writes.then((_) => store.write(batch)).catchError((
      Object error,
    ) {
      storageError = 'Không thể lưu thay đổi trên thiết bị.';
      notifyListeners();
    });
  }

  Future<void> flush() => _writes;
  void complete(StudySession session) {
    if (!history.any((s) => s.id == session.id)) {
      history.insert(0, session);
      _put(RecordKind.session, session.id, sessionData(session));
      commit();
    }
  }

  void rate(FlashWord word, int rating) {
    final event = ReviewEvent(
      id: newId(),
      wordId: word.id,
      at: now(),
      rating: rating,
    );
    applyReview(word, event);
    _put(RecordKind.review, event.id, event.toJson());
    commit();
  }

  void saveWord(String word, String meaning) {
    final saved = decks.where((d) => d.id == 'saved').firstOrNull;
    final deck =
        saved ??
        Deck(
          id: 'saved',
          title: 'Từ đã lưu',
          description: 'Từ vựng của riêng bạn',
          words: [],
        );
    if (saved == null) {
      decks.add(deck);
      _put(RecordKind.deck, deck.id, deckData(deck, now()));
    }
    if (!deck.words.any((w) => w.word.toLowerCase() == word.toLowerCase())) {
      final card = FlashWord(
        id: savedWordId(word),
        word: word,
        meaning: meaning,
      );
      deck.words.add(card);
      _put(RecordKind.word, card.id, wordData(card, deck.id, now()));
      commit();
    }
  }

  void setVoice(String value) {
    voice = value;
    _setting('voice', value);
    commit();
  }

  void setName(String value) {
    name = value;
    _setting('name', value);
    commit();
  }

  void setLanguage(Language value) {
    language = value;
    _setting('language', value.code);
    commit();
  }

  /// Speaks [text] in the study language's voice.
  Future<void> speak(String text) =>
      feedback.speak(text, locale: language.speechLocale);

  void setLevel(String value) {
    level = value;
    _setting('level', value);
    commit();
  }

  void setAppearance(String value) {
    appearance = value;
    _setting('appearance', value);
    commit();
  }

  void setInputColor(String value) {
    inputColor = value;
    _setting('inputColor', value);
    commit();
  }

  void setDifficulty(String value) {
    difficulty = value;
    _setting('difficulty', value);
    commit();
  }

  /// Conversation settings from the topic screen's popover.
  ChatSettings get chatSettings =>
      ChatSettings(freeChat: chatFree, tone: chatTone);

  void setChatFree(bool value) {
    chatFree = value;
    _setting('chatFree', value);
    commit();
  }

  void setChatTone(String value) {
    chatTone = value;
    _setting('chatTone', value);
    commit();
  }

  void dismissChatTip() {
    if (chatTipSeen) return;
    chatTipSeen = true;
    _setting('chatTipSeen', true);
    commit();
  }

  void setShowHints(bool value) {
    showHints = value;
    _setting('showHints', value);
    commit();
  }

  void setSound(bool value) {
    sound = value;
    _device('sound', value);
    commit();
  }

  void setHaptic(bool value) {
    haptic = value;
    _device('haptic', value);
    commit();
  }

  void _saveModeOrder() =>
      _setting('modeOrder', [for (final m in modeOrder) m.index]);

  void resetModeOrder() {
    modeOrder = StudyMode.values.toList();
    _saveModeOrder();
    commit();
  }

  void moveMode(int from, int to) {
    final mode = modeOrder.removeAt(from);
    modeOrder.insert(to, mode);
    _saveModeOrder();
    commit();
  }

  void addDeck(Deck deck) {
    decks.add(deck);
    _put(RecordKind.deck, deck.id, deckData(deck, now()));
    _putWords(deck, deck.words);
    commit();
  }

  void addWords(Deck deck, List<FlashWord> words) {
    deck.words.addAll(words);
    _putWords(deck, words);
    commit();
  }

  void _putWords(Deck deck, List<FlashWord> words) {
    final base = now();
    for (var i = 0; i < words.length; i++) {
      // A millisecond apart, so the cards keep their order.
      final at = base.add(Duration(milliseconds: i));
      _put(RecordKind.word, words[i].id, wordData(words[i], deck.id, at));
    }
  }

  void resetSchedule(Deck deck) {
    final at = now();
    for (final word in deck.words) {
      final event = ReviewEvent(
        id: newId(),
        wordId: word.id,
        at: at,
        rating: ReviewEvent.reset,
      );
      applyReview(word, event);
      _put(RecordKind.review, event.id, event.toJson());
    }
    commit();
  }

  /// Hides every result dated before now, here and, after sync, on other
  /// devices; a lesson finished later elsewhere stays.
  void clearHistory() {
    history.clear();
    _put(RecordKind.historyCleared, 'history', {'at': now().toIso8601String()});
    commit();
  }

  void saveGameProgress(Map<String, dynamic> progress) {
    gameResume = progress;
    _device('gameResume', progress);
    commit();
  }

  void finishGame(int score, {required bool clearResume}) {
    gamesPlayed++;
    totalXp += score;
    bestScore = max(bestScore, score);
    _put(RecordKind.game, newId(), {
      'score': score,
      'at': now().toIso8601String(),
    });
    if (clearResume) {
      gameResume = null;
      _device('gameResume', null);
    }
    commit();
  }

  /// Whole days since the first recorded use, counting older saved data from
  /// its earliest session because the first-use date was not stored then.
  int get daysWithHifive {
    var first = firstUse;
    for (final session in history) {
      if (session.date.isBefore(first)) first = session.date;
    }
    return DateUtils.dateOnly(now())
        .difference(DateUtils.dateOnly(first))
        .inDays;
  }

  Set<String> get studyDays => history.map((h) => dayKey(h.date)).toSet();
  int get streak {
    final days = studyDays;
    var date = DateUtils.dateOnly(now());
    if (!days.contains(dayKey(date))) {
      date = date.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (days.contains(dayKey(date))) {
      count++;
      date = date.subtract(const Duration(days: 1));
    }
    return count;
  }

  int get longestStreak {
    final dates = studyDays.toList()..sort();
    var longest = 0, current = 0;
    DateTime? previous;
    for (final key in dates) {
      final d = DateTime.parse(key);
      current = previous != null && d.difference(previous).inDays == 1
          ? current + 1
          : 1;
      if (current > longest) longest = current;
      previous = d;
    }
    return longest;
  }

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
