import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design/design.dart';
import 'ambient.dart';

/// The Home menu's animated icons, also used on the Hifive 101 cards. They share the streak flame's look (one
/// hue, dark on top, with a pale core) and its easing, and each makes one
/// movement per loop, then rests.
enum MenuArtKind {
  /// Insight: a big sparkle breathes and turns while a small one twinkles.
  sparkle(Duration(milliseconds: 2600), 0),

  /// Plus: a cut gem floats; a glint flashes at its corner.
  gem(Duration(milliseconds: 3000), 0),

  /// Flashcards: the two plain cards behind the front one part and close.
  cards(Duration(milliseconds: 3000), 0),

  /// FlowLetter: a block is carried in, the two below part, and it drops in.
  blocks(Duration(milliseconds: 3600), .75),

  /// Garden: a sprout stretches up, its two leaves sway open and a glint
  /// twinkles by the top leaf.
  sprout(Duration(milliseconds: 3200), 0),

  /// Listening: the headphones nod to a beat while two notes float up.
  headphones(Duration(milliseconds: 3000), 0);

  final Duration loop;

  /// The point of the loop shown when motion is off: a complete picture.
  final double rest;
  const MenuArtKind(this.loop, this.rest);
}

/// One menu icon, [size] points square. It loops only under [AmbientMotion],
/// like the flame, and otherwise holds its [MenuArtKind.rest] frame.
class MenuArt extends StatefulWidget {
  final MenuArtKind kind;
  final double size;
  const MenuArt({super.key, required this.kind, this.size = 30});

  @override
  State<MenuArt> createState() => _MenuArtState();
}

class _MenuArtState extends State<MenuArt> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: widget.kind.loop,
    value: widget.kind.rest,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AmbientMotion.of(context)) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop
        ..stop()
        ..value = widget.kind.rest;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    key: ValueKey('menu-art-${widget.kind.name}'),
    dimension: widget.size,
    child: CustomPaint(painter: MenuArtPainter(widget.kind, _loop)),
  );
}

/// Draws a [MenuArtKind] on a 48 × 48 grid at the point [t] of its loop.
class MenuArtPainter extends CustomPainter {
  final MenuArtKind kind;
  final Animation<double> t;
  MenuArtPainter(this.kind, this.t) : super(repaint: t);

  /// The flame's easing (its Lottie in/out handles are .333 and .667).
  static const _ease = Cubic(.333, 0, .667, 1);

  /// The value at [x] of a track of (time, value) keys, eased between keys.
  static double key(double x, List<(double, double)> keys) {
    if (x <= keys.first.$1) return keys.first.$2;
    for (var i = 1; i < keys.length; i++) {
      final (t1, v1) = keys[i];
      if (x <= t1) {
        final (t0, v0) = keys[i - 1];
        final p = t1 == t0 ? 1.0 : (x - t0) / (t1 - t0);
        return v0 + (v1 - v0) * _ease.transform(p);
      }
    }
    return keys.last.$2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final x = t.value;
    switch (kind) {
      case MenuArtKind.sparkle:
        _sparkles(canvas, x);
      case MenuArtKind.gem:
        _gem(canvas, x);
      case MenuArtKind.cards:
        _cards(canvas, x);
      case MenuArtKind.blocks:
        _blocks(canvas, x);
      case MenuArtKind.sprout:
        _sprout(canvas, x);
      case MenuArtKind.headphones:
        _headphones(canvas, x);
    }
    canvas.restore();
  }

  static Paint _body(ArtTone tone, Rect r) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: tone.bodyColors,
      stops: ArtTone.body,
    ).createShader(r);

  static Paint _core(ArtTone tone, Rect r) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: tone.coreColors,
      stops: ArtTone.coreStops,
    ).createShader(r);

  static void _round(Canvas c, Rect r, double radius, Paint paint) =>
      c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), paint);

  /// Turns [canvas] by [degrees] and scales it about [origin].
  static void _about(
    Canvas canvas,
    Offset origin, {
    double degrees = 0,
    double sx = 1,
    double sy = 1,
  }) {
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.scale(sx, sy);
    canvas.translate(-origin.dx, -origin.dy);
  }

  /// [path] filled with [paint] and outlined in it [width] wide, which
  /// rounds its points softly.
  static void _soft(Canvas c, Path path, Paint paint, double width) {
    c.drawPath(path, paint);
    c.drawPath(
      path,
      Paint()
        ..shader = paint.shader
        ..color = paint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _sparkles(Canvas c, double x) {
    const tone = ArtTone.insight;
    final breathe = key(x, const [(0, 0), (.5, 1), (1, 0)]);

    c.save();
    _about(
      c,
      const Offset(22, 26),
      degrees: 12 * breathe,
      sx: 1 - .14 * breathe,
      sy: 1 - .14 * breathe,
    );
    final big = _sparkle(const Offset(22, 26), 17);
    _soft(c, big, _body(tone, big.getBounds()), 2.4);
    final bigCore = _sparkle(const Offset(22, 27.5), 8.5);
    c.drawPath(bigCore, _core(tone, bigCore.getBounds()));
    c.restore();

    final grow = .55 + .55 * breathe;
    c.saveLayer(
      const Rect.fromLTWH(24, -4, 28, 28),
      Paint()..color = Colors.white.withValues(alpha: .6 + .4 * breathe),
    );
    _about(c, const Offset(38, 9.5), sx: grow, sy: grow);
    final small = _sparkle(const Offset(38, 9.5), 6.5);
    _soft(c, small, _body(tone, small.getBounds()), 1.6);
    final smallCore = _sparkle(const Offset(38, 10.2), 3);
    c.drawPath(smallCore, _core(tone, smallCore.getBounds()));
    c.restore();
  }

  void _gem(Canvas c, double x) {
    const tone = ArtTone.plus;
    c.save();
    c.translate(0, key(x, const [(0, 1), (.5, -2), (1, 1)]));
    final outline = Path()
      ..moveTo(15, 10)
      ..lineTo(33, 10)
      ..lineTo(41, 20)
      ..lineTo(24, 40)
      ..lineTo(7, 20)
      ..close();
    _soft(c, outline, Paint()..color = tone.mid, 2.2);
    final crown = Path()
      ..moveTo(15, 10)
      ..lineTo(33, 10)
      ..lineTo(41, 20)
      ..lineTo(7, 20)
      ..close();
    c.drawPath(crown, _core(tone, crown.getBounds()));
    final pavilion = Path()
      ..moveTo(7, 20)
      ..lineTo(41, 20)
      ..lineTo(24, 40)
      ..close();
    c.drawPath(pavilion, _body(tone, pavilion.getBounds()));
    c.drawPath(
      Path()
        ..moveTo(17, 20)
        ..lineTo(24, 40)
        ..lineTo(31, 20)
        ..close(),
      Paint()..color = tone.light,
    );
    c.drawPath(
      Path()
        ..moveTo(15, 10)
        ..lineTo(17, 20)
        ..lineTo(24, 10)
        ..lineTo(31, 20)
        ..lineTo(33, 10),
      Paint()
        ..color = tone.core3
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
    c.restore();

    final glint = key(x, const [(0, 0), (.4, 0), (.58, 1), (.8, 0)]);
    if (glint <= 0) return;
    c.save();
    _about(
      c,
      const Offset(38, 9),
      degrees: 45 * key(x, const [(0, 0), (.4, 0), (.58, 1), (.8, 1)]),
      sx: 1.1 * glint,
      sy: 1.1 * glint,
    );
    c.drawPath(
      _sparkle(const Offset(38, 9), 5.5),
      Paint()..color = Colors.white.withValues(alpha: glint),
    );
    c.restore();
  }

  void _cards(Canvas c, double x) {
    const tone = ArtTone.flashcard;
    const pivot = Offset(24, 34.8);
    const card = Rect.fromLTWH(14, 9, 20, 28);
    final open = key(x, const [(0, 0), (.25, 0), (.5, 1), (.65, 1), (.85, 0)]);

    // The two plain cards behind part to the sides and close again.
    for (final (side, color) in [(-1.0, tone.light), (1.0, tone.mid)]) {
      c.save();
      _about(c, pivot, degrees: side * (6 + 14 * open));
      _round(c, card, 5, Paint()..color = color);
      c.restore();
    }
    _round(c, card, 5, _body(tone, card));
    const face = Rect.fromLTWH(17.2, 12.2, 13.6, 21.6);
    _round(c, face, 3.4, _core(tone, face));
    c.drawPath(_sparkle(const Offset(24, 23), 5), Paint()..color = tone.mid);
  }

  void _blocks(Canvas c, double x) {
    const tone = ArtTone.game;
    // The row sits low on the grid to leave room for the carried block;
    // raise the whole scene so its resting state is centered.
    c.save();
    c.translate(0, -7);

    void block(double left, double top) {
      _round(
        c,
        Rect.fromLTWH(left, top + 2.2, 12.5, 12),
        3.6,
        Paint()..color = tone.deep,
      );
      final body = Rect.fromLTWH(left, top, 12.5, 12);
      _round(c, body, 3.6, _body(tone, body));
      final core = Rect.fromLTWH(left + 2.6, top + 2.4, 7.3, 7);
      _round(c, core, 2.2, _core(tone, core));
    }

    final shade = key(x, const [
      (0, 0),
      (.25, 0),
      (.4, .2),
      (.52, .3),
      (.84, 0),
    ]);
    if (shade > 0) {
      final width = 12 * key(x, const [(0, .6), (.25, .6), (.4, .7), (.52, 1)]);
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(24.25, 42.6),
          width: width,
          height: 3,
        ),
        Paint()..color = ArtTone.gameShadow.withValues(alpha: shade),
      );
    }

    final part =
        6.5 * key(x, const [(0, 0), (.26, 0), (.42, 1), (.88, 1), (1, 0)]);
    block(11.5 - part, 28);
    block(24.5 + part, 28);

    final opacity = key(x, const [(0, 0), (.1, 1), (.84, 1), (.96, 0)]);
    if (opacity <= 0) {
      c.restore();
      return;
    }
    c.save();
    c.translate(
      key(x, const [(0, 14), (.1, 10), (.3, 0)]),
      key(x, const [
        (0, -20),
        (.1, -19),
        (.3, -18),
        (.4, -17),
        (.52, .8),
        (.6, -.6),
        (.66, 0),
      ]),
    );
    _about(
      c,
      const Offset(24.25, 40),
      degrees: key(x, const [(0, 10), (.1, 8), (.3, -4), (.4, 0)]),
      sx: key(x, const [
        (0, 1.08),
        (.3, 1.08),
        (.4, 1.06),
        (.52, 1.06),
        (.6, .98),
        (.66, 1),
      ]),
      sy: key(x, const [
        (0, 1.08),
        (.3, 1.08),
        (.4, 1.06),
        (.52, .9),
        (.6, 1.03),
        (.66, 1),
      ]),
    );
    c.saveLayer(
      const Rect.fromLTWH(0, 0, 48, 48),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    block(18, 28);
    c.restore();
    c.restore();
    c.restore();
  }

  void _sprout(Canvas c, double x) {
    const tone = ArtTone.garden;
    final g = key(x, const [(0, 0), (.2, 0), (.45, 1), (.65, 1), (.9, 0)]);

    final mound = Path()
      ..moveTo(9, 43)
      ..cubicTo(11, 33.5, 37, 33.5, 39, 43)
      ..close();
    _soft(c, mound, _body(tone, mound.getBounds()), 2);
    final shine = Path()
      ..moveTo(15, 41)
      ..cubicTo(16.5, 36.6, 31.5, 36.6, 33, 41)
      ..close();
    c.drawPath(shine, _core(tone, shine.getBounds()));

    final lift = 1.6 * g;
    c.drawLine(
      const Offset(24, 37),
      Offset(24, 21 - lift),
      Paint()
        ..color = tone.deep
        ..strokeWidth = 3.8
        ..strokeCap = StrokeCap.round,
    );
    for (final (base, tip, width, turn) in [
      (Offset(24, 29 - lift * .5), Offset(6, 17.5 - lift * .5), 7.2, 9.0),
      (Offset(24, 23 - lift), Offset(42, 9 - lift), 8.4, -9.0),
    ]) {
      c.save();
      _about(c, base, degrees: turn * g, sx: 1 + .07 * g, sy: 1 + .07 * g);
      final leaf = _leaf(base, tip, width);
      _soft(c, leaf, _body(tone, leaf.getBounds()), 1.4);
      final d = tip - base;
      final vein = _leaf(base + d * .24, base + d * .84, width * .38);
      c.drawPath(vein, _core(tone, vein.getBounds()));
      c.restore();
    }

    final glint = key(x, const [(0, 0), (.4, 0), (.55, 1), (.75, 0)]);
    if (glint <= 0) return;
    c.save();
    _about(c, const Offset(41, 23), degrees: 45 * glint, sx: glint, sy: glint);
    c.drawPath(
      _sparkle(const Offset(41, 23), 5),
      Paint()..color = Colors.white.withValues(alpha: glint),
    );
    c.restore();
  }

  void _headphones(Canvas c, double x) {
    const tone = ArtTone.listen;
    for (final (from, to, delay) in [
      (const Offset(37, 19), const Offset(41, 3), 0.0),
      (const Offset(9, 19), const Offset(5, 6), .22),
    ]) {
      final p = key(x, [(delay, 0), (delay + .5, 1)]);
      final a = key(x, [
        (0, 0),
        (delay + .04, 0),
        (delay + .14, 1),
        (delay + .38, 1),
        (delay + .5, 0),
      ]);
      if (a > 0) _note(c, Offset.lerp(from, to, p)!, (p - .5) * 24, a);
    }

    c.save();
    c.translate(
      0,
      key(x, const [(0, 0), (.12, 1.4), (.24, 0), (.36, 1.4), (.48, 0)]),
    );
    final band = Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(24, 27), radius: 13.5),
        math.pi,
        math.pi,
      );
    c.drawPath(
      band,
      Paint()
        ..shader = _body(tone, const Rect.fromLTWH(10, 13, 28, 14)).shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round,
    );
    for (final left in const [8.5, 30.5]) {
      final cup = Rect.fromLTWH(left, 23.5, 9, 15.5);
      _round(
        c,
        cup.shift(const Offset(0, 1.8)),
        4.4,
        Paint()..color = tone.deep,
      );
      _round(c, cup, 4.4, _body(tone, cup));
      final core = Rect.fromLTWH(left + 2.3, 26.2, 4.4, 9.8);
      _round(c, core, 2.2, _core(tone, core));
    }
    c.restore();
  }

  /// An eighth note with its head at [at], turned [degrees], white at
  /// [alpha].
  static void _note(Canvas c, Offset at, double degrees, double alpha) {
    c.save();
    _about(c, at, degrees: degrees);
    final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
    c.save();
    _about(c, at, degrees: -22);
    c.drawOval(Rect.fromCenter(center: at, width: 5.6, height: 4), paint);
    c.restore();
    c.drawRect(Rect.fromLTWH(at.dx + 1.6, at.dy - 9.5, 1.5, 9.5), paint);
    c.drawPath(
      Path()
        ..moveTo(at.dx + 3.1, at.dy - 9.5)
        ..quadraticBezierTo(at.dx + 7.4, at.dy - 7.6, at.dx + 6, at.dy - 3.4)
        ..quadraticBezierTo(at.dx + 5.6, at.dy - 6.2, at.dx + 3.1, at.dy - 6.6)
        ..close(),
      paint,
    );
    c.restore();
  }

  /// A leaf from [base] to [tip], [width] across at its widest.
  static Path _leaf(Offset base, Offset tip, double width) {
    final d = tip - base;
    final n = Offset(-d.dy, d.dx) / d.distance * width;
    final m1 = base + d * .3, m2 = base + d * .72;
    return Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        (m1 + n).dx,
        (m1 + n).dy,
        (m2 + n).dx,
        (m2 + n).dy,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        (m2 - n).dx,
        (m2 - n).dy,
        (m1 - n).dx,
        (m1 - n).dy,
        base.dx,
        base.dy,
      )
      ..close();
  }

  /// A four-point sparkle with curved sides.
  static Path _sparkle(Offset c, double r) {
    final k = r * .18;
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..cubicTo(c.dx + k, c.dy - k, c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..cubicTo(c.dx + k, c.dy + k, c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..cubicTo(c.dx - k, c.dy + k, c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..cubicTo(c.dx - k, c.dy - k, c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
  }

  @override
  bool shouldRepaint(MenuArtPainter oldDelegate) =>
      kind != oldDelegate.kind || t != oldDelegate.t;
}
