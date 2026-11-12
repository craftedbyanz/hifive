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
          (seconds + MenuMotion.rowDelay) / MenuMotion.openSeconds,
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

    test('opening ends without a last-frame jump', () {
      // The rows' settle used to be cut off at 0.45 s, a 3 pt jump at the end.
      final last = MenuMotion.at(
        1 - 1 / 60 / MenuMotion.openSeconds,
        closing: false,
      );
      expect((1 - last.spread) * 4 * MenuMotion.rowSpacing, lessThan(.5));
    });

    test('opening blurs the screen behind gradually', () {
      double backdrop(double seconds) => MenuMotion.at(
        (seconds + MenuMotion.rowDelay) / MenuMotion.openSeconds,
        closing: false,
      ).backdropOpacity;
      // A faint ghost of the screen still shows a tenth of a second in.
      expect(backdrop(.1), inInclusiveRange(.6, .8));
      expect(backdrop(.2), 1);
    });

    test('closing folds the rows away as smoothly as they open', () {
      double at(double seconds) => 1 - seconds / MenuMotion.closeSeconds;
      // Half way the rows have drawn half together and still show clearly.
      final mid = MenuMotion.at(at(.15), closing: true);
      expect(mid.spread, closeTo(.5, .03));
      expect(mid.rowOpacity, greaterThan(.8));
      // The screen behind is half way back on the same curve.
      expect(mid.backdropOpacity, inInclusiveRange(.5, .9));
      // No step between frames is large: the fold eases in and out.
      var previous = MenuMotion.at(at(0), closing: true).spread;
      for (var ms = 16.7; ms <= 300; ms += 16.7) {
        final next = MenuMotion.at(at(ms / 1000), closing: true).spread;
        expect(previous - next, lessThan(.16));
        previous = next;
      }
      expect(MenuMotion.at(at(.3), closing: true).rowOpacity, 0);
    });

    test('closing ends with the rows gone and the screen clear', () {
      double at(double seconds) => 1 - seconds / MenuMotion.closeSeconds;
      final end = MenuMotion.at(at(.4), closing: true);
      expect(end.rowOpacity, 0);
      expect(end.backdropOpacity, lessThan(.01));
      expect(end.barOpacity, 1);
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
