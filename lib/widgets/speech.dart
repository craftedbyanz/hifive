import 'package:flutter/material.dart';

import '../state/state.dart';

/// Speaks [word] in the study language through the app's [FeedbackService].
void playWord(BuildContext context, String word) =>
    AppScope.read(context).speak(word);
