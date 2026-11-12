import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/widgets/ambient.dart';
import 'package:hifive/widgets/streak_flame.dart';
import 'package:lottie/lottie.dart';

Widget _flame({required bool enabled, bool active = true}) => AmbientMotion(
  enabled: enabled,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: StreakFlame(size: 100, active: active)),
  ),
);

Future<void> _load(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    // The composition is parsed off the frame; give it time to arrive.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
}

void main() {
  testWidgets('a lit streak shows the active animation, looping', (
    tester,
  ) async {
    await _load(tester, _flame(enabled: true));
    expect(find.byKey(const ValueKey('streak-flame-active')), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isTrue);
  });

  testWidgets('no streak yet shows the grey flame', (tester) async {
    await _load(tester, _flame(enabled: true, active: false));
    expect(find.byKey(const ValueKey('streak-flame-inactive')), findsOneWidget);
  });

  testWidgets('the flame holds still without ambient motion', (tester) async {
    await _load(tester, _flame(enabled: false));
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the flame is raised so its body sits centered', (tester) async {
    await _load(tester, _flame(enabled: false));
    final shift = tester.widget<Transform>(
      find.ancestor(of: find.byType(Lottie), matching: find.byType(Transform)),
    );
    expect(shift.transform.getTranslation().y, closeTo(-100 * .065, .001));
  });

  testWidgets('both animations are bundled and parse', (tester) async {
    for (final asset in [StreakFlame.activeAsset, StreakFlame.inactiveAsset]) {
      final composition = await tester.runAsync(
        () => AssetLottie(asset).load(),
      );
      expect(composition!.duration, greaterThan(Duration.zero), reason: asset);
    }
  });
}
