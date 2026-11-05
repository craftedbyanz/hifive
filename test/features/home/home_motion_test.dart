import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/home/home.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  group('menu matches the reference recording', () {
    // Seconds after the first screen change, and how far the Insight row still
    // had to travel, as a share of its 840 px trip from the bottom row.
    const opening = [
      (.133, .252),
      (.150, .201),
      (.167, .162),
      (.183, .129),
      (.200, .102),
      (.217, .081),
      (.233, .064),
      (.250, .051),
      (.267, .040),
      (.300, .025),
      (.350, .012),
    ];
    for (final (seconds, remaining) in opening) {
      test('rows at $seconds s', () {
        final m = MenuMotion.at(
          (seconds + MenuMotion.rowDelay) / .45,
          closing: false,
        );
        expect(1 - m.spread, closeTo(remaining, .012));
      });
    }

    test('opening ends fully resolved', () {
      final m = MenuMotion.at(1, closing: false);
      expect(m.spread, 1);
      expect(m.rowOpacity, 1);
      expect(m.rowScale, 1);
      expect(m.rowBlur, 0);
      expect(m.backdropOpacity, 1);
      expect(m.barOpacity, 0);
    });

    test('rest state leaves the bottom controls untouched', () {
      for (final closing in [false, true]) {
        final m = MenuMotion.at(0, closing: closing);
        expect(m.barOpacity, 1);
        expect(m.barBlur, 0);
        expect(m.barScale, 1);
        expect(m.backdropOpacity, 0);
      }
    });

    test('closing hides rows before the backdrop clears', () {
      double at(double seconds) => 1 - seconds / .45;
      final rowsGone = MenuMotion.at(at(.12), closing: true);
      expect(rowsGone.rowOpacity, 0);
      expect(rowsGone.backdropOpacity, greaterThan(.3));
      expect(
        MenuMotion.at(at(.25), closing: true).backdropOpacity,
        lessThan(.1),
      );
    });
  });

  testWidgets('rows spread from the bottom row in proportion', (tester) async {
    await mount(tester, fresh(), const HomeScreen(animateAmbient: false));
    await tester.tap(find.text('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 133));
    double y(String label) => tester.getCenter(find.text(label)).dy;
    final bottom = y('Chơi FlowLetter');
    final far = bottom - y('Insight'), near = bottom - y('Học flashcard');
    expect(far / near, closeTo(2, .02));
    await tester.pumpAndSettle();
    expect(y('Chơi FlowLetter') - y('Insight'), closeTo(280, 1));
  });

  test('carousel settles without overshoot at the measured rate', () {
    const physics = CardPagePhysics();
    final sim = ScrollSpringSimulation(physics.spring, 0, 1000, 1500);
    var previous = 0.0;
    for (var t = 0.0; t < 2; t += 1 / 60) {
      final x = sim.x(t);
      expect(x, lessThanOrEqualTo(1000.01));
      expect(x, greaterThanOrEqualTo(previous - .01));
      previous = x;
    }
    final d1 = 1000 - sim.x(.5), d2 = 1000 - sim.x(.7);
    expect((d1 / d2 - 1).abs(), greaterThan(0));
    final rate = (log(d1) - log(d2)) / .2;
    expect(rate, closeTo(10.9, .6));
  });
}
