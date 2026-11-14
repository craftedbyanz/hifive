// Renders a few garden species large, to judge their painting up close,
// and every species as the collection shows it (garden_collection.png):
//   flutter test tool/garden_zoom_test.dart --dart-define=PIX_OUT=<dir>
// PIX_OUT must exist and sit outside the repo.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/garden/garden.dart';
import 'package:hifive/widgets/garden/garden_art.dart';

const out = String.fromEnvironment('PIX_OUT');
const ids = String.fromEnvironment(
  'PIX_SPECIES',
  defaultValue: 'oak,cherry,maple,banyan',
);

/// `--dart-define=PIX_ISLAND=false` draws the large trees without land.
const island = bool.fromEnvironment('PIX_ISLAND', defaultValue: true);

void main() {
  testWidgets('garden zoom', (tester) async {
    if (out.isEmpty) return;
    final list = ids.split(',');
    tester.view
      ..physicalSize = Size(380.0 * list.length, 420)
      ..devicePixelRatio = 1;
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: island ? const Color(0xFF4C52D2) : const Color(0xFFF8FBFC),
            child: Row(
              children: [
                for (final s in list)
                  TreeArt(species: s, size: 380, island: island),
              ],
            ),
          ),
        ),
      ),
    );
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/garden_zoom.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  });

  testWidgets('garden collection', (tester) async {
    if (out.isEmpty) return;
    tester.view
      ..physicalSize = const Size(6 * 150, 5 * 150)
      ..devicePixelRatio = 1;
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: const Color(0xFFF4F8F6),
            child: Wrap(
              children: [
                for (final s in species)
                  TreeArt(
                    species: s.id,
                    size: 150,
                    island: false,
                    animate: false,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/garden_collection.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
