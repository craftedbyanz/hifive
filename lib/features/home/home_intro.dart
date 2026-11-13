import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../flashcards/flashcards.dart';
import '../garden/garden.dart';
import 'home_design.dart';
import 'home_lower.dart';
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
          const HomeTodayCard(),
          const SizedBox(height: 12),
          HomeGardenBanner(
            onTap: () => go<void>(context, const GardenScreen()),
          ),
          const SizedBox(height: 23),
          Text(t.homeModesTitle, style: HomeDesign.section),
          const SizedBox(height: 3),
          Text(t.homeModesSubtitle, style: HomeDesign.body),
        ],
      ),
    );
  }
}

/// Opens today's review in the flashcard session: the next leg of due words
/// and new ones, flipped and swiped like any deck.
Future<void> openToday(BuildContext context) {
  final state = AppScope.read(context);
  final leg = state.today.leg();
  if (leg.isEmpty) return go<void>(context, const DeckListScreen());
  final deck = Deck(
    id: 'today',
    title: context.t.todayTitle,
    description: '',
    words: leg,
  );
  return go<void>(
    context,
    ReviewScreen(deck: deck, words: leg, source: 'today'),
  );
}

/// Today's review on Home, in the flashcards' own look: what is waiting,
/// how long it takes, and a small fan of cards showing the next word.
class HomeTodayCard extends StatelessWidget {
  const HomeTodayCard({super.key});

  /// Seconds a card takes, for the estimate.
  static const secondsPerCard = 12;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final plan = AppScope.of(context).today;
    final leg = plan.leg();
    final done = leg.isEmpty;
    final minutes = (leg.length * secondsPerCard / 60).ceil();
    return PressFade(
      key: const ValueKey('home-today'),
      onTap: () => openToday(context),
      child: Container(
        // Grows with the text size, like every fixed height holding text.
        height: context.grow(118),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: D.shadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 4, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      done
                          ? t.todayEyebrow
                          : '${t.todayEyebrow} · ${t.todayMinutes(minutes).toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CapsLabel.style,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      done ? t.todayAllDone : t.todayHeadline,
                      style: D.text(19, weight: FontWeight.w800, spacing: -.4),
                    ),
                    const SizedBox(height: 9),
                    if (done)
                      Text(
                        t.todayDoneBody,
                        key: const ValueKey('home-today-summary'),
                        style: D.text(12.5, color: D.secondary),
                      )
                    else
                      Wrap(
                        key: const ValueKey('home-today-summary'),
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (plan.due.isNotEmpty)
                            _Chip(t.todayDueChip(plan.due.length), D.orange),
                          if (plan.fresh.isNotEmpty)
                            _Chip(
                              t.todayNewChip(plan.fresh.length),
                              Palette.menuFocus,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 108,
              child: done
                  ? const Center(
                      child: Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        size: 44,
                        color: D.green,
                      ),
                    )
                  : _CardFan(word: leg.first.word),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  /// The dot's color; null draws none.
  final Color? color;
  const _Chip(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: D.background,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: D.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (color case final c?) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: D.text(11.5, weight: FontWeight.w600, color: D.secondary),
        ),
      ],
    ),
  );
}

/// Three flashcards fanned out, the front one showing the next word, as the
/// review screen stacks them.
class _CardFan extends StatelessWidget {
  final String word;
  const _CardFan({required this.word});

  Widget _card({required double angle, required Offset at, Widget? child}) =>
      Positioned(
        left: at.dx,
        top: at.dy,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: 70,
            height: 88,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: D.line),
              boxShadow: D.shadow,
            ),
            child: child,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      _card(angle: .2, at: const Offset(34, 16)),
      _card(angle: .08, at: const Offset(22, 14)),
      _card(
        angle: -.08,
        at: const Offset(8, 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: D.text(13, weight: FontWeight.w800, height: 1.15),
            ),
            const SizedBox(height: 6),
            Container(
              width: 18,
              height: 3,
              decoration: BoxDecoration(
                color: Palette.menuFocus,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
