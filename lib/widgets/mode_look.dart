import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/design/design.dart';
import '../domain/models/models.dart';

/// How each study mode looks. It sits in widgets, not in the design tokens,
/// so `lib/core` doesn't depend on the domain models.
extension StudyModeLook on StudyMode {
  Color get color => switch (this) {
    StudyMode.writing => D.blue,
    StudyMode.grammar => D.violet,
    StudyMode.conversation => D.cyan,
  };

  IconData get icon => switch (this) {
    StudyMode.writing => Icons.article_rounded,
    StudyMode.grammar => Icons.sync_rounded,
    StudyMode.conversation => CupertinoIcons.ellipses_bubble_fill,
  };

  /// Card fill and ink per appearance, from the reference on the iPhone
  /// (4 November 2026): Glass keeps each mode's colour; Regular gives
  /// Paragraph a white card and Quick Fix a near-black one (Speaking's was
  /// only seen at the edge, so it keeps its colour); Mono is pale grey with
  /// slate ink; Minimal is white with ink.
  (Color, Color) cardLook(String appearance) => switch (appearance) {
    'Mono' => (Palette.monoCard, Palette.monoInk),
    'Minimal' => (Colors.white, D.ink),
    'Regular' => switch (this) {
      StudyMode.writing => (Colors.white, D.ink),
      StudyMode.grammar => (Palette.regularDark, Colors.white),
      StudyMode.conversation => (color, Colors.white),
    },
    _ => (color, Colors.white),
  };

  /// The answer-box color named [name], one of [D.inputColors].
  Color inputColor(String name) =>
      {
        'Orange': Palette.inputOrange,
        'Yellow': Palette.inputYellow,
        'Green': Palette.inputGreen,
        'Blue': Palette.inputBlue,
        'Pink': Palette.inputPink,
        'Purple': Palette.inputPurple,
        'Indigo': Palette.inputIndigo,
      }[name] ??
      (this == StudyMode.writing ? D.purple : D.answerBlue);
}
