import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../widgets/common.dart';

/// The end of a session. Measured from video: the content fades in over about
/// 0.4 s while the medal scales up, then gold confetti bursts out from behind it.
/// Only the "Xuất sắc!" result was seen on the reference.
class ReviewComplete extends StatefulWidget {
  final String deckTitle;
  final int seen, known, again;
  final VoidCallback onContinue;
  const ReviewComplete({
    super.key,
    required this.deckTitle,
    required this.seen,
    required this.known,
    required this.again,
    required this.onContinue,
  });
  @override
  State<ReviewComplete> createState() => _ReviewCompleteState();
}

class _ReviewCompleteState extends State<ReviewComplete>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _span(double from, double to, Curve curve) =>
      curve.transform(((_c.value - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.completePage,
    body: AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final content = _span(0, .125, Curves.easeOut);
        final medal = _span(0, .19, Curves.elasticOut);
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 219,
              child: Center(
                child: Transform.scale(
                  scale: .35 + .65 * medal,
                  child: Opacity(
                    opacity: content,
                    child: const CustomPaint(
                      size: Size(92, 120),
                      painter: MedalPainter(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ConfettiPainter(_c.value)),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: 412,
              child: Opacity(
                opacity: content,
                child: Column(
                  children: [
                    Text(
                      'Xuất sắc!',
                      style: D.text(
                        24,
                        weight: FontWeight.w800,
                        height: 30 / 24,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Bạn đã nắm vững hầu hết các thẻ!',
                      style: D.text(
                        13.5,
                        color: Palette.settingsMuted,
                        height: 18 / 13.5,
                      ),
                    ),
                    const SizedBox(height: 23),
                    Container(
                      height: 114,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          _Stat(
                            CupertinoIcons.square_stack_3d_up_fill,
                            Palette.statSeen,
                            widget.seen,
                            'Đã xem',
                          ),
                          _rule,
                          _Stat(
                            CupertinoIcons.checkmark_circle_fill,
                            Palette.statKnown,
                            widget.known,
                            'Thuộc',
                          ),
                          _rule,
                          _Stat(
                            CupertinoIcons.arrow_counterclockwise,
                            Palette.medalOrange,
                            widget.again,
                            'Học lại',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 23),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.tray_full_fill,
                          size: 16,
                          color: Palette.settingsHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.deckTitle,
                          style: D.text(
                            13.5,
                            weight: FontWeight.w500,
                            color: Palette.settingsMuted,
                            height: 18 / 13.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 66,
              child: Opacity(
                opacity: content,
                child: PressFade(
                  key: const ValueKey('review-continue'),
                  onTap: widget.onContinue,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: D.ink,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Text(
                      'Tiếp tục',
                      style: D.text(
                        15.5,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  static final _rule = Container(
    width: 1,
    height: 32,
    color: Palette.settingsPanel,
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  const _Stat(this.icon, this.color, this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: D.text(21, weight: FontWeight.w800, height: 25 / 21),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: D.text(11.5, color: Palette.settingsHint, height: 14 / 11.5),
        ),
      ],
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  static const count = 84;
  final double t;
  const _ConfettiPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // It starts as the medal lands.
    final life = ((t - .1) / .9).clamp(0.0, 1.0);
    if (life == 0 || life == 1) return;
    final random = Random(7);
    final origin = Offset(size.width / 2, 264);
    final eased = 1 - pow(1 - min(life * 2.2, 1.0), 3).toDouble();
    final fade = life < .7 ? 1.0 : (1 - life) / .3;
    for (var i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final reach = 58 + random.nextDouble() * 112;
      final side = 5 + random.nextDouble() * 6;
      final spin = random.nextDouble() * 6;
      final color = random.nextBool() ? Palette.medalGold : Palette.medalOrange;
      final p =
          origin +
          Offset(cos(angle), sin(angle)) * reach * eased +
          Offset(0, 26 * life * life);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(spin + life * 5);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: side, height: side * .6),
        Paint()..color = color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => t != oldDelegate.t;
}
