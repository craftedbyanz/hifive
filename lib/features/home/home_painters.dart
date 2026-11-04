import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../core/design.dart';

export '../../widgets/glyphs.dart';

class StreakBarsPainter extends CustomPainter {
  const StreakBarsPainter();
  @override
  void paint(Canvas c, Size s) {
    for (var i = 0; i < 7; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 5, 2, 3, 8),
          const Radius.circular(1),
        ),
        Paint()..color = D.muted.withValues(alpha: .45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AiOrb extends StatelessWidget {
  final double size;
  final Animation<double>? animation;
  const AiOrb({super.key, this.size = 30, this.animation});
  @override
  Widget build(BuildContext context) => animation == null
      ? CustomPaint(size: Size.square(size), painter: const AiOrbPainter())
      : AnimatedBuilder(
          animation: animation!,
          builder: (_, _) => CustomPaint(
            size: Size.square(size),
            painter: AiOrbPainter(phase: animation!.value),
          ),
        );
}

class AiOrbPainter extends CustomPainter {
  final double phase;
  const AiOrbPainter({this.phase = 0});
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width / 2, s.height / 2);
    c.rotate(math.sin(phase * 2 * math.pi) * .35);
    c.translate(-s.width / 2, -s.height / 2);
    c.drawOval(
      Rect.fromLTWH(
        2 + math.sin(phase * 2 * math.pi) * 2,
        1,
        s.width * (.73 + .1 * math.sin(phase * 2 * math.pi)),
        s.height * .82,
      ),
      Paint()..color = Palette.orbBack.withValues(alpha: .65),
    );
    c.drawOval(
      Rect.fromLTWH(
        3 - math.sin(phase * 2 * math.pi) * 2,
        6 + math.cos(phase * 2 * math.pi) * 2,
        s.width * .82,
        s.height * .72,
      ),
      Paint()..color = Palette.orbMiddle.withValues(alpha: .6),
    );
    c.drawOval(
      Rect.fromLTWH(1, 10, s.width * .76, s.height * .65),
      Paint()..color = Palette.orbFront.withValues(alpha: .4),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(AiOrbPainter oldDelegate) => oldDelegate.phase != phase;
}

class HomeMenuGlyph extends StatelessWidget {
  final String label;
  const HomeMenuGlyph({super.key, required this.label});
  @override
  Widget build(BuildContext context) => label == 'Chuỗi của tôi'
      ? const Icon(
          CupertinoIcons.flame_fill,
          size: 23,
          color: Palette.menuGlyph,
        )
      : SizedBox.square(
          dimension: 24,
          child: CustomPaint(painter: HomeMenuGlyphPainter(label)),
        );
}

/// Menu glyphs traced from zoomed reference captures, in points from the center.
class HomeMenuGlyphPainter extends CustomPainter {
  final String kind;
  const HomeMenuGlyphPainter(this.kind);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final fill = Paint()..color = Palette.menuGlyph;
    switch (kind) {
      case 'Insight':
        for (final (center, radius) in const [
          (Offset(3.5, -1.8), 6.6),
          (Offset(-6, -6), 4.2),
          (Offset(-4.8, 4.2), 5.3),
        ]) {
          canvas.drawPath(_lobes(center, radius), fill);
        }
      case 'Nâng cấp Hifive Plus':
        final fin = Path()
          ..moveTo(-3.8, 4)
          ..lineTo(-9.6, 7.2)
          ..lineTo(-7.2, 7.7)
          ..lineTo(-6.4, 10.4)
          ..lineTo(-2.4, 5.8)
          ..close();
        final soft = Paint()
          ..color = Palette.menuGlyph
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..strokeJoin = StrokeJoin.round;
        for (final path in [
          fin,
          fin.transform(Matrix4.diagonal3Values(-1, 1, 1).storage),
        ]) {
          canvas.drawPath(path, fill);
          canvas.drawPath(path, soft);
        }
        canvas.saveLayer(null, Paint());
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: const Offset(0, -3),
              width: 14.8,
              height: 14.2,
            ),
            const Radius.circular(6.4),
          ),
          fill,
        );
        canvas.drawPath(
          _star(const Offset(0, -3), 4, 2.2),
          Paint()
            ..blendMode = BlendMode.clear
            ..strokeWidth = .8
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.fill,
        );
        canvas.restore();
      case 'Học flashcard':
        canvas.saveLayer(null, Paint());
        canvas.drawRRect(
          RRect.fromLTRBR(-2.1, -9.8, 8, 5.3, const Radius.circular(4)),
          fill,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(-9, -6.8, 4, 10.4, const Radius.circular(4)),
          Paint()..blendMode = BlendMode.clear,
        );
        canvas.restore();
        canvas.drawRRect(
          RRect.fromLTRBR(-7.9, -5.8, 3, 9.4, const Radius.circular(3.2)),
          fill,
        );
      default:
        final fillStroke = Paint()
          ..color = Palette.menuGlyph
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round;
        final body = Paint()
          ..color = Palette.menuGlyph
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round;
        for (final turn in [0.0, math.pi]) {
          canvas.save();
          canvas.rotate(turn);
          canvas.drawLine(
            const Offset(-2.2, -2.9),
            const Offset(3.4, -2.9),
            body,
          );
          final head = Path()
            ..moveTo(3.2, -7.8)
            ..lineTo(9, -2.9)
            ..lineTo(3.2, 2)
            ..close();
          canvas.drawPath(head, fill);
          canvas.drawPath(head, fillStroke);
          canvas.restore();
        }
    }
    canvas.restore();
  }

  /// A soft four-lobed star.
  static Path _lobes(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i <= 72; i++) {
      final angle = i / 72 * 2 * math.pi;
      final r = radius * (.8 + .2 * math.cos(4 * angle));
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  static Path _star(Offset center, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(HomeMenuGlyphPainter oldDelegate) =>
      kind != oldDelegate.kind;
}

/// Footer glyphs drawn from zoomed reference captures, on a 24 × 24 box.
class RotateGlyphPainter extends CustomPainter {
  const RotateGlyphPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = Palette.footerIcon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 8.6),
      162 * math.pi / 180,
      -292 * math.pi / 180,
      false,
      paint,
    );
    final head = Path()
      ..moveTo(center.dx - 11, center.dy - 7.6)
      ..lineTo(center.dx - 2, center.dy - 3.2)
      ..lineTo(center.dx - 7.4, center.dy - .4)
      ..close();
    canvas.drawPath(head, paint..strokeWidth = 3);
    canvas.drawPath(head, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(RotateGlyphPainter oldDelegate) => false;
}
