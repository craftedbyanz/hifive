import 'dart:math' as math;

/// Home menu animation values at one moment.
///
/// Row position, backdrop timing and durations come from one menu open and
/// close in the 60 fps reference recording of 2 November 2026. Row blur and the
/// bottom bar values are estimates read from the same frames.
class MenuMotion {
  static const duration = Duration(milliseconds: 450);
  static const _seconds = .45;

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
  }) : rowScale = .6 + .4 * spread;

  factory MenuMotion.at(double value, {required bool closing}) =>
      closing ? MenuMotion._closing(value) : MenuMotion._opening(value);

  factory MenuMotion._opening(double value) {
    final t = value * _seconds, rows = t - rowDelay;
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
      backdropOpacity: value >= 1 ? 1 : _progress(rows, .03, .13),
      barOpacity: 1 - hide,
      barBlur: 6 * hide,
    );
  }

  factory MenuMotion._closing(double value) {
    final t = (1 - value) * _seconds;
    final spread = 1 - math.pow(_progress(t, .035, .105), 1.5).toDouble();
    final settle = _progress(t, .1, .35);
    return MenuMotion._(
      spread: spread,
      rowOpacity: 1 - _progress(t, .04, .11),
      rowBlur: 10 * (1 - spread),
      backdropOpacity: value <= 0
          ? 0
          : t < .085
          ? 1
          : math.exp(-20 * (t - .085)),
      barOpacity: _progress(t, .1, .2),
      barBlur: 6 * (1 - settle),
      barScale: 1 + .12 * (1 - settle),
    );
  }

  static double _progress(double t, double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);
}
