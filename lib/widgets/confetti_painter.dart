import 'dart:math';

import 'package:flutter/material.dart';

import '../core/design/design.dart';

class ConfettiPainter extends CustomPainter {
  final double progress;
  ConfettiPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(47);
    for (var i = 0; i < 65; i++) {
      final x = random.nextDouble() * size.width,
          start = random.nextDouble() * size.height * .5;
      final y = start + progress * size.height * .65;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 10 + i);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 4 + random.nextDouble() * 5,
          height: 10,
        ),
        Paint()
          ..color = [
            D.blue,
            D.lime,
            D.orange,
            D.purple,
            D.turquoise,
          ][i % 5].withValues(alpha: 1 - progress * .5),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
