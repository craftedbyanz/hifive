import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'settings_kit.dart';

/// Each mode's preview copy (tag, title, name, number, blurb, Glass tint).
(String, String, String, String, String, Color) _modeCopy(
  BuildContext context,
  StudyMode mode,
) {
  final t = context.t;
  return switch (mode) {
    StudyMode.writing => (
      t.previewWritingTag,
      t.previewWritingTitle,
      t.previewWritingName,
      '01',
      t.previewWritingBlurb,
      Palette.previewBlue,
    ),
    StudyMode.grammar => (
      t.previewGrammarTag,
      t.previewGrammarTitle,
      t.previewGrammarName,
      '02',
      t.previewGrammarBlurb,
      Palette.previewPurple,
    ),
    StudyMode.conversation => (
      t.previewChatTag,
      t.previewChatTitle,
      t.previewChatName,
      '03',
      t.previewChatBlurb,
      Palette.previewCyan,
    ),
  };
}

/// A card style's name; the stored id stays the English word.
String _styleName(BuildContext context, String style) {
  final t = context.t;
  return switch (style) {
    'Regular' => t.styleRegular,
    'Mono' => t.styleMono,
    'Minimal' => t.styleMinimal,
    _ => t.styleGlass,
  };
}

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});
  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  final _preview = PageController(viewportFraction: 309 / 361);

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return SettingsPage(
      title: context.t.appearanceTitle,
      padding: const EdgeInsets.fromLTRB(16, 121, 16, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRSuperellipse(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              height: 320,
              color: Palette.settingsPanel,
              child: PageView(
                key: const ValueKey('appearance-preview'),
                controller: _preview,
                padEnds: false,
                children: [
                  for (final mode in s.modeOrder)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 9),
                      child: _PreviewCard(mode: mode, style: s.appearance),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 31),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Row(
              children: [
                for (final (i, style) in const [
                  'Regular',
                  'Mono',
                  'Minimal',
                  'Glass',
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _StyleTile(
                      style: style,
                      selected: s.appearance == style,
                      onTap: () => s.setAppearance(style),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 23),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.t.cardOrder,
                  style: D.text(16, weight: FontWeight.w700, height: 20 / 16),
                ),
                PressFade(
                  key: const ValueKey('appearance-reset'),
                  onTap: s.resetModeOrder,
                  child: Container(
                    width: 55,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Palette.settingsPanel,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      context.t.reset,
                      style: D.text(
                        12,
                        weight: FontWeight.w600,
                        color: Palette.settingsMuted,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Container(
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(26),
                side: const BorderSide(color: Palette.settingsEdge),
              ),
            ),
            child: ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: s.moveMode,
              proxyDecorator: (child, _, _) =>
                  Material(color: Colors.transparent, child: child),
              children: [
                for (final (i, mode) in s.modeOrder.indexed)
                  _OrderRow(key: ValueKey(mode), mode: mode, index: i),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final StudyMode mode;
  final int index;
  const _OrderRow({super.key, required this.mode, required this.index});
  @override
  Widget build(BuildContext context) {
    final copy = _modeCopy(context, mode);
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: mode.color.withValues(alpha: .72),
              shape: BoxShape.circle,
            ),
            child: Icon(mode.icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.$2,
                  style: D.text(14, weight: FontWeight.w600, height: 19 / 14),
                ),
                const SizedBox(height: 1),
                Text(
                  copy.$3,
                  style: D.text(
                    12.5,
                    color: Palette.settingsMuted,
                    height: 16 / 12.5,
                  ),
                ),
              ],
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              label: context.t.reorderItem(copy.$2),
              child: const SizedBox(
                width: 53,
                height: 45,
                child: Center(
                  child: CustomPaint(
                    size: Size(21, 12),
                    painter: _HandlePainter(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandlePainter extends CustomPainter {
  const _HandlePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.ctaDisabled
      ..strokeWidth = 1.3;
    for (var i = 0; i < 3; i++) {
      final y = .65 + i * (size.height - 1.3) / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_HandlePainter oldDelegate) => false;
}

class _StyleTile extends StatelessWidget {
  final String style;
  final bool selected;
  final VoidCallback onTap;
  const _StyleTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey('appearance-$style'),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 109,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? D.ink : Palette.settingsEdge,
            width: selected ? 2 : 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 59,
            height: 59,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: Palette.settingsPage,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _dot,
          ),
          const SizedBox(height: 11),
          Text(
            _styleName(context, style),
            style: D.text(
              12.5,
              weight: FontWeight.w700,
              color: selected ? D.ink : Palette.settingsHint,
              height: 16 / 12.5,
            ),
          ),
        ],
      ),
    ),
  );

  Widget get _dot => Container(
    width: 32,
    height: 32,
    decoration: switch (style) {
      'Mono' => const BoxDecoration(
        color: Palette.iconGrey,
        shape: BoxShape.circle,
      ),
      'Minimal' => BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Palette.settingsHint, width: 1.5),
      ),
      'Glass' => const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.styleGlassStart, Palette.styleGlassEnd],
        ),
      ),
      _ => const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.styleRegularStart, Palette.styleRegularEnd],
        ),
      ),
    },
  );
}

/// One card of the swipeable preview: the Home card at 88%, clipped by the panel
/// and fading into it at the bottom, in the same look as the Home cards.
class _PreviewCard extends StatelessWidget {
  final StudyMode mode;
  final String style;
  const _PreviewCard({required this.mode, required this.style});
  @override
  Widget build(BuildContext context) {
    final copy = _modeCopy(context, mode);
    final look = mode.cardLook(style);
    final fill = style == 'Glass' ? copy.$6 : look.$1;
    final ink = look.$2;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 80,
              top: -173,
              child: Container(
                width: 348,
                height: 348,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ink.withValues(alpha: .14),
                    width: 38,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 31,
              top: 32,
              child: Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: ink.withValues(alpha: .35)),
                ),
                child: Text(
                  copy.$1,
                  style: D.text(
                    10,
                    weight: FontWeight.w700,
                    color: ink.withValues(alpha: .85),
                    spacing: 1.8,
                    height: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 32,
              top: 32,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: .2),
                  shape: BoxShape.circle,
                ),
                child: Icon(mode.icon, size: 24, color: ink),
              ),
            ),
            Positioned(
              left: 32,
              top: 61,
              child: Text(
                copy.$2,
                style: D.text(
                  33.5,
                  weight: FontWeight.w800,
                  color: ink,
                  spacing: -.7,
                  height: 44 / 33.5,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 196,
              height: 55,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: 146,
                  child: Transform.translate(
                    offset: const Offset(0, -32),
                    child: Text(
                      copy.$4,
                      textAlign: TextAlign.center,
                      style: D.text(
                        112,
                        weight: FontWeight.w800,
                        color: ink.withValues(alpha: .18),
                        height: 146 / 112,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 32,
              top: 296,
              child: Text(
                copy.$5,
                style: D.text(13.5, color: ink, height: 18 / 13.5),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [.77, 1],
                      colors: [
                        Palette.settingsPanelClear,
                        Palette.settingsPanel,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
