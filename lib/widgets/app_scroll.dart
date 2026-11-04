import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Velocity tracking that reports no fling once the finger has stopped.
///
/// Flutter's iOS tracker keeps the speed of the last movement even when the
/// finger rests before lifting, so content kept drifting after a held drag. The
/// reference stops dead in that case. The limit leaves room for a real flick,
/// whose last movement can arrive a few frames before the finger lifts.
class HoldAwareVelocityTracker extends IOSScrollViewFlingVelocityTracker {
  HoldAwareVelocityTracker(super.kind);
  static const stoppedAfter = Duration(milliseconds: 80);
  final Stopwatch _sinceLastMove = Stopwatch()..start();

  @override
  void addPosition(Duration time, Offset position) {
    _sinceLastMove.reset();
    super.addPosition(time, position);
  }

  @override
  VelocityEstimate getVelocityEstimate() =>
      _sinceLastMove.elapsed > stoppedAfter
      ? const VelocityEstimate(
          pixelsPerSecond: Offset.zero,
          confidence: 1,
          duration: Duration.zero,
          offset: Offset.zero,
        )
      : super.getVelocityEstimate();
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();
  @override
  GestureVelocityTrackerBuilder velocityTrackerBuilder(BuildContext context) =>
      getPlatform(context) == TargetPlatform.iOS
      ? (event) => HoldAwareVelocityTracker(event.kind)
      : super.velocityTrackerBuilder(context);
}

/// Home's flick behavior, from repeated video measurements on the iPhone.
///
/// Against Flutter's default the reference travels about 1.3 times further after
/// the finger lifts and takes about 1.25 times longer to come to rest. A slow
/// gesture (80 pt in 250 ms) does not fling at all. The cutoff is in Flutter's
/// estimated velocity, where that gesture read about 130 pt/s and the slowest
/// that flings about 336 pt/s; its exact position between them is not measured.
class HomeScrollPhysics extends BouncingScrollPhysics {
  const HomeScrollPhysics({super.parent});
  static const flingCutoff = 230.0, flingScale = 1.3;

  @override
  HomeScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      HomeScrollPhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final simulation = super.createBallisticSimulation(
      position,
      velocity.abs() < flingCutoff ? 0 : velocity * flingScale,
    );
    return simulation == null ? null : _SlowerSimulation(simulation);
  }
}

/// Runs a simulation slower without changing how far it travels.
class _SlowerSimulation extends Simulation {
  static const rate = .8;
  final Simulation inner;
  _SlowerSimulation(this.inner) : super(tolerance: inner.tolerance);
  @override
  double x(double time) => inner.x(time * rate);
  @override
  double dx(double time) => inner.dx(time * rate) * rate;
  @override
  bool isDone(double time) => inner.isDone(time * rate);
}
