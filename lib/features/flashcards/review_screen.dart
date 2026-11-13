import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'review_complete.dart';
import 'review_guide.dart';

part 'review_card.dart';
part 'review_controls.dart';

/// One study session, measured from video on the reference:
/// - the card follows the finger at 0.85, tilting about 3.5° per 110 pt;
/// - the other three buttons fade while the matching one grows and fills;
/// - a rated card flies off in about 0.35 s, and the next settles over 0.73 s;
/// - "Học lại" sends the card to the end of the queue without advancing progress.
class ReviewScreen extends StatefulWidget with CoverPage {
  final Deck deck;
  final List<FlashWord> words;

  /// Where the session was opened from, kept on each review.
  final String source;
  const ReviewScreen({
    super.key,
    required this.deck,
    required this.words,
    this.source = 'flashcard',
  });

  /// How far a card must travel to be rated. The reference did not rate at 110 pt
  /// held and returned, and did at 170 pt, so this is inside that range.
  static const commitDistance = 100.0;
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with TickerProviderStateMixin {
  late final List<FlashWord> queue = List.of(widget.words);
  late final total = queue.length;

  /// Garden waterings before this session, to show how many it added.
  late final _wateredBefore = AppScope.read(context).countedStudyCredits.length;
  FlashWord? previous;
  int passed = 0, again = 0;
  bool done = false, autoplay = false, colorful = false;
  Timer? autoplayTimer;
  FeedbackService? activeFeedback;

  late final flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 730),
    value: 1,
  );
  late final fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final badge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 260),
  );

  Offset drag = Offset.zero;
  Offset snapFrom = Offset.zero;
  Offset flyFrom = Offset.zero, flyTo = Offset.zero;
  FlashWord? flying;
  bool flyingBack = false;
  double settleTilt = 0;
  int activeRating = 0;
  double dragBadge = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wateredBefore;
    activeFeedback = AppScope.read(context).feedback;
  }

  @override
  void dispose() {
    autoplayTimer?.cancel();
    flip.dispose();
    settle.dispose();
    fly.dispose();
    snap.dispose();
    badge.dispose();
    activeFeedback?.stop();
    super.dispose();
  }

  void toggleFlip() {
    AppScope.read(context).feedback.tap();
    flip.value < .5 ? flip.forward() : flip.reverse();
  }

  double _tiltFor(Offset o) => o.dx / 110 * (3.5 * pi / 180);

  Offset get _shown => snap.isAnimating
      ? Offset.lerp(
          snapFrom,
          Offset.zero,
          Curves.easeOut.transform(snap.value),
        )!
      : drag;

  void _onDragUpdate(DragUpdateDetails d) {
    if (flying != null) return;
    snap.stop();
    setState(() {
      drag += d.delta * .85;
      final horizontal = drag.dx.abs() >= drag.dy.abs();
      activeRating = horizontal ? (drag.dx < 0 ? 0 : 3) : (drag.dy > 0 ? 1 : 2);
      dragBadge = (max(drag.dx.abs(), drag.dy.abs()) / 80).clamp(0, 1);
      badge.value = dragBadge;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (flying != null) return;
    final speed = d.velocity.pixelsPerSecond.distance;
    final distance = max(drag.dx.abs(), drag.dy.abs());
    if (distance > ReviewScreen.commitDistance ||
        (speed > 700 && distance > 30)) {
      rate(activeRating);
      return;
    }
    snapFrom = drag;
    drag = Offset.zero;
    snap.forward(from: 0);
    badge.reverse();
  }

  void rate(int value) {
    if (flying != null || queue.isEmpty) return;
    final state = AppScope.read(context);
    final word = queue.first;
    state.feedback.tap();
    state.rate(word, value, source: widget.source);
    activeRating = value;
    final direction = _ratings[value].$2;
    final size = MediaQuery.sizeOf(context);
    setState(() {
      flyFrom = drag;
      flyTo = Offset(
        direction.dx * size.width * 1.2 + drag.dx * .3,
        direction.dy * size.height * .95 + drag.dy * .3,
      );
      flying = word;
      flyingBack = flip.value > .5;
      settleTilt = direction.dx * (3.5 * pi / 180);
      drag = Offset.zero;
      previous = word;
      queue.removeAt(0);
      if (value == 0) {
        again++;
        queue.add(word);
      } else {
        passed++;
      }
    });
    flip.value = 0;
    badge.forward().then((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) badge.reverse();
    });
    settle.forward(from: 0);
    fly.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        flying = null;
        if (queue.isEmpty) done = true;
      });
      if (autoplay && queue.isNotEmpty) playWord(context, queue.first.word);
    });
  }

  void autoPlay() {
    autoplayTimer?.cancel();
    setState(() => autoplay = !autoplay);
    if (autoplay && queue.isNotEmpty) {
      playWord(context, queue.first.word);
      autoplayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || queue.isEmpty) return;
        if (flip.value < .5) {
          toggleFlip();
        } else {
          playWord(context, queue.first.word);
        }
      });
    }
  }

  Future<void> _openMenu(BuildContext anchor) async {
    final choice = await showGlassMenu<String>(anchor, [
      GlassMenuItem(
        'auto',
        context.t.autoPlay,
        icon: autoplay
            ? CupertinoIcons.speaker_2
            : CupertinoIcons.speaker_slash,
      ),
      GlassMenuItem(
        'color',
        context.t.cardColor,
        icon: Icons.brush_outlined,
        trailing: CupertinoIcons.chevron_forward,
      ),
      GlassMenuItem(
        'guide',
        context.t.guide,
        icon: CupertinoIcons.question_circle,
      ),
    ]);
    if (!mounted || !anchor.mounted) return;
    if (choice == 'auto') autoPlay();
    if (choice == 'guide') unawaited(showReviewGuide(context));
    if (choice == 'color') {
      final tint = await showGlassMenu<bool>(
        anchor,
        [
          GlassMenuItem(true, context.t.colorful, icon: Icons.palette_outlined),
          GlassMenuItem(
            false,
            context.t.monochrome,
            icon: CupertinoIcons.square,
          ),
        ],
        title: context.t.cardColor,
        behind: GlassMenuItem(
          false,
          context.t.autoPlay,
          icon: autoplay
              ? CupertinoIcons.speaker_2
              : CupertinoIcons.speaker_slash,
        ),
      );
      if (tint != null && mounted) setState(() => colorful = tint);
    }
  }

  Color _cardColor(FlashWord word) {
    if (!colorful) return Colors.white;
    const tints = [
      Palette.cardTintBlue,
      Palette.cardTintPurple,
      Palette.cardTintGreen,
      Palette.cardTintAmber,
    ];
    return tints[word.word.hashCode.abs() % tints.length];
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Palette.completePage,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      child: done
          ? ReviewComplete(
              key: const ValueKey('review-complete'),
              deckTitle: widget.deck.title,
              seen: total,
              known: passed,
              again: again,
              watered:
                  AppScope.read(context).countedStudyCredits.length -
                  _wateredBefore,
              onContinue: () => Navigator.pop(context),
            )
          : _session(),
    ),
  );

  Widget _session() {
    final size = MediaQuery.sizeOf(context);
    final cardWidth = size.width - 86;
    final cardHeight = (size.height - 420).clamp(280.0, 432.0);
    return Scaffold(
      backgroundColor: Palette.settingsPage,
      body: AnimatedBuilder(
        animation: Listenable.merge([settle, fly, snap, flip, badge]),
        builder: (context, _) {
          final s = Curves.easeOutCubic.transform(settle.value);
          final shown = _shown;
          final tilt = settleTilt * (1 - s) + _tiltFor(shown);
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 61,
                child: _TopBar(
                  progress: passed / total,
                  onClose: () => Navigator.pop(context),
                  onMenu: _openMenu,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 118,
                height: 30,
                child: _WordStrip(
                  previous: previous?.word,
                  current: queue.isEmpty ? '' : queue.first.word,
                  next: queue.length > 1 ? queue[1].word : null,
                  t: s,
                ),
              ),
              // Back of the stack first, so the top card paints last.
              for (var i = min(queue.length - 1, 3); i >= 1; i--)
                _stacked(
                  queue[i],
                  i + (1 - s),
                  cardWidth,
                  cardHeight,
                  tilt,
                  shown,
                ),
              if (queue.isNotEmpty)
                Positioned(
                  left: 43,
                  top: 203,
                  width: cardWidth,
                  height: cardHeight,
                  child: _top(queue.first, s, tilt, shown),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 82,
                child: _RatingRow(
                  word: queue.isEmpty ? null : queue.first,
                  active: activeRating,
                  progress: badge.value,
                  onRate: rate,
                ),
              ),
              if (flying != null)
                Positioned(
                  left: 43,
                  top: 203,
                  width: cardWidth,
                  height: cardHeight,
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset.lerp(
                        flyFrom,
                        flyTo,
                        Curves.easeIn.transform(fly.value),
                      )!,
                      child: Transform.rotate(
                        angle: _tiltFor(flyFrom) + settleTilt * fly.value,
                        child: flyingBack
                            ? _CardBack(
                                word: flying!,
                                color: _cardColor(flying!),
                              )
                            : _CardFront(
                                word: flying!,
                                color: _cardColor(flying!),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// A card behind the top one. [depth] 1 and 2 are the two visible behind it.
  Widget _stacked(
    FlashWord word,
    double depth,
    double width,
    double height,
    double tilt,
    Offset shown,
  ) => Positioned(
    left: 43,
    top: 203,
    width: width,
    height: height,
    child: IgnorePointer(
      child: Opacity(
        opacity: (3 - depth).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(-shown.dx * .07, _depthY(depth)),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(
              alignment: Alignment.topCenter,
              scale: _depthScale(depth),
              child: _CardFront(word: word, color: _cardColor(word)),
            ),
          ),
        ),
      ),
    ),
  );

  static double _depthY(double d) =>
      d <= 1 ? -21 * d : -21 - 15 * (d - 1).clamp(0.0, 1.0);
  static double _depthScale(double d) =>
      d <= 1 ? 1 - .06 * d : .94 - .06 * (d - 1).clamp(0.0, 1.0);

  Widget _top(FlashWord word, double s, double tilt, Offset shown) {
    final depth = 1 - s;
    return Transform.translate(
      offset: shown + Offset(0, _depthY(depth)),
      child: Transform.rotate(
        angle: tilt,
        child: Transform.scale(
          alignment: Alignment.topCenter,
          scale: _depthScale(depth),
          child: GestureDetector(
            key: const ValueKey('review-card'),
            behavior: HitTestBehavior.opaque,
            onTap: toggleFlip,
            onPanUpdate: _onDragUpdate,
            onPanEnd: _onDragEnd,
            child: _FlipCard(
              turn: Curves.easeOut.transform(flip.value),
              front: _CardFront(word: word, color: _cardColor(word)),
              back: _CardBack(word: word, color: _cardColor(word)),
            ),
          ),
        ),
      ),
    );
  }
}
