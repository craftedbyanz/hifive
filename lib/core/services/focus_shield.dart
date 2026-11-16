import 'package:flutter/services.dart';

/// What happened when a session asked to block other apps.
enum ShieldResult {
  /// Every other app and website is blocked until [FocusShield.stop].
  on,

  /// The learner said no to Screen Time access just now.
  declined,

  /// Screen Time access was refused before, or revoked in Settings.
  denied,

  /// No blocking here: before iOS 16, without the Family Controls
  /// entitlement, on Android and in tests.
  unavailable,
}

/// Blocks every other app and website while a focus session runs, through
/// Apple's Screen Time API (FamilyControls and ManagedSettings) over the
/// `hifive/shield` channel, as focus apps do: there is no switch and no list
/// to pick. The first session asks for Screen Time access; the phone's own
/// essentials (Phone, Settings, emergency calls) always stay open.
///
/// The iOS side does its work off the main thread, which Flutter's frames
/// share, so starting a session doesn't stutter.
abstract final class FocusShield {
  static const _channel = MethodChannel('hifive/shield');

  /// Blocks other apps, asking for Screen Time access the first time.
  static Future<ShieldResult> start() async {
    try {
      final raw = await _channel.invokeMethod<String>('start');
      return ShieldResult.values.firstWhere(
        (r) => r.name == raw,
        orElse: () => ShieldResult.unavailable,
      );
    } on MissingPluginException {
      return ShieldResult.unavailable;
    } on PlatformException {
      return ShieldResult.unavailable;
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
