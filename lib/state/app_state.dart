import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/services/feedback_service.dart';
import '../core/services/system_actions.dart';
import '../domain/community/community.dart';
import '../domain/garden/garden.dart';
import '../domain/listening/listening.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';
import '../domain/sync/sync.dart';
import '../domain/vocab/vocab.dart';
import 'app_records.dart';

class AppState extends ChangeNotifier {
  /// The device database, the app's source of truth.
  final RecordStore store;

  /// The JSON blob saved before records, imported once on first launch.
  final AppRepository? legacy;
  final AuthService auth;

  /// The sync API, or null when the build has no API address; then nothing
  /// syncs and signing out keeps local data.
  final SyncService? syncService;

  /// hifive's word catalog on the server; null keeps only the bundled decks.
  final CatalogRepository? catalog;

  /// Decks shared by link or code; null when the build has no server, which
  /// hides sharing.
  final ShareRepository? shares;

  /// Study groups and classes; null when the build has no server.
  final CircleRepository? circles;

  /// Codes of the learner's decks shared by link, by deck id.
  Map<String, String> sharedDecks = {};

  /// Ids of the learner's shared decks that Explore lists.
  Set<String> publicDecks = {};

  /// Whether the learner agreed to the community rules, asked the first
  /// time they make a deck public.
  bool communityRules = false;

  /// Catalog decks cached on the device, shown beside the bundled ones.
  List<Deck> _catalogDecks = const [];

  /// Listening sources from the cached catalog.
  List<ListeningSource> listening = const [];

  /// What the learner listened to, by video and day.
  ListenLog listenLog = ListenLog();

  /// Every deck the learner did not make.
  List<Deck> get _allBuiltIn => [..._builtIn, ..._catalogDecks];
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
    required this.auth,
    this.syncService,
    this.catalog,
    this.shares,
    this.circles,
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
    user = auth.current;
    _authChanges = auth.changes.listen(_onUser);
  }
  // Glass, the look every Home measurement was made with; the reference's
  // default for a new account was not seen.
  String name = 'An',
      level = 'A1',
      appearance = 'Glass',
      inputColor = 'Default',
      voice = 'Aaron',
      difficulty = 'Dễ',
      chatTone = 'Thoải mái',
          // The interface language code, or empty to follow the device.
          appLanguage =
          '';
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

  /// The species the next study tree grows as.
  String studySpecies = defaultSpecies;

  /// Tags the learner made; [builtInTags] come first in [focusTags].
  List<FocusTag> customTags = const [];

  /// The tag the last focus session used, offered for the next one.
  String focusTag = defaultTag;

  /// Finished focus sessions, oldest first.
  List<FocusSession> focusSessions = [];

  /// Ratings of new or due cards, oldest first, before the once-a-day rule.
  List<StudyCredit> studyCredits = [];

  /// Every rating with the card's status before it, for memory insight.
  List<Rated> rated = [];

  MemoryInsight get memoryInsight =>
      MemoryInsight.of(uniqueWords.values, rated, now());

  /// The log of ratings for [word] (any card holding the same word).
  List<ReviewEvent> historyOf(FlashWord word) {
    final key = wordKey(word.word);
    final ids = {
      for (final w in decks.expand((d) => d.words))
        if (wordKey(w.word) == key) w.id,
    };
    return [
      for (final r in rated)
        if (r.event.word == key || ids.contains(r.event.wordId)) r.event,
    ]..sort((a, b) => b.at.compareTo(a.at));
  }

  late DateTime firstUse = now();
  Map<String, dynamic>? gameResume;
  String? storageError;

  /// The signed-in learner, or null while the app is used without an
  /// account. Local data stays on the device either way until sync exists.
  AuthUser? user;
  late final StreamSubscription<AuthUser?> _authChanges;

  /// Whether the account finished onboarding (name, level, goals). A synced
  /// setting, so a second device signing in skips it.
  bool onboarded = false;

  /// Learning goals picked during onboarding, as [learningGoals] ids.
  List<String> goals = const [];

  /// When this device last finished a sync with the account, if ever.
  DateTime? lastSyncedAt;

  /// Why the last sync failed, or null after a success.
  SyncError? syncError;
  bool syncing = false;
  Future<void>? _syncing;
  bool _syncAgain = false;
  Timer? _syncSoon, _syncEvery;

  /// How long after a change the app syncs, so a burst of changes such as a
  /// review session costs one request.
  static const syncDelay = Duration(seconds: 20);
  static const syncInterval = Duration(minutes: 5);

  /// Set once [load] finished; sync waits for it, so it never runs with a
  /// temporary device id or unread data.
  bool _loaded = false;

  bool get syncEnabled => _loaded && syncService != null && user != null;

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
      _catalogDecks = await _cachedCatalog();
      final restored = restore(
        records,
        builtIn: _allBuiltIn,
        examples: _examples,
        deviceId: _deviceId,
      );
      _clock.receive(restored.latest);
      _apply(restored);
      if (!restored.hasOwnFirstUse) {
        _put(AppKinds.firstUse, _deviceId, {'at': firstUse.toIso8601String()});
        await store.write(_takePending());
      }
      if (user case final AuthUser u) {
        final at = await store.meta(_lastSyncKey(u.uid));
        lastSyncedAt = at == null ? null : DateTime.tryParse(at);
      }
      _loaded = true;
      if (user != null) _startSyncing();
      unawaited(refreshCatalog());
    } catch (_) {
      // Unreadable or mistyped data must not stop the app from opening.
      _pending.clear();
      storageError =
          'Không thể đọc dữ liệu đã lưu. Dữ liệu gốc chưa bị ghi đè.';
    }
    _syncFeedback();
  }

  static const _catalogLanguage = 'en';
  static const catalogCheckEvery = Duration(hours: 20);

  Future<List<Deck>> _cachedCatalog() async {
    final text = await store.meta('catalog:$_catalogLanguage');
    if (text == null) return const [];
    try {
      listening = parseListening(text);
      return parseCatalog(text);
    } on Object {
      return const [];
    }
  }

  /// Fetches a newer catalog pack, about once a day, and shows its decks.
  /// Offline or failing, it keeps what is cached; nothing is lost.
  Future<void> refreshCatalog({bool force = false}) =>
      _catalogRefresh ??= _refreshCatalog(force: force)
          .whenComplete(() => _catalogRefresh = null);
  Future<void>? _catalogRefresh;

  Future<void> _refreshCatalog({required bool force}) async {
    final repo = catalog;
    if (repo == null || storageError != null) return;
    try {
      final checked = DateTime.tryParse(
        await store.meta('catalogChecked:$_catalogLanguage') ?? '',
      );
      if (!force &&
          checked != null &&
          now().difference(checked) < catalogCheckEvery) {
        return;
      }
      final latest = await repo.latestVersion(_catalogLanguage);
      // A server without a catalog yet is asked again next launch.
      if (latest == null) return;
      await store.setMeta(
        'catalogChecked:$_catalogLanguage',
        now().toIso8601String(),
      );
      final have = int.tryParse(
        await store.meta('catalogVersion:$_catalogLanguage') ?? '',
      );
      if (latest == have) return;
      final text = await repo.pack(_catalogLanguage, latest);
      final decks = parseCatalog(text);
      listening = parseListening(text);
      await store.setMeta('catalog:$_catalogLanguage', text);
      await store.setMeta('catalogVersion:$_catalogLanguage', '$latest');
      await flush();
      _catalogDecks = decks;
      _apply(
        restore(
          await store.loadAll(),
          builtIn: _allBuiltIn,
          examples: _examples,
          deviceId: _deviceId,
        ),
      );
      notifyListeners();
    } on Object {
      // The catalog is extra; the bundled decks keep working without it.
    }
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
    appLanguage = s['appLanguage'] as String? ?? appLanguage;
    studySpecies = s['studySpecies'] as String? ?? studySpecies;
    focusTag = s['focusTag'] as String? ?? focusTag;
    newPerDay = int.tryParse(s['newPerDay'] as String? ?? '') ?? newPerDay;
    exTyping = s['exTyping'] as bool? ?? exTyping;
    reminderOn = s['reminderOn'] as bool? ?? reminderOn;
    reminderTime = s['reminderTime'] as String? ?? reminderTime;
    exListening = s['exListening'] as bool? ?? exListening;
    customTags = s['focusTags'] as List<FocusTag>? ?? customTags;
    focusSessions = [...r.focusSessions];
    listenLog = ListenLog(r.listenDays);
    sharedDecks = {...r.sharedDecks};
    publicDecks = {...r.publicDecks};
    communityRules = s['communityRules'] as bool? ?? communityRules;
    studyCredits = [...r.studyCredits];
    rated = [...r.rated];
    chatFree = s['chatFree'] as bool? ?? chatFree;
    showHints = s['showHints'] as bool? ?? showHints;
    chatTipSeen = s['chatTipSeen'] as bool? ?? chatTipSeen;
    onboarded = s['onboarded'] as bool? ?? onboarded;
    goals = s['goals'] as List<String>? ?? goals;
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
    _scheduleSync(syncDelay);
    _writes = _writes.then((_) => store.write(batch)).catchError((
      Object error,
    ) {
      storageError = 'Không thể lưu thay đổi trên thiết bị.';
      notifyListeners();
    });
  }

  Future<void> flush() => _writes;

  /// Remembers which account this device's records belong to, then syncs:
  /// on first sign-in that merges the guest data into the account.
  void _onUser(AuthUser? next) {
    // A sign-in method already applied this account; the stream repeats it.
    if (next != null && next.uid == user?.uid) return;
    user = next;
    if (next != null && storageError == null) {
      _writes = _writes.then((_) => store.setMeta('accountUid', next.uid));
      _startSyncing();
    } else {
      _stopSyncing();
    }
    notifyListeners();
  }

  /// Applies the account as soon as sign-in returns, so screens and sync
  /// don't wait for the auth stream's next event.
  Future<void> _signIn(Future<AuthUser> Function() call) async =>
      _onUser(await call());

  Future<void> signInWithApple() => _signIn(auth.signInWithApple);
  Future<void> signInWithGoogle() => _signIn(auth.signInWithGoogle);

  static String _lastSyncKey(String uid) => 'lastSyncedAt:$uid';

  /// Syncs now unless it can't: signed out, no API, unreadable data. A call
  /// during a sync waits for it and runs once more, so no change is missed.
  Future<void> sync() {
    if (!syncEnabled || storageError != null) return Future.value();
    if (_syncing case final running?) {
      _syncAgain = true;
      return running;
    }
    return _syncing = _runSync().whenComplete(() => _syncing = null);
  }

  Future<void> _runSync() async {
    _syncSoon?.cancel();
    syncing = true;
    notifyListeners();
    try {
      do {
        _syncAgain = false;
        await _syncOnce();
      } while (_syncAgain && syncEnabled);
      syncError = null;
    } on SyncException catch (e) {
      syncError = e.error;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncOnce() async {
    final account = user;
    await flush();
    final token = await auth.idToken();
    if (account == null || token == null) return;
    final outcome = await Syncer(
      store: store,
      service: syncService!,
    ).run(uid: account.uid, deviceId: _deviceId, idToken: token);
    // Later local edits must win over everything just pulled.
    _clock.receive(outcome.latest);
    if (outcome.pulled > 0) {
      await flush();
      _apply(
        restore(
          await store.loadAll(),
          builtIn: _allBuiltIn,
          examples: _examples,
          deviceId: _deviceId,
        ),
      );
      _syncFeedback();
    }
    lastSyncedAt = now();
    await store.setMeta(
      _lastSyncKey(account.uid),
      lastSyncedAt!.toIso8601String(),
    );
  }

  void _scheduleSync(Duration delay) {
    if (!syncEnabled) return;
    _syncSoon?.cancel();
    _syncSoon = Timer(delay, sync);
  }

  void _startSyncing() {
    if (!syncEnabled) return;
    _syncEvery?.cancel();
    _syncEvery = Timer.periodic(syncInterval, (_) => sync());
    sync();
  }

  void _stopSyncing() {
    _syncSoon?.cancel();
    _syncEvery?.cancel();
    _syncSoon = _syncEvery = null;
  }

  /// True while a signed-in account that hasn't onboarded on this device
  /// waits for its first sync, which may bring onboarding from another
  /// device. A failed sync ends the wait.
  bool get awaitingAccount =>
      !onboarded && syncEnabled && lastSyncedAt == null && syncError == null;

  /// Saves the answers from onboarding and opens the app.
  void completeOnboarding({
    required String name,
    required String level,
    required List<String> goals,
  }) {
    this.name = name;
    this.level = level;
    this.goals = List.unmodifiable(goals);
    onboarded = true;
    _setting('name', name);
    _setting('level', level);
    _setting('goals', goals);
    _setting('onboarded', true);
    commit();
  }

  /// The app came back to the foreground: catch up with other devices.
  void appResumed() {
    if (user != null) _startSyncing();
  }

  /// The app is leaving the screen: push what changed while it can.
  void appPaused() {
    _stopSyncing();
    sync();
  }

  /// Tries to push every pending change before signing out. True when
  /// nothing would be lost, including when sync isn't set up.
  Future<bool> pushBeforeSignOut() async {
    if (!syncEnabled) return true;
    await sync();
    return syncError == null && (await store.dirtyRecords(limit: 1)).isEmpty;
  }

  /// Signs out. With sync set up, the account's data is on the server, so
  /// this device deletes it and starts again as a guest; without sync,
  /// local data stays, since it exists nowhere else.
  Future<void> signOut() async {
    final account = user;
    final clear = syncService != null && account != null;
    _stopSyncing();
    await auth.signOut();
    if (!clear) return;
    await flush();
    _pending.clear();
    await store.clearRecords();
    for (final key in [
      'accountUid',
      Syncer.cursorKey(account.uid),
      _lastSyncKey(account.uid),
    ]) {
      await store.deleteMeta(key);
    }
    _resetToDefaults();
    _put(AppKinds.firstUse, _deviceId, {'at': firstUse.toIso8601String()});
    commit();
  }

  /// The state of a fresh install, used after signing out.
  void _resetToDefaults() {
    name = 'An';
    level = 'A1';
    appearance = 'Glass';
    inputColor = 'Default';
    voice = 'Aaron';
    difficulty = 'Dễ';
    chatTone = 'Thoải mái';
    appLanguage = '';
    studySpecies = defaultSpecies;
    focusTag = defaultTag;
    newPerDay = 10;
    exTyping = true;
    exListening = true;
    reminderOn = false;
    reminderTime = '20:00';
    customTags = const [];
    showHints = false;
    chatFree = true;
    sound = true;
    haptic = true;
    language = Language.english;
    chatTipSeen = false;
    communityRules = false;
    onboarded = false;
    goals = const [];
    modeOrder = [StudyMode.writing, StudyMode.grammar, StudyMode.conversation];
    gameResume = null;
    firstUse = now();
    lastSyncedAt = null;
    syncError = null;
    _apply(
      restore(
        const [],
        builtIn: _allBuiltIn,
        examples: _examples,
        deviceId: _deviceId,
      ),
    );
    _syncFeedback();
  }

  @override
  void dispose() {
    _stopSyncing();
    _authChanges.cancel();
    super.dispose();
  }

  void complete(StudySession session) {
    if (!history.any((s) => s.id == session.id)) {
      history.insert(0, session);
      _put(RecordKind.session, session.id, sessionData(session));
      commit();
    }
  }

  /// Rates [word] 0 (Học lại) to 3 (Dễ). Every card holding the same word
  /// shares the result. [mode], [skill], [source], [ms] and [hints] describe
  /// how it was asked (see `ReviewEvent`).
  void rate(
    FlashWord word,
    int rating, {
    String mode = 'flip',
    String skill = 'meaning',
    String source = 'flashcard',
    int? ms,
    int hints = 0,
  }) {
    final at = now();
    final grows = word.isDue(at);
    final event = ReviewEvent(
      id: newId(),
      wordId: word.id,
      at: at,
      rating: rating,
      tree: grows ? studySpecies : null,
      word: wordKey(word.word),
      mode: mode,
      skill: skill,
      source: source,
      ms: ms,
      hints: hints,
    );
    if (grows) studyCredits.add(StudyCredit(word.id, at, studySpecies));
    rated.add(Rated(event, word.status));
    final key = wordKey(word.word);
    for (final w in decks.expand((d) => d.words)) {
      if (!identical(w, word) && wordKey(w.word) == key) applyReview(w, event);
    }
    applyReview(word, event);
    _put(RecordKind.review, event.id, event.toJson());
    commit();
  }

  /// Ratings that grow the garden: one per card per day.
  List<StudyCredit> get countedStudyCredits => countedCredits(studyCredits);

  /// Cards whose memory lasts three weeks or more.
  int get wordsKnown => uniqueWords.values.where((w) {
    final level = levelOf(w, now());
    return level == MemoryLevel.known || level == MemoryLevel.mastered;
  }).length;

  /// New words offered each day; reviews are never capped.
  int newPerDay = 10;

  /// The daily review reminder, and its time as "HH:mm".
  bool reminderOn = false;
  String reminderTime = '20:00';

  void setReminder({bool? on, String? time}) {
    if (on != null) {
      reminderOn = on;
      _setting('reminderOn', on);
    }
    if (time != null) {
      reminderTime = time;
      _setting('reminderTime', time);
    }
    commit();
  }

  /// The next moment the reminder would fire, from now.
  DateTime get nextReminder {
    final parts = reminderTime.split(':');
    final n = now();
    var at = DateTime(
      n.year,
      n.month,
      n.day,
      int.tryParse(parts.first) ?? 20,
      int.tryParse(parts.last) ?? 0,
    );
    if (!at.isAfter(n)) {
      at = DateTime(at.year, at.month, at.day + 1, at.hour, at.minute);
    }
    return at;
  }

  /// Words already learned that will be due by [at].
  int dueBy(DateTime at) => uniqueWords.values
      .where((w) => w.status != 'new' && w.due != null && !w.due!.isAfter(at))
      .length;

  /// Whether exercises may ask the learner to type, or to listen.
  bool exTyping = true, exListening = true;

  void setExercises({bool? typing, bool? listening}) {
    if (typing != null) {
      exTyping = typing;
      _setting('exTyping', typing);
    }
    if (listening != null) {
      exListening = listening;
      _setting('exListening', listening);
    }
    commit();
  }

  /// Today's reviews and new words. Saved words come first, then the
  /// learner's own decks, then hifive's.
  TodayPlan get today {
    final builtIn = {for (final d in _allBuiltIn) d.id};
    final ordered = [
      ...decks.where((d) => d.id == 'saved'),
      ...decks.where((d) => d.id != 'saved' && !builtIn.contains(d.id)),
      ...decks.where((d) => builtIn.contains(d.id)),
    ];
    return planToday(
      words: uniqueWords,
      decks: ordered,
      now: now(),
      perDay: newPerDay,
    );
  }

  void setNewPerDay(int count) {
    newPerDay = count.clamp(0, 50);
    _setting('newPerDay', '$newPerDay');
    commit();
  }

  /// One card per word: cards holding the same word share one memory.
  Map<String, FlashWord> get uniqueWords => {
    for (final w in decks.expand((d) => d.words)) wordKey(w.word): w,
  };

  GardenStats get gardenStats => GardenStats.from(
    counted: countedStudyCredits,
    sessions: focusSessions,
    reviews: studyCredits.length,
    wordsKnown: wordsKnown,
    streak: streak,
  );

  /// Trees planted from [from] (inclusive) to [to] (exclusive).
  List<Plant> plants(DateTime from, DateTime to) =>
      plantsBetween(countedStudyCredits, focusSessions, from, to);

  /// Chooses the species of the next study tree; ignored while locked.
  void setStudySpecies(String id) {
    if (!gardenStats.unlocks(speciesById(id)) || speciesById(id).id != id) {
      return;
    }
    studySpecies = id;
    _setting('studySpecies', id);
    commit();
  }

  List<FocusTag> get focusTags => [...builtInTags, ...customTags];

  /// The tag with [id]; a deleted tag reads as "other".
  FocusTag tagById(String id) =>
      focusTags.firstWhere((t) => t.id == id, orElse: () => builtInTags.last);

  void setFocusTag(String id) {
    focusTag = id;
    _setting('focusTag', id);
    commit();
  }

  /// Adds a tag named [name] and returns its id.
  String addTag(String name, int color) {
    final tag = FocusTag(newId(), name: name.trim(), color: color);
    _saveTags([...customTags, tag]);
    return tag.id;
  }

  void editTag(String id, String name, int color) => _saveTags([
    for (final t in customTags)
      t.id == id ? FocusTag(id, name: name.trim(), color: color) : t,
  ]);

  /// Removes a tag the learner made. Its sessions keep their time and show
  /// as "other".
  void deleteTag(String id) {
    _saveTags([
      for (final t in customTags)
        if (t.id != id) t,
    ]);
    if (focusTag == id) setFocusTag(defaultTag);
  }

  void _saveTags(List<FocusTag> tags) {
    customTags = List.unmodifiable(tags);
    _setting('focusTags', [for (final t in tags) t.toJson()]);
    commit();
  }

  /// Minutes of finished focus by tag in [from] to [to], largest first.
  List<(FocusTag, int)> focusByTag(DateTime from, DateTime to) {
    final minutes = <String, int>{};
    for (final s in focusSessions) {
      if (s.outcome != FocusOutcome.done) continue;
      if (s.end.isBefore(from) || !s.end.isBefore(to)) continue;
      final id = tagById(s.tag).id;
      minutes[id] = (minutes[id] ?? 0) + s.minutes;
    }
    return [for (final e in minutes.entries) (tagById(e.key), e.value)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
  }

  /// Records listening to [video]: where playback stands, the seconds
  /// [heard] since the last call, and whether it reached the end.
  void listened(
    String video, {
    required int position,
    int heard = 0,
    bool done = false,
  }) {
    final at = now();
    final day = dayKey(at);
    final before = listenLog.day(video, day);
    final entry = ListenDay(
      video: video,
      day: day,
      position: position,
      heard: (before?.heard ?? 0) + heard,
      done: done || (before?.done ?? false),
      at: at,
    );
    listenLog.put(entry);
    _put(RecordKind.listen, entry.id, entry.toJson());
    commit();
  }

  /// Seconds of listening today.
  int get listenedToday => listenLog.heardOn(dayKey(now()));

  /// What to play next: the episode played last, from where it stopped, or
  /// the one after it once it was heard to the end. Null before any
  /// listening, or when the last source has no episode left.
  ({ListeningSource source, int index, int position})? get listenNext {
    final progress = listenLog.progress;
    ({ListeningSource source, int index, ListenProgress p})? last;
    for (final s in listening) {
      for (final (i, e) in s.episodes.indexed) {
        final p = progress[e.id];
        if (p != null && (last == null || !p.at.isBefore(last.p.at))) {
          last = (source: s, index: i, p: p);
        }
      }
    }
    if (last == null) return null;
    if (!last.p.done) {
      return (
        source: last.source,
        index: last.index,
        position: last.p.position,
      );
    }
    final next = last.index + 1;
    return next < last.source.episodes.length
        ? (source: last.source, index: next, position: 0)
        : null;
  }

  /// Saves a focus session when it ends, or again when its tree blooms.
  void recordFocus(FocusSession session) {
    final i = focusSessions.indexWhere((s) => s.id == session.id);
    if (i >= 0) {
      focusSessions[i] = session;
    } else {
      focusSessions.add(session);
    }
    _put(RecordKind.focus, session.id, session.toJson());
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

  /// Sets the interface language: a code from `appLanguages`, or empty to
  /// follow the device.
  void setAppLanguage(String code) {
    appLanguage = code;
    _setting('appLanguage', code);
    commit();
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

  /// Shares [deck] by link: publishes a snapshot of its words (never the
  /// learner's progress) and returns its code. Sharing it again keeps the
  /// code and updates the words. [public] lists it in Explore under the
  /// learner's name; left out, it stays as it was. Throws [ShareException].
  Future<String> shareDeck(Deck deck, {bool? public}) async {
    final repo = shares;
    final token = await auth.idToken();
    if (repo == null || token == null) {
      throw const ShareException(ShareError.unauthorized);
    }
    final listed = public ?? publicDecks.contains(deck.id);
    final code = await repo.publish(
      token,
      deck.id,
      SharedDeck.of(deck, language.code),
      public: listed,
      author: name.trim(),
    );
    sharedDecks[deck.id] = code;
    listed ? publicDecks.add(deck.id) : publicDecks.remove(deck.id);
    _put(RecordKind.share, deck.id, {'code': code, 'public': listed});
    commit();
    return code;
  }

  void acceptCommunityRules() {
    communityRules = true;
    _setting('communityRules', true);
    commit();
  }

  /// A page of public decks in the study language. Signed in, decks the
  /// learner reported or whose owners they blocked are left out.
  Future<ExplorePage> explore({
    ExploreSort sort = ExploreSort.popular,
    String query = '',
    int offset = 0,
  }) async {
    final repo = shares;
    if (repo == null) throw const ShareException(ShareError.unavailable);
    return repo.explore(
      language: language.code,
      sort: sort,
      query: query,
      offset: offset,
      idToken: await auth.idToken(),
    );
  }

  /// Copies the public deck [shared] into the learner's decks and counts
  /// the add for its owner, without waiting for the server.
  Deck addPublicDeck(SharedDeck shared) {
    final deck = addSharedDeck(shared);
    final repo = shares;
    if (repo != null && shared.code.isNotEmpty) {
      unawaited(
        () async {
          final token = await auth.idToken();
          if (token != null) await repo.countAdd(token, shared.code);
        }().catchError((Object _) {}),
      );
    }
    return deck;
  }

  Future<String> _token() async =>
      await auth.idToken() ??
      (throw const ShareException(ShareError.unauthorized));

  /// Reports the public deck [code]; it leaves the learner's Explore.
  Future<void> reportDeck(String code, ReportReason reason) async {
    final repo = shares;
    if (repo == null) throw const ShareException(ShareError.unavailable);
    await repo.report(await _token(), code, reason);
  }

  /// Blocks the owner of [code]; their decks leave the learner's Explore.
  Future<void> blockOwnerOf(String code) async {
    final repo = shares;
    if (repo == null) throw const ShareException(ShareError.unavailable);
    await repo.blockOwner(await _token(), code);
  }

  CircleRepository _circles() =>
      circles ?? (throw const ShareException(ShareError.unavailable));

  /// The study groups and classes the learner is in.
  Future<List<Circle>> myCircles() async => _circles().mine(await _token());

  Future<Circle> createCircle(
    CircleKind kind,
    String name, {
    int goal = 3,
  }) async => _circles().create(
    await _token(),
    kind: kind,
    name: name.trim(),
    goal: goal,
  );

  /// Joins the group or class with [code], typed or pasted.
  Future<Circle> joinCircle(String code) async {
    final clean = code.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    return _circles().join(await _token(), clean);
  }

  /// The Monday of this week, `yyyy-mm-dd`.
  String get weekStart {
    final today = DateUtils.dateOnly(now());
    return dayKey(today.subtract(Duration(days: today.weekday - 1)));
  }

  /// A circle with this week's study days, and a class's decks set.
  Future<CircleDetail> circle(String id) async =>
      _circles().detail(await _token(), id, weekStart);

  Future<void> updateCircle(String id, String name, int goal) async =>
      _circles().update(await _token(), id, name: name.trim(), goal: goal);

  Future<void> leaveCircle(String id) async =>
      _circles().leave(await _token(), id);

  Future<void> removeFromCircle(String id, String member) async =>
      _circles().remove(await _token(), id, member);

  /// Sets [deck] for class [id], due [due]: shares the deck (keeping its
  /// code if already shared) and sets that.
  Future<void> assignDeck(String id, Deck deck, DateTime due) async {
    final code = await shareDeck(deck);
    await _circles().assign(await _token(), id, code, dayKey(due));
  }

  Future<void> unassign(String id, String assignment) async =>
      _circles().unassign(await _token(), id, assignment);

  /// The learner's copy of the deck shared as [code], if they added it.
  Deck? deckFrom(String code) =>
      decks.where((d) => d.source == code).firstOrNull;

  /// Opens an assignment's deck: the learner's copy, made now if needed.
  Future<Deck> assignedDeck(Assignment a) async =>
      deckFrom(a.shareCode) ?? addSharedDeck(await openSharedDeck(a.shareCode));

  /// Unblocks everyone the learner blocked.
  Future<void> unblockAll() async {
    final repo = shares;
    if (repo == null) throw const ShareException(ShareError.unavailable);
    await repo.unblockAll(await _token());
  }

  /// Stops sharing [deck]; its link and code stop working.
  Future<void> unshareDeck(Deck deck) async {
    final code = sharedDecks[deck.id];
    final repo = shares;
    if (code == null || repo == null) return;
    final token = await auth.idToken();
    if (token == null) throw const ShareException(ShareError.unauthorized);
    try {
      await repo.unpublish(token, code);
    } on ShareException catch (e) {
      if (e.error != ShareError.notFound) rethrow;
    }
    sharedDecks.remove(deck.id);
    publicDecks.remove(deck.id);
    _put(RecordKind.share, deck.id, null);
    commit();
  }

  /// The deck shared under [code]. Throws [ShareException].
  Future<SharedDeck> openSharedDeck(String code) {
    final repo = shares;
    if (repo == null) throw const ShareException(ShareError.unavailable);
    return repo.open(code);
  }

  /// Copies [shared] into a deck of the learner's own, with new ids, so it
  /// is learned like any deck they made.
  Deck addSharedDeck(SharedDeck shared) {
    final deck = Deck(
      id: newId(),
      title: shared.title,
      description: shared.description,
      icon: shared.icon,
      source: shared.code.isEmpty ? null : shared.code,
      words: [
        for (final w in shared.words)
          FlashWord(
            id: newId(),
            word: w.word,
            meaning: w.meaning,
            phonetic: w.phonetic,
            example: w.example,
            partOfSpeech: w.partOfSpeech,
            definition: w.definition,
          ),
      ],
    );
    addDeck(deck);
    return deck;
  }

  /// Renames [deck], changes its description and gives it [icon]. Any
  /// deck can be: for one hifive provides, only these are stored, as a deck
  /// record that restoring lays over the bundled deck; its words and the
  /// learner's progress stay as they are.
  void editDeck(
    Deck deck, {
    required String title,
    String? description,
    required int icon,
  }) {
    deck
      ..title = title.trim().isEmpty ? deck.title : title.trim()
      ..description = description?.trim() ?? deck.description
      ..icon = icon;
    _put(RecordKind.deck, deck.id, deckData(deck, deck.createdAt ?? now()));
    commit();
  }

  void addDeck(Deck deck) {
    deck.createdAt ??= now();
    decks.add(deck);
    _put(RecordKind.deck, deck.id, deckData(deck, deck.createdAt!));
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
  /// Sample results are dated before any use, so they don't count.
  int get daysWithHifive {
    var first = firstUse;
    for (final session in history) {
      if (session.isExample) continue;
      if (session.date.isBefore(first)) first = session.date;
    }
    return DateUtils.dateOnly(now())
        .difference(DateUtils.dateOnly(first))
        .inDays;
  }

  /// Days the learner studied: a finished lesson, any rating of a word
  /// (Flashcard, Ôn hôm nay, the break after focus) or a minute of
  /// listening. Sample results don't count; a focus session alone doesn't
  /// either.
  Set<String> get studyDays => {
    for (final h in history)
      if (!h.isExample) dayKey(h.date),
    for (final r in rated) dayKey(r.event.at),
    ...listenLog.studyDays,
  };
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
