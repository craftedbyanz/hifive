import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../information/information.dart';
import 'home_design.dart';
import 'home_painters.dart';

class HomeIntro extends StatelessWidget {
  final Animation<double> ambient;
  const HomeIntro({super.key, required this.ambient});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final hour = state.now().hour, t = context.t;
    final greeting = hour < 5 || hour >= 22
        ? t.greetingNight
        : hour < 12
        ? t.greetingMorning
        : hour < 18
        ? t.greetingAfternoon
        : t.greetingEvening;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: HomeDesign.greeting),
          Text(state.name, style: HomeDesign.name),
          const SizedBox(height: 18),
          Text(t.homeWhatToLearn, style: HomeDesign.body),
          const SizedBox(height: 4),
          // AI lessons come later; the link shows what is coming.
          Semantics(
            label: '${t.homeAiLesson}, ${t.comingSoon}',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Positioned(
                      left: 0,
                      bottom: 0,
                      width: 70,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Palette.aiUnderline,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: .5,
                      child: Text(t.homeAiLesson, style: HomeDesign.aiLink),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                AiOrb(size: 30, animation: ambient),
                const SizedBox(width: 8),
                const SoonBadge(),
              ],
            ),
          ),
          const SizedBox(height: 39),
          PlusBanner(onTap: () => go<void>(context, const PlusScreen())),
          const SizedBox(height: 23),
          Text(t.homeModesTitle, style: HomeDesign.section),
          const SizedBox(height: 3),
          Text(t.homeModesSubtitle, style: HomeDesign.body),
        ],
      ),
    );
  }
}
