import 'package:flutter/material.dart';

import '../state/state.dart';

/// Speaks [word] through the app's [FeedbackService].
void playWord(BuildContext context, String word) =>
    AppScope.read(context).feedback.speak(word);
