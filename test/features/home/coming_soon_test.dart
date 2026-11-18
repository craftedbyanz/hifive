import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/history/history.dart';
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

  testWidgets('history offers no way to start a coming-soon lesson', (
    tester,
  ) async {
    await mount(tester, fresh(includeExamples: true), const HistoryScreen());
    expect(find.byKey(const ValueKey('history-new')), findsNothing);
    expect(find.byIcon(CupertinoIcons.add), findsNothing);
  });

  testWidgets('a deck offers no AI card maker, which is coming soon', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, DeckScreen(deck: state.decks.first));
    await tester.tap(find.byTooltip('Tùy chọn bộ thẻ'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm từ'), findsOneWidget);
    expect(find.text('Học lại từ đầu'), findsOneWidget);
    // Before: "Add Cards", a sheet whose only action was the AI maker.
    expect(find.text('Add Cards'), findsNothing);
  });
}
