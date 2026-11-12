import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/home/home.dart';
import 'package:hifive/features/learning/learning.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('practice modes are marked coming soon and do not open', (
    tester,
  ) async {
    await mount(tester, fresh(), const HomeScreen(animateAmbient: false));
    final card = find.byType(ModeCard).first;
    expect(
      find.descendant(of: card, matching: find.text('Sắp ra mắt')),
      findsOneWidget,
    );
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(TopicScreen), findsNothing);
  });

  testWidgets('the AI lesson link is coming soon and does not open', (
    tester,
  ) async {
    await mount(tester, fresh(), const HomeScreen(animateAmbient: false));
    await tester.tap(find.text('Tạo bài học với AI'));
    await tester.pumpAndSettle();
    expect(find.byType(GeneratorScreen), findsNothing);
  });
}
