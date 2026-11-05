import 'package:flutter/material.dart';

abstract final class D {
  static const ink = Color(0xff111827),
      muted = Color(0xff9ca3af),
      secondary = Color(0xff6b7280),
      background = Color(0xfff8fbfc),
      line = Color(0xffe7e9ed),
      blue = Color(0xff3b82f6),
      purple = Color(0xffa34ef5),
      turquoise = Color(0xff08b1ca),
      lime = Color(0xffceff32),
      orange = Color(0xffff7919),
      green = Color(0xff10b98a),
      violet = Color(0xff8a5bf6),
      cyan = Color(0xff06b6d4),
      answerBlue = Color(0xff0084ff);

  /// Answer-box colors offered by Lesson Settings and the lesson menu.
  static const inputColors = [
    'Default',
    'Orange',
    'Yellow',
    'Green',
    'Blue',
    'Pink',
    'Purple',
    'Indigo',
  ];
  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double? height,
    double? spacing,
  }) => TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height ?? 1.4,
    letterSpacing: spacing ?? 0,
  );
  static final shadow = [
    BoxShadow(
      color: ink.withValues(alpha: .06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    fontFamily: 'PlusJakartaSans',
    colorScheme: ColorScheme.fromSeed(seedColor: blue, surface: background),
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'PlusJakartaSans',
      bodyColor: ink,
      displayColor: ink,
    ),
    dividerColor: line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: blue),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
