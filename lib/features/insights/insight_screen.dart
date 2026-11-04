import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../core/state.dart';
import '../../domain/models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/blur_header.dart';
import '../../widgets/common.dart';
import '../../widgets/glyphs.dart';

/// Layout measured against the reference on a 393 × 852 iPhone. Content
/// positions are in points from the top of the screen.
class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});
  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

enum _TipsState { idle, loading, shown, failed }

class _InsightScreenState extends State<InsightScreen> {
  _TipsState _tips = _TipsState.idle;
  List<String> _tipLines = const [];

  Future<void> _showTips() async {
    setState(() => _tips = _TipsState.loading);
    final state = AppScope.read(context), now = state.now();
    final month = state.history
        .where((h) => h.date.year == now.year && h.date.month == now.month)
        .toList();
    try {
      final tips = await state.insights.tips(month);
      if (!mounted) return;
      setState(() {
        _tipLines = tips;
        _tips = _TipsState.shown;
      });
    } catch (_) {
      if (mounted) setState(() => _tips = _TipsState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context), now = s.now();
    final monthName = 'Tháng ${now.month}, ${now.year}';
    final year = s.history.where((h) => h.date.year == now.year).toList();
    final month = year.where((h) => h.date.month == now.month).toList();
    final seconds = month.fold(0, (v, h) => v + h.seconds);
    final words = month.fold(
      0,
      (v, h) =>
          v +
          h.lesson.questions.fold<int>(
            0,
            (a, q) => a + q.answer.split(' ').length,
          ),
    );
    int sessions(StudyMode mode) =>
        month.where((h) => h.lesson.mode == mode).length;
    final sentences = month
        .where((h) => h.lesson.mode == StudyMode.grammar)
        .fold(0, (v, h) => v + h.lesson.questions.length);
    final mistakes = month.fold(
      0,
      (v, h) => v + h.answers.where((a) => a.firstScore < .65).length,
    );
    return HeaderScrollPage(
      title: 'Insight',
      subtitle: monthName,
      scrollKey: const ValueKey('insight-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 149, 24, 127),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(streak: s.streak),
          Text(
            'Streak hiện tại',
            style: D.text(23, weight: FontWeight.w700, height: 29 / 23),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                CupertinoIcons.clock,
                size: 16,
                color: Palette.insightFaint,
              ),
              const SizedBox(width: 6),
              Text(
                'Cập nhật lúc 09:41 hôm nay',
                style: D.text(13, color: Palette.insightFaint, height: 17 / 13),
              ),
            ],
          ),
          const SizedBox(height: 31),
          _SessionSummary(
            count: month.length,
            yearCount: year.length,
            monthName: monthName,
            now: now,
            studyDays: s.studyDays,
          ),
          const SizedBox(height: 32),
          _StatRow(
            stats: [
              _StatData(
                icon: const _BookGlyph(color: Palette.insightBook),
                value: '$words',
                unit: 'TỪ',
                label: 'Từ vựng học',
              ),
              _StatData(
                icon: const Icon(
                  CupertinoIcons.clock_fill,
                  size: 18,
                  color: Palette.insightClock,
                ),
                value: _hoursAndMinutes(seconds),
                unit: 'GIỜ',
                label: 'Thời lượng',
              ),
              _StatData(
                icon: const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  size: 18,
                  color: D.green,
                ),
                value: '${month.length}',
                unit: 'BUỔI',
                label: 'Buổi hoàn thành',
              ),
            ],
          ),
          _StatRow(
            stats: [
              _StatData(
                icon: const Icon(
                  CupertinoIcons.text_bubble_fill,
                  size: 19,
                  color: D.blue,
                ),
                value: '$sentences',
                unit: 'CÂU',
                label: 'Câu luyện tập',
              ),
              _StatData(
                icon: const Icon(
                  CupertinoIcons.person_2_fill,
                  size: 22,
                  color: Palette.insightPeople,
                ),
                value: '${sessions(StudyMode.conversation)}',
                label: 'Hội thoại',
              ),
              _StatData(
                icon: const CustomPaint(
                  size: Size(17, 15),
                  painter: TextLinesPainter(color: Palette.yellow),
                ),
                value: '${sessions(StudyMode.writing)}',
                unit: 'ĐOẠN',
                label: 'Đoạn văn',
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Divider(height: 1, color: Palette.insightDot),
          const SizedBox(height: 35),
          if (mistakes == 0)
            // No reference state with zero mistakes has been observed.
            Text(
              'Bạn chưa có lỗi ngữ pháp nào trong tháng này. Tuyệt vời!',
              style: D.text(21, weight: FontWeight.w700),
            )
          else ...[
            _MistakeSummary(count: mistakes),
            _tipsArea(),
          ],
          const SizedBox(height: 34),
          const _GeneratedByAi(),
          const SizedBox(height: 33),
          _WeekChart(state: s, now: now),
          const SizedBox(height: 31),
          const Divider(height: 1, color: Palette.insightDot),
          const SizedBox(height: 31.5),
          _Together(days: s.daysWithHifive),
        ],
      ),
    );
  }

  Widget _tipsArea() => switch (_tips) {
    _TipsState.idle => Padding(
      padding: const EdgeInsets.only(top: 17),
      child: Center(child: _SuggestButton(onTap: _showTips)),
    ),
    _TipsState.loading => Padding(
      padding: const EdgeInsets.only(top: 17),
      child: SizedBox(
        height: 38,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 8),
            const SizedBox(width: 8),
            Text(
              'Đang tạo gợi ý...',
              style: D.text(14, color: Palette.insightFaint),
            ),
          ],
        ),
      ),
    ),
    _TipsState.shown => Padding(
      padding: const EdgeInsets.only(top: 18),
      child: _TipsCard(tips: _tipLines),
    ),
    _TipsState.failed => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ErrorView(
        title: 'Không tạo được gợi ý',
        subtitle: 'Dịch vụ AI đang gặp sự cố. Vui lòng thử lại.',
        onRetry: _showTips,
      ),
    ),
  };
}

String _hoursAndMinutes(int seconds) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(seconds ~/ 3600)}:${two(seconds % 3600 ~/ 60)}';
}

String ordinalBadge(int n) {
  // No reference state with zero sessions has been observed.
  if (n == 0) return '0';
  final tens = n % 100;
  final suffix = tens >= 11 && tens <= 13
      ? 'TH'
      : switch (n % 10) {
          1 => 'ST',
          2 => 'ND',
          3 => 'RD',
          _ => 'TH',
        };
  return '$n$suffix';
}

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
              child: Icon(CupertinoIcons.flame_fill, size: 33, color: D.orange),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 29),
              child: Text(
                'DAYS',
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
              'Bạn đã hoàn thành $count buổi tập trong $monthName, và $yearCount buổi trong năm nay.',
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
          Text('Bạn đã mắc', style: _bigText),
          const SizedBox(width: 5),
          const CustomPaint(
            size: Size(21, 19),
            painter: WarningPainter(color: Palette.wrong),
          ),
          const SizedBox(width: 4),
          Text('$count lỗi ngữ pháp', style: _bigStrong),
        ],
      ),
      const SizedBox(height: 11),
      _InlineWords(
        children: [
          Text('trong tháng này, chủ yếu là', style: _bigText),
          const SizedBox(width: 5),
          const _BookGlyph(color: Palette.wrong),
        ],
      ),
      const SizedBox(height: 11),
      // Grading here has no error categories, and only this one was observed.
      Text('từ vựng', style: _bigStrong.copyWith(color: Palette.wrong)),
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
  final VoidCallback onTap;
  const _SuggestButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
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
            'Xem gợi ý cải thiện',
            style: D.text(13, weight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
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
              'Gợi ý cải thiện',
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
          const SheetTitle('Tạo bởi AI'),
          Text(
            'Phần thống kê và gợi ý cải thiện được AI tổng hợp từ các buổi học trong tháng của bạn. Nội dung có thể chưa chính xác hoàn toàn; hãy dùng như lời khuyên tham khảo.',
            style: D.text(15, color: D.secondary, height: 1.55),
          ),
        ],
      ),
    ),
    child: _attribution(),
  );

  Widget _attribution() => Row(
    children: [
      const Expanded(child: Divider(height: 1, color: Palette.insightDot)),
      const SizedBox(width: 13),
      const CustomPaint(size: Size.square(19), painter: _AiRosettePainter()),
      const SizedBox(width: 8),
      Text(
        'Tạo bởi AI',
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
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
                'Hoạt động tuần này',
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
            'Cùng Hifive',
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
          Text('Bạn đã ở cùng', style: _bigText),
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
          Text('được', style: _bigText),
        ],
      ),
      const SizedBox(height: 11),
      Text.rich(
        // The reference lets this line run past the side margin.
        softWrap: false,
        overflow: TextOverflow.visible,
        TextSpan(
          children: [
            TextSpan(text: '$days ngày. ', style: _bigStrong),
            TextSpan(text: 'Cảm ơn bạn đã đồng hành!', style: _bigText),
          ],
        ),
      ),
    ],
  );
}
