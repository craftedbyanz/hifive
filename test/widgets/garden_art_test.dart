import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  testWidgets('the lock screen picture is round, with clear corners', (
    tester,
  ) async {
    // A sprout is framed closest, so its grass reaches the picture's edges.
    for (final growth in const [.05, .3, 1.0]) {
      final pixels = await tester.runAsync(() async {
        final png = await plantPicture(defaultSpecies, growth, size: 120);
        final codec = await ui.instantiateImageCodec(png!);
        final image = (await codec.getNextFrame()).image;
        final data = await image.toByteData();
        image.dispose();
        return data!;
      });
      int alpha(int x, int y) => pixels!.getUint8((y * 120 + x) * 4 + 3);
      for (final (x, y) in const [(2, 2), (117, 2), (2, 117), (117, 117)]) {
        expect(alpha(x, y), 0, reason: 'corner $x,$y at growth $growth');
      }
      // Straight down from the centre, just inside the circle.
      expect(alpha(60, 112), greaterThan(0), reason: 'growth $growth');
    }
  });

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

  testWidgets('the weather moves with ambient motion and stays still without', (
    tester,
  ) async {
    for (final w in GardenWeather.values) {
      await tester.pumpWidget(
        _frame(
          GardenScene(plants: const [], width: 300, weather: w),
          motion: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.hasScheduledFrame, isTrue, reason: w.name);
    }
    // Without weather (past periods) or without motion it draws one frame.
    await tester.pumpWidget(
      _frame(const GardenScene(plants: [], width: 300), motion: true),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(
      _frame(
        const GardenScene(plants: [], width: 300, weather: GardenWeather.rain),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the weather repaints; the land holds still under it', (
    tester,
  ) async {
    final plants = [
      for (final s in species.take(8))
        Plant(source: PlantSource.focus, species: s.id, at: DateTime(2026)),
    ];
    await tester.pumpWidget(
      _frame(
        GardenScene(plants: plants, width: 300, weather: GardenWeather.rain),
        motion: true,
      ),
    );
    List<int> paints() => [
      for (final b in tester.renderObjectList<RenderRepaintBoundary>(
        find.descendant(
          of: find.byType(GardenScene),
          matching: find.byType(RepaintBoundary),
        ),
      ))
        b.debugSymmetricPaintCount + b.debugAsymmetricPaintCount,
    ];
    final before = paints();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 17));
    }
    final after = paints();
    // The still sky, the clouds and rain behind, the still land, the
    // weather in front.
    expect(before, hasLength(4));
    expect(after[0], before[0]);
    expect(after[1], greaterThan(before[1]));
    expect(after[2], before[2]);
    expect(after[3], greaterThan(before[3]));
  });
}
