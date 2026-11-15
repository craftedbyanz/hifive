part of 'review_screen.dart';

/// The ratings, each tied to the direction its card leaves in.
const _ratings = [
  (Palette.rateAgain, Offset(-1, 0)),
  (Palette.rateHard, Offset(0, 1)),
  (Palette.rateGood, Offset(0, -1)),
  (Palette.rateEasy, Offset(1, 0)),
];

String _ratingName(AppLocalizations t, int index) =>
    [t.rateAgain, t.rateHardCard, t.rateGood, t.rateEasyCard][index];

String _intervalLabel(Duration d) =>
    d.inDays > 0 ? '${d.inDays}d' : '${d.inMinutes}m';

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
            label: context.t.closeReview,
            child: Tooltip(
              message: context.t.closeReview,
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
              label: context.t.reviewOptions,
              child: Tooltip(
                message: context.t.reviewOptions,
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
    final intervals = word?.nextIntervals(AppScope.read(context).now());
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
    final (color, _) = _ratings[index];
    final label = _ratingName(context.t, index);
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
