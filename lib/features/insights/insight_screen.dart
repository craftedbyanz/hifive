import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/design.dart';
import '../../domain/vocab/vocab.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'memory_screen.dart';

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
    final monthName = context.t.monthYearShort(now.month, now.year);
    final month = s.history
        .where((h) => h.date.year == now.year && h.date.month == now.month)
        .toList();
    // Everything studied, not only lessons: vocabulary, listening, games
    // and focus count too.
    final activity = s.activityBetween(
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    );
    final yearSessions = s
        .activityBetween(DateTime(now.year), DateTime(now.year + 1))
        .sessions;
    final mistakes = month.fold(
      0,
      (v, h) => v + h.answers.where((a) => a.firstScore < .65).length,
    );
    return HeaderScrollPage(
      title: context.t.menuInsight,
      subtitle: monthName,
      scrollKey: const ValueKey('insight-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 149, 24, 127),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(streak: s.streak),
          Text(
            context.t.currentStreak,
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
                context.t.updatedToday(DateFormat('HH:mm').format(now)),
                style: D.text(13, color: Palette.insightFaint, height: 17 / 13),
              ),
            ],
          ),
          const SizedBox(height: 31),
          _SessionSummary(
            count: activity.sessions,
            yearCount: yearSessions,
            monthName: monthName,
            now: now,
            studyDays: s.studyDays,
          ),
          const SizedBox(height: 20),
          const _MemoryCard(),
          const SizedBox(height: 32),
          _StatRow(
            stats: [
              _StatData(
                icon: const _BookGlyph(color: Palette.insightBook),
                value: '${activity.words}',
                unit: context.t.unitWords,
                label: context.t.vocabularyLearned,
              ),
              _StatData(
                icon: const Icon(
                  CupertinoIcons.clock_fill,
                  size: 18,
                  color: Palette.insightClock,
                ),
                value: _hoursAndMinutes(activity.seconds),
                unit: context.t.unitHours,
                label: context.t.studyTime,
              ),
              _StatData(
                icon: const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  size: 18,
                  color: D.green,
                ),
                value: '${activity.sessions}',
                unit: context.t.unitSessions,
                label: context.t.sessionsDone,
              ),
            ],
          ),
          _StatRow(
            stats: [
              // Writing, grammar and conversation are coming soon, so the
              // second row shows what can be done now.
              _StatData(
                icon: const Icon(
                  CupertinoIcons.headphones,
                  size: 19,
                  color: D.blue,
                ),
                value: '${activity.listenSeconds ~/ 60}',
                unit: context.t.unitMinutes,
                label: context.t.menuListen,
              ),
              _StatData(
                icon: const Icon(
                  CupertinoIcons.gamecontroller_fill,
                  size: 20,
                  color: Palette.insightPeople,
                ),
                value: '${activity.games}',
                unit: context.t.unitGames,
                label: context.t.activityGames,
              ),
              _StatData(
                icon: const Icon(
                  CupertinoIcons.tree,
                  size: 19,
                  color: Palette.yellow,
                ),
                value: '${activity.focusMinutes}',
                unit: context.t.unitMinutes,
                label: context.t.activityFocus,
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Divider(height: 1, color: Palette.insightDot),
          // Mistakes come from lessons, which are coming soon: without a
          // lesson this month there is nothing to say about them.
          if (month.isNotEmpty) ...[
            const SizedBox(height: 35),
            if (mistakes == 0)
              // No reference state with zero mistakes has been observed.
              Text(
                context.t.noMistakesMonth,
                style: D.text(21, weight: FontWeight.w700),
              )
            else ...[
              _MistakeSummary(count: mistakes),
              _tipsArea(),
            ],
          ],
          // Only suggestions are made by AI, and only once they are shown.
          if (_tips == _TipsState.shown) ...[
            const SizedBox(height: 34),
            const _GeneratedByAi(),
          ],
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
    _TipsState.idle => const Padding(
      padding: EdgeInsets.only(top: 17),
      // Suggestions come from samples, not AI yet: shown as coming soon.
      child: Center(child: _SuggestButton()),
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
              context.t.makingSuggestions,
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
        title: context.t.suggestionsFailed,
        subtitle: context.t.aiServiceDown,
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

/// The way into word memory: words met and known, with the level bar.
class _MemoryCard extends StatelessWidget {
  const _MemoryCard();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final m = AppScope.of(context).memoryInsight;
    final known =
        m.levels[MemoryLevel.known]! + m.levels[MemoryLevel.mastered]!;
    final met = m.levels.entries
        .where((e) => e.key != MemoryLevel.fresh)
        .fold(0, (sum, e) => sum + e.value);
    return PressFade(
      key: const ValueKey('insight-memory'),
      onTap: () => go<void>(context, const MemoryScreen()),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: D.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.memoryTitle,
                    style: D.text(16, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t.memoryCardBody(known, met),
                    style: D.text(12.5, color: D.secondary),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: D.muted),
          ],
        ),
      ),
    );
  }
}
