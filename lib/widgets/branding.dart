import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/design/design.dart';
import 'ambient.dart';

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

/// The art of hifive's own story in Hifive 101: the logo's five bars, large
/// on a soft ground, moving like a voice's sound wave and then settling into
/// the raised hand of the logo, with ripples of sound behind. It fills the
/// space it is given and moves only under [AmbientMotion].
class LogoStoryArt extends StatefulWidget {
  const LogoStoryArt({super.key});

  @override
  State<LogoStoryArt> createState() => _LogoStoryArtState();
}

class _LogoStoryArtState extends State<LogoStoryArt>
    with SingleTickerProviderStateMixin {
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(
    (e) => _time.value = e.inMicroseconds / 1e6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = AmbientMotion.of(context);
    if (on && !_ticker.isActive) {
      _ticker.start();
    } else if (!on && _ticker.isActive) {
      _ticker.stop();
      _time.value = 0;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _StoryPainter(_time, still: !_ticker.isActive),
      child: const SizedBox.expand(),
    ),
  );
}

class _StoryPainter extends CustomPainter {
  final ValueNotifier<double> time;
  final bool still;
  _StoryPainter(this.time, {required this.still}) : super(repaint: time);

  /// The logo's bar heights, as a share of the tallest.
  static const _logo = [.55, .87, 1.0, .89, .68];
  static const _cycle = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.storyTop, Palette.storyBottom],
        ).createShader(Offset.zero & size),
    );
    final t = time.value;
    final unit = math.min(w, h * 1.15);
    final barW = unit * .085, gap = unit * .045;
    final total = barW * 5 + gap * 4;
    final left = (w - total) / 2, base = h * .78, tallest = h * .56;
    final c = Offset(w / 2, base - tallest * .45);

    // Ripples of sound spreading from behind the bars.
    for (var i = 0; i < 3; i++) {
      final u = still ? (i + 1) / 4 : ((t * .22 + i / 3) % 1);
      final r = unit * (.22 + u * .5);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Palette.logoBars[2].withValues(alpha: .22 * (1 - u)),
      );
    }

    // Talking, then settling into the logo's raised hand, then talking again.
    final phase = still ? _cycle : t % _cycle;
    final settle = Curves.easeInOutCubic.transform(
      ((phase - 3.2) / 1.1).clamp(0.0, 1.0) *
          (1 - ((phase - 5.4) / .6).clamp(0.0, 1.0)),
    );
    for (var i = 0; i < 5; i++) {
      final talk =
          .35 +
          .6 *
              (math.sin(t * (2.4 + i * .7) + i * 1.3).abs() * .7 +
                  math.sin(t * 1.3 + i).abs() * .3);
      final k = still ? _logo[i] : talk + (_logo[i] - talk) * settle;
      final bh = tallest * k;
      final x = left + i * (barW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, base - bh, barW, bh),
        Radius.circular(barW / 2),
      );
      canvas
        ..drawRRect(
          rect.shift(Offset(0, unit * .02)),
          Paint()
            ..color = Palette.logoBars[i].withValues(alpha: .18)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * .025),
        )
        ..drawRRect(rect, Paint()..color = Palette.logoBars[i]);
      // A soft highlight down the left of each bar.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + barW * .18,
            base - bh + barW * .3,
            barW * .16,
            bh - barW * .6,
          ),
          Radius.circular(barW),
        ),
        Paint()..color = Colors.white.withValues(alpha: .28),
      );
    }
  }

  @override
  bool shouldRepaint(_StoryPainter old) => old.still != still;
}
