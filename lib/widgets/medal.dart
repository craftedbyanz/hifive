import 'dart:math';

import 'package:flutter/material.dart';

import '../core/design.dart';

/// The gold rosette shown on completion: flashcard sessions and lessons.
class MedalPainter extends CustomPainter {
  const MedalPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.width / 2);
    final ribbon = Paint()..color = Palette.medalRibbon;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx + side * 10, c.dy + 30)
          ..lineTo(c.dx + side * 36, c.dy + 30)
          ..lineTo(c.dx + side * 39, size.height - 18)
          ..lineTo(c.dx + side * 28, size.height - 26)
          ..lineTo(c.dx + side * 18, size.height - 10)
          ..close(),
        ribbon,
      );
    }
    // Twelve soft scallops around the rim.
    final rim = Path();
    const lobes = 12;
    for (var i = 0; i <= 240; i++) {
      final a = i / 240 * 2 * pi;
      final r = size.width * .47 + 2.6 * cos(lobes * a);
      final p = c + Offset(sin(a), -cos(a)) * r;
      i == 0 ? rim.moveTo(p.dx, p.dy) : rim.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(rim..close(), Paint()..color = Palette.medalGold);
    canvas.drawCircle(c, size.width * .36, Paint()..color = Colors.white);
    canvas.drawCircle(
      c,
      size.width * .31,
      Paint()..color = Palette.medalOrange,
    );
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? size.width * .16 : size.width * .075;
      final a = i * pi / 5;
      final p = c + Offset(sin(a), -cos(a)) * r;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = Palette.medalGold);
  }

  @override
  bool shouldRepaint(MedalPainter oldDelegate) => false;
}

/// Gold confetti frozen around the medal, as on the lesson result
/// (survey 175), where the burst is part of the still illustration.
class StillConfettiPainter extends CustomPainter {
  const StillConfettiPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(11);
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 90; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final reach = 66 + random.nextDouble() * (size.width / 2 - 36);
      final side = 5 + random.nextDouble() * 7;
      final p = c + Offset(cos(angle) * reach, sin(angle) * reach * .95);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(random.nextDouble() * pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: side, height: side * .62),
        Paint()
          ..color =
              (random.nextBool() ? Palette.medalGold : Palette.medalOrange)
                  .withValues(alpha: .65 + random.nextDouble() * .35),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
