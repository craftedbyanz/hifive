import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract interface class FeedbackService {
  Future<void> speak(String text);
  Future<void> stop();
  void tap();
  void success();
}

class PlatformFeedback implements FeedbackService {
  final FlutterTts _tts = FlutterTts();
  bool sound = true, haptic = true;
  @override
  Future<void> speak(String text) async {
    try {
      await _tts.setLanguage('en-US');
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
}

class SilentFeedback implements FeedbackService {
  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stop() async {}
  @override
  void tap() {}
  @override
  void success() {}
}
