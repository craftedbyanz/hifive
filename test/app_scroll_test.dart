import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/widgets/app_scroll.dart';

void main() {
  group('velocity tracker', () {
    HoldAwareVelocityTracker moving() {
      final tracker = HoldAwareVelocityTracker(PointerDeviceKind.touch);
      for (var i = 0; i < 6; i++) {
        tracker.addPosition(Duration(milliseconds: i * 16), Offset(0, i * 10));
      }
      return tracker;
    }

    testWidgets('keeps speed when the finger lifts while moving', (_) async {
      expect(
        moving().getVelocityEstimate().pixelsPerSecond.dy,
        greaterThan(100),
      );
    });

    testWidgets('reports no speed when the finger rested before lifting', (
      tester,
    ) async {
      final tracker = moving();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      expect(tracker.getVelocityEstimate().pixelsPerSecond, Offset.zero);
    });
  });

  group('Home fling', () {
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 5000,
      pixels: 1000,
      viewportDimension: 852,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 3,
    );
    const home = HomeScrollPhysics();
    const plain = BouncingScrollPhysics();
    double travel(ScrollPhysics physics, double velocity) =>
        physics.createBallisticSimulation(metrics, velocity)!.x(10) - 1000;

    test('a slow release does not fling', () {
      expect(home.createBallisticSimulation(metrics, 120), isNull);
    });

    test('a flick takes longer to settle than the default', () {
      double restTime(ScrollPhysics physics) {
        final simulation = physics.createBallisticSimulation(metrics, 800)!;
        var t = 0.0;
        while (!simulation.isDone(t)) {
          t += .01;
        }
        return t;
      }

      expect(restTime(home), greaterThan(restTime(plain) * 1.2));
    });

    test('a fast flick travels further than the default', () {
      expect(travel(home, 800) / travel(plain, 800), closeTo(1.3, .03));
    });
  });
}
