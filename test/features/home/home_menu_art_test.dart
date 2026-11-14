import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/home/home.dart';
import 'package:hifive/widgets/common.dart';

Widget _art(MenuArtKind kind, {required bool ambient}) => AmbientMotion(
  enabled: ambient,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: MenuArt(kind: kind)),
  ),
);

double _loop(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(MenuArt),
      matching: find.byType(CustomPaint),
    ),
  );
  return (paint.painter! as MenuArtPainter).t.value;
}

void main() {
  for (final kind in MenuArtKind.values) {
    testWidgets('${kind.name} loops under ambient motion', (tester) async {
      await tester.pumpWidget(_art(kind, ambient: true));
      final start = _loop(tester);
      await tester.pump(kind.loop * .3);
      expect(_loop(tester), isNot(start));
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('${kind.name} holds its rest frame in tests', (tester) async {
      await tester.pumpWidget(_art(kind, ambient: false));
      await tester.pump(kind.loop);
      expect(_loop(tester), kind.rest);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }

  testWidgets('turning ambient motion off stops a running icon', (
    tester,
  ) async {
    await tester.pumpWidget(_art(MenuArtKind.blocks, ambient: true));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(_art(MenuArtKind.blocks, ambient: false));
    await tester.pump();
    expect(_loop(tester), MenuArtKind.blocks.rest);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test('keys ease between values and hold past either end', () {
    const track = [(.2, 0.0), (.6, 10.0)];
    expect(MenuArtPainter.key(0, track), 0);
    expect(MenuArtPainter.key(.4, track), closeTo(5, .001));
    expect(MenuArtPainter.key(.25, track), lessThan(1.25));
    expect(MenuArtPainter.key(1, track), 10);
  });

  testWidgets('each menu row shows its own glyph', (tester) async {
    Future<void> row(HomeMenuItem item) => tester.pumpWidget(
      AmbientMotion(
        enabled: false,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: HomeMenuGlyph(item: item),
        ),
      ),
    );
    for (final (item, key) in const [
      (HomeMenuItem.insight, 'menu-art-sparkle'),
      (HomeMenuItem.plus, 'menu-art-gem'),
      (HomeMenuItem.flashcards, 'menu-art-cards'),
      (HomeMenuItem.game, 'menu-art-blocks'),
      (HomeMenuItem.focus, 'menu-art-sprout'),
      (HomeMenuItem.listen, 'menu-art-headphones'),
    ]) {
      await row(item);
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: item.name);
    }
    await row(HomeMenuItem.streak);
    expect(find.byType(StreakFlame), findsOneWidget);
  });
}
