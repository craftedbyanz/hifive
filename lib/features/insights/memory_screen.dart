import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/design.dart';
import '../../domain/vocab/vocab.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../flashcards/flashcards.dart';

/// The learner's word memory: words by level, measured retention, the next
/// seven days of reviews, skills from graded exercises and the hard words.
class MemoryScreen extends StatelessWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = AppScope.of(context);
    final now = state.now();
    final m = state.memoryInsight;
    final met = m.levels.entries
        .where((e) => e.key != MemoryLevel.fresh)
        .fold(0, (sum, e) => sum + e.value);
    return AppPage(
      title: t.memoryTitle,
      child: ListView(
        key: const ValueKey('memory-list'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          PressFade(
            key: const ValueKey('memory-practice'),
            onTap: () => go<void>(context, const TodayScreen()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              decoration: BoxDecoration(
                color: Palette.menuFocus,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.practiceTitle,
                          style: D.text(
                            16,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.practiceBody,
                          style: D.text(
                            12.5,
                            color: Colors.white.withValues(alpha: .85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          _Section(
            title: t.memoryLevels,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        for (final level in MemoryLevel.values)
                          if (m.levels[level]! > 0)
                            Expanded(
                              flex: m.levels[level]!,
                              child: ColoredBox(color: levelLook(t, level).$2),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final level in MemoryLevel.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: levelLook(t, level).$2,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            levelLook(t, level).$1,
                            style: D.text(14, weight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${m.levels[level]}',
                          key: ValueKey('memory-level-${level.name}'),
                          style: D.text(14, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  t.memoryLevelsNote,
                  style: D.text(12, color: D.secondary, height: 1.45),
                ),
              ],
            ),
          ),
          _Section(
            title: t.memoryRetention,
            child: m.retention == null
                ? Text(
                    t.memoryRetentionWait,
                    key: const ValueKey('memory-retention-wait'),
                    style: D.text(14, color: D.secondary),
                  )
                : Row(
                    children: [
                      Text(
                        '${(m.retention! * 100).round()}%',
                        key: const ValueKey('memory-retention'),
                        style: D.text(34, weight: FontWeight.w800),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          t.memoryRetentionBody(m.retentionReviews),
                          style: D.text(12.5, color: D.secondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
          ),
          _Section(
            title: t.memoryForecast,
            child: _Forecast(
              counts: m.forecast,
              labels: [
                t.memoryToday,
                for (var i = 1; i < 7; i++)
                  DateFormat.E(t.localeName)
                      .format(DateTime(now.year, now.month, now.day + i)),
              ],
            ),
          ),
          _Section(
            title: t.memorySkills,
            child: m.skills.isEmpty
                ? Text(
                    t.memorySkillsEmpty,
                    style: D.text(14, color: D.secondary),
                  )
                : Column(
                    children: [
                      for (final (id, name) in [
                        ('meaning', t.skillMeaning),
                        ('recall', t.skillRecall),
                        ('form', t.skillForm),
                        ('use', t.skillUse),
                      ])
                        if (m.skills[id] case final share?)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 128,
                                  child: Text(
                                    name,
                                    style: D.text(
                                      13.5,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: share,
                                      minHeight: 8,
                                      color: share < .7
                                          ? Palette.menuPlus
                                          : D.green,
                                      backgroundColor: D.line,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${(share * 100).round()}%',
                                  style: D.text(13, weight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
          ),
          _Section(
            title: t.memoryHard,
            child: m.hard.isEmpty
                ? Text(t.memoryHardEmpty, style: D.text(14, color: D.secondary))
                : Column(
                    children: [
                      for (final w in m.hard.take(20))
                        PressFade(
                          key: ValueKey('memory-hard-${w.id}'),
                          onTap: () => go<void>(context, WordScreen(word: w)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    w.word,
                                    style: D.text(15, weight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  '×${w.lapses}',
                                  style: D.text(
                                    13,
                                    weight: FontWeight.w700,
                                    color: Palette.wrong,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (met > 0) const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Surface(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: D.text(16, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _Forecast extends StatelessWidget {
  final List<int> counts;
  final List<String> labels;
  const _Forecast({required this.counts, required this.labels});

  @override
  Widget build(BuildContext context) {
    final top = counts.fold(1, (m, c) => c > m ? c : m);
    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < counts.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${counts[i]}',
                    key: ValueKey('memory-forecast-$i'),
                    style: D.text(11.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 22,
                    height: 4 + 76 * counts[i] / top,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? Palette.menuFocus
                          : D.blue.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    maxLines: 1,
                    style: D.text(
                      10.5,
                      weight: FontWeight.w600,
                      color: D.secondary,
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
