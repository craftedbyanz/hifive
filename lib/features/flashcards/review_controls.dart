part of 'review_screen.dart';

/// The two answers, each with the FSRS rating it records, its color and the
/// direction its card leaves in: left for "Chưa nhớ" (Again), right for
/// "Đã nhớ" (Good). Hard and Easy are not asked for: two choices are
/// quicker, and FSRS schedules well on Again and Good alone.
const _answers = [
  (rating: 0, color: Palette.rateAgain, direction: Offset(-1, 0)),
  (rating: 2, color: D.green, direction: Offset(1, 0)),
];

String _answerName(AppLocalizations t, int index) =>
    [t.rateForgot, t.rateRemembered][index];

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

  /// The answer the card is being dragged toward, 0 or 1.
  final int active;
  final double progress;
  final ValueChanged<int> onAnswer;
  const _RatingRow({
    required this.word,
    required this.active,
    required this.progress,
    required this.onAnswer,
  });
  @override
  Widget build(BuildContext context) {
    final intervals = word?.nextIntervals(AppScope.read(context).now());
    return SizedBox(
      height: 101,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _answers.length; i++) ...[
            if (i > 0) const SizedBox(width: 72),
            _AnswerButton(
              index: i,
              interval: intervals == null
                  ? ''
                  : _intervalLabel(intervals[_answers[i].rating]),
              progress: i == active ? progress : 0,
              hidden: i == active ? 0 : progress,
              onTap: () => onAnswer(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final int index;
  final String interval;
  final double progress, hidden;
  final VoidCallback onTap;
  const _AnswerButton({
    required this.index,
    required this.interval,
    required this.progress,
    required this.hidden,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final color = _answers[index].color;
    final label = _answerName(context.t, index);
    return Semantics(
      button: true,
      label: '$interval, $label',
      child: GestureDetector(
        key: ValueKey('answer-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: 1 - hidden,
          child: SizedBox(
            width: 88,
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
                  scale: 1 + .3 * progress,
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
                    child: Icon(
                      index == 0
                          ? CupertinoIcons.xmark
                          : CupertinoIcons.checkmark_alt,
                      size: 28,
                      color: Color.lerp(color, Colors.white, progress),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: D.text(
                    13,
                    weight: FontWeight.w700,
                    color: Color.lerp(
                      Palette.settingsHint,
                      color,
                      .6 + .4 * progress,
                    )!,
                    height: 15 / 13,
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
