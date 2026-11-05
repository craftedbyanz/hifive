import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/services/feedback_service.dart';
import '../core/services/system_actions.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';

class AppState extends ChangeNotifier {
  final AppRepository repository;
  final LessonRepository lessons;
  final GradingRepository grading;
  final ConversationRepository conversation;
  final DeckGenerator deckGenerator;
  final InsightRepository insights;
  final FeedbackService feedback;
  final SystemActions system;
  final DateTime Function() now;

  /// Wires the state to its services. `lib/app/app_state_factory.dart` picks
  /// the implementations, so this layer never imports `lib/data`.
  AppState({
    required this.repository,
    required this.lessons,
    required this.grading,
    required this.conversation,
    required this.deckGenerator,
    required this.insights,
    required this.decks,
    List<StudySession> examples = const [],
    FeedbackService? feedback,
    SystemActions? system,
    DateTime Function()? now,
  }) : history = [...examples],
       feedback = feedback ?? PlatformFeedback(),
       system = system ?? const PlatformSystemActions(),
       now = now ?? DateTime.now;
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
  Future<void> _writes = Future.value();
  Future<void> load() async {
    try {
      final j = await repository.load();
      if (j != null) _apply(j);
    } catch (_) {
      // Unreadable or mistyped data must not stop the app from opening.
      storageError =
          'Không thể đọc dữ liệu đã lưu. Dữ liệu gốc chưa bị ghi đè.';
    }
    _syncFeedback();
  }

  /// Parses everything before assigning, so bad data leaves the defaults whole.
  void _apply(Map<String, dynamic> j) {
    final savedName = j['name'] as String? ?? name,
        savedLevel = j['level'] as String? ?? level,
        savedLanguage = Language.fromCode(j['language'] as String?) ?? language,
        savedAppearance = j['appearance'] as String? ?? appearance,
        savedInputColor = j['inputColor'] as String? ?? inputColor,
        savedVoice = j['voice'] as String? ?? voice,
        savedDifficulty = j['difficulty'] as String? ?? difficulty,
        savedTone = j['chatTone'] as String? ?? chatTone;
    final savedChatFree = j['chatFree'] as bool? ?? true,
        savedTipSeen = j['chatTipSeen'] as bool? ?? false;
    final savedHints = j['showHints'] as bool? ?? false,
        savedSound = j['sound'] as bool? ?? true,
        savedHaptic = j['haptic'] as bool? ?? true;
    final savedBest = j['bestScore'] as int? ?? 0,
        savedPlayed = j['gamesPlayed'] as int? ?? 0,
        savedXp = j['totalXp'] as int? ?? 0;
    final order = j['modeOrder'] as List?;
    final savedOrder = order != null && order.toSet().length == 3
        ? order.map((i) => StudyMode.values[i as int]).toList()
        : modeOrder;
    final savedDecks = j['decks'] == null
        ? decks
        : (j['decks'] as List)
              .map((d) => Deck.fromJson(Map<String, dynamic>.from(d as Map)))
              .toList();
    final savedHistory = (j['history'] as List? ?? const [])
        .map((h) => StudySession.fromJson(Map<String, dynamic>.from(h as Map)))
        .toList();
    final savedFirstUse = j['firstUse'] == null
        ? null
        : DateTime.parse(j['firstUse'] as String);
    final savedResume = j['gameResume'] == null
        ? null
        : Map<String, dynamic>.from(j['gameResume'] as Map);
    name = savedName;
    level = savedLevel;
    language = savedLanguage;
    appearance = savedAppearance;
    inputColor = savedInputColor;
    // Saved before voices were selectable.
    voice = savedVoice == 'System' ? voice : savedVoice;
    difficulty = savedDifficulty;
    chatTone = savedTone;
    chatFree = savedChatFree;
    chatTipSeen = savedTipSeen;
    showHints = savedHints;
    sound = savedSound;
    haptic = savedHaptic;
    bestScore = savedBest;
    gamesPlayed = savedPlayed;
    totalXp = savedXp;
    modeOrder = savedOrder;
    decks = savedDecks;
    history = savedHistory;
    gameResume = savedResume;
    if (savedFirstUse != null) firstUse = savedFirstUse;
  }

  void _syncFeedback() {
    if (feedback case final PlatformFeedback f) {
      f.sound = sound;
      f.haptic = haptic;
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'name': name,
    'level': level,
    'language': language.code,
    'appearance': appearance,
    'inputColor': inputColor,
    'voice': voice,
    'difficulty': difficulty,
    'chatTone': chatTone,
    'chatFree': chatFree,
    'chatTipSeen': chatTipSeen,
    'showHints': showHints,
    'sound': sound,
    'haptic': haptic,
    'modeOrder': modeOrder.map((m) => m.index).toList(),
    'decks': decks.map((d) => d.toJson()).toList(),
    'history': history.map((h) => h.toJson()).toList(),
    'bestScore': bestScore,
    'gamesPlayed': gamesPlayed,
    'totalXp': totalXp,
    'gameResume': gameResume,
    'firstUse': firstUse.toIso8601String(),
  };
  void commit() {
    _syncFeedback();
    notifyListeners();
    if (storageError != null) return;
    final snapshot = jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>;
    _writes = _writes.then((_) => repository.save(snapshot)).catchError((
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
      commit();
    }
  }

  void rate(FlashWord word, int rating) {
    final interval = word.nextIntervals[rating];
    word.status = rating == 0 ? 'learning' : 'review';
    word.intervalDays = interval.inDays;
    word.due = now().add(interval);
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
    if (saved == null) decks.add(deck);
    if (!deck.words.any((w) => w.word.toLowerCase() == word.toLowerCase())) {
      deck.words.add(
        FlashWord(
          id: 'saved-${now().microsecondsSinceEpoch}',
          word: word,
          meaning: meaning,
        ),
      );
      commit();
    }
  }

  void setVoice(String value) {
    voice = value;
    commit();
  }

  void setName(String value) {
    name = value;
    commit();
  }

  void setLanguage(Language value) {
    language = value;
    commit();
  }

  /// Speaks [text] in the study language's voice.
  Future<void> speak(String text) =>
      feedback.speak(text, locale: language.speechLocale);

  void setLevel(String value) {
    level = value;
    commit();
  }

  void setAppearance(String value) {
    appearance = value;
    commit();
  }

  void setInputColor(String value) {
    inputColor = value;
    commit();
  }

  void setDifficulty(String value) {
    difficulty = value;
    commit();
  }

  /// Conversation settings from the topic screen's popover.
  ChatSettings get chatSettings =>
      ChatSettings(freeChat: chatFree, tone: chatTone);

  void setChatFree(bool value) {
    chatFree = value;
    commit();
  }

  void setChatTone(String value) {
    chatTone = value;
    commit();
  }

  void dismissChatTip() {
    if (chatTipSeen) return;
    chatTipSeen = true;
    commit();
  }

  void setShowHints(bool value) {
    showHints = value;
    commit();
  }

  void setSound(bool value) {
    sound = value;
    commit();
  }

  void setHaptic(bool value) {
    haptic = value;
    commit();
  }

  void resetModeOrder() {
    modeOrder = StudyMode.values.toList();
    commit();
  }

  void moveMode(int from, int to) {
    final mode = modeOrder.removeAt(from);
    modeOrder.insert(to, mode);
    commit();
  }

  void addDeck(Deck deck) {
    decks.add(deck);
    commit();
  }

  void addWords(Deck deck, List<FlashWord> words) {
    deck.words.addAll(words);
    commit();
  }

  void resetSchedule(Deck deck) {
    for (final word in deck.words) {
      word.status = 'new';
      word.due = null;
      word.intervalDays = 0;
    }
    commit();
  }

  void clearHistory() {
    history.clear();
    commit();
  }

  void saveGameProgress(Map<String, dynamic> progress) {
    gameResume = progress;
    commit();
  }

  void finishGame(int score, {required bool clearResume}) {
    gamesPlayed++;
    totalXp += score;
    bestScore = max(bestScore, score);
    if (clearResume) gameResume = null;
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
