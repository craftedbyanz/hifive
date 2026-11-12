import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/design/design.dart';
import '../l10n/l10n.dart';
import 'common.dart';

class PlusBanner extends StatelessWidget {
  final VoidCallback onTap;
  const PlusBanner({super.key, required this.onTap});

  /// Measured on Home (F01) at 393 pt.
  static const _height = 101.0;
  @override
  Widget build(BuildContext context) => Material(
    color: D.blue,
    borderRadius: BorderRadius.circular(28),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: _height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(child: BannerStars()),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(child: Flower(size: 40)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t.plusBannerTitle,
                          style: D.text(
                            15,
                            weight: FontWeight.w700,
                            color: Colors.white,
                            height: 20 / 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          width: 231,
                          child: Text(
                            context.t.plusBannerBody,
                            style: D.text(
                              11.5,
                              spacing: -.17,
                              color: Colors.white.withValues(alpha: .9),
                              height: 14.5 / 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class BannerStarsPainter extends CustomPainter {
  const BannerStarsPainter();
  @override
  void paint(Canvas c, Size s) {
    for (final p in const [
      Offset(.74, .12),
      Offset(.14, .2),
      Offset(.48, .12),
      Offset(.56, .23),
      Offset(.86, .32),
      Offset(.9, .6),
      Offset(.51, .82),
      Offset(.3, .72),
    ]) {
      final center = Offset(p.dx * s.width, p.dy * s.height);
      final paint = Paint()..color = Colors.white.withValues(alpha: .32);
      c.drawLine(
        center - const Offset(2, 0),
        center + const Offset(2, 0),
        paint,
      );
      c.drawLine(
        center - const Offset(0, 2),
        center + const Offset(0, 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stars measured on the reference banner: each stays still, brightens and
/// fades over about 1.6 s, then returns elsewhere, with about a dozen visible.
/// Tests and reduced motion get the still version.
class BannerStars extends StatefulWidget {
  const BannerStars({super.key});
  @override
  State<BannerStars> createState() => _BannerStarsState();
}

class _BannerStarsState extends State<BannerStars>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((elapsed) {
    _seconds.value = elapsed.inMicroseconds / 1e6;
  });
  final _seconds = ValueNotifier<double>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AmbientMotion.of(context)) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: AmbientMotion.of(context)
            ? _TwinklePainter(_seconds)
            : const BannerStarsPainter(),
      ),
    ),
  );
}

class _TwinklePainter extends CustomPainter {
  static const count = 12;
  static const life = 1.6;
  final ValueNotifier<double> seconds;
  _TwinklePainter(this.seconds) : super(repaint: seconds);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < count; i++) {
      final clock = seconds.value / life + i / count;
      final round = clock.floor();
      final alpha = math.sin((clock - round) * math.pi);
      final random = math.Random(i * 7919 + round * 104729);
      final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = 1.5 + random.nextDouble() * 1.5;
      final q = radius * .14;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - radius)
          ..quadraticBezierTo(
            center.dx + q,
            center.dy - q,
            center.dx + radius,
            center.dy,
          )
          ..quadraticBezierTo(
            center.dx + q,
            center.dy + q,
            center.dx,
            center.dy + radius,
          )
          ..quadraticBezierTo(
            center.dx - q,
            center.dy + q,
            center.dx - radius,
            center.dy,
          )
          ..quadraticBezierTo(
            center.dx - q,
            center.dy - q,
            center.dx,
            center.dy - radius,
          ),
        Paint()..color = Colors.white.withValues(alpha: .33 * alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_TwinklePainter oldDelegate) => false;
}
