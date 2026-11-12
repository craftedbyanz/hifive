part of 'insight_screen.dart';

class _Hero extends StatelessWidget {
  final int streak;
  const _Hero({required this.streak});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 104,
    child: OverflowBox(
      alignment: Alignment.topLeft,
      maxHeight: 108,
      child: FittedBox(
        alignment: Alignment.topLeft,
        fit: BoxFit.scaleDown,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$streak',
              style: D.text(
                80,
                weight: FontWeight.w800,
                height: 96 / 80,
                spacing: -1.5,
              ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: StreakFlame(size: 33),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 29),
              child: Text(
                context.t.daysCaps,
                style: D.text(
                  61,
                  weight: FontWeight.w800,
                  color: Palette.insightDot,
                  height: 78 / 61,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SessionSummary extends StatelessWidget {
  final int count, yearCount;
  final String monthName;
  final DateTime now;
  final Set<String> studyDays;
  const _SessionSummary({
    required this.count,
    required this.yearCount,
    required this.monthName,
    required this.now,
    required this.studyDays,
  });
  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    return SizedBox(
      height: 92,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Row(
              children: [
                const CustomPaint(
                  size: Size(20, 18),
                  painter: TrophyPainter(color: Palette.yellow),
                ),
                const SizedBox(width: 5),
                Text(
                  ordinalBadge(count),
                  style: D.text(
                    18,
                    weight: FontWeight.w800,
                    color: Palette.yellow,
                    height: 23 / 18,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 29,
            width: 200,
            child: Text(
              context.t.monthSummary(count, monthName, yearCount),
              style: D.text(14, color: D.secondary, height: 21.5 / 14),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            width: 108,
            child: Wrap(
              spacing: 4.4,
              runSpacing: 4.4,
              children: [
                for (var day = 1; day <= days; day++)
                  Container(
                    key: ValueKey('insight-day-$day'),
                    width: 11.6,
                    height: 11.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          studyDays.contains(
                            AppState.dayKey(DateTime(now.year, now.month, day)),
                          )
                          ? Palette.insightDotDone
                          : Palette.insightDot,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final Widget icon;
  final String value, label;
  final String? unit;
  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
  });
}

class _StatRow extends StatelessWidget {
  final List<_StatData> stats;
  const _StatRow({required this.stats});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.grow(96),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, stat) in stats.indexed)
          Expanded(
            // Columns start at 24, 141.5 and 259 on a 393 pt screen.
            flex: i == 2 ? 220 : 235,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 27,
                  child: Align(alignment: Alignment.topLeft, child: stat.icon),
                ),
                // Scales down rather than overflow at large text sizes.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        stat.value,
                        style: D.text(
                          21,
                          weight: FontWeight.w800,
                          height: 27 / 21,
                        ),
                      ),
                      if (stat.unit != null) ...[
                        const SizedBox(width: 2),
                        Text(
                          stat.unit!,
                          style: D.text(
                            11,
                            weight: FontWeight.w600,
                            color: Palette.insightFaint,
                            height: 15 / 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  stat.label,
                  style: D.text(
                    11.3,
                    color: Palette.insightFaint,
                    height: 15 / 11.3,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _BookGlyph extends StatelessWidget {
  final Color color;
  const _BookGlyph({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 15,
    height: 18,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2.5),
    ),
    child: Stack(
      children: [
        Positioned(
          left: 2.4,
          top: 2,
          bottom: 4,
          child: Container(width: .9, color: Colors.white),
        ),
        Positioned(
          left: 2.4,
          right: 0,
          bottom: 2,
          child: Container(height: 1.3, color: Colors.white),
        ),
        Positioned(
          left: 4,
          right: 1,
          top: 2.4,
          child: Text(
            'A',
            textAlign: TextAlign.center,
            style: D.text(
              9,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The reference's rosette of interlaced rings beside "Tạo bởi AI".
class _AiRosettePainter extends CustomPainter {
  const _AiRosettePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..shader = const LinearGradient(
        colors: [Palette.artOrange, Palette.insightPeople],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 10));
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate(i * pi / 3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 15.8, height: 9),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AiRosettePainter oldDelegate) => false;
}

/// The chart glyph: two axes and a rising line.
class _ChartGlyphPainter extends CustomPainter {
  const _ChartGlyphPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = D.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(.8, 1)
        ..lineTo(.8, 15)
        ..lineTo(16.5, 15),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(3.5, 11)
        ..lineTo(7, 6.5)
        ..lineTo(10, 9.5)
        ..lineTo(16, 2.5),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(11.8, 1)
        ..lineTo(17, .6)
        ..lineTo(16.4, 6)
        ..close(),
      Paint()..color = D.blue,
    );
  }

  @override
  bool shouldRepaint(_ChartGlyphPainter oldDelegate) => false;
}

TextStyle get _bigText =>
    D.text(21, color: Palette.insightFaint, height: 27 / 21);
TextStyle get _bigStrong =>
    D.text(21, weight: FontWeight.w700, height: 27 / 21);

class _MistakeSummary extends StatelessWidget {
  final int count;
  const _MistakeSummary({required this.count});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _InlineWords(
        children: [
          if (context.t.mistakesPrefix.isNotEmpty)
            Text(context.t.mistakesPrefix, style: _bigText),
          const SizedBox(width: 5),
          const CustomPaint(
            size: Size(21, 19),
            painter: WarningPainter(color: Palette.wrong),
          ),
          const SizedBox(width: 4),
          Text(context.t.mistakesCount(count), style: _bigStrong),
        ],
      ),
      const SizedBox(height: 11),
      _InlineWords(
        children: [
          Text(context.t.mistakesMiddle, style: _bigText),
          const SizedBox(width: 5),
          const _BookGlyph(color: Palette.wrong),
        ],
      ),
      const SizedBox(height: 11),
      // Grading here has no error categories, and only this one was observed.
      Text(
        context.t.mistakesTopic,
        style: _bigStrong.copyWith(color: Palette.wrong),
      ),
    ],
  );
}

/// Words and icons on one line that wrap instead of overflowing small screens.
class _InlineWords extends StatelessWidget {
  final List<Widget> children;
  const _InlineWords({required this.children});
  @override
  Widget build(BuildContext context) =>
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: children);
}

class _SuggestButton extends StatelessWidget {
  const _SuggestButton();
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${context.t.seeSuggestions}, ${context.t.comingSoon}',
    child: Column(
      children: [
        Opacity(opacity: .45, child: _face(context)),
        const SizedBox(height: 8),
        const SoonBadge(),
      ],
    ),
  );

  Widget _face(BuildContext context) => Container(
    key: const ValueKey('insight-suggest'),
    width: 179,
    height: 38,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(19),
      gradient: const LinearGradient(
        colors: [Palette.artOrange, Palette.insightPeople],
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.sparkles, size: 16, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          context.t.seeSuggestions,
          style: D.text(13, weight: FontWeight.w600, color: Colors.white),
        ),
      ],
    ),
  );
}

class _TipsCard extends StatelessWidget {
  final List<String> tips;
  const _TipsCard({required this.tips});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Palette.insightTips,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              CupertinoIcons.lightbulb_fill,
              size: 18,
              color: Palette.insightClock,
            ),
            const SizedBox(width: 4),
            Text(
              context.t.suggestionsTitle,
              style: D.text(13, weight: FontWeight.w600, color: D.secondary),
            ),
          ],
        ),
        const SizedBox(height: 9),
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: 10.5),
                  child: Container(
                    width: 5.5,
                    height: 5.5,
                    decoration: const BoxDecoration(
                      color: Palette.insightClock,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: D.text(
                      13,
                      color: Palette.insightTipsInk,
                      height: 16 / 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// "Tạo bởi AI ›" under the tips. The reference never had it pressed; here it
/// explains where the suggestions come from.
class _GeneratedByAi extends StatelessWidget {
  const _GeneratedByAi();
  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('insight-ai-info'),
    behavior: HitTestBehavior.opaque,
    onTap: () => sheet<void>(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(context.t.madeByAi),
          Text(
            context.t.madeByAiBody,
            style: D.text(15, color: D.secondary, height: 1.55),
          ),
        ],
      ),
    ),
    child: _attribution(context),
  );

  Widget _attribution(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(height: 1, color: Palette.insightDot)),
      const SizedBox(width: 13),
      const CustomPaint(size: Size.square(19), painter: _AiRosettePainter()),
      const SizedBox(width: 8),
      Text(
        context.t.madeByAi,
        style: D.text(
          11,
          weight: FontWeight.w600,
          color: Palette.insightAiInk,
          height: 15 / 11,
        ),
      ),
      const SizedBox(width: 10),
      const Icon(
        CupertinoIcons.chevron_forward,
        size: 12,
        color: Palette.insightAiInk,
      ),
      const SizedBox(width: 13),
      const Expanded(child: Divider(height: 1, color: Palette.insightDot)),
    ],
  );
}
