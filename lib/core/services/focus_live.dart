import 'package:flutter/services.dart';

/// Shows a running focus session on the iPhone's lock screen and in the
/// Dynamic Island as a Live Activity, over the `hifive/live` channel. The
/// FocusActivity widget extension draws it; its timer and progress bar run
/// by themselves, so the app only starts it, sends a new picture of the
/// plant when it grows a step, and ends it.
///
/// The ✕ on the lock screen comes back as [listen]'s callback.
///
/// Without the channel (tests, Android, iOS before 16.1) the calls do
/// nothing.
abstract final class FocusLive {
  static const _channel = MethodChannel('hifive/live');

  /// Calls [onStop] when the learner ends the session from the lock screen;
  /// null stops listening.
  static void listen(VoidCallback? onStop) {
    _channel.setMethodCallHandler(
      onStop == null
          ? null
          : (call) async {
              if (call.method == 'stop') onStop();
            },
    );
  }

  /// Starts the Live Activity for a session that began at [start] and ends
  /// at [end] (null for the stopwatch), under [tag] in [color].
  static Future<void> start({
    required DateTime start,
    required DateTime? end,
    required String tag,
    required Color color,
  }) => _call('start', {
    'start': start.millisecondsSinceEpoch.toDouble(),
    'end': end?.millisecondsSinceEpoch.toDouble(),
    'tag': tag,
    'color': hex(color),
  });

  /// Shows [png] as the plant.
  static Future<void> plant(Uint8List png) => _call('plant', {'png': png});

  static Future<void> end() => _call('end');

  /// [c] as #RRGGBB.
  static String hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static Future<void> _call(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Tests, Android.
    } on PlatformException {
      // The session goes on without its Live Activity.
    }
  }
}
