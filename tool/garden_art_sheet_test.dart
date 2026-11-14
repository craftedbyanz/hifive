// Renders every garden species as the collection shows it, the forms of a
// few species as they grow, bloom and wither on the focus screen's sunlit
// patch, and a sample garden, to one PNG to judge by eye:
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
      ..physicalSize = const Size(1200, 2280)
      ..devicePixelRatio = 1;
    final key = GlobalKey();
    final plants = [
      for (var i = 0; i < 22; i++)
        Plant(
          source: PlantSource.focus,
          species: species[(i * 7) % species.length].id,
          at: DateTime(2026, 11, 13),
          growth: i == 20 ? .05 : (i == 17 ? .3 : 1),
          withered: i == 9,
          bloomed: i == 4,
        ),
    ];
    const label = TextStyle(fontSize: 13, color: Color(0xFF374151));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: const Color(0xFFF8FBFC),
            child: Column(
              children: [
                Wrap(
                  children: [
                    for (final s in species)
                      SizedBox(
                        width: 200,
                        child: Column(
                          children: [
                            TreeArt(species: s.id, size: 190, island: false),
                            Text(s.id, style: label),
                          ],
                        ),
                      ),
                  ],
                ),
                Container(
                  color: const Color(0xFF4C52D2),
                  child: Column(
                    children: [
                      for (final id in const ['oak', 'pine', 'cherry'])
                        Row(
                          children: [
                            for (final g in const [.06, .3, .6, 1.0])
                              TreeArt(species: id, size: 170, growth: g),
                            TreeArt(species: id, size: 170, bloom: 1),
                            TreeArt(species: id, size: 170, withered: true),
                          ],
                        ),
                    ],
                  ),
                ),
                GardenScene(plants: plants, width: 520),
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
