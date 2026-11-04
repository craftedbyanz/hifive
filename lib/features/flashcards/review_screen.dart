import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../../widgets/glass_menu.dart';
import '../../widgets/press.dart';
import 'review_complete.dart';
import 'review_guide.dart';

/// The ratings, each tied to the direction its card leaves in.
const _ratings = [
  ('Học lại', Palette.rateAgain, Offset(-1, 0)),
  ('Khó', Palette.rateHard, Offset(0, 1)),
  ('Tốt', Palette.rateGood, Offset(0, -1)),
  ('Dễ', Palette.rateEasy, Offset(1, 0)),
];

String _intervalLabel(Duration d) =>
    d.inDays > 0 ? '${d.inDays}d' : '${d.inMinutes}m';

/// One study session, measured from video on the reference:
/// - the card follows the finger at 0.85, tilting about 3.5° per 110 pt;
/// - the other three buttons fade while the matching one grows and fills;
/// - a rated card flies off in about 0.35 s, and the next settles over 0.73 s;
/// - "Học lại" sends the card to the end of the queue without advancing progress.
class ReviewScreen extends StatefulWidget with CoverPage {
  final Deck deck;
  final List<FlashWord> words;
  const ReviewScreen({super.key, required this.deck, required this.words});

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
    state.rate(word, value);
    activeRating = value;
    final direction = _ratings[value].$3;
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
        'Tự động phát',
        icon: autoplay
            ? CupertinoIcons.speaker_2
            : CupertinoIcons.speaker_slash,
      ),
      const GlassMenuItem(
        'color',
        'Màu thẻ',
        icon: Icons.brush_outlined,
        trailing: CupertinoIcons.chevron_forward,
      ),
      const GlassMenuItem(
        'guide',
        'Hướng dẫn',
        icon: CupertinoIcons.question_circle,
      ),
    ]);
    if (!mounted || !anchor.mounted) return;
    if (choice == 'auto') autoPlay();
    if (choice == 'guide') unawaited(showReviewGuide(context));
    if (choice == 'color') {
      final tint = await showGlassMenu<bool>(
        anchor,
        const [
          GlassMenuItem(true, 'Màu sắc', icon: Icons.palette_outlined),
          GlassMenuItem(false, 'Đơn sắc', icon: CupertinoIcons.square),
        ],
        title: 'Màu thẻ',
        behind: GlassMenuItem(
          false,
          'Tự động phát',
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

class _TopBar extends StatelessWidget {
  final double progress;
  final VoidCallback onClose;
  final ValueChanged<BuildContext> onMenu;
  const _TopBar({
    required this.progress,
    required this.onClose,
    required this.onMenu,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Stack(
      children: [
        Positioned(
          left: 16,
          top: 0,
          child: Semantics(
            label: 'Đóng ôn tập',
            child: Tooltip(
              message: 'Đóng ôn tập',
              triggerMode: TooltipTriggerMode.manual,
              child: PressFade(
                onTap: onClose,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 21,
                    color: Palette.settingsHint,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 72,
          right: 72,
          top: 16,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Palette.settingsEdge,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  key: const ValueKey('review-progress'),
                  width: c.maxWidth * progress.clamp(0, 1),
                  height: 8,
                  decoration: BoxDecoration(
                    color: Palette.reviewFill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: 0,
          child: Builder(
            builder: (anchor) => Semantics(
              label: 'Tùy chọn ôn tập',
              child: Tooltip(
                message: 'Tùy chọn ôn tập',
                triggerMode: TooltipTriggerMode.manual,
                child: PressFade(
                  onTap: () => onMenu(anchor),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      CupertinoIcons.ellipsis,
                      size: 20,
                      color: Palette.settingsHint,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// The current word in the middle with blurred neighbors, sliding one place left
/// as each card is rated.
class _WordStrip extends StatelessWidget {
  static const step = 110.0;
  final String? previous, next;
  final String current;
  final double t;
  const _WordStrip({
    required this.previous,
    required this.current,
    required this.next,
    required this.t,
  });

  Widget _word(String text, double position, double width) {
    final distance = position.abs().clamp(0.0, 1.0);
    return Positioned(
      left: width / 2 + position * step - 80,
      width: 160,
      top: 0,
      bottom: 0,
      child: Opacity(
        opacity:
            (1 - distance * .62) *
            (position.abs() > 1 ? (2 - position.abs()).clamp(0.0, 1.0) : 1),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: distance * 1.5,
            sigmaY: distance * 1.5,
          ),
          child: Transform.scale(
            scale: 1 - distance * .32,
            child: Center(
              child: Text(
                text,
                maxLines: 1,
                style: D.text(14, weight: FontWeight.w700, height: 18 / 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final shift = 1 - t;
      return ClipRect(
        child: Stack(
          children: [
            if (previous != null) _word(previous!, -1 + shift, c.maxWidth),
            if (current.isNotEmpty) _word(current, shift, c.maxWidth),
            if (next != null) _word(next!, 1 + shift, c.maxWidth),
          ],
        ),
      );
    },
  );
}

class _RatingRow extends StatelessWidget {
  final FlashWord? word;
  final int active;
  final double progress;
  final ValueChanged<int> onRate;
  const _RatingRow({
    required this.word,
    required this.active,
    required this.progress,
    required this.onRate,
  });
  @override
  Widget build(BuildContext context) {
    final intervals = word?.nextIntervals;
    return SizedBox(
      height: 101,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 19),
            _RatingButton(
              index: i,
              interval: intervals == null ? '' : _intervalLabel(intervals[i]),
              progress: i == active ? progress : 0,
              hidden: i == active ? 0 : progress,
              onTap: () => onRate(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final int index;
  final String interval;
  final double progress, hidden;
  final VoidCallback onTap;
  const _RatingButton({
    required this.index,
    required this.interval,
    required this.progress,
    required this.hidden,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final (label, color, _) = _ratings[index];
    return Semantics(
      button: true,
      label: '$interval, $label',
      child: GestureDetector(
        key: ValueKey('rate-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: 1 - hidden,
          child: SizedBox(
            width: 65,
            child: Column(
              children: [
                Opacity(
                  opacity: 1 - progress,
                  child: Text(
                    interval,
                    style: D.text(
                      11,
                      weight: FontWeight.w600,
                      color: Palette.settingsHint,
                      height: 15 / 11,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Transform.scale(
                  scale: 1 + .37 * progress,
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.lerp(Colors.white, color, progress),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: D.ink.withValues(alpha: .08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _RatingGlyph(index: index, color: color),
                  ),
                ),
                const SizedBox(height: 6),
                Transform.translate(
                  offset: Offset(0, 9 * progress),
                  child: Text(
                    label,
                    style: D.text(
                      12.5,
                      weight: progress > .5 ? FontWeight.w700 : FontWeight.w600,
                      color: Color.lerp(Palette.settingsHint, color, progress)!,
                      height: 15 / 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Khó" glyph's two clock hands, without a dial.
class _ClockHandsPainter extends CustomPainter {
  const _ClockHandsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, c + const Offset(0, -7.5), paint);
    canvas.drawLine(c, c + const Offset(-7, 0), paint);
  }

  @override
  bool shouldRepaint(_ClockHandsPainter oldDelegate) => false;
}

class _RatingGlyph extends StatelessWidget {
  final int index;
  final Color color;
  const _RatingGlyph({required this.index, required this.color});
  @override
  Widget build(BuildContext context) {
    final icon = const [
      CupertinoIcons.arrow_uturn_left,
      null,
      Icons.check_rounded,
      CupertinoIcons.star_fill,
    ][index];
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: icon == null
                ? const CustomPaint(painter: _ClockHandsPainter())
                : Icon(icon, size: 18, color: Colors.white, weight: 700),
          ),
          if (index == 1)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14.5,
                height: 14.5,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                ),
                child: Text(
                  '!',
                  style: D.text(
                    8,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A 3D turn. Past the edge the faces cross-fade, so the far side shows mirrored
/// for a moment, as on the reference.
class _FlipCard extends StatelessWidget {
  final double turn;
  final Widget front, back;
  const _FlipCard({
    required this.turn,
    required this.front,
    required this.back,
  });
  @override
  Widget build(BuildContext context) {
    final frontOpacity = (1 - (turn - .35) / .3).clamp(0.0, 1.0);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, .0012)
        ..rotateY(turn * pi),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (frontOpacity < 1)
            Opacity(
              opacity: 1 - frontOpacity,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(pi),
                child: back,
              ),
            ),
          if (frontOpacity > 0) Opacity(opacity: frontOpacity, child: front),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Color color;
  final Widget child;
  const _CardShell({required this.color, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: ShapeDecoration(
      color: color,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(36),
        side: BorderSide(color: D.ink.withValues(alpha: .1), width: .5),
      ),
      shadows: [
        BoxShadow(
          color: D.ink.withValues(alpha: .08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _CardFront extends StatelessWidget {
  final FlashWord word;
  final Color color;
  const _CardFront({required this.word, required this.color});
  @override
  Widget build(BuildContext context) => _CardShell(
    color: color,
    child: Column(
      children: [
        const Spacer(flex: 154),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.75),
          decoration: BoxDecoration(
            color: Palette.settingsPanel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            word.partOfSpeech,
            style: D.text(
              10.5,
              weight: FontWeight.w700,
              color: Palette.settingsMuted,
              spacing: 1.2,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word.word,
              maxLines: 1,
              style: D.text(29.5, weight: FontWeight.w800, height: 38 / 29.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          word.phonetic,
          style: D.text(
            13.5,
            color: Palette.settingsHint,
            spacing: .3,
            height: 18 / 13.5,
          ),
        ),
        const Spacer(flex: 109),
        Text(
          'CHẠM ĐỂ LẬT',
          style: D.text(
            10.5,
            weight: FontWeight.w700,
            color: Palette.settingsHint,
            spacing: 1.2,
            height: 13 / 10.5,
          ),
        ),
        const SizedBox(height: 31),
      ],
    ),
  );
}

class _CardBack extends StatelessWidget {
  final FlashWord word;
  final Color color;
  const _CardBack({required this.word, required this.color});
  @override
  Widget build(BuildContext context) => _CardShell(
    color: color,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 23, 22, 23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 21,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Palette.newPill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  word.partOfSpeech,
                  style: D.text(
                    10.5,
                    weight: FontWeight.w700,
                    color: Palette.newPillInk,
                    height: 1,
                  ),
                ),
              ),
              Semantics(
                label: 'Phát âm',
                child: Tooltip(
                  message: 'Phát âm',
                  triggerMode: TooltipTriggerMode.manual,
                  child: PressFade(
                    onTap: () => playWord(context, word.word),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Palette.settingsPage,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.speaker_2_fill,
                        size: 19,
                        color: D.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Palette.settingsEdge),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.meaning,
                    style: D.text(
                      20.5,
                      weight: FontWeight.w800,
                      height: 26.5 / 20.5,
                    ),
                  ),
                  if (word.definition.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      word.definition,
                      style: D.text(
                        13.2,
                        color: Palette.settingsMuted,
                        height: 19.7 / 13.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxWidth: 222),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: ShapeDecoration(
              color: Palette.settingsPage,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ví dụ',
                  style: D.text(
                    11,
                    weight: FontWeight.w600,
                    color: Palette.settingsMuted,
                    height: 15 / 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${word.example}"',
                  style: D
                      .text(12.5, height: 16 / 12.5)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
