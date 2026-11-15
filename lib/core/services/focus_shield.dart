import 'package:flutter/services.dart';

/// What app blocking can do on this phone: whether it exists here at all
/// (iOS 16 and later), whether the learner turned it on, and how many apps,
/// categories and sites they chose.
typedef ShieldStatus = ({bool available, bool enabled, int picked});

/// Why turning app blocking on failed.
enum ShieldError {
  /// The learner said no to Screen Time access, or revoked it in Settings.
  denied,

  /// This build lacks Apple's Family Controls entitlement.
  unavailable,
}

/// Blocks the apps the learner chose while a focus session runs, through
/// Apple's Screen Time API (FamilyControls and ManagedSettings) over the
/// `hifive/shield` channel. The choice and the on/off switch live on the
/// phone, since the app tokens Apple hands out only mean something there.
///
/// Without the channel (tests, Android) [status] says unavailable and the
/// other calls do nothing.
abstract final class FocusShield {
  static const _channel = MethodChannel('hifive/shield');
  static const off = (available: false, enabled: false, picked: 0);

  static ShieldStatus _read(Object? raw) {
    final m = raw is Map ? raw : const <Object?, Object?>{};
    return (
      available: m['available'] == true,
      enabled: m['enabled'] == true,
      picked: (m['picked'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<ShieldStatus> status() async {
    try {
      return _read(await _channel.invokeMethod<Object?>('status'));
    } on MissingPluginException {
      return off;
    } on PlatformException {
      return off;
    }
  }

  /// Turns blocking on or off. Turning it on asks for Screen Time access the
  /// first time and opens the picker when nothing is chosen yet. [title]
  /// and [done] label the picker. Returns the new status, or the reason it
  /// could not be turned on.
  static Future<(ShieldStatus, ShieldError?)> setEnabled(
    bool on, {
    required String title,
    required String done,
  }) async {
    try {
      final raw = await _channel.invokeMethod<Object?>('enable', {
        'on': on,
        'title': title,
        'done': done,
      });
      return (_read(raw), null);
    } on MissingPluginException {
      return (off, ShieldError.unavailable);
    } on PlatformException catch (e) {
      final error = e.code == 'denied'
          ? ShieldError.denied
          : ShieldError.unavailable;
      return (await status(), error);
    }
  }

  /// Opens Apple's picker to change the chosen apps.
  static Future<ShieldStatus> pick({
    required String title,
    required String done,
  }) async {
    try {
      return _read(
        await _channel.invokeMethod<Object?>('pick', {
          'title': title,
          'done': done,
        }),
      );
    } on MissingPluginException {
      return off;
    } on PlatformException {
      return status();
    }
  }

  /// Shields the chosen apps, if blocking is on.
  static Future<void> start() => _call('start');

  /// Lifts the shield. Safe to call when nothing is shielded.
  static Future<void> stop() => _call('stop');

  static Future<void> _call(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Tests and Android.
    } on PlatformException {
      // A session goes on without the shield.
    }
  }
}
