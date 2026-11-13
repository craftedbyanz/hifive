import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../core/design/design.dart';
import '../../widgets/common.dart';
import '../../widgets/garden/garden_art.dart';
import 'home_menu_art.dart';

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

/// The glyph in a Home menu row: the streak flame, or an animated [MenuArt].
class HomeMenuGlyph extends StatelessWidget {
  final HomeMenuItem item;
  const HomeMenuGlyph({super.key, required this.item});
  @override
  Widget build(BuildContext context) => switch (item) {
    HomeMenuItem.streak => const StreakFlame(size: 26),
    HomeMenuItem.insight => const MenuArt(kind: MenuArtKind.sparkle),
    HomeMenuItem.plus => const MenuArt(kind: MenuArtKind.gem),
    HomeMenuItem.flashcards => const MenuArt(kind: MenuArtKind.cards),
    HomeMenuItem.game => const MenuArt(kind: MenuArtKind.blocks),
    HomeMenuItem.listen => const Icon(
      CupertinoIcons.headphones,
      size: 22,
      color: D.background,
    ),
    HomeMenuItem.focus => const Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: TreeArt(species: 'oak', size: 40, floating: false),
    ),
  };
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
