import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract interface class FeedbackService {
  /// Speaks [text] with a voice for [locale], such as `en-US`.
  Future<void> speak(String text, {required String locale});
  Future<void> stop();
  void tap();
  void success();

  /// A physical knock with no sound: light, or [heavy] for something
  /// landing.
  void impact({bool heavy = false});
}

class PlatformFeedback implements FeedbackService {
  final FlutterTts _tts = FlutterTts();
  bool sound = true, haptic = true;
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
    if (haptic) unawaited(HapticFeedback.selectionClick());
  }

  @override
  void success() {
    if (haptic) unawaited(HapticFeedback.mediumImpact());
    if (sound) unawaited(SystemSound.play(SystemSoundType.click));
  }

  @override
  void impact({bool heavy = false}) {
    if (!haptic) return;
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
  void success() {}
  @override
  void impact({bool heavy = false}) {}
}
