import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design/design.dart';

class FlagPainter extends CustomPainter {
  const FlagPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final stripe = size.height / 7;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    for (var i = 0; i < 7; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripe, size.width, stripe),
        Paint()..color = Palette.flagRed,
      );
    }
    final canton = Rect.fromLTWH(0, 0, size.width * .47, stripe * 4);
    canvas.drawRect(canton, Paint()..color = Palette.flagBlue);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 5; col++) {
        canvas.drawCircle(
          Offset(canton.width * (col + .5) / 5, canton.height * (row + .5) / 3),
          canton.height * .06,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarGlyphPainter extends CustomPainter {
  final Color color;
  const StarGlyphPainter({this.color = Palette.footerIcon});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 21, height: 22.4),
        const Radius.circular(10),
      ),
      Paint()..color = color,
    );
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? 6.1 : 3.5;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0
          ? star.moveTo(point.dx, point.dy)
          : star.lineTo(point.dx, point.dy);
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(star, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(StarGlyphPainter oldDelegate) => false;
}

class GearGlyphPainter extends CustomPainter {
  final Color color;
  const GearGlyphPainter({this.color = Palette.footerIcon});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final path = Path()..fillType = PathFillType.evenOdd;
    for (var i = 0; i <= 96; i++) {
      final angle = i / 96 * 2 * math.pi;
      final radius = 9.5 * (1 + .08 * math.cos(8 * angle));
      final point = center + Offset(math.sin(angle), -math.cos(angle)) * radius;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    path
      ..close()
      ..addOval(Rect.fromCircle(center: center, radius: 5.1));
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(GearGlyphPainter oldDelegate) => false;
}

/// Glyphs traced from zoomed reference captures, in points from the center.
abstract final class _Trace {
  static double rad(double degrees) => degrees * math.pi / 180;
}

/// The grammar card's badge: two heavy arrows circling a bolt.
class GrammarBadgePainter extends CustomPainter {
  final Color color;
  const GrammarBadgePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;
    final ring = Rect.fromCircle(center: Offset.zero, radius: 9);
    canvas.drawArc(ring, _Trace.rad(205), _Trace.rad(125), false, stroke);
    canvas.drawArc(ring, _Trace.rad(25), _Trace.rad(125), false, stroke);
    final join = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    for (final head in [
      Path()
        ..moveTo(6.6, -.2)
        ..lineTo(12.8, -.2)
        ..lineTo(9.7, 3.4)
        ..close(),
      Path()
        ..moveTo(-6.6, .2)
        ..lineTo(-12.8, .2)
        ..lineTo(-9.7, -3.4)
        ..close(),
    ]) {
      canvas.drawPath(head, fill);
      canvas.drawPath(head, join);
    }
    final bolt = Path()
      ..moveTo(1.6, -6.6)
      ..lineTo(-3.8, 1)
      ..lineTo(-.4, 1)
      ..lineTo(-1.6, 6.6)
      ..lineTo(3.8, -1)
      ..lineTo(.4, -1)
      ..close();
    canvas.drawPath(bolt, fill);
    canvas.drawPath(bolt, join..strokeWidth = .6);
  }

  @override
  bool shouldRepaint(GrammarBadgePainter oldDelegate) =>
      color != oldDelegate.color;
}

/// The conversation card's badge: a rounded bubble with three dots.
class ConversationBadgePainter extends CustomPainter {
  final Color color, dots;
  const ConversationBadgePainter({required this.color, required this.dots});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(.6, -1), width: 21, height: 18.4),
        const Radius.circular(8.4),
      ),
      paint,
    );
    final tail = Path()
      ..moveTo(-9.6, 2)
      ..lineTo(-10.2, 8.6)
      ..quadraticBezierTo(-6.4, 8.2, -3.4, 6)
      ..close();
    canvas.drawPath(tail, paint);
    for (final x in const [-3.9, .6, 5.1]) {
      canvas.drawCircle(Offset(x, -1), 1.35, Paint()..color = dots);
    }
  }

  @override
  bool shouldRepaint(ConversationBadgePainter oldDelegate) =>
      color != oldDelegate.color || dots != oldDelegate.dots;
}

/// Insight's four text lines, long and short in turn.
class TextLinesPainter extends CustomPainter {
  final Color color;
  const TextLinesPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final (i, end) in const [16.0, 10.0, 16.0, 10.0].indexed) {
      final y = 1.5 + i * 4.1;
      canvas.drawLine(Offset(.8, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(TextLinesPainter oldDelegate) =>
      color != oldDelegate.color;
}

class TrophyPainter extends CustomPainter {
  final Color color;
  const TrophyPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, 0);
    final fill = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(-5.4, .6)
        ..lineTo(5.4, .6)
        ..lineTo(5.4, 6)
        ..quadraticBezierTo(5, 10.6, 0, 11)
        ..quadraticBezierTo(-5, 10.6, -5.4, 6)
        ..close(),
      fill,
    );
    canvas.drawRect(const Rect.fromLTWH(-1.5, 10.5, 3, 3.6), fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3.8, 14, 7.6, 3.2),
        const Radius.circular(1),
      ),
      fill,
    );
    final handle = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawPath(
      Path()
        ..moveTo(-5, 2.2)
        ..lineTo(-7.2, 2.2)
        ..quadraticBezierTo(-7.2, 6.8, -4.2, 8),
      handle,
    );
    canvas.drawPath(
      Path()
        ..moveTo(5, 2.2)
        ..lineTo(7.2, 2.2)
        ..quadraticBezierTo(7.2, 6.8, 4.2, 8),
      handle,
    );
  }

  @override
  bool shouldRepaint(TrophyPainter oldDelegate) => color != oldDelegate.color;
}

/// A rounded warning triangle with a knocked-out mark.
class WarningPainter extends CustomPainter {
  final Color color;
  const WarningPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final triangle = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width - 1.6, size.height - 1.6)
      ..lineTo(1.6, size.height - 1.6)
      ..close();
    canvas.drawPath(triangle, Paint()..color = color);
    canvas.drawPath(
      triangle,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    final mark = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    canvas.drawLine(
      Offset(x, size.height * .36),
      Offset(x, size.height * .62),
      mark,
    );
    canvas.drawCircle(
      Offset(x, size.height * .8),
      1.15,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(WarningPainter oldDelegate) => color != oldDelegate.color;
}

/// Sign out: a dashed rounded box with a solid arrow leaving it.
class SignOutPainter extends CustomPainter {
  final Color color;
  const SignOutPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(1.5, 2);
    canvas.scale(.82);
    final dash = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    final box = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1, 3, 12, 14),
          const Radius.circular(3),
        ),
      );
    for (final metric in box.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 5.4) {
        canvas.drawPath(metric.extractPath(d, d + 3), dash);
      }
    }
    final arrow = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(9, 10), const Offset(17, 10), arrow);
    canvas.drawPath(
      Path()
        ..moveTo(15.5, 6)
        ..lineTo(20.6, 10)
        ..lineTo(15.5, 14)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(SignOutPainter oldDelegate) => color != oldDelegate.color;
}

/// A shield whose top edge has a shallow scallop.
class ShieldPainter extends CustomPainter {
  final Color color;
  const ShieldPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, 0);
    canvas.drawPath(
      Path()
        ..moveTo(0, 1)
        ..quadraticBezierTo(3, 3.4, 8.2, 3)
        ..lineTo(8.6, 9)
        ..quadraticBezierTo(8.4, 16, 0, 20)
        ..quadraticBezierTo(-8.4, 16, -8.6, 9)
        ..lineTo(-8.2, 3)
        ..quadraticBezierTo(-3, 3.4, 0, 1)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(ShieldPainter oldDelegate) => color != oldDelegate.color;
}
