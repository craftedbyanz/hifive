import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/core/services/feedback_service.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/home/home.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('with no words at all, today points to the decks', (
    tester,
  ) async {
    // Like a first launch offline: no catalog yet, so no deck.
    final state = createAppState(
      store: MemoryRecordStore(),
      feedback: SilentFeedback(),
      sampleDecks: false,
      now: () => DateTime(2026, 11, 18, 9),
    )..onboarded = true;
    await mount(tester, state, const HomeScreen(animateAmbient: false));
    expect(find.text('Chưa có từ để ôn'), findsOneWidget);
    expect(find.text('Hôm nay đã ôn xong'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('home-today')));
    await tester.pumpAndSettle();
    expect(find.byType(DeckListScreen), findsOneWidget);
  });

  testWidgets('words all studied for today still read as done', (tester) async {
    final state = fresh()..setNewPerDay(0);
    await mount(tester, state, const HomeScreen(animateAmbient: false));
    expect(find.text('Hôm nay đã ôn xong'), findsOneWidget);
    expect(find.text('Chưa có từ để ôn'), findsNothing);
  });
}
