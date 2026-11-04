import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';

/// The small artwork on the seven Hifive 101 cards, traced from zoomed
/// reference captures on a 160 × 120 canvas.
class HomeMiniArtwork extends CustomPainter {
  final int index;
  const HomeMiniArtwork(this.index);

  static const _tints = [
    Palette.miniArtPurple,
    Palette.magenta,
    D.green,
    D.blue,
    Palette.artOrange,
    Palette.helpTeal,
    Palette.artOrange,
  ];

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 160, s.height / 120);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 160, 120),
      Paint()
        ..shader = RadialGradient(
          colors: [
            _tints[index].withValues(alpha: .05),
            _tints[index].withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 160, 120)),
    );
    switch (index) {
      case 0:
        _modes(c);
      case 1:
        _assistant(c);
      case 2:
        _generator(c);
      case 3:
        _deck(c);
      case 4:
        _progress(c);
      case 5:
        _review(c);
      default:
        _letters(c);
    }
    c.restore();
  }

  void _box(Canvas c, Rect r, double radius, Color color) => c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius)),
    Paint()..color = color,
  );

  void _shadow(Canvas c, Rect r, double radius, Color color, double blur) =>
      c.drawRRect(
        RRect.fromRectAndRadius(
          r.translate(0, blur / 3),
          Radius.circular(radius),
        ),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );

  void _icon(Canvas c, IconData icon, Offset center, double size, Color ink) {
    final p = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(c, center - Offset(p.width / 2, p.height / 2));
  }

  void _sparkle(Canvas c, Offset o, double r, Color color) {
    final q = r * .14;
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - r)
        ..quadraticBezierTo(o.dx + q, o.dy - q, o.dx + r, o.dy)
        ..quadraticBezierTo(o.dx + q, o.dy + q, o.dx, o.dy + r)
        ..quadraticBezierTo(o.dx - q, o.dy + q, o.dx - r, o.dy)
        ..quadraticBezierTo(o.dx - q, o.dy - q, o.dx, o.dy - r),
      Paint()..color = color,
    );
  }

  void _modes(Canvas c) {
    const color = Palette.miniArtPurple;
    c.save();
    c.translate(80.5, 61.6);
    c.rotate(-.082);
    const pill = Rect.fromLTWH(-52, -19.5, 104, 39);
    _shadow(c, pill, 19.5, color.withValues(alpha: .14), 8);
    _box(c, pill, 19.5, Colors.white);
    c.restore();
    for (final (center, icon) in const [
      (Offset(48.3, 64.3), CupertinoIcons.book_fill),
      (Offset(112.3, 58.7), CupertinoIcons.chat_bubble_fill),
    ]) {
      c.drawCircle(center, 12, Paint()..color = Palette.artPurpleSoft);
      _icon(c, icon, center, 14, Palette.artPurpleIcon);
    }
    const middle = Offset(80.3, 61.3);
    c.drawCircle(middle, 13.3, Paint()..color = color);
    _icon(c, CupertinoIcons.bolt_fill, middle, 15, Colors.white);
  }

  void _assistant(Canvas c) {
    const top = Rect.fromLTRB(40.3, 23.7, 140.7, 59.3);
    _shadow(c, top, 13, Palette.magenta.withValues(alpha: .08), 7);
    _box(c, top, 13, Colors.white);
    _sparkle(c, const Offset(57.8, 42.3), 6, Palette.magenta);
    _sparkle(c, const Offset(53.8, 38.3), 2.3, Palette.magenta);
    _sparkle(c, const Offset(57.3, 35.3), 1.6, Palette.magenta);
    _box(
      c,
      const Rect.fromLTRB(70.3, 38.7, 130.3, 44.3),
      3,
      Palette.artPinkLine,
    );
    final bottom = RRect.fromRectAndRadius(
      const Rect.fromLTRB(25, 67.3, 135.7, 99.3),
      const Radius.circular(16),
    );
    c.drawRRect(bottom, Paint()..color = Palette.artPinkFill);
    c.drawRRect(
      bottom,
      Paint()
        ..color = Palette.artPinkBorder
        ..style = PaintingStyle.stroke,
    );
    _box(c, const Rect.fromLTRB(33.3, 81.7, 73.7, 85.7), 2, Palette.artPinkBar);
    const send = Offset(119.7, 83.3);
    c.drawCircle(send, 8, Paint()..color = Palette.magenta);
    _icon(c, Icons.arrow_upward_rounded, send, 12, Colors.white);
  }

  void _generator(Canvas c) {
    final top = RRect.fromRectAndRadius(
      const Rect.fromLTRB(28.3, 20.7, 79, 47.7),
      const Radius.circular(13.5),
    );
    c.drawRRect(top, Paint()..color = Palette.artGreenFill);
    c.drawRRect(
      top,
      Paint()
        ..color = Palette.artGreenBorder
        ..style = PaintingStyle.stroke,
    );
    _box(c, const Rect.fromLTRB(38.7, 29, 69, 32.7), 2, Palette.artGreenBar);
    _box(c, const Rect.fromLTRB(38.7, 35.7, 59, 39.7), 2, Palette.artGreenBar2);
    _icon(
      c,
      Icons.arrow_downward_rounded,
      const Offset(80.7, 61.5),
      12,
      Palette.artGreenBar,
    );
    const bottom = Rect.fromLTRB(78, 75.7, 133, 102.3);
    _shadow(c, bottom, 13.3, D.green.withValues(alpha: .28), 5);
    _box(c, bottom, 13.3, D.green);
    _box(c, const Rect.fromLTRB(87.7, 83.7, 123, 87.7), 2, Colors.white);
    _box(
      c,
      const Rect.fromLTRB(98, 90.7, 123, 94.7),
      2,
      Colors.white.withValues(alpha: .6),
    );
  }

  void _deck(Canvas c) {
    void sheet(double angle, double dx) {
      c.save();
      c.translate(79.3 + dx, 62);
      c.rotate(angle);
      _box(c, const Rect.fromLTWH(-27, -30, 54, 60), 7, Palette.artBlueSheet);
      c.restore();
    }

    sheet(-.12, -7);
    sheet(.1, 7);
    c.save();
    c.translate(79.7, 61.4);
    c.rotate(-.02);
    const front = Rect.fromLTWH(-27, -34.7, 54, 69.4);
    _shadow(c, front, 8, D.blue.withValues(alpha: .1), 6);
    final card = RRect.fromRectAndRadius(front, const Radius.circular(8));
    c.drawRRect(card, Paint()..color = Colors.white);
    c.drawRRect(
      card,
      Paint()
        ..color = Palette.artBlueSheet
        ..style = PaintingStyle.stroke,
    );
    c.drawCircle(
      const Offset(0, -7.4),
      10,
      Paint()..color = Palette.artBlueDisc,
    );
    c.restore();
    c.save();
    c.translate(80.3, 72.5);
    c.rotate(-.05);
    _box(c, const Rect.fromLTWH(-12, -1.5, 24, 3), 1.5, Palette.artBlueSheet);
    _box(c, const Rect.fromLTWH(-8, 4.7, 16, 2.6), 1.3, Palette.artBlueDisc);
    c.restore();
  }

  void _progress(Canvas c) {
    c.drawCircle(
      const Offset(80, 63),
      30,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Palette.artOrangeGlow.withValues(alpha: .7),
                Palette.artOrangeGlow.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: const Offset(80, 63), radius: 30),
            ),
    );
    for (final (left, top, color) in const [
      (57.3, 70.7, Palette.artOrangeFaint),
      (67.7, 64.7, Palette.artOrangeLight),
      (77.7, 58.7, Palette.artOrangeMedium),
      (87.7, 50.7, Palette.artOrange),
    ]) {
      _box(c, Rect.fromLTRB(left, top, left + 6, 82.3), 2, color);
    }
    _icon(
      c,
      CupertinoIcons.flame_fill,
      const Offset(103.3, 45),
      16,
      Palette.artOrange,
    );
  }

  void _review(Canvas c) {
    const center = Offset(80.3, 61.3);
    c.drawCircle(center, 15, Paint()..color = Palette.artTealDisc);
    c.drawCircle(center, 4, Paint()..color = Palette.helpTeal);
    final arc = Paint()
      ..color = Palette.artTealArc
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final ring = Rect.fromCircle(center: center, radius: 25.5);
    double rad(double degrees) => degrees * math.pi / 180;
    c.drawArc(ring, rad(-85), rad(75), false, arc);
    c.drawArc(ring, rad(-129), rad(-77), false, arc);
    c.drawArc(ring, rad(110), rad(-76), false, arc);
    c.drawCircle(
      const Offset(98.3, 43.7),
      3,
      Paint()..color = Palette.helpTeal,
    );
  }

  void _letters(Canvas c) {
    for (final (letter, center, angle, filled) in const [
      ('C', Offset(46, 63.3), -.1, true),
      ('A', Offset(68.3, 58.3), .06, false),
      ('T', Offset(94, 62.7), -.03, false),
      ('S', Offset(114.3, 61.3), .06, false),
    ]) {
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(angle);
      final tile = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 20, height: 20),
        const Radius.circular(5),
      );
      c.drawRRect(
        tile,
        Paint()..color = filled ? Palette.artOrange : Palette.artOrangeFill,
      );
      if (!filled) {
        c.drawRRect(
          tile,
          Paint()
            ..color = Palette.artOrangeBorder
            ..style = PaintingStyle.stroke,
        );
      }
      final p = TextPainter(
        text: TextSpan(
          text: letter,
          style: D.text(
            13,
            weight: FontWeight.w700,
            height: 1,
            color: filled ? Colors.white : Palette.artOrange,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(c, Offset(-p.width / 2, -p.height / 2));
      c.restore();
    }
    _icon(
      c,
      Icons.touch_app_rounded,
      const Offset(116, 76.7),
      11,
      Palette.artOrangeHand,
    );
  }

  @override
  bool shouldRepaint(HomeMiniArtwork oldDelegate) => oldDelegate.index != index;
}
