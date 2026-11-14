import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/garden/garden.dart';
import 'package:hifive/widgets/ambient.dart';
import 'package:hifive/widgets/garden/garden_art.dart';

Widget _frame(Widget child, {bool motion = false}) => AmbientMotion(
  enabled: motion,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

void main() {
  test('every species has a drawing', () {
    expect(species.where((s) => !hasTreeArt(s.id)), isEmpty);
  });

  testWidgets('every species draws in every form without errors', (
    tester,
  ) async {
    for (final s in species) {
      // Across the sprout, the young plant and the grown one, and the
      // cross-fades between them.
      for (final g in const [.05, .13, .3, .45, .7, 1.0]) {
        await tester.pumpWidget(
          _frame(TreeArt(species: s.id, size: 120, growth: g)),
        );
      }
      await tester.pumpWidget(
        _frame(TreeArt(species: s.id, size: 120, bloom: 1)),
      );
      await tester.pumpWidget(
        _frame(
          TreeArt(species: s.id, size: 120, withered: true, island: false),
        ),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a garden places its plants and holds still without motion', (
    tester,
  ) async {
    final plants = [
      for (final s in species)
        Plant(source: PlantSource.focus, species: s.id, at: DateTime(2026)),
    ];
    await tester.pumpWidget(
      _frame(
        GardenScene(
          plants: plants,
          width: 300,
          cells: GardenScene.cellsFor(plants.length),
        ),
      ),
    );
    expect(GardenScene.cellsFor(plants.length), 6);
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('trees sway while ambient motion is on', (tester) async {
    await tester.pumpWidget(
      _frame(const TreeArt(species: 'willow', size: 120), motion: true),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('a tree in a grid stays still and asks for no frames', (
    tester,
  ) async {
    await tester.pumpWidget(
      _frame(
        Wrap(
          children: [
            for (final id in ['oak', 'cherry', 'maple'])
              TreeArt(species: id, size: 92, animate: false),
          ],
        ),
        motion: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
