import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

part 'insight_cards.dart';
part 'insight_chart.dart';

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
