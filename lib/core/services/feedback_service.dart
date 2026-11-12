import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract interface class FeedbackService {
  /// Speaks [text] with a voice for [locale], such as `en-US`.
  Future<void> speak(String text, {required String locale});
  Future<void> stop();
  void tap();

  /// A light knock for tapping any button, card or row (see `TapFeedback`).
  /// It stays quiet when another haptic has just played, so a control that
  /// already gives its own does not knock twice.
  void buttonTap();
  void success();

  /// A physical knock with no sound: light, or [heavy] for something
  /// landing.
  void impact({bool heavy = false});
}

class PlatformFeedback implements FeedbackService {
  final FlutterTts _tts = FlutterTts();
  bool sound = true, haptic = true;

  /// Two haptics closer together than this feel like one doubled knock.
  static const _together = Duration(milliseconds: 80);
  DateTime _lastHaptic = DateTime(0), _lastButton = DateTime(0);
  bool _recent(DateTime at) => DateTime.now().difference(at) < _together;
  @override
  Future<void> speak(String text, {required String locale}) async {
    try {
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(.45);
      await _tts.speak(text);
    } on Exception {
      /* The OS may have no installed voice. */
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Exception {
      /* No active engine. */
    }
  }

  @override
  void tap() {
    // The shared button knock fires first, on the finger's release; a
    // control's own tap a moment later would double it.
    if (!haptic || _recent(_lastButton)) return;
    _lastHaptic = DateTime.now();
    unawaited(HapticFeedback.selectionClick());
  }

  @override
  void buttonTap() {
    if (!haptic || _recent(_lastHaptic)) return;
    _lastButton = _lastHaptic = DateTime.now();
    unawaited(HapticFeedback.lightImpact());
  }

  @override
  void success() {
    if (haptic) {
      _lastHaptic = DateTime.now();
      unawaited(HapticFeedback.mediumImpact());
    }
    if (sound) unawaited(SystemSound.play(SystemSoundType.click));
  }

  @override
  void impact({bool heavy = false}) {
    if (!haptic) return;
    _lastHaptic = DateTime.now();
    unawaited(
      heavy ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact(),
    );
  }
}

class SilentFeedback implements FeedbackService {
  @override
  Future<void> speak(String text, {required String locale}) async {}
  @override
  Future<void> stop() async {}
  @override
  void tap() {}
  @override
  void buttonTap() {}
  @override
  void success() {}
  @override
  void impact({bool heavy = false}) {}
}
