import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../domain/sync/sync.dart';
import '../../domain/vocab/vocab.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

/// The name and color of a memory level.
(String, Color) levelLook(AppLocalizations t, MemoryLevel level) =>
    switch (level) {
      MemoryLevel.fresh => (t.levelFresh, D.muted),
      MemoryLevel.learning => (t.levelLearning, Palette.menuPlus),
      MemoryLevel.remembering => (t.levelRemembering, D.blue),
      MemoryLevel.known => (t.levelKnown, D.green),
      MemoryLevel.mastered => (t.levelMastered, Palette.menuFocus),
    };

/// One word's memory: its level, the chance it is remembered now, when it
/// is next due, how long it lasts, how often it was forgotten, and every
/// meeting with it.
class WordScreen extends StatelessWidget {
  final FlashWord word;
  const WordScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = AppScope.of(context);
    final now = state.now();
    final (level, color) = levelLook(t, levelOf(word, now));
    final history = state.historyOf(word);
    final due = word.due;
    final locale = t.localeName;
    return AppPage(
      title: word.word,
      child: ListView(
        key: const ValueKey('word-list'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Surface(
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        word.word,
                        style: D.text(
                          30,
                          weight: FontWeight.w800,
                          spacing: -.6,
                        ),
                      ),
                    ),
                    Container(
                      key: const ValueKey('word-level'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        level,
                        style: D.text(
                          12,
                          weight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (word.phonetic.isNotEmpty)
                  Text(word.phonetic, style: D.text(14, color: D.secondary)),
                const SizedBox(height: 10),
                Text(
                  word.meaning,
                  style: D.text(16, weight: FontWeight.w600, height: 1.4),
                ),
                if (word.example.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    word.example,
                    style: D.system(15, color: D.secondary, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              _Fact(
                t.wordRecallNow,
                word.status == 'new'
                    ? '–'
                    : '${(recallNow(word, now) * 100).round()}%',
              ),
              _Fact(
                t.wordNextReview,
                due == null
                    ? '–'
                    : due.isAfter(now)
                    ? DateFormat.MMMd(locale).add_Hm().format(due)
                    : t.wordNow,
              ),
              _Fact(
                t.wordStability,
                word.status == 'new' ? '–' : t.wordDays(word.stability.round()),
              ),
              _Fact(t.wordLapses, '${word.lapses}'),
            ],
          ),
          const SizedBox(height: 20),
          Text(t.wordHistory, style: D.text(18, weight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (history.isEmpty)
            Text(t.wordNoHistory, style: D.text(14, color: D.secondary))
          else
            for (final e in history) _Meeting(event: e, locale: locale),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label, value;
  const _Fact(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: D.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: D.text(19, weight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          style: D.text(11.5, weight: FontWeight.w600, color: D.secondary),
        ),
      ],
    ),
  );
}

class _Meeting extends StatelessWidget {
  final ReviewEvent event;
  final String locale;
  const _Meeting({required this.event, required this.locale});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rating = [t.rateAgain, t.rateHardCard, t.rateGood, t.rateEasyCard];
    final color = [Palette.wrong, Palette.menuPlus, D.green, D.blue];
    final skill = switch (event.skill) {
      'recall' => t.skillRecall,
      'form' => t.skillForm,
      'use' => t.skillUse,
      _ => t.skillMeaning,
    };
    final r = event.rating.clamp(0, 3);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(CupertinoIcons.circle_fill, size: 9, color: color[r]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${DateFormat.MMMd(locale).add_Hm().format(event.at)} · $skill',
              style: D.text(13.5, weight: FontWeight.w500),
            ),
          ),
          Text(
            rating[r],
            style: D.text(13, weight: FontWeight.w700, color: color[r]),
          ),
        ],
      ),
    );
  }
}
