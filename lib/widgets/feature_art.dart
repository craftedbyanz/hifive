import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/design/design.dart';

// The art of hifive's own Hifive 101 articles, on their Home cards and at
// the top of each article. Each fills the space it is given.

/// Hifive 101's garden and focus, abstract like the other cards: a focus
/// timer's ring running round a leaf, and a pill of time below.
class GardenFeatureArt extends StatelessWidget {
  const GardenFeatureArt({super.key});

  @override
  Widget build(BuildContext context) =>
      const _Card(tint: D.green, painter: _GardenPainter());
}

/// Hifive 101's listening, abstract like the other cards: a small player
/// with a play button beside a sound wave, partly heard, and a speed chip.
class ListenFeatureArt extends StatelessWidget {
  const ListenFeatureArt({super.key});

  @override
  Widget build(BuildContext context) =>
      const _Card(tint: Palette.menuListen, painter: _ListenPainter());
}

/// Hifive 101's community, abstract like the other cards: three faces
/// side by side, a chat bubble with a heart, and a shared bar of progress.
class CommunityFeatureArt extends StatelessWidget {
  const CommunityFeatureArt({super.key});

  @override
  Widget build(BuildContext context) =>
      const _Card(tint: D.violet, painter: _CommunityPainter());
}

/// A card's art: a faint glow of [tint] behind [painter]'s 160 by 120 stage.
class _Card extends StatelessWidget {
  final Color tint;
  final CustomPainter painter;
  const _Card({required this.tint, required this.painter});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      gradient: RadialGradient(
        colors: [tint.withValues(alpha: .06), tint.withValues(alpha: 0)],
      ),
    ),
    child: _Scene(child: CustomPaint(painter: painter)),
  );
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

class _GardenPainter extends CustomPainter {
  const _GardenPainter();

  @override
  void paint(Canvas c, Size size) {
    const green = D.green;
    final pale = Color.lerp(Colors.white, green, .16)!;
    const center = Offset(80, 50);
    // The timer: a white face, a pale track and the time run so far.
    final face = Rect.fromCircle(center: center, radius: 27);
    _shadow(c, face, 27, green.withValues(alpha: .16), 8);
    c.drawCircle(center, 27, Paint()..color = Colors.white);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    c
      ..drawCircle(center, 20, ring..color = pale)
      ..drawArc(
        Rect.fromCircle(center: center, radius: 20),
        -math.pi / 2,
        math.pi * 2 * .68,
        false,
        ring..color = green,
      );
    const end = -math.pi / 2 + math.pi * 2 * .68;
    c.drawCircle(
      center + Offset(math.cos(end), math.sin(end)) * 20,
      3.6,
      Paint()..color = Colors.white,
    );
    c.drawCircle(
      center + Offset(math.cos(end), math.sin(end)) * 20,
      2.2,
      Paint()..color = green,
    );
    c.drawCircle(center, 11, Paint()..color = green);
    _icon(c, Icons.eco_rounded, center, 13, Colors.white);
    // The time left, as a pill of two bars.
    const pill = Rect.fromLTRB(56, 88, 104, 102);
    _shadow(c, pill, 7, green.withValues(alpha: .12), 5);
    _box(c, pill, 7, Colors.white);
    _box(c, const Rect.fromLTRB(64, 93.2, 79, 96.8), 1.8, green);
    _box(c, const Rect.fromLTRB(83, 93.2, 96, 96.8), 1.8, pale);
    _sparkle(c, const Offset(121, 30), 5.5, green.withValues(alpha: .7));
    _sparkle(c, const Offset(127, 42), 2.4, green.withValues(alpha: .5));
    _sparkle(c, const Offset(38, 66), 3.2, green.withValues(alpha: .45));
  }

  @override
  bool shouldRepaint(_GardenPainter old) => false;
}

class _ListenPainter extends CustomPainter {
  const _ListenPainter();

  /// The wave's bars, as shares of the tallest; the first [_heard] are
  /// played.
  static const _bars = [
    .35,
    .6,
    .9,
    .55,
    1.0,
    .7,
    .4,
    .8,
    .5,
    .95,
    .6,
    .3,
    .55,
    .4,
  ];
  static const _heard = 8;

  @override
  void paint(Canvas c, Size size) {
    const pink = Palette.menuListen;
    final pale = Color.lerp(Colors.white, pink, .2)!;
    // The player.
    const card = Rect.fromLTRB(30, 42, 130, 82);
    _shadow(c, card, 20, pink.withValues(alpha: .14), 8);
    _box(c, card, 20, Colors.white);
    const play = Offset(51, 62);
    c.drawCircle(play, 12.5, Paint()..color = pink);
    _icon(
      c,
      CupertinoIcons.play_fill,
      play + const Offset(1.2, 0),
      12,
      Colors.white,
    );
    for (final (i, h) in _bars.indexed) {
      final x = 70.0 + i * 4.1, half = 3 + h * 9;
      _box(
        c,
        Rect.fromLTRB(x, 62 - half, x + 2.4, 62 + half),
        1.2,
        i < _heard ? pink : pale,
      );
    }
    // A speed chip above, and the episode's progress below.
    const chip = Rect.fromLTRB(100, 22, 128, 35);
    _shadow(c, chip, 6.5, pink.withValues(alpha: .1), 4);
    _box(c, chip, 6.5, Colors.white);
    _box(c, const Rect.fromLTRB(106, 27, 114, 30), 1.5, pink);
    _box(c, const Rect.fromLTRB(116, 27, 122, 30), 1.5, pale);
    _box(c, const Rect.fromLTRB(46, 94, 114, 98), 2, pale);
    _box(c, const Rect.fromLTRB(46, 94, 84, 98), 2, pink);
    _sparkle(c, const Offset(36, 30), 4.5, pink.withValues(alpha: .55));
    _sparkle(c, const Offset(44, 24), 2, pink.withValues(alpha: .4));
  }

  @override
  bool shouldRepaint(_ListenPainter old) => false;
}

class _CommunityPainter extends CustomPainter {
  const _CommunityPainter();

  @override
  void paint(Canvas c, Size size) {
    const violet = D.violet;
    final pale = Color.lerp(Colors.white, violet, .18)!;
    final soft = Color.lerp(Colors.white, violet, .42)!;
    // A chat bubble with a heart, above and to the right.
    const bubble = Rect.fromLTRB(88, 16, 134, 40);
    _shadow(c, bubble, 12, violet.withValues(alpha: .12), 6);
    _box(c, bubble, 12, Colors.white);
    c.drawPath(
      Path()
        ..moveTo(96, 38)
        ..lineTo(93, 45)
        ..lineTo(103, 39)
        ..close(),
      Paint()..color = Colors.white,
    );
    _icon(c, CupertinoIcons.heart_fill, const Offset(100, 28), 10, violet);
    _box(c, const Rect.fromLTRB(108, 24.5, 126, 27.5), 1.5, pale);
    _box(c, const Rect.fromLTRB(108, 30.5, 120, 33.5), 1.5, soft);
    // Three faces side by side, the middle one in colour.
    for (final (x, y, r, strong) in const [
      (54.0, 66.0, 13.0, false),
      (106.0, 66.0, 13.0, false),
      (80.0, 62.0, 16.0, true),
    ]) {
      final o = Offset(x, y);
      if (strong) {
        _shadow(
          c,
          Rect.fromCircle(center: o, radius: r),
          r,
          violet.withValues(alpha: .25),
          6,
        );
      }
      c
        ..drawCircle(o, r + 2.5, Paint()..color = Colors.white)
        ..drawCircle(o, r, Paint()..color = strong ? violet : pale);
      _icon(
        c,
        CupertinoIcons.person_fill,
        o + const Offset(0, 1),
        r * 1.15,
        strong ? Colors.white : soft,
      );
    }
    // Progress they share.
    const track = Rect.fromLTRB(50, 92, 110, 97);
    _box(c, track, 2.5, pale);
    _box(c, const Rect.fromLTRB(50, 92, 92, 97), 2.5, violet);
    _sparkle(c, const Offset(36, 36), 4.5, violet.withValues(alpha: .55));
    _sparkle(c, const Offset(42, 46), 2, violet.withValues(alpha: .4));
  }

  @override
  bool shouldRepaint(_CommunityPainter old) => false;
}

/// Draws its [child] on a 160 by 120 stage, scaled to fit the space, so the
/// art keeps its proportions from a Home card to the top of an article.
class _Scene extends StatelessWidget {
  final Widget child;
  const _Scene({required this.child});

  @override
  Widget build(BuildContext context) =>
      FittedBox(child: SizedBox(width: 160, height: 120, child: child));
}
