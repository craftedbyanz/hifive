import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/garden/garden.dart';
import 'package:hifive/features/home/home.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Home offers the garden where it offered Plus', (tester) async {
    await mount(tester, fresh(), const HomeScreen(animateAmbient: false));
    expect(find.text('Đăng ký Hifive Plus'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('home-garden')));
    await tester.pumpAndSettle();
    expect(find.byType(GardenScreen), findsOneWidget);
  });

  testWidgets('Hifive 101 opens with the story of hifive', (tester) async {
    await mount(tester, fresh(), const HomeScreen(animateAmbient: false));
    final first = find.text('Câu chuyện của hifive');
    await tester.dragUntilVisible(
      first,
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Lời hứa của hifive'), findsOneWidget);
  });
}
