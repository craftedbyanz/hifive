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
  static var _listening = false;

  static void listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'locked') locked.value = call.arguments == true;
    });
  }

  /// Asks once for permission to show the warning.
  static Future<void> prepareWarning() => _call('prepareWarning');

  static Future<void> warn(String title, String body) =>
      _call('warn', {'title': title, 'body': body});

  static Future<void> clearWarning() => _call('clearWarning');

  /// The daily review reminder: one notification at [at], replacing any
  /// earlier one.
  static Future<void> scheduleReminder(
    DateTime at,
    String title,
    String body,
  ) => _call('scheduleReminder', {
    'at': at.millisecondsSinceEpoch.toDouble(),
    'title': title,
    'body': body,
  });

  static Future<void> cancelReminder() => _call('cancelReminder');

  /// Asks for permission to show notifications, once.
  static Future<void> askPermission() => _call('prepareWarning');

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
