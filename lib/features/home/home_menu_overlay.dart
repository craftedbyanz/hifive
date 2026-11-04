import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../flashcards/flashcards.dart';
import '../game/game.dart';
import '../information/information.dart';
import '../insights/insights.dart';
import 'home_menu_motion.dart';
import 'home_painters.dart';

class HomeMenuOverlay extends StatelessWidget {
  final Animation<double> motion;
  final ui.Image? backdrop;
  final VoidCallback onClose;
  final ValueChanged<Widget> onSelect;
  const HomeMenuOverlay({
    super.key,
    required this.motion,
    required this.backdrop,
    required this.onClose,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Insight', Palette.menuInsight, const InsightScreen()),
      ('Nâng cấp Hifive Plus', Palette.menuPlus, const PlusScreen()),
      ('Học flashcard', Palette.menuFlashcard, const DeckListScreen()),
      ('Chuỗi của tôi', Palette.menuStreak, const StreakScreen()),
      ('Chơi FlowLetter', Palette.menuGame, const GameHomeScreen()),
    ];
    return AnimatedBuilder(
      animation: motion,
      builder: (context, _) {
        final m = MenuMotion.at(
          motion.value,
          closing: motion.status == AnimationStatus.reverse,
        );
        return GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: m.backdropOpacity,
                      child: _MenuBackdrop(image: backdrop),
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      key: const ValueKey('home-menu-list'),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      // The reference list has 14 pt of travel when dragged.
                      child: SizedBox(
                        height: box.maxHeight + MenuMotion.listTravel,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 6 + MenuMotion.listTravel,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              for (var i = 0; i < items.length; i++)
                                Transform.translate(
                                  offset: Offset(
                                    0,
                                    (items.length - 1 - i) *
                                        MenuMotion.rowSpacing *
                                        (1 - m.spread),
                                  ),
                                  child: Transform.scale(
                                    scale: m.rowScale,
                                    child: Opacity(
                                      opacity: m.rowOpacity,
                                      child: ImageFiltered(
                                        enabled: m.rowBlur > .05,
                                        imageFilter: ImageFilter.blur(
                                          sigmaX: m.rowBlur,
                                          sigmaY: m.rowBlur,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => onSelect(items[i].$3),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: items[i].$2,
                                                  child: HomeMenuGlyph(
                                                    label: items[i].$1,
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Text(
                                                  items[i].$1,
                                                  style: HomeDesign.menuLabel,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuBackdrop extends StatelessWidget {
  final ui.Image? image;
  const _MenuBackdrop({required this.image});
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (image != null)
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.white,
              Colors.white,
            ],
            stops: [0, .23, .52, 1],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
            child: RawImage(image: image, fit: BoxFit.fill),
          ),
        ),
      // Veil color and opacity solved from the reference over known colors.
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Palette.menuVeil.withValues(alpha: .14),
              Palette.menuVeil.withValues(alpha: .18),
              Palette.menuVeil.withValues(alpha: .32),
              Palette.menuVeil.withValues(alpha: .54),
              Palette.menuVeil.withValues(alpha: .5),
            ],
            stops: const [0, .09, .18, .26, 1],
          ),
        ),
      ),
    ],
  );
}
