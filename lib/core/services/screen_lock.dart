import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Talks to the iOS app delegate over the `hifive/screen` channel about a
/// running focus session.
///
/// [locked] is whether the phone is locked (protected data became
/// unavailable, which needs a passcode). A focus session keeps going while
/// the phone is locked but not while another app is open, and this is how
/// the two are told apart.
///
/// [warn] schedules a local notification a few seconds after the app goes to
/// the background, telling the learner the tree is about to wither; locking
/// the phone or [clearWarning] withdraws it.
///
/// Without the channel (tests, Android for now) [locked] stays false and the
/// calls do nothing, so leaving the app always counts as leaving.
abstract final class ScreenLock {
  static const _channel = MethodChannel('hifive/screen');
  static final locked = ValueNotifier<bool>(false);

  /// Counts taps on a review reminder while the app runs; see
  /// [takeReviewTap].
  static final reviewTaps = ValueNotifier<int>(0);

  /// Counts taps on a word note while the app runs; see [takeWordTap].
  static final wordTaps = ValueNotifier<int>(0);
  static var _listening = false;

  static void listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'locked') locked.value = call.arguments == true;
      if (call.method == 'reviewTapped') reviewTaps.value++;
      if (call.method == 'wordTapped') wordTaps.value++;
    });
  }

  /// Whether a review reminder was tapped since the last call, including
  /// the tap that launched the app; answering clears it.
  static Future<bool> takeReviewTap() async {
    try {
      return await _channel.invokeMethod<bool>('takeReviewTap') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// The id of the card whose word note was tapped since the last call,
  /// including the tap that launched the app; answering clears it.
  static Future<String?> takeWordTap() async {
    try {
      return await _channel.invokeMethod<String>('takeWordTap');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// The word notes for the coming days, replacing any scheduled before.
  /// Each names its card by [word] id, which a tap opens.
  static Future<void> scheduleWordNotes(
    List<({DateTime at, String title, String body, String word})> notes,
  ) => _call('scheduleWordNotes', [
    for (final n in notes)
      {
        'at': n.at.millisecondsSinceEpoch.toDouble(),
        'title': n.title,
        'body': n.body,
        'word': n.word,
      },
  ]);

  static Future<void> cancelWordNotes() => _call('cancelWordNotes');

  /// Asks once for permission to show the warning.
  static Future<void> prepareWarning() => _call('prepareWarning');

  static Future<void> warn(String title, String body) =>
      _call('warn', {'title': title, 'body': body});

  static Future<void> clearWarning() => _call('clearWarning');

  /// The daily review reminders for the coming days, each at its time with
  /// its own text, replacing any scheduled before.
  static Future<void> scheduleReminders(
    List<({DateTime at, String title, String body})> reminders,
  ) => _call('scheduleReminders', [
    for (final r in reminders)
      {
        'at': r.at.millisecondsSinceEpoch.toDouble(),
        'title': r.title,
        'body': r.body,
      },
  ]);

  static Future<void> cancelReminder() => _call('cancelReminder');

  /// Asks for permission to show notifications (iOS asks only once) and
  /// answers whether they are allowed; null where there is no answer
  /// (tests, Android for now).
  static Future<bool?> askPermission() async {
    try {
      return await _channel.invokeMethod<bool>('prepareWarning');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Whether hifive may send notifications, without asking; [unknown]
  /// where there is no answer (tests, Android for now).
  static Future<NotificationAccess> access() async {
    try {
      return switch (await _channel.invokeMethod<String>(
        'notificationStatus',
      )) {
        'allowed' => NotificationAccess.allowed,
        'denied' => NotificationAccess.denied,
        'unasked' => NotificationAccess.unasked,
        _ => NotificationAccess.unknown,
      };
    } on MissingPluginException {
      return NotificationAccess.unknown;
    } on PlatformException {
      return NotificationAccess.unknown;
    }
  }

  static Future<void> _call(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // No delegate listening: tests and Android.
    } on PlatformException {
      // The warning is a courtesy; the session goes on without it.
    }
  }
}

/// What the phone lets hifive do with notifications.
enum NotificationAccess {
  allowed,

  /// Turned off in Settings; only the learner can turn it back on there.
  denied,

  /// Never asked on this phone, as after installing again or on a second
  /// device where the synced reminder is already on.
  unasked,

  /// No answer from the platform.
  unknown,
}
