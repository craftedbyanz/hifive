import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'privacy_screen.dart';

/// The reference's upgrade screen, opened as a cover. Nothing here can purchase
/// or start a trial: the button only explains that.
class PlusScreen extends StatefulWidget with CoverPage {
  const PlusScreen({super.key});
  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen> {
  // Only the yearly state was observed. The monthly button and note follow its
  // pattern, using the numbers on the monthly plan's row.
  bool _yearly = true;

  @override
  Widget build(BuildContext context) {
    final note = _yearly ? context.t.plusYearlyNote : context.t.plusMonthlyNote;
    return HeaderScrollPage(
      title: context.t.plusTitle,
      titleSize: 16.5,
      leadingIcon: Icons.close_rounded,
      leadingIconSize: 30,
      leadingWidth: 48,
      leadingLabel: context.t.close,
      padding: const EdgeInsets.only(top: 133, bottom: 254),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PressFade(
              key: const ValueKey('plus-cta'),
              onTap: () => toast(context, context.t.plusNoTransaction),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: D.ink,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  _yearly ? context.t.plusYearlyCta : context.t.plusMonthlyCta,
                  style: D.text(
                    15,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    height: 20 / 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 33),
              child: Text(
                note,
                textAlign: TextAlign.center,
                style: D.text(10.5, color: Palette.plusBody, height: 14 / 10.5),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Hero(),
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Column(
              children: [
                _Plan(
                  title: context.t.planYearly,
                  monthly: context.t.planYearlyPerMonth,
                  price: context.t.priceYearly,
                  unit: context.t.perYear,
                  trial: context.t.planYearlyTrial,
                  badge: context.t.save40,
                  height: 90.5,
                  selected: _yearly,
                  onTap: () => setState(() => _yearly = true),
                ),
                const SizedBox(height: 11.5),
                _Plan(
                  title: context.t.planMonthly,
                  monthly: context.t.planMonthlyPerMonth,
                  price: context.t.priceMonthly,
                  unit: context.t.perMonth,
                  trial: context.t.planMonthlyTrial,
                  height: 74,
                  selected: !_yearly,
                  onTap: () => setState(() => _yearly = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 46),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.plusPerksTitle,
                  style: D.text(19, weight: FontWeight.w700, height: 25 / 19),
                ),
                const SizedBox(height: 5),
                Text(
                  context.t.plusPerksBody,
                  style: D.text(13, color: Palette.plusBody, height: 18 / 13),
                ),
                const SizedBox(height: 39),
                ..._perks(context.t),
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note,
                        style: D.text(
                          12,
                          color: Palette.plusBody,
                          height: 15 / 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.t.plusRenewalNote,
                        style: D.text(
                          12,
                          color: Palette.plusBody,
                          height: 15 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 57),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Link(
                      context.t.agreeTerms,
                      onTap: () async {
                        final shown = await AppScope.read(context).system
                            .openTerms();
                        if (!shown && context.mounted) {
                          toast(context, context.t.cannotOpenTermsPage);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    _Link(
                      context.t.privacyShort,
                      onTap: () => PrivacyScreen.showSheet(context),
                    ),
                    const SizedBox(width: 16),
                    _Link(
                      context.t.restore,
                      onTap: () => toast(context, context.t.plusNoTransaction),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<_Perk> _perks(AppLocalizations t) => [
    _Perk(
      icon: CupertinoIcons.chart_bar_alt_fill,
      title: t.perkLimitsTitle,
      body: t.perkLimitsBody,
    ),
    _Perk(
      icon: CupertinoIcons.rectangle_stack_fill,
      title: t.perkDecksTitle,
      body: t.perkDecksBody,
    ),
    _Perk(
      icon: CupertinoIcons.bubble_left_fill,
      title: t.perkChatTitle,
      body: t.perkChatBody,
    ),
    _Perk(
      icon: CupertinoIcons.infinite,
      disc: true,
      title: t.perkInfiniteTitle,
      body: t.perkInfiniteBody,
    ),
    _Perk(
      icon: CupertinoIcons.arrow_2_circlepath,
      title: t.perkEarlyTitle,
      body: t.perkEarlyBody,
    ),
    _Perk(
      icon: CupertinoIcons.globe,
      disc: true,
      title: t.perkLanguagesTitle,
      soon: true,
      body: t.perkLanguagesBody,
    ),
  ];
}

class _Link extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Link(this.label, {required this.onTap});
  @override
  Widget build(BuildContext context) => PressFade(
    onTap: onTap,
    child: Text(
      label,
      style: D.text(12, color: Palette.settingsMuted, height: 15 / 12),
    ),
  );
}

class _Perk extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final bool soon, disc;
  const _Perk({
    required this.icon,
    required this.title,
    required this.body,
    this.soon = false,
    this.disc = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 3),
          child: disc
              ? Container(
                  width: 21,
                  height: 21,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: Colors.white),
                )
              : Icon(icon, size: 25, color: Colors.black),
        ),
        const SizedBox(width: 19),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: D.text(13, weight: FontWeight.w700, height: 18 / 13),
                  ),
                  if (soon) ...[
                    const SizedBox(width: 11),
                    Container(
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Palette.plusSoonFill,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        context.t.comingSoonLower,
                        style: D.text(
                          10.5,
                          weight: FontWeight.w600,
                          color: Palette.plusSoonInk,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: D.text(
                  11.8,
                  color: Palette.settingsMuted,
                  height: 16.7 / 11.8,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Plan extends StatelessWidget {
  final String title, monthly, price, unit, trial;
  final String? badge;
  final double height;
  final bool selected;
  final VoidCallback onTap;
  const _Plan({
    required this.title,
    required this.monthly,
    required this.price,
    required this.unit,
    required this.trial,
    this.badge,
    required this.height,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: PressFade(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: ShapeDecoration(
                  color: selected ? Palette.plusFill : Colors.white,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: BorderSide(
                      color: selected
                          ? Palette.plusBlue
                          : Palette.settingsPanel,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                left: 17,
                top: -9,
                child: Container(
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Palette.plusBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: D.text(
                      10.5,
                      weight: FontWeight.w600,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, badge != null ? 16 : 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: badge != null ? 15.5 : 12.5),
                    child: _Radio(selected: selected),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: badge != null
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: D.text(
                                  15,
                                  weight: FontWeight.w700,
                                  height: 21 / 15,
                                ),
                              ),
                            ),
                            Text(
                              price,
                              style: D.text(
                                16.5,
                                weight: FontWeight.w700,
                                height: 22 / 16.5,
                              ),
                            ),
                            Text(
                              unit,
                              style: D.text(
                                11,
                                color: Palette.settingsMuted,
                                height: 15 / 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              monthly,
                              style: D.text(
                                12.5,
                                color: Palette.settingsMuted,
                                height: 17 / 12.5,
                              ),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 9),
                                child: Text(
                                  trial,
                                  textAlign: TextAlign.right,
                                  style: D.text(
                                    11,
                                    color: Palette.settingsMuted,
                                    height: 14 / 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? Palette.plusBlue : Palette.settingsEdge,
        width: 2,
      ),
    ),
    child: selected
        ? Container(
            width: 13,
            height: 13,
            decoration: const BoxDecoration(
              color: Palette.plusBlue,
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}

/// The headline slides horizontally every 3 s, in about 0.3 s, and always
/// continues to the left. Measured from video.
class _Hero extends StatefulWidget {
  const _Hero();
  static const interval = Duration(seconds: 3);
  static const slideCount = 3;
  static List<(String, String, String)> slides(AppLocalizations t) => [
    (t.heroSlide1Top, t.heroSlide1Bottom, t.heroSlide1Body),
    (t.heroSlide2Top, t.heroSlide2Bottom, t.heroSlide2Body),
    (t.heroSlide3Top, t.heroSlide3Bottom, t.heroSlide3Body),
  ];
  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  // Starting far from zero allows swiping back past the first slide.
  static const _firstPage = 300;
  final _pages = PageController(initialPage: _firstPage);
  late final Timer _timer = Timer.periodic(_Hero.interval, (_) {
    if (!mounted || !_pages.hasClients) return;
    _pages.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  });
  int _slide = 0;

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void dispose() {
    _timer.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 150,
        child: PageView.builder(
          key: const ValueKey('plus-hero'),
          controller: _pages,
          onPageChanged: (page) =>
              setState(() => _slide = (page - _firstPage) % _Hero.slideCount),
          itemBuilder: (_, page) {
            final index = (page - _firstPage) % _Hero.slideCount;
            final (top, bottom, text) = _Hero.slides(context.t)[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(top, style: _headline(D.ink)),
                      const SizedBox(width: 13),
                      _HeroGlyph(index),
                    ],
                  ),
                  Text(bottom, style: _headline(Palette.plusBlue)),
                  const SizedBox(height: 5),
                  Text(
                    text,
                    style: D.text(
                      14,
                      color: Palette.plusBody,
                      height: 18.5 / 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            for (var i = 0; i < _Hero.slideCount; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 6),
                width: i == _slide ? 24 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: i == _slide ? Palette.plusBlue : Palette.settingsEdge,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  static TextStyle _headline(Color color) => D.text(
    38,
    weight: FontWeight.w800,
    color: color,
    spacing: -.8,
    height: 50 / 38,
  );
}

class _HeroGlyph extends StatelessWidget {
  final int slide;
  const _HeroGlyph(this.slide);
  @override
  Widget build(BuildContext context) => switch (slide) {
    0 => const Icon(
      CupertinoIcons.sparkles,
      size: 38,
      color: Palette.plusSpark,
    ),
    1 => const Icon(CupertinoIcons.infinite, size: 42, color: Palette.plusBlue),
    _ => Container(
      width: 34,
      height: 32,
      decoration: BoxDecoration(
        color: Palette.plusChat,
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Icon(CupertinoIcons.ellipsis, size: 20, color: Colors.white),
    ),
  };
}
