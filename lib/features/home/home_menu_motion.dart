import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Home menu animation values at one moment.
///
/// Row position, backdrop timing and durations come from one menu open and
/// close in the 60 fps reference recording of 2 November 2026. Row blur and the
/// bottom bar values are estimates read from the same frames. The backdrop's
/// fade timing and the longer open were matched on 11 November 2026 against a
/// second recording (two opens and closes), frame by frame.
class MenuMotion {
  /// Opening runs long enough for the rows' slow settle to finish without a
  /// last-frame jump; closing takes about as long to look as smooth.
  static const duration = Duration(milliseconds: 600);
  static const reverseDuration = Duration(milliseconds: 450);
  static const openSeconds = .6, closeSeconds = .45;

  /// Rows sit this far apart when fully open, in points.
  static const rowSpacing = 70.0;
  static const listTravel = 14.0;

  /// The reference's footer starts to hide first, and its rows follow this
  /// many seconds later, compared frame by frame against a tap on the iPhone.
  static const rowDelay = .08;

  /// How far rows have spread from the bottom row: 0 is collapsed, 1 is open.
  final double spread;
  final double rowOpacity, rowScale, rowBlur;

  final double backdropOpacity;
  final double barOpacity, barScale, barBlur;

  const MenuMotion._({
    required this.spread,
    required this.rowOpacity,
    required this.rowBlur,
    required this.backdropOpacity,
    required this.barOpacity,
    required this.barBlur,
    this.barScale = 1,
    double? rowScale,
  }) : rowScale = rowScale ?? .6 + .4 * spread;

  factory MenuMotion.at(double value, {required bool closing}) =>
      closing ? MenuMotion._closing(value) : MenuMotion._opening(value);

  factory MenuMotion._opening(double value) {
    final t = value * openSeconds, rows = t - rowDelay;
    final spread = value >= 1
        ? 1.0
        : rows <= .032
        ? 0.0
        : 1 - math.exp(-13.65 * (rows - .032));
    final hide = _progress(t, 0, .1);
    return MenuMotion._(
      spread: spread,
      rowOpacity: _progress(rows, .032, .152),
      rowBlur: 10 * (1 - spread),
      // The blurred screen fades in steadily, starting with the first change;
      // the sharp card behind is gone by about 0.07 s, its ghost by 0.2 s.
      backdropOpacity: value >= 1 ? 1 : _progress(rows, -.03, .16),
      barOpacity: 1 - hide,
      barBlur: 6 * hide,
    );
  }

  /// Closing mirrors the opening's pace instead of the reference's 0.14 s
  /// snap, which felt abrupt next to the smooth open (iPhone, 11 November
  /// 2026): the rows draw together into the bottom row and shrink over about
  /// 0.3 s, easing in and out, and fade over the second half; the screen
  /// behind clears on the same curve; the bottom bar returns blurred and a
  /// little large as the rows go, then sharpens.
  factory MenuMotion._closing(double value) {
    final t = (1 - value) * closeSeconds;
    final fold = Curves.easeInOutCubic.transform(_progress(t, 0, .3));
    final settle = _progress(t, .22, .44);
    return MenuMotion._(
      spread: 1 - fold,
      rowScale: 1 - .6 * fold,
      rowOpacity: 1 - Curves.easeIn.transform(_progress(t, .1, .3)),
      rowBlur: 8 * fold,
      backdropOpacity: value <= 0
          ? 0
          : 1 - Curves.easeInOutCubic.transform(_progress(t, .04, .38)),
      barOpacity: _progress(t, .2, .32),
      barBlur: 9 * (1 - settle),
      barScale: 1 + .12 * (1 - settle),
    );
  }

  static double _progress(double t, double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);
}
