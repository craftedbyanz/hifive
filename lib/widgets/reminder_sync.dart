import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/services/screen_lock.dart';
import '../l10n/l10n.dart';
import '../state/state.dart';

/// Keeps the daily review reminder in step with the learner's words: after
/// any change, and when the app goes to the background, it schedules one
/// notification at the reminder time saying how many words will be due, or
/// cancels it when none will be or the reminder is off.
class ReminderSync extends StatefulWidget {
  final Widget child;
  const ReminderSync({super.key, required this.child});

  /// Seconds of review a word takes, for the time estimate.
  static const secondsPerWord = 12;

  @override
  State<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends State<ReminderSync>
    with WidgetsBindingObserver {
  AppState? _state;
  Timer? _debounce;

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
    if (!state.reminderOn) {
      ScreenLock.cancelReminder();
      return;
    }
    final at = state.nextReminder;
    final count = state.dueBy(at);
    if (count == 0) {
      ScreenLock.cancelReminder();
      return;
    }
    final t = context.t;
    final minutes = (count * ReminderSync.secondsPerWord / 60).ceil();
    ScreenLock.scheduleReminder(
      at,
      t.reminderNoteTitle(count),
      t.reminderNoteBody(minutes),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
