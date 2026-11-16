part of 'onboarding_screen.dart';

/// The garden step: reviewing words waters the study tree, with the
/// garden's real rules (a drop a review, [waterPerDay] a day, grown after
/// [reviewsPerTree] drops on [waterDays] days). Nothing here is stored.
class _GardenDemo extends StatelessWidget {
  final bool active;
  const _GardenDemo({required this.active});
  @override
  Widget build(BuildContext context) => _StepPage(
    active: active,
    fill: true,
    title: context.t.gardenStepTitle,
    accent: context.t.gardenStepAccent,
    accentColor: D.green,
    body: context.t.gardenStepBody,
    gap: 20,
    children: const [Expanded(child: _After(child: _Watering()))],
  );
}

/// How long a filled day or a grown tree shows before the demo moves on.
const _dayTurn = Duration(milliseconds: 900);

/// The demo starts on the second day with the first day watered, so three
/// taps show a new day and a tree.
const _startDrops = [4, 3];

/// The species a learner can pick before unlocking any.
const _firstSpecies = ['oak', 'pine'];

/// Plants shown in the collection teaser; the last ones are locked.
const _teaserSpecies = ['oak', 'pine', 'cherry', 'mai', 'coconut'];

class _Watering extends StatefulWidget {
  const _Watering();
  @override
  State<_Watering> createState() => _WateringState();
}

class _WateringState extends State<_Watering> {
  /// Drops given each demo day; the last is today.
  var drops = [..._startDrops];
  final planted = <String>[];
  var species = defaultSpecies;
  var word = 0;
  String? note;
  Timer? _turn, _hide;

  int get water => drops.fold(0, (a, b) => a + b);
  bool get _waiting => _turn?.isActive ?? false;

  @override
  void dispose() {
    _turn?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  void _say(String text) {
    setState(() => note = text);
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => note = null);
    });
  }

  /// One review: a drop for today; a full day turns to the next, and the
  /// last drop of a grown tree plants it.
  void _rate() {
    if (_waiting) return;
    AppScope.read(context).feedback.tap();
    final t = context.t;
    setState(() {
      drops = [...drops.take(drops.length - 1), drops.last + 1];
      word++;
    });
    if (water >= reviewsPerTree && drops.length >= waterDays) {
      _turn = Timer(_dayTurn, () {
        if (!mounted) return;
        _say(t.gardenDemoPlanted(speciesName(t, species)));
        setState(() {
          planted.add(species);
          drops = [0];
        });
      });
    } else if (drops.last >= waterPerDay) {
      _turn = Timer(_dayTurn, () {
        if (!mounted) return;
        _say(t.gardenDemoNextDay);
        setState(() => drops = [...drops, 0]);
      });
    }
  }

  void _switchSpecies() {
    AppScope.read(context).feedback.tap();
    setState(
      () => species =
          _firstSpecies[(_firstSpecies.indexOf(species) + 1) %
              _firstSpecies.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final words = _wordsOf(t);
    final current = words[word % words.length];
    final still = MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  D.green.withValues(alpha: .05),
                  D.green.withValues(alpha: .12),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: D.green.withValues(alpha: .2)),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: CapsLabel(t.gardenDemoCaps)),
                        PressFade(
                          key: const ValueKey('onboarding-garden-species'),
                          onTap: _switchSpecies,
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: D.shadow,
                            ),
                            child: Text(
                              t.gardenDemoSpecies(speciesName(t, species)),
                              style: D.text(13, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: water / reviewsPerTree),
                        duration: still
                            ? Duration.zero
                            : const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, growth, _) => FittedBox(
                          child: GardenScene(
                            key: const ValueKey('onboarding-garden-plot'),
                            width: 240,
                            cells: 3,
                            plants: [
                              for (final s in planted)
                                Plant(
                                  source: PlantSource.study,
                                  species: s,
                                  at: _demoDay,
                                ),
                              Plant(
                                source: PlantSource.study,
                                species: species,
                                at: _demoDay,
                                growth: growth.clamp(.02, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _DropDays(drops: drops),
                    const SizedBox(height: 6),
                    Text(
                      t.gardenGrowingDays(
                        water,
                        reviewsPerTree,
                        drops.where((d) => d > 0).length,
                        waterDays,
                      ),
                      textAlign: TextAlign.center,
                      style: D.system(
                        12,
                        weight: FontWeight.w600,
                        color: D.secondary,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 40,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: note == null ? 0 : 1,
                      duration: const Duration(milliseconds: 220),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: D.shadow,
                          ),
                          child: Text(
                            note ?? '',
                            key: const ValueKey('onboarding-garden-note'),
                            style: D.text(13, weight: FontWeight.w700),
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: _panel(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: D.text(17, weight: FontWeight.w800),
                    ),
                    Text(
                      current.meaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: D.system(13, color: D.secondary),
                    ),
                  ],
                ),
              ),
              for (final (i, (color, label)) in [
                (Palette.rateAgain, t.rateAgain),
                (Palette.rateHard, t.rateHardCard),
                (Palette.rateGood, t.rateGood),
                (Palette.rateEasy, t.rateEasyCard),
              ].indexed) ...[
                const SizedBox(width: 6),
                PressFade(
                  key: ValueKey('onboarding-water-$i'),
                  onTap: _rate,
                  child: Container(
                    width: 52,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          label,
                          style: D.system(
                            12,
                            weight: FontWeight.w700,
                            color: Color.lerp(color, D.ink, .25)!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (i, s) in _teaserSpecies.indexed)
              Align(
                widthFactor: .78,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: D.green.withValues(alpha: .08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Opacity(
                    opacity: i < _firstSpecies.length ? 1 : .4,
                    child: TreeArt(
                      species: s,
                      size: 32,
                      island: false,
                      animate: false,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.gardenDemoCollection,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: D.system(12.5, color: D.secondary, height: 17 / 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// When the demo's plants were planted; only their drawing reads it.
final _demoDay = DateTime(2026);

/// [waterDays] groups of [waterPerDay] drops, one group a day, today's
/// marked.
class _DropDays extends StatelessWidget {
  final List<int> drops;
  const _DropDays({required this.drops});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var d = 0; d < waterDays; d++) ...[
        if (d > 0) const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          decoration: BoxDecoration(
            color: d == drops.length - 1 ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < waterPerDay; i++)
                    Icon(
                      CupertinoIcons.drop_fill,
                      size: 12,
                      color: d < drops.length && i < drops[d]
                          ? D.cyan
                          : D.green.withValues(alpha: .22),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                context.t.gardenDemoDay(d + 1),
                style: D.system(
                  10.5,
                  weight: FontWeight.w600,
                  color: D.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

/// The focus step: a small focus screen that plays a 25-minute session in
/// a few seconds, lets the learner try leaving (the warning, then a withered
/// tree) and ends with the break's offer to make the tree bloom.
class _FocusDemo extends StatelessWidget {
  final bool active;
  const _FocusDemo({required this.active});
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    return _StepPage(
      active: active,
      fill: true,
      title: t.focusStepTitle,
      accent: t.focusStepAccent,
      accentColor: Palette.focusSkyMiddle,
      body: t.focusStepBody,
      gap: 20,
      children: [
        const Expanded(child: _After(child: _FocusTry())),
        const SizedBox(height: 10),
        _After(
          delay: const Duration(milliseconds: 150),
          child: Column(
            children: [
              // Android has no app blocking yet.
              if (ios)
                _FocusFact(
                  icon: CupertinoIcons.shield_lefthalf_fill,
                  title: t.focusFactShieldTitle,
                  body: t.focusFactShieldBody,
                ),
              _FocusFact(
                icon: CupertinoIcons.lock_fill,
                title: t.focusFactLockTitle,
                body: t.focusFactLockBody,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FocusFact extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _FocusFact({
    required this.icon,
    required this.title,
    required this.body,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Palette.focusSkyMiddle.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Palette.focusSkyMiddle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: D.text(14.5, weight: FontWeight.w700)),
              Text(
                body,
                style: D.system(13, color: D.secondary, height: 17 / 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

enum _Try { idle, running, away, done, withered }

/// The demo's session length and how fast it plays.
const _tryMinutes = matureMinutes;
const _tryRun = Duration(seconds: 9);

/// The real 30 seconds away, played in three.
const _tryAway = Duration(seconds: 3);
const _awaySeconds = 30;

/// Due words the break offers, as on the real done screen.
const _tryWords = 8;

class _FocusTry extends StatefulWidget {
  const _FocusTry();
  @override
  State<_FocusTry> createState() => _FocusTryState();
}

class _FocusTryState extends State<_FocusTry> with TickerProviderStateMixin {
  var state = _Try.idle;
  late final run = AnimationController(vsync: this, duration: _tryRun)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && state == _Try.running) {
        setState(() => state = _Try.done);
      }
    });
  late final away = AnimationController(vsync: this, duration: _tryAway)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && state == _Try.away) {
        run.stop();
        AppScope.read(context).feedback.impact();
        setState(() => state = _Try.withered);
      }
    });
  late final bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void dispose() {
    run.dispose();
    away.dispose();
    bloom.dispose();
    super.dispose();
  }

  void _go(_Try next) {
    AppScope.read(context).feedback.tap();
    setState(() => state = next);
  }

  void _try() {
    bloom.value = 0;
    run.value = 0;
    _go(_Try.running);
    unawaited(_drive(context, run, 1));
  }

  void _leave() {
    away.value = 0;
    _go(_Try.away);
    unawaited(_drive(context, away, 1));
  }

  void _return() {
    away.stop();
    _go(run.isCompleted ? _Try.done : _Try.running);
  }

  void _bloom() {
    AppScope.read(context).feedback.tap();
    unawaited(_drive(context, bloom, 1));
  }

  String get _clock {
    final left = (_tryMinutes * 60 * (1 - run.value)).round();
    return '${(left ~/ 60).toString().padLeft(2, '0')}:'
        '${(left % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: FocusBackdrop(
        child: AnimatedBuilder(
          animation: Listenable.merge([run, away, bloom]),
          builder: (context, _) {
            final bloomed = bloom.value > 0;
            final (title, line) = switch (state) {
              _Try.idle => (
                _clock,
                '${t.focusTagEnglish} · ${t.focusMinutes(_tryMinutes)}',
              ),
              _Try.running || _Try.away => (_clock, t.focusRunningHint),
              _Try.done => (
                t.focusDoneTitle(_tryMinutes),
                bloomed ? t.focusBloomed : t.focusDoneReview(_tryWords),
              ),
              _Try.withered => (
                t.focusWitheredTitle,
                t.focusWitheredBody(
                  (_tryMinutes * run.value).round().clamp(1, _tryMinutes),
                ),
              ),
            };
            final big =
                state == _Try.running ||
                state == _Try.away ||
                state == _Try.idle;
            return Stack(
              children: [
                Positioned(
                  left: 18,
                  top: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Palette.tagColors.first,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.focusTagEnglish,
                        style: D.text(
                          14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(height: 30),
                    // The plant takes the room the words leave it.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, room) => Center(
                          child: TreeArt(
                            key: const ValueKey('onboarding-focus-tree'),
                            species: defaultSpecies,
                            size: min(room.maxHeight, 170),
                            growth: state == _Try.idle
                                ? .05
                                : run.value.clamp(.05, 1),
                            withered: state == _Try.withered,
                            bloom: bloom.value,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      title,
                      key: const ValueKey('onboarding-focus-title'),
                      style: D
                          .text(
                            big ? 40 : 22,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          )
                          .copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        line,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: D.system(
                          13,
                          weight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: .88),
                          height: 17 / 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: switch (state) {
                        _Try.idle => [
                          _FocusPill(
                            'onboarding-focus-try',
                            t.focusDemoTry,
                            _try,
                          ),
                        ],
                        _Try.running => [
                          _FocusPill(
                            'onboarding-focus-leave',
                            t.focusDemoLeave,
                            _leave,
                            soft: true,
                          ),
                        ],
                        _Try.away => [
                          _FocusPill(
                            'onboarding-focus-return',
                            t.focusDemoReturn,
                            _return,
                          ),
                        ],
                        _Try.done => [
                          if (!bloomed)
                            _FocusPill(
                              'onboarding-focus-bloom',
                              t.focusReviewWords(_tryWords),
                              _bloom,
                            ),
                          _FocusPill(
                            'onboarding-focus-again',
                            t.focusDemoAgain,
                            _try,
                            soft: true,
                          ),
                        ],
                        _Try.withered => [
                          _FocusPill(
                            'onboarding-focus-replant',
                            t.focusReplant,
                            _try,
                          ),
                        ],
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
                // The warning a learner would get after leaving.
                AnimatedPositioned(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  left: 10,
                  right: 10,
                  top: state == _Try.away ? 10 : -90,
                  child: _FocusWarning(
                    seconds: (_awaySeconds * (1 - away.value)).ceil(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FocusPill extends StatelessWidget {
  final String id, label;
  final VoidCallback onTap;
  final bool soft;
  const _FocusPill(this.id, this.label, this.onTap, {this.soft = false});
  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey(id),
    onTap: onTap,
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: soft ? Colors.white.withValues(alpha: .18) : Colors.white,
        borderRadius: BorderRadius.circular(19),
      ),
      // Centred without stretching to the row's width.
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: D.text(
            13.5,
            weight: FontWeight.w700,
            color: soft ? Colors.white : Palette.focusSkyMiddle,
          ),
        ),
      ),
    ),
  );
}

/// The notification banner: the app's logo, the warning and its countdown.
class _FocusWarning extends StatelessWidget {
  final int seconds;
  const _FocusWarning({required this.seconds});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(18),
      boxShadow: D.shadow,
    ),
    child: Row(
      children: [
        const AppLogo(size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.focusWarnTitle,
                style: D.text(13, weight: FontWeight.w700),
              ),
              Text(
                context.t.focusDemoWarnBody(seconds),
                key: const ValueKey('onboarding-focus-warning'),
                style: D.system(12, color: D.secondary, height: 16 / 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
