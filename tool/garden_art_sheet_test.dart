// Renders every garden species, its five forms and a sample garden to one PNG,
// to compare with the approved mockup (docs/mockups/garden.html) by eye:
//   flutter test tool/garden_art_sheet_test.dart --dart-define=PIX_OUT=<dir>
// PIX_OUT must exist and sit outside the repo.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/garden/garden.dart';
import 'package:hifive/widgets/garden/garden_art.dart';

const out = String.fromEnvironment('PIX_OUT');

void main() {
  testWidgets('garden art sheet', (tester) async {
    if (out.isEmpty) return;
    tester.view
      ..physicalSize = const Size(1200, 1900)
      ..devicePixelRatio = 1;
    final key = GlobalKey();
    final plants = [
      for (var i = 0; i < 22; i++)
        Plant(
          source: PlantSource.focus,
          species: species[(i * 5) % species.length].id,
          at: DateTime(2026, 11, 13),
          growth: i == 20 ? .05 : (i == 17 ? .3 : 1),
          withered: i == 9,
          bloomed: i == 4,
        ),
    ];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: const Color(0xFF4C52D2),
            child: Column(
              children: [
                Wrap(
                  children: [
                    for (final s in species)
                      Column(
                        children: [
                          TreeArt(species: s.id, size: 170),
                          Text(s.id, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                  ],
                ),
                Row(
                  children: [
                    for (final g in const [.06, .3, .66, 1.0])
                      TreeArt(species: 'cherry', size: 150, growth: g),
                    const TreeArt(species: 'cherry', size: 150, bloom: 1),
                    const TreeArt(species: 'oak', size: 150, withered: true),
                    const TreeArt(species: 'mai', size: 150, growth: .3),
                  ],
                ),
                Container(
                  color: const Color(0xFFF5F6FD),
                  child: GardenScene(plants: plants, width: 420),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage();
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    File('$out/garden_art.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
