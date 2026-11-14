// Renders the Home menu's animated icons at points through their loops, on
// their row colors, to one PNG for checking by eye:
//   flutter test tool/menu_art_sheet_test.dart --dart-define=PIX_OUT=<dir>
// PIX_OUT must exist and sit outside the repo.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/core/design/design.dart';
import 'package:hifive/widgets/menu_art.dart';

const out = String.fromEnvironment('PIX_OUT');

void main() {
  testWidgets('menu art sheet', (tester) async {
    if (out.isEmpty) return;
    tester.view
      ..physicalSize = const Size(1100, 900)
      ..devicePixelRatio = 1;
    final key = GlobalKey();
    const rows = [
      (MenuArtKind.sparkle, Palette.menuInsight),
      (MenuArtKind.gem, Palette.menuPlus),
      (MenuArtKind.cards, Palette.menuFlashcard),
      (MenuArtKind.blocks, Palette.menuGame),
      (MenuArtKind.sprout, Palette.menuFocus),
      (MenuArtKind.headphones, Palette.menuListen),
    ];
    const at = [0.0, .15, .3, .45, .55, .7, .85];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                for (final (kind, color) in rows)
                  Row(
                    children: [
                      for (final x in at)
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: color,
                            child: CustomPaint(
                              size: const Size.square(90),
                              painter: MenuArtPainter(
                                kind,
                                AlwaysStoppedAnimation(x),
                              ),
                            ),
                          ),
                        ),
                    ],
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
      File('$out/menu_art.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
