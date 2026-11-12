import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'home_design.dart';

class ModeCard extends StatelessWidget {
  final StudyMode mode;

  /// Null while the mode's content is still simulated: the card is dimmed,
  /// marked "Sắp ra mắt" and can't be opened.
  final VoidCallback? onTap;
  const ModeCard({super.key, required this.mode, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final appearance = AppScope.of(context).appearance;
    final (tint, foreground) = mode.cardLook(appearance);
    final soon = onTap == null;
    final card = Semantics(
      button: !soon,
      label: soon
          ? '${mode.title(context)}, ${context.t.comingSoon}'
          : mode.title(context),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: appearance == 'Glass' ? tint.withValues(alpha: .82) : tint,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(38),
              side: BorderSide(
                color: appearance == 'Mono'
                    ? Palette.monoCardEdge
                    : Color.lerp(tint, Colors.black, .12)!,
              ),
            ),
            shadows: [
              BoxShadow(
                color: D.ink.withValues(alpha: .075),
                blurRadius: 26,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Bright rim along the top edge.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .35),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -141,
                right: -143,
                child: Container(
                  width: 322,
                  height: 322,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 40,
                      color: foreground.withValues(alpha: .15),
                    ),
                  ),
                ),
              ),
              // The reference always shows the top of the number, cut flat.
              Positioned(
                top: 171,
                left: 3,
                right: 0,
                height: 91,
                child: ClipRect(
                  child: OverflowBox(
                    maxHeight: 200,
                    alignment: Alignment.topCenter,
                    child: Text(
                      '0${mode.index + 1}',
                      textAlign: TextAlign.center,
                      style: D.text(
                        113,
                        weight: FontWeight.w700,
                        spacing: -.8,
                        color: foreground.withValues(alpha: .22),
                        height: 146 / 106,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 31,
                left: 31,
                right: 31,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.blurb(context),
                      style: D.text(
                        13,
                        weight: FontWeight.w600,
                        height: 21 / 13,
                        color: foreground.withValues(alpha: .85),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: foreground.withValues(alpha: .28),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.t.explore,
                          style: D.text(
                            11,
                            color: foreground.withValues(alpha: .7),
                            weight: FontWeight.w700,
                            spacing: 1.8,
                          ),
                        ),
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: foreground,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(31, 30.3, 31, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 25.7,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: foreground.withValues(alpha: .3),
                                ),
                              ),
                              child: Text(
                                mode.category(context),
                                style: D.text(
                                  10,
                                  color: foreground.withValues(alpha: .72),
                                  weight: FontWeight.w700,
                                  spacing: 1.8,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: .7,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: foreground.withValues(
                                alpha: .17,
                              ),
                              child: mode == StudyMode.writing
                                  ? _WritingGlyph(color: mode.color)
                                  : CustomPaint(
                                      size: Size.square(
                                        mode == StudyMode.grammar ? 30 : 26,
                                      ),
                                      painter: mode == StudyMode.grammar
                                          ? GrammarBadgePainter(
                                              color: foreground,
                                            )
                                          : ConversationBadgePainter(
                                              color: foreground,
                                              dots: tint,
                                            ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mode.title(context),
                      style: HomeDesign.modeTitle.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!soon) return card;
    return Stack(
      children: [
        Opacity(opacity: .55, child: card),
        // Below the mode icon, beside the title.
        const Positioned(top: 100, right: 22, child: SoonBadge(light: true)),
      ],
    );
  }
}

/// The writing card's badge: a white tile with two bars.
class _WritingGlyph extends StatelessWidget {
  final Color color;
  const _WritingGlyph({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 2; i++)
          Container(
            height: 2.4,
            margin: const EdgeInsets.symmetric(vertical: 1.5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    ),
  );
}
