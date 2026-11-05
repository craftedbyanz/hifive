import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/widgets/ambient.dart';
import 'package:hifive/widgets/plus_banner.dart';

Widget _stars({required bool enabled, bool reduced = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: AmbientMotion(
    enabled: enabled,
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 300, height: 100, child: BannerStars()),
    ),
  ),
);

void main() {
  testWidgets('stars keep animating when ambient motion is on', (tester) async {
    await tester.pumpWidget(_stars(enabled: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('stars stay still in tests', (tester) async {
    await tester.pumpWidget(_stars(enabled: false));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('stars keep moving under Reduce Motion, as on the reference', (
    tester,
  ) async {
    await tester.pumpWidget(_stars(enabled: true, reduced: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('stars stay still without the app wrapper', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 300, height: 100, child: BannerStars()),
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
