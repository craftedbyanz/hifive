import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/home/home.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('tapping a reminder opens today on Home', (tester) async {
    const channel = MethodChannel('hifive/screen');
    var tapped = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'takeReviewTap') return null;
          final was = tapped;
          tapped = false;
          return was;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    // The tap that launched the app opens the review once Home is up.
    await mount(tester, fresh(), const HomeScreen(animateAmbient: false));
    await tester.pumpAndSettle();
    final review = tester.widget<ReviewScreen>(find.byType(ReviewScreen));
    expect(review.source, 'today');
    await tester.tap(find.byTooltip('Đóng ôn tập'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewScreen), findsNothing);

    // A tap while the app runs opens it again.
    tapped = true;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(const MethodCall('reviewTapped')),
          (_) {},
        );
    await tester.pumpAndSettle();
    expect(find.byType(ReviewScreen), findsOneWidget);
  });

  testWidgets('tapping a word note opens that word', (tester) async {
    const channel = MethodChannel('hifive/screen');
    final state = fresh();
    final word = state.decks.first.words[2];
    String? tapped = word.id;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'takeWordTap') return null;
          final was = tapped;
          tapped = null;
          return was;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await mount(tester, state, const HomeScreen(animateAmbient: false));
    await tester.pumpAndSettle();
    final page = tester.widget<WordScreen>(find.byType(WordScreen));
    expect(page.word, same(word));
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(WordScreen), findsNothing);

    // A note for a word deleted since opens nothing.
    tapped = 'gone';
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            const MethodCall('wordTapped', 'gone'),
          ),
          (_) {},
        );
    await tester.pumpAndSettle();
    expect(find.byType(WordScreen), findsNothing);
  });
}
