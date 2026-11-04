import 'package:flutter/material.dart';

import '../../core/design/design.dart';

/// F01 values measured from the 393 × 852 reference hierarchy.
abstract final class HomeDesign {
  static const cardHeight = 441.0;
  static const menuRowHeight = 70.0;
  static TextStyle get body =>
      D.text(13, weight: FontWeight.w500, height: 18 / 13, color: D.secondary);
  static TextStyle get greeting =>
      D.text(28, weight: FontWeight.w700, spacing: -.87, height: 36 / 28);
  static TextStyle get name => D.text(
    28,
    weight: FontWeight.w700,
    spacing: -.87,
    height: 36 / 28,
    color: D.blue,
  );
  static TextStyle get aiLink =>
      D.text(15, weight: FontWeight.w700, height: 20 / 15);
  static TextStyle get section =>
      D.text(20, weight: FontWeight.w700, spacing: -.47, height: 1.25);
  static TextStyle get modeTitle => D.text(
    34,
    weight: FontWeight.w700,
    spacing: -.75,
    height: 44 / 34,
    color: Colors.white,
  );
  static TextStyle get menuLabel => D.text(
    18,
    weight: FontWeight.w700,
    spacing: 0,
    height: 24 / 18,
    color: Palette.menuLabelInk,
  );
}
