import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design/design.dart';

/// The app's logo as the reference draws it on white: long overlapping petals,
/// deepening toward the middle, around a white four-point star.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, required this.size});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _AppLogoPainter());
}

class _AppLogoPainter extends CustomPainter {
  const _AppLogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final petal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Palette.logoTop, Palette.logoMiddle, Palette.logoBottom],
      ).createShader(rect)
      ..color = Colors.white.withValues(alpha: .62);
    final w = size.width;
    final c = size.center(Offset.zero);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final along = Offset(math.sin(angle), -math.cos(angle)) * (w * .25);
      canvas.save();
      canvas.translate(c.dx + along.dx, c.dy + along.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w * .34, height: w * .5),
        petal,
      );
      canvas.restore();
    }
    final r = w * .21;
    const k = .16;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + r * k, c.dy - r * k, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + r * k, c.dy + r * k, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - r * k, c.dy + r * k, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - r * k, c.dy - r * k, c.dx, c.dy - r)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_AppLogoPainter oldDelegate) => false;
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
