import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../core/services/screen_lock.dart';
import '../../domain/garden/garden.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../../widgets/garden/garden_art.dart';
import '../flashcards/flashcards.dart';
import 'tag_sheet.dart';
import 'timer_sheet.dart';

part 'focus_parts.dart';

enum _Phase { setup, running, done, withered }

/// A focus session: pick a length on the timer ruler (or the stopwatch), a
/// tag, a title and a tree, then leave the phone alone while the tree grows. Leaving the app for more than [awayLimit]
/// withers it; locking the phone does not. The first [cancelWindow] can be
/// cancelled without a withered tree. After a finished session the break
/// offers due words; reviewing them makes the tree bloom.
class FocusScreen extends StatefulWidget {
  /// Wall time for the running session, so tests can move it.
  final DateTime Function() clock;
  const FocusScreen({super.key, this.clock = DateTime.now});

  /// A stopwatch session shorter than this plants nothing.
  static const stopwatchMinimum = Duration(minutes: 10);
  static const awayLimit = Duration(seconds: 30);
  static const cancelWindow = Duration(seconds: 10);

  /// How many due words the break offers at most.
  static const breakWords = 8;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  var _phase = _Phase.setup;

  /// The chosen length; 0 is the stopwatch.
  var _minutes = 25;
  var _title = '';
  late String _tag = AppScope.read(context).focusTag;
  late String _species = AppScope.read(context).studySpecies;

  DateTime? _startedAt, _recordStart, _leftAt;
  var _elapsed = Duration.zero;
  Timer? _timer;
  FocusSession? _session;
  late final _bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool get _stopwatch => _minutes == 0;

  /// The countdown's length, or the stopwatch's limit.
  Duration get _planned =>
      Duration(minutes: _stopwatch ? maxMinutes : _minutes);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ScreenLock.listen();
    ScreenLock.locked.addListener(_onLock);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenLock.locked.removeListener(_onLock);
    _timer?.cancel();
    if (_phase == _Phase.running) ScreenLock.clearWarning();
    _bloom.dispose();
    super.dispose();
  }

  void _start() {
    final state = AppScope.read(context);
    setState(() {
      _phase = _Phase.running;
      _startedAt = widget.clock();
      _recordStart = state.now();
      _elapsed = Duration.zero;
      _leftAt = null;
      _session = null;
      _bloom.value = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ScreenLock.prepareWarning();
  }

  void _tick() {
    if (_phase != _Phase.running || _leftAt != null) return;
    setState(() => _elapsed = widget.clock().difference(_startedAt!));
    if (_elapsed >= _planned) _end(FocusOutcome.done, _planned);
  }

  void _end(FocusOutcome outcome, Duration focused) {
    _timer?.cancel();
    ScreenLock.clearWarning();
    final state = AppScope.read(context);
    if (outcome == FocusOutcome.cancelled) {
      setState(() => _phase = _Phase.setup);
      return;
    }
    final session = FocusSession(
      id: state.newId(),
      start: _recordStart!,
      end: _recordStart!.add(focused),
      plannedMinutes: _minutes,
      tag: _tag,
      title: _title,
      species: _species,
      outcome: outcome,
    );
    state.recordFocus(session);
    if (outcome == FocusOutcome.done) state.feedback.success();
    setState(() {
      _session = session;
      _elapsed = focused;
      _phase = outcome == FocusOutcome.done ? _Phase.done : _Phase.withered;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (_phase != _Phase.running) return;
    switch (s) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        if (!ScreenLock.locked.value && _leftAt == null) {
          _leftAt = widget.clock();
          final t = context.t;
          ScreenLock.warn(t.focusWarnTitle, t.focusWarnBody);
        }
      case AppLifecycleState.resumed:
        final left = _leftAt;
        _leftAt = null;
        ScreenLock.clearWarning();
        if (left == null) return _tick();
        if (widget.clock().difference(left) > FocusScreen.awayLimit) {
          final focused = left.difference(_startedAt!);
          _end(
            focused >= _planned ? FocusOutcome.done : FocusOutcome.withered,
            focused >= _planned ? _planned : focused,
          );
        } else {
          _tick();
        }
      default:
    }
  }

  /// The lock arrives a few seconds after the app went to the background;
  /// that time was the phone being put down, not another app.
  void _onLock() {
    if (ScreenLock.locked.value) _leftAt = null;
  }

  bool get _canCancel => _elapsed < FocusScreen.cancelWindow;

  Future<void> _stop() async {
    if (_canCancel) return _end(FocusOutcome.cancelled, _elapsed);
    final t = context.t;
    if (_stopwatch) {
      final elapsed = widget.clock().difference(_startedAt!);
      if (elapsed >= FocusScreen.stopwatchMinimum) {
        return _end(FocusOutcome.done, elapsed);
      }
      final stop = await confirm(
        context,
        t.focusStopShortTitle,
        t.focusStopShortBody,
        action: t.focusStop,
        cancel: t.focusKeepGoing,
        destructive: true,
      );
      if (stop && mounted && _phase == _Phase.running) {
        _end(FocusOutcome.cancelled, elapsed);
      }
      return;
    }
    final yes = await confirm(
      context,
      t.focusGiveUpTitle,
      t.focusGiveUpBody,
      action: t.focusGiveUp,
      cancel: t.focusKeepGoing,
      destructive: true,
    );
    if (yes && mounted && _phase == _Phase.running) {
      _end(FocusOutcome.withered, widget.clock().difference(_startedAt!));
    }
  }

  List<FlashWord> _dueWords(AppState state) => state.decks
      .expand((d) => d.words)
      .where((w) => w.isDue(state.now()))
      .take(FocusScreen.breakWords)
      .toList();

  Future<void> _review() async {
    final state = AppScope.read(context);
    final words = _dueWords(state);
    final before = state.studyCredits.length;
    final deck = Deck(
      id: 'focus-break',
      title: context.t.focusBreakDeck,
      description: '',
      words: words,
    );
    await go<void>(
      context,
      ReviewScreen(deck: deck, words: words, source: 'focusBreak'),
    );
    if (!mounted || state.studyCredits.length == before) return;
    state.recordFocus(_session!.copyWith(bloomed: true));
    _bloom.forward(from: 0);
    setState(() {});
  }

  Future<void> _pickTree() async {
    final picked = await sheet<String>(
      context,
      SpeciesPicker(selected: _species),
    );
    if (picked != null) setState(() => _species = picked);
  }

  Future<void> _openTimer() async {
    final choice = await showTimerSheet(context, _minutes);
    if (choice == null || !mounted) return;
    setState(() => _minutes = choice.minutes);
    if (choice.start) _start();
  }

  Future<void> _editTitle() async {
    final title = await sheet<String>(
      context,
      SessionTitleSheet(title: _title),
    );
    if (title != null && mounted) setState(() => _title = title);
  }

  Future<void> _pickTag() async {
    final picked = await showTagSheet(context, _tag);
    if (picked == null || !mounted) return;
    setState(() => _tag = picked);
    AppScope.read(context).setFocusTag(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = AppScope.of(context);
    final running = _phase == _Phase.running;
    // A stopwatch tree is fully grown after an hour.
    final growTo = _stopwatch ? const Duration(minutes: 60) : _planned;
    final progress = (_elapsed.inMilliseconds / growTo.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final shown = _stopwatch ? _elapsed : _planned - _elapsed;
    final due = _phase == _Phase.done ? _dueWords(state).length : 0;
    final bloomed = _session?.bloomed ?? false;

    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _stop();
      },
      child: Scaffold(
        backgroundColor: Palette.focusSkyMiddle,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Palette.focusSkyTop,
                Palette.focusSkyMiddle,
                Palette.focusSkyBottom,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                FocusTopBar(
                  tag: tagName(t, state.tagById(_tag)),
                  color: tagColor(state.tagById(_tag)),
                  title: _title,
                  titleHint: t.sessionTitleHint,
                  onTag: _phase == _Phase.setup ? _pickTag : null,
                  onTitle: _phase == _Phase.setup ? _editTitle : null,
                  closeKey: running ? null : 'focus-close',
                  onClose: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                SizedBox(
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (running) FocusRing(value: progress),
                      AnimatedBuilder(
                        animation: _bloom,
                        builder: (context, _) => TreeArt(
                          key: ValueKey('focus-tree-$_species'),
                          species: _species,
                          size: 250,
                          growth: switch (_phase) {
                            _Phase.setup => 1,
                            _Phase.running => .05 + .95 * progress,
                            _Phase.done || _Phase.withered => 1,
                          },
                          withered: _phase == _Phase.withered,
                          bloom: bloomed ? math.max(_bloom.value, .001) : 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                switch (_phase) {
                  _Phase.setup => PressFade(
                    key: const ValueKey('focus-timer-button'),
                    onTap: _openTimer,
                    child: FocusTimer(Duration(minutes: _minutes)),
                  ),
                  _Phase.running => Column(
                    children: [
                      FocusTimer(shown),
                      FocusNote(t.focusRunningHint),
                    ],
                  ),
                  _Phase.done => Column(
                    children: [
                      FocusTitle(t.focusDoneTitle(_elapsed.inMinutes)),
                      FocusNote(
                        bloomed
                            ? t.focusBloomed
                            : due > 0
                            ? t.focusDoneReview(due)
                            : t.focusDoneRest,
                      ),
                    ],
                  ),
                  _Phase.withered => Column(
                    children: [
                      FocusTitle(t.focusWitheredTitle),
                      FocusNote(t.focusWitheredBody(_elapsed.inMinutes)),
                    ],
                  ),
                },
                const Spacer(),
                ...switch (_phase) {
                  _Phase.setup => [
                    FocusButton('focus-start', t.focusStart, _start),
                    FocusLink(
                      'focus-change-tree',
                      t.focusChangeTree,
                      _pickTree,
                    ),
                  ],
                  _Phase.running => [
                    FocusLink(
                      _canCancel
                          ? 'focus-cancel'
                          : _stopwatch
                          ? 'focus-stop'
                          : 'focus-give-up',
                      _canCancel
                          ? t.focusCancel(
                              (FocusScreen.cancelWindow - _elapsed).inSeconds,
                            )
                          : _stopwatch
                          ? t.focusStop
                          : t.focusGiveUp,
                      _stop,
                    ),
                  ],
                  _Phase.done => [
                    if (due > 0 && !bloomed)
                      FocusButton(
                        'focus-review',
                        t.focusReviewWords(due),
                        _review,
                      )
                    else
                      FocusButton(
                        'focus-finish',
                        t.focusFinish,
                        () => Navigator.of(context).maybePop(),
                      ),
                    if (due > 0 && !bloomed)
                      FocusLink(
                        'focus-rest',
                        t.focusRest,
                        () => Navigator.of(context).maybePop(),
                      ),
                  ],
                  _Phase.withered => [
                    FocusButton('focus-replant', t.focusReplant, () {
                      setState(() => _phase = _Phase.setup);
                    }),
                    FocusLink(
                      'focus-finish',
                      t.focusFinish,
                      () => Navigator.of(context).maybePop(),
                    ),
                  ],
                },
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The display name of a species.
String speciesName(AppLocalizations t, String id) => switch (id) {
  'pine' => t.speciesPine,
  'sunflower' => t.speciesSunflower,
  'tulip' => t.speciesTulip,
  'cherry' => t.speciesCherry,
  'apple' => t.speciesApple,
  'orange' => t.speciesOrange,
  'maple' => t.speciesMaple,
  'birch' => t.speciesBirch,
  'ginkgo' => t.speciesGinkgo,
  'willow' => t.speciesWillow,
  'lavender' => t.speciesLavender,
  'mushroom' => t.speciesMushroom,
  'cactus' => t.speciesCactus,
  'bonsai' => t.speciesBonsai,
  'baobab' => t.speciesBaobab,
  'wisteria' => t.speciesWisteria,
  'bamboo' => t.speciesBamboo,
  'coconut' => t.speciesCoconut,
  'banana' => t.speciesBanana,
  'phuong' => t.speciesPhuong,
  'bang' => t.speciesBang,
  'mai' => t.speciesMai,
  'dao' => t.speciesDao,
  'lotus' => t.speciesLotus,
  'banyan' => t.speciesBanyan,
  'snowpine' => t.speciesSnowpine,
  'galaxy' => t.speciesGalaxy,
  _ => t.speciesOak,
};

/// The species grid shown from "Đổi cây"; locked species are dimmed and
/// can't be picked. Pops the chosen id.
class SpeciesPicker extends StatelessWidget {
  final String selected;
  const SpeciesPicker({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final stats = AppScope.of(context).gardenStats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.focusPickTree, style: D.text(20, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          Flexible(
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: .78,
              children: [
                for (final s in species)
                  _SpeciesTile(
                    id: s.id,
                    name: speciesName(t, s.id),
                    open: stats.unlocks(s),
                    picked: s.id == selected,
                    locked: t.focusLocked,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesTile extends StatelessWidget {
  final String id, name, locked;
  final bool open, picked;
  const _SpeciesTile({
    required this.id,
    required this.name,
    required this.open,
    required this.picked,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey('focus-species-$id'),
    onTap: open ? () => Navigator.of(context).pop(id) : null,
    child: Opacity(
      opacity: open ? 1 : .4,
      child: Container(
        decoration: BoxDecoration(
          color: D.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: picked ? Palette.menuFocus : D.line,
            width: picked ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: TreeArt(species: id, size: 72, floating: false)),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!open) ...[
                    const Icon(
                      CupertinoIcons.lock_fill,
                      size: 10,
                      color: D.muted,
                    ),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      open ? name : locked,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: D.text(11, weight: FontWeight.w700),
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
