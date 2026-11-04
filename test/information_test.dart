import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/features/game/game.dart';
import 'package:hifive/features/information/information.dart';

import 'helpers.dart';

const tall = Size(393, 2200);

void main() {
  setUpAll(loadAppFonts);

  for (var i = 0; i < helpTitles.length; i++) {
    testWidgets('help page $i shows its title and body', (tester) async {
      await mount(tester, fresh(), HelpScreen(index: i), size: tall);
      expect(find.text(helpTitles[i]), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Plus lets you switch plans without purchasing', (tester) async {
    await mount(tester, fresh(), const PlusScreen(), size: tall);
    await tester.tap(find.text('Hàng tháng'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Khôi phục'));
    await tester.pumpAndSettle();
    expect(find.textContaining('không có giao dịch'), findsOneWidget);
  });

  testWidgets('article shows the given content', (tester) async {
    await mount(
      tester,
      fresh(),
      const ArticleScreen(title: 'Điều khoản', body: 'Nội dung'),
    );
    expect(find.text('Nội dung'), findsOneWidget);
  });

  testWidgets('game help explains the rules', (tester) async {
    await mount(tester, fresh(), const GameHelpScreen(), size: tall);
    expect(find.text('Cách chơi Flow Letter'), findsOneWidget);
  });
}
