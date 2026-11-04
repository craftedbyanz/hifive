import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/main.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(HifiveApp(state: fresh(), animateAmbient: false));
    await tester.pumpAndSettle();
  }

  testWidgets('type size ignores the system text size setting', (tester) async {
    // A physical iPhone with a smaller system text size shrank every clone
    // label by about 6%, while the reference kept its size.
    tester.platformDispatcher.textScaleFactorTestValue = .94;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await launch(tester);
    final height = tester.getSize(find.text('Chế độ học tập')).height;

    tester.platformDispatcher.textScaleFactorTestValue = 1;
    await tester.pumpAndSettle();
    expect(height, tester.getSize(find.text('Chế độ học tập')).height);
  });

  testWidgets('cold launch shows the writing card first', (tester) async {
    await launch(tester);
    final left = tester.getTopLeft(find.text('Đoạn văn')).dx;
    expect(left, inInclusiveRange(16, 60));
  });

  testWidgets('side cards are not cut off before the screen edge', (
    tester,
  ) async {
    await launch(tester);
    final pages = tester.widget<PageView>(
      find.byKey(const ValueKey('mode-carousel')),
    );
    expect(pages.clipBehavior, Clip.none);
  });

  testWidgets('open menu list drags 14 pt and tapping the veil closes it', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.text('Insight')).dy;

    await tester.drag(
      find.byKey(const ValueKey('home-menu-list')),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Insight')).dy,
      closeTo(before - 14, .5),
    );

    await tester.tapAt(const Offset(196, 420));
    await tester.pumpAndSettle();
    expect(find.text('Insight'), findsNothing);
  });
}
