import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});
  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  DateTime? month;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context), now = s.now();
    month ??= DateTime(now.year, now.month);
    final m = month!,
        first = DateTime(m.year, m.month).weekday % 7,
        total = DateTime(m.year, m.month + 1, 0).day;
    return AppPage(
      title: context.t.streakTitle,
      background: Colors.white,
      child: SingleChildScrollView(
        // Spacing measured from survey 113 (iPhone).
        padding: const EdgeInsets.fromLTRB(24, 13, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Palette.streakOrange.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                context.t.onFire,
                style: D.text(
                  11,
                  weight: FontWeight.w800,
                  color: Palette.streakOrange,
                  spacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.streak}',
                        style: D.text(72, weight: FontWeight.w800, height: 1),
                      ),
                      Text(
                        context.t.daysInARow,
                        style: D.text(
                          17,
                          weight: FontWeight.w700,
                          color: D.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.streak == 0
                            ? context.t.startStreakToday
                            : context.t.keepHabit,
                        style: D.text(14, color: D.muted, height: 1.3),
                      ),
                    ],
                  ),
                ),
                // Grey until the streak starts, then the lit flame.
                StreakFlame(size: 150, active: s.streak > 0),
              ],
            ),
            const SizedBox(height: 29),
            Surface(
              radius: 33,
              padding: const EdgeInsets.fromLTRB(23, 22, 23, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat.yMMMM(context.t.localeName).format(m),
                          style: D.text(
                            20,
                            weight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.t.previousMonth,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 28,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(
                          () => month = DateTime(m.year, m.month - 1),
                        ),
                        icon: const Icon(
                          CupertinoIcons.chevron_left,
                          size: 20,
                          color: D.muted,
                        ),
                      ),
                      IconButton(
                        tooltip: context.t.nextMonth,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 28,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(
                          () => month = DateTime(m.year, m.month + 1),
                        ),
                        icon: const Icon(
                          CupertinoIcons.chevron_right,
                          size: 20,
                          color: D.muted,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    context.t.studiedDays(
                      s.studyDays
                          .where(
                            (d) =>
                                DateTime.parse(d).year == m.year &&
                                DateTime.parse(d).month == m.month,
                          )
                          .length,
                    ),
                    style: D.text(13, color: D.muted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final day in context.t.weekdaysSunFirst.split(','))
                        Text(
                          day,
                          style: D.text(
                            11,
                            color: D.muted,
                            weight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          // Rows 44 pt apart (survey 113).
                          mainAxisExtent: 44,
                        ),
                    itemCount: ((first + total) / 7).ceil() * 7,
                    itemBuilder: (_, i) {
                      final day = i - first + 1;
                      if (day < 1 || day > total) return const SizedBox();
                      final date = DateTime(m.year, m.month, day),
                          studied = s.studyDays.contains(AppState.dayKey(date)),
                          future = date.isAfter(DateUtils.dateOnly(now));
                      return Center(
                        child: Container(
                          width: 31,
                          height: 31,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: studied ? D.orange : null,
                          ),
                          child: Text(
                            '$day',
                            style: D.text(
                              12,
                              weight: FontWeight.w600,
                              color: studied
                                  ? Colors.white
                                  : future
                                  ? D.line
                                  : D.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            Row(
              children: [
                _StreakStat(
                  icon: StreakFlame(size: 17, active: s.streak > 0),
                  label: context.t.currentCaps,
                  color: Palette.streakOrange,
                  value: s.streak,
                ),
                const SizedBox(width: 16),
                _StreakStat(
                  icon: const Icon(
                    CupertinoIcons.bolt_fill,
                    size: 15,
                    color: Palette.yellow,
                  ),
                  label: context.t.longestCaps,
                  color: Palette.yellow,
                  value: s.longestStreak,
                ),
              ],
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}

/// "HIỆN TẠI" / "DÀI NHẤT": a flat tinted card, 81 pt tall (survey 113).
class _StreakStat extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final int value;
  const _StreakStat({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 81,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: D.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 5),
              Text(
                label,
                style: D.text(
                  12,
                  weight: FontWeight.w700,
                  color: color,
                  spacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$value', style: D.text(24, weight: FontWeight.w800)),
        ],
      ),
    ),
  );
}
