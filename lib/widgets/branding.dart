import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design/design.dart';

/// The hifive logo: five rounded bars, a hand raised for a high five and a
/// voice's sound wave at once, each in a study mode's color, on an ink tile.
/// [tile] false draws the bars alone, for the Android adaptive icon.
class AppLogo extends StatelessWidget {
  final double size;
  final bool tile;
  const AppLogo({super.key, required this.size, this.tile = true});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Hifive',
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: LogoPainter(tile: tile),
    ),
  );
}

/// Paints [AppLogo]; also used to render the app icons
/// (`tool/app_icons_test.dart`). The geometry is drawn on a 1024 grid.
class LogoPainter extends CustomPainter {
  /// Draws the ink tile under the bars.
  final bool tile;

  /// Rounds the tile's corners; the iOS icon is square, as iOS masks it.
  final bool rounded;

  /// Scales the bars about the centre, for an icon's safe zone.
  final double scale;
  const LogoPainter({this.tile = true, this.rounded = true, this.scale = 1});

  /// Each bar's left edge, top and bottom on the 1024 grid; all are 84 wide.
  static const _bars = [
    (222.0, 470.0),
    (346.0, 300.0),
    (470.0, 230.0),
    (594.0, 290.0),
    (718.0, 400.0),
  ];
  static const _barWidth = 84.0, _barBottom = 760.0;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 1024;
    canvas.save();
    canvas.scale(unit);
    if (tile) {
      const square = Rect.fromLTWH(0, 0, 1024, 1024);
      final ink = Paint()..color = D.ink;
      if (rounded) {
        canvas.drawRSuperellipse(
          RSuperellipse.fromRectAndRadius(square, const Radius.circular(230)),
          ink,
        );
      } else {
        canvas.drawRect(square, ink);
      }
    }
    // The bars stand on one baseline; [scale] shrinks them about their
    // block's centre, 17 units above the tile's middle, as drawn.
    canvas.translate(512, 495);
    canvas.scale(scale);
    canvas.translate(-512, -495);
    for (final (i, (left, top)) in _bars.indexed) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          left,
          top,
          left + _barWidth,
          _barBottom,
          const Radius.circular(_barWidth / 2),
        ),
        Paint()..color = Palette.logoBars[i],
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoPainter old) =>
      old.tile != tile || old.rounded != rounded || old.scale != scale;
}

class Flower extends StatelessWidget {
  final double size;

  /// Deeper petals for use on a white background.
  final bool strong;
  const Flower({super.key, this.size = 48, this.strong = false});
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _FlowerPainter(strong: strong),
  );
}

class _FlowerPainter extends CustomPainter {
  final bool strong;
  const _FlowerPainter({this.strong = false});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, c = size.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    final area = Rect.fromCircle(center: Offset.zero, radius: w / 2);
    // One gradient across the whole flower, so petals overlap into a deep center.
    final petals = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Palette.flowerTop, Palette.flowerBottom],
      ).createShader(area);
    final petal = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -w * .19),
            width: w * .36,
            height: w * .62,
          ),
          Radius.circular(w * .18),
        ),
      );
    canvas.saveLayer(area, Paint());
    for (var i = 0; i < 8; i++) {
      canvas.drawPath(
        petal.transform(Matrix4.rotationZ(i * math.pi / 4).storage),
        petals..color = Colors.white.withValues(alpha: strong ? .85 : .6),
      );
    }
    canvas.restore();
    final r = w * .2, q = r * .1;
    final star = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(q, -q, r, 0)
      ..quadraticBezierTo(q, q, 0, r)
      ..quadraticBezierTo(-q, q, -r, 0)
      ..quadraticBezierTo(-q, -q, 0, -r);
    canvas.drawPath(
      star,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Palette.flowerStarEnd],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
