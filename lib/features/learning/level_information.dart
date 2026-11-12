import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';

/// The CEFR levels; the first two letters are the stored id.
const levels = [
  'A1 - Beginner',
  'A2 - Elementary',
  'B1 - Intermediate',
  'B2 - Upper Intermediate',
  'C1 - Advanced',
  'C2 - Proficient',
];

/// A level's name in the interface language; [levels] keeps the ids.
String levelTitle(AppLocalizations t, int index) => [
  t.levelA1Title,
  t.levelA2Title,
  t.levelB1Title,
  t.levelB2Title,
  t.levelC1Title,
  t.levelC2Title,
][index];

String levelDescription(AppLocalizations t, int index) => [
  t.levelA1Body,
  t.levelA2Body,
  t.levelB1Body,
  t.levelB2Body,
  t.levelC1Body,
  t.levelC2Body,
][index];

/// Bar colour for each level on the information sheet, sampled on the iPhone.
const levelColors = [
  Palette.levelGreen,
  Palette.levelLime,
  Palette.levelAmber,
  Palette.categorySelected,
  Palette.levelRed,
  Palette.levelDeepRed,
];

/// Opens the CEFR sheet: a floating sheet inset 9 pt that opens at half
/// height and drags up to nearly full (physical iPhone, 3 November 2026).
Future<void> showLevelInformation(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Palette.sheetBarrier,
      elevation: 0,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: .53,
        minChildSize: .3,
        maxChildSize: .93,
        snap: true,
        snapSizes: const [.53],
        expand: false,
        builder: (ctx, scroll) => Padding(
          padding: EdgeInsets.fromLTRB(
            9,
            0,
            9,
            MediaQuery.paddingOf(ctx).bottom > 0 ? 9 : 0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: ColoredBox(
              color: D.background,
              child: LevelInformation(controller: scroll),
            ),
          ),
        ),
      ),
    );

class LevelInformation extends StatelessWidget {
  final ScrollController? controller;
  const LevelInformation({super.key, this.controller});
  @override
  Widget build(BuildContext context) {
    final current = AppScope.of(context).level;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 24),
      children: [
        Center(
          child: Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: D.line,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.t.levelInfoTitle,
          textAlign: TextAlign.center,
          style: D.text(17, weight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          context.t.cefrBody,
          textAlign: TextAlign.center,
          style: D.text(14, color: D.secondary, height: 1.38),
        ),
        const SizedBox(height: 14),
        Text(
          context.t.changeLevelInSettings,
          textAlign: TextAlign.center,
          style: D.text(12, color: D.muted),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < levels.length; i++) ...[
          if (i > 0 && levels[i - 1].substring(0, 2) != current)
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Divider(height: 1, thickness: .5, color: D.line),
            ),
          _LevelRow(
            title: levelTitle(context.t, i),
            description: levelDescription(context.t, i),
            color: levelColors[i],
            current: levels[i].startsWith(current),
          ),
        ],
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  final String title, description;
  final Color color;
  final bool current;
  const _LevelRow({
    required this.title,
    required this.description,
    required this.color,
    required this.current,
  });
  @override
  Widget build(BuildContext context) => Container(
    color: current ? Palette.levelCurrent : null,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The bar stops 8 pt short of the row's top and bottom.
          Container(
            width: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: D.text(16, weight: FontWeight.w700)),
                      if (current) ...[
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Palette.levelGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.t.currentLabel,
                            style: D.text(
                              9,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: D.text(13, color: D.secondary, height: 1.43),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
