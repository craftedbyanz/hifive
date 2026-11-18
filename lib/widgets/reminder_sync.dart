import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/services/screen_lock.dart';
import '../domain/vocab/vocab.dart';
import '../l10n/l10n.dart';
import '../state/state.dart';

/// Keeps the daily review reminders in step with the learner's words: after
/// any change, and when the app goes to the background, it schedules a
/// notification at the reminder time on each of the coming [ReminderSync.days]
/// days: how many words will be due, or on a day with none a nudge to learn
/// a few new words (skipped once the learner studied that day). Cancels them
/// all when the reminder is off. Word notes (`WordNotes`) are kept in step the
/// same way. Asks for notification permission on a phone that never
/// answered while the synced reminder or word notes are on.
class ReminderSync extends StatefulWidget {
  final Widget child;
  const ReminderSync({super.key, required this.child});

  /// Seconds of review a word takes, for the time estimate.
  static const secondsPerWord = 12;

  /// Seconds a new word takes to learn, for the nudge's estimate.
  static const secondsPerNewWord = 30;

  /// How many days ahead reminders are scheduled, so they keep coming while
  /// the app stays closed, the time a learner drifting away needs them most.
  /// Each day's count is the forecast from now. iOS keeps at most 64
  /// pending notifications per app.
  static const days = 30;

  @override
  State<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends State<ReminderSync>
    with WidgetsBindingObserver {
  AppState? _state;
  Timer? _debounce;

  /// Whether this run already asked for notification permission.
  var _asked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.read(context);
    if (!identical(state, _state)) {
      _state?.removeListener(_changed);
      _state = state..addListener(_changed);
      _changed();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state?.removeListener(_changed);
    _debounce?.cancel();
    super.dispose();
  }

  void _changed() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _sync);
  }

  void _sync() {
    final state = _state;
    if (state == null || !mounted) return;
    _syncWordNotes(state);
    if (!state.reminderOn) {
      ScreenLock.cancelReminder();
      return;
    }
    _askOnce();
    final t = context.t;
    final first = state.nextReminder;
    // A nudge never offers more new words than the decks still hold.
    final unseen = state.uniqueWords.values
        .where((w) => w.status == 'new')
        .length;
    final fresh = math.min(state.newPerDay, unseen);
    final reminders = [
      for (var i = 0; i < ReminderSync.days; i++)
        ?_note(state, t, _at(first, i), fresh),
    ];
    if (reminders.isEmpty) {
      ScreenLock.cancelReminder();
    } else {
      ScreenLock.scheduleReminders(reminders);
    }
  }

  /// The word notes for the coming days, or none when they are off.
  void _syncWordNotes(AppState state) {
    if (!state.wordNotesOn) {
      ScreenLock.cancelWordNotes();
      return;
    }
    _askOnce();
    ScreenLock.scheduleWordNotes([
      for (final n in state.wordNotes)
        (
          at: n.at,
          title: wordNoteText(n.word).title,
          body: wordNoteText(n.word).body,
          word: n.word.id,
        ),
    ]);
  }

  /// The reminder is a synced setting but permission belongs to the phone:
  /// after installing again, or on a second device, the switch comes back on
  /// while iOS has never been asked and would drop every reminder. Asks
  /// there, once a run.
  Future<void> _askOnce() async {
    if (_asked) return;
    _asked = true;
    if (await ScreenLock.access() == NotificationAccess.unasked) {
      await ScreenLock.askPermission();
    }
  }

  /// What the reminder at [at] says: the words due by then, or on a day
  /// with none a nudge to learn [fresh] new ones, unless the learner already
  /// studied that day or has no new word to take.
  static ({DateTime at, String title, String body})? _note(
    AppState state,
    AppLocalizations t,
    DateTime at,
    int fresh,
  ) {
    final due = state.dueBy(at);
    if (due > 0) {
      return (
        at: at,
        title: t.reminderNoteTitle(due),
        body: t.reminderNoteBody(
          (due * ReminderSync.secondsPerWord / 60).ceil(),
        ),
      );
    }
    if (fresh == 0 || state.studyDays.contains(AppState.dayKey(at))) {
      return null;
    }
    return (
      at: at,
      title: t.reminderNudgeTitle,
      body: t.reminderNudgeBody(
        fresh,
        (fresh * ReminderSync.secondsPerNewWord / 60).ceil(),
      ),
    );
  }

  /// The reminder [days] after [first], at the same wall-clock time.
  static DateTime _at(DateTime first, int days) => DateTime(
    first.year,
    first.month,
    first.day + days,
    first.hour,
    first.minute,
  );

  @override
  Widget build(BuildContext context) => widget.child;
}
