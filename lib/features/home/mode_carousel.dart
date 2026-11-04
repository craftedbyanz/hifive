import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../widgets/common.dart';
import '../learning/learning.dart';
import 'home_design.dart';
import 'mode_card.dart';

class ModeCarousel extends StatelessWidget {
  final PageController controller;
  final List<StudyMode> modes;
  final int selected;
  final ValueChanged<int> onPageChanged;
  const ModeCarousel({
    super.key,
    required this.controller,
    required this.modes,
    required this.selected,
    required this.onPageChanged,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: HomeDesign.cardHeight,
    child: Padding(
      padding: const EdgeInsets.only(left: 8.5, right: 9.5),
      child: ClipRect(
        clipper: const _CarouselClip(),
        child: PageView.builder(
          clipBehavior: Clip.none,
          padEnds: false,
          physics: const CardPagePhysics(),
          key: const ValueKey('mode-carousel'),
          controller: controller,
          itemCount: modes.length,
          onPageChanged: onPageChanged,
          itemBuilder: (_, i) => AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final page = controller.hasClients
                  ? (controller.page ?? selected.toDouble())
                  : selected.toDouble();
              final distance = (page - i).abs().clamp(0.0, 1.0);
              return Transform.scale(
                scaleX: 1,
                scaleY: 1 - .04 * distance,
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: 1 - .48 * distance,
                  // Cards away from the center rest slightly out of focus.
                  child: distance == 0
                      ? child
                      : ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 2.4 * distance,
                            sigmaY: 2.4 * distance,
                          ),
                          child: child,
                        ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7.5),
              child: ModeCard(
                mode: modes[i],
                onTap: () => go<void>(context, TopicScreen(mode: modes[i])),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Side cards reach the screen edges, and the shadow stops 19 pt below the card.
class _CarouselClip extends CustomClipper<Rect> {
  const _CarouselClip();
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-40, -40, size.width + 40, size.height + 19);
  @override
  bool shouldReclip(_CarouselClip oldClipper) => false;
}

class ModeIndicator extends StatelessWidget {
  final int count, selected;
  const ModeIndicator({super.key, required this.count, required this.selected});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: selected == i ? 32 : 8,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected == i ? D.lime : D.line,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
    ],
  );
}

/// Page settle measured from six swipes in the reference recording: no
/// overshoot, with the remaining distance decaying at about 10.9 per second.
class CardPagePhysics extends BouncingScrollPhysics {
  const CardPagePhysics({super.parent});
  @override
  CardPagePhysics applyTo(ScrollPhysics? ancestor) =>
      CardPagePhysics(parent: buildParent(ancestor));
  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: .5,
    stiffness: 144.5,
    ratio: 1.1,
  );
}
