import 'package:flutter/services.dart';

/// What happened when a session asked to block other apps.
enum ShieldResult {
  /// Every other app and website is blocked until [FocusShield.stop].
  on,

  /// The learner said no to Screen Time access just now.
  declined,

  /// Screen Time access was refused before, or revoked in Settings.
  denied,

  /// The phone answered with an error; [ShieldOutcome.reason] says which.
  failed,

  /// No blocking here: before iOS 16, on Android and in tests.
  unavailable,
}

/// A [ShieldResult] and, when it [ShieldResult.failed], the system's reason.
typedef ShieldOutcome = ({ShieldResult result, String? reason});

/// Blocks every other app and website while a focus session runs, through
/// Apple's Screen Time API (FamilyControls and ManagedSettings) over the
/// `hifive/shield` channel, as focus apps do: there is no switch and no list
/// to pick. The first session asks for Screen Time access; the phone's own
/// essentials (Phone, Settings, emergency calls) always stay open.
abstract final class FocusShield {
  static const _channel = MethodChannel('hifive/shield');

  /// Blocks other apps, asking for Screen Time access the first time.
  static Future<ShieldOutcome> start() async {
    try {
      final raw = await _channel.invokeMethod<String>('start');
      return (
        result: ShieldResult.values.firstWhere(
          (r) => r.name == raw,
          orElse: () => ShieldResult.unavailable,
        ),
        reason: null,
      );
    } on MissingPluginException {
      return (result: ShieldResult.unavailable, reason: null);
    } on PlatformException catch (e) {
      return (result: ShieldResult.failed, reason: e.message ?? e.code);
    }
  }

  /// Lifts the shield. Safe to call when nothing is shielded.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // Tests and Android.
    } on PlatformException {
      // Nothing to lift.
    }
  }
}
