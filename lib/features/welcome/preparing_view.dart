import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../widgets/common.dart';
import 'welcome_motion.dart';

/// A full screen wait: dots in the three mode colors orbit the logo, with a
/// status line under them. With [duration] the dots gather into the logo as
/// a bar fills, each of [steps] shows in turn, and [onDone] runs at the end;
/// without it the wait has no end of its own.
class PreparingView extends StatefulWidget {
  final List<String> steps;
  final String detail;
  final Duration? duration;
  final VoidCallback? onDone;
  const PreparingView({
    super.key,
    required this.steps,
    required this.detail,
    this.duration,
    this.onDone,
  });
  @override
  State<PreparingView> createState() => _PreparingViewState();
}

class _PreparingViewState extends State<PreparingView>
    with TickerProviderStateMixin {
  late final progress = AnimationController(
    vsync: this,
    duration: widget.duration ?? Duration.zero,
  );

  /// Spins the orbits; one turn of the slowest ring.
  late final spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (widget.duration != null) {
      progress.forward().whenComplete(() {
        if (mounted) widget.onDone?.call();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (welcomeAutoplay(context)) {
      if (!spin.isAnimating) spin.repeat();
    } else {
      spin.stop();
    }
  }

  @override
  void dispose() {
    progress.dispose();
    spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([progress, spin]),
          builder: (context, _) {
            final p = progress.value;
            final measured = widget.duration != null;
            final step = measured
                ? min(
                    (p * widget.steps.length).floor(),
                    widget.steps.length - 1,
                  )
                : 0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 240,
                  child: CustomPaint(
                    painter: _OrbitPainter(
                      turn: spin.value,
                      gather: measured ? Curves.easeInCubic.transform(p) : 0,
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: .85 + .15 * p,
                        child: const AppLogo(size: 64),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                if (measured)
                  Container(
                    width: 140,
                    height: 4,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: D.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: p,
                      child: Container(
                        decoration: BoxDecoration(
                          color: D.ink,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    widget.steps[step],
                    key: ValueKey(step),
                    textAlign: TextAlign.center,
                    style: D.text(16, weight: FontWeight.w700, height: 22 / 16),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.detail,
                    textAlign: TextAlign.center,
                    style: D.text(14, color: D.secondary, height: 20 / 14),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Three tilted rings of dots, one per study mode, turning at their own
/// speeds; [gather] pulls them in towards the centre and fades them.
class _OrbitPainter extends CustomPainter {
  final double turn, gather;
  _OrbitPainter({required this.turn, required this.gather});

  static final _rings = [
    for (final (i, mode) in StudyMode.values.indexed)
      (
        color: mode.color,
        radius: 108.0 - i * 20,
        tilt: -.5 + i * .55,
        squash: .42 + i * .1,
        speed: i.isEven ? 1.0 : -1.4,
        count: 34 - i * 6,
      ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint();
    for (final (r, ring) in _rings.indexed) {
      final radius = ring.radius * (1 - .7 * gather);
      for (var i = 0; i < ring.count; i++) {
        final a = 2 * pi * (i / ring.count + turn * ring.speed + r * .13);
        // A point on a flattened circle, then turned by the ring's tilt.
        final x = cos(a) * radius, y = sin(a) * radius * ring.squash;
        final p = Offset(
          x * cos(ring.tilt) - y * sin(ring.tilt),
          x * sin(ring.tilt) + y * cos(ring.tilt),
        );
        // Dots on the near half of the ring are larger and stronger.
        final depth = (sin(a) + 1) / 2;
        paint.color = ring.color.withValues(
          alpha: (.25 + .6 * depth) * (1 - gather),
        );
        canvas.drawCircle(c + p, 1.6 + 2.2 * depth, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.turn != turn || old.gather != gather;
}
