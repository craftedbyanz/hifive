part of 'insight_screen.dart';

class _WeekChart extends StatelessWidget {
  final AppState state;
  final DateTime now;
  const _WeekChart({required this.state, required this.now});
  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(now);
    // The reference ends the week on today, so the first bar is six days ago.
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final counts = [
      for (final day in days)
        state.history
            .where((h) => AppState.dayKey(h.date) == AppState.dayKey(day))
            .length,
    ];
    final highest = counts.fold(1, (a, b) => a > b ? a : b);
    final names = context.t.weekdaysMonFirst.split(',');
    return Container(
      key: const ValueKey('insight-week'),
      height: 193.5,
      decoration: BoxDecoration(
        color: Palette.insightCard,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(21, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomPaint(
                size: Size(17, 16),
                painter: _ChartGlyphPainter(),
              ),
              const SizedBox(width: 10),
              Text(
                context.t.thisWeekActivity,
                style: D.text(
                  13,
                  weight: FontWeight.w500,
                  color: D.secondary,
                  height: 18 / 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Palette.insightDot, width: 2),
              ),
            ),
            child: SizedBox(
              height: 103,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: counts[i] == 0
                              ? const SizedBox.shrink()
                              : Container(
                                  key: ValueKey('insight-bar-$i'),
                                  width: 30,
                                  height: 101 * counts[i] / highest,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Palette.insightBarTop,
                                        Palette.insightBarEnd,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(8),
                                      bottom: Radius.circular(3),
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
          const SizedBox(height: 3),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Text(
                    names[day.weekday - 1],
                    textAlign: TextAlign.center,
                    style: D.text(11, color: Palette.insightFaint),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Together extends StatelessWidget {
  final int days;
  const _Together({required this.days});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Icon(
              CupertinoIcons.heart_fill,
              size: 18,
              color: Palette.insightPeople,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            context.t.withHifive,
            style: D.text(
              13,
              weight: FontWeight.w500,
              color: D.secondary,
              height: 17 / 13,
            ),
          ),
        ],
      ),
      const SizedBox(height: 9),
      _InlineWords(
        children: [
          if (context.t.withPrefix.isNotEmpty)
            Text(context.t.withPrefix, style: _bigText),
          const SizedBox(width: 5),
          const Icon(
            CupertinoIcons.sparkles,
            size: 19,
            color: Palette.insightPeople,
          ),
          const SizedBox(width: 4),
          Text(
            'Hifive',
            style: _bigStrong.copyWith(color: Palette.insightPeople),
          ),
          const SizedBox(width: 4),
          if (context.t.withMiddle.isNotEmpty)
            Text(context.t.withMiddle, style: _bigText),
        ],
      ),
      const SizedBox(height: 11),
      Text.rich(
        // The reference lets this line run past the side margin.
        // Other languages wrap, since their line can be longer.
        softWrap: context.t.localeName != 'vi',
        overflow: TextOverflow.visible,
        TextSpan(
          children: [
            TextSpan(text: context.t.withDays(days), style: _bigStrong),
            TextSpan(text: context.t.thanksForJourney, style: _bigText),
          ],
        ),
      ),
    ],
  );
}
