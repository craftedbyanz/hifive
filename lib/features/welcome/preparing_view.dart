import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/design/design.dart';
import 'welcome_motion.dart';

part 'preparing_brain.dart';

/// A full screen wait: a neural network shaped like a brain lights up from
/// front to back, with a status line under it. With [duration] its nodes
/// then gather into the hifive logo as a bar fills, each of [steps] shows in
/// turn, the screen lifts away and [onDone] runs; without it the network
/// stays lit and the wait has no end of its own.
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

/// How far an endless wait goes: the whole network lit, before any
/// gathering.
const _endlessHold = .7;

/// How long an endless wait takes to light up.
const _endlessBuild = Duration(milliseconds: 4400);

/// The screen lifting away once the logo has formed.
const _leaveTime = Duration(milliseconds: 450);

class _PreparingViewState extends State<PreparingView>
    with TickerProviderStateMixin {
  late final progress = AnimationController(
    vsync: this,
    duration: widget.duration ?? _endlessBuild,
  );
  late final leave = AnimationController(vsync: this, duration: _leaveTime);

  /// Seconds since the wait began, for the pulses; still under Reduce
  /// Motion and in tests that stop ambient motion.
  final _time = ValueNotifier<double>(0);
  late final Ticker _clock = createTicker(
    (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
  );

  bool get _measured => widget.duration != null;

  @override
  void initState() {
    super.initState();
    progress.forward().whenComplete(() async {
      if (!mounted || !_measured) return;
      if (!MediaQuery.disableAnimationsOf(context)) await leave.forward();
      if (mounted) widget.onDone?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (welcomeAutoplay(context)) {
      if (!_clock.isActive) _clock.start();
    } else if (_clock.isActive) {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    progress.dispose();
    leave.dispose();
    _clock.dispose();
    _time.dispose();
    super.dispose();
  }

  /// Where the drawing is: an endless wait holds once fully lit.
  double get _drawn =>
      _measured ? progress.value : progress.value * _endlessHold;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([progress, leave]),
          builder: (context, _) {
            final p = progress.value;
            final step = _measured
                ? math.min(
                    (p * widget.steps.length).floor(),
                    widget.steps.length - 1,
                  )
                : 0;
            final gone = Curves.easeIn.transform(leave.value);
            return Opacity(
              opacity: 1 - gone,
              child: Transform.scale(
                scale: 1 + .06 * gone,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      key: const ValueKey('preparing-brain'),
                      width: 300,
                      height: 260,
                      child: RepaintBoundary(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _time,
                          builder: (context, time, _) => CustomPaint(
                            painter: _BrainPainter(
                              progress: _drawn,
                              time: time,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    if (_measured)
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
                        style: D.text(
                          16,
                          weight: FontWeight.w700,
                          height: 22 / 16,
                        ),
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
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
