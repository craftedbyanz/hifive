import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import '../../core/design/design.dart';
import '../../domain/garden/garden.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../../widgets/garden/garden_art.dart';
import 'focus_screen.dart';
import 'tag_sheet.dart';

enum GardenPeriod { day, week, month, year }

/// The start (inclusive) and end (exclusive) of the [period] holding [at].
(DateTime, DateTime) periodRange(GardenPeriod period, DateTime at) {
  final day = DateTime(at.year, at.month, at.day);
  return switch (period) {
    GardenPeriod.day => (day, DateTime(day.year, day.month, day.day + 1)),
    GardenPeriod.week => (
      DateTime(day.year, day.month, day.day - day.weekday + 1),
      DateTime(day.year, day.month, day.day - day.weekday + 8),
    ),
    GardenPeriod.month => (
      DateTime(day.year, day.month),
      DateTime(day.year, day.month + 1),
    ),
    GardenPeriod.year => (DateTime(day.year), DateTime(day.year + 1)),
  };
}

/// The garden: trees planted in a day, week, month or year, what was done
/// in that time, the study tree growing now, the species collection and the
/// way into a focus session.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  var _period = GardenPeriod.week;
  late DateTime _at = AppScope.read(context).now();

  void _shift(int step) {
    final (from, to) = periodRange(_period, _at);
    setState(
      () => _at = step < 0 ? from.subtract(const Duration(days: 1)) : to,
    );
  }

  String _label(AppLocalizations t, DateTime from, DateTime to) {
    final locale = t.localeName;
    return switch (_period) {
      GardenPeriod.day => DateFormat.yMMMd(locale).format(from),
      GardenPeriod.week =>
        '${DateFormat.MMMd(locale).format(from)} – '
            '${DateFormat.MMMd(locale).format(to.subtract(const Duration(days: 1)))}',
      GardenPeriod.month => DateFormat.yMMMM(locale).format(from),
      GardenPeriod.year => DateFormat.y(locale).format(from),
    };
  }

  final _shareKey = GlobalKey();

  /// Shares a picture of the garden as shown, with its counts.
  Future<void> _share(int trees) async {
    final state = AppScope.read(context);
    final t = context.t;
    final boundary =
        _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final shown = await state.system.shareImage(
      data.buffer.asUint8List(),
      t.gardenShareText(trees),
    );
    if (!shown && mounted) toast(context, t.gardenShareFailed);
  }

  Future<void> _pickStudyTree(AppState state) async {
    final picked = await sheet<String>(
      context,
      SpeciesPicker(selected: state.studySpecies),
    );
    if (picked != null) state.setStudySpecies(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = AppScope.of(context);
    final (from, to) = periodRange(_period, _at);
    final plants = state.plants(from, to);
    final withered = plants.where((p) => p.withered).length;
    bool inRange(DateTime d) => !d.isBefore(from) && d.isBefore(to);
    final focusMinutes = state.focusSessions
        .where((s) => s.outcome == FocusOutcome.done && inRange(s.end))
        .fold(0, (sum, s) => sum + s.minutes);
    final credits = state.countedStudyCredits
        .where((c) => inRange(c.at))
        .toList();
    final days = {for (final c in credits) DateUtils.dateOnly(c.at)}.length;
    final stats = state.gardenStats;
    final open = species.where(stats.unlocks).length;
    final isNow = inRange(state.now());

    final byTag = state.focusByTag(from, to);
    final tagTotal = byTag.fold(0, (sum, e) => sum + e.$2);

    return AppPage(
      title: t.gardenTitle,
      trailing: PressFade(
        key: const ValueKey('garden-share'),
        onTap: () => _share(plants.length - withered),
        child: Semantics(
          button: true,
          label: t.gardenShare,
          child: const Icon(CupertinoIcons.share, size: 22, color: D.ink),
        ),
      ),
      child: ListView(
        key: const ValueKey('garden-list'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _PeriodTabs(
            selected: _period,
            labels: [t.gardenDay, t.gardenWeek, t.gardenMonth, t.gardenYear],
            onPick: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Arrow('garden-previous', CupertinoIcons.chevron_left, () {
                _shift(-1);
              }),
              Expanded(
                child: Text(
                  _label(t, from, to),
                  textAlign: TextAlign.center,
                  style: D.text(
                    13,
                    weight: FontWeight.w600,
                    color: D.secondary,
                  ),
                ),
              ),
              _Arrow(
                'garden-next',
                CupertinoIcons.chevron_right,
                isNow ? null : () => _shift(1),
              ),
            ],
          ),
          RepaintBoundary(
            key: _shareKey,
            child: ColoredBox(
              color: D.background,
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, box) => GardenScene(
                      key: ValueKey(
                        'garden-scene-${_period.name}-${from.toIso8601String()}',
                      ),
                      plants: plants,
                      width: box.maxWidth,
                      cells: GardenScene.cellsFor(plants.length),
                    ),
                  ),
                  Text(
                    plants.isEmpty
                        ? t.gardenEmpty
                        : t.gardenCounts(plants.length - withered, withered),
                    key: const ValueKey('garden-counts'),
                    textAlign: TextAlign.center,
                    style: D.text(
                      13,
                      weight: FontWeight.w700,
                      color: D.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Surface(
            radius: 20,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _Stat(
                  t.gardenHoursMinutes(focusMinutes ~/ 60, focusMinutes % 60),
                  t.gardenFocusTime,
                ),
                _Stat('${credits.length}', t.gardenReviews),
                _Stat('$days', t.gardenStudyDays),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Surface(
            key: const ValueKey('garden-by-tag'),
            radius: 20,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.gardenByTag, style: D.text(14, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (byTag.isEmpty)
                  Text(
                    t.gardenByTagEmpty,
                    style: D.text(12, color: D.secondary, height: 1.4),
                  )
                else
                  for (final (tag, minutes) in byTag)
                    _TagShare(
                      name: tagName(t, tag),
                      color: tagColor(tag),
                      time: t.gardenHoursMinutes(minutes ~/ 60, minutes % 60),
                      share: minutes / tagTotal,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PressFade(
            key: const ValueKey('garden-study-tree'),
            onTap: () => _pickStudyTree(state),
            child: Surface(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
              child: Row(
                children: [
                  TreeArt(
                    species: state.studySpecies,
                    size: 76,
                    growth: .05 + .95 * stats.growing / reviewsPerTree,
                    island: false,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.gardenGrowing(stats.growing, reviewsPerTree),
                          style: D.text(13, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: stats.growing / reviewsPerTree,
                            minHeight: 7,
                            color: Palette.menuFocus,
                            backgroundColor: D.line,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.gardenGrowingHint,
                          style: D.text(11, color: D.secondary, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: PressFade(
              key: const ValueKey('garden-start-focus'),
              onTap: () => go<void>(context, const FocusScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Palette.menuFocus,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  t.gardenStartFocus,
                  style: D.text(
                    16,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                t.gardenCollection,
                style: D.text(20, weight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Text(
                t.gardenUnlocked(open, species.length),
                style: D.text(12, weight: FontWeight.w600, color: D.muted),
              ),
            ],
          ),
          for (final g in SpeciesGroup.values) ...[
            const SizedBox(height: 18),
            _GroupHeader(
              name: groupName(t, g),
              open: speciesInGroup(g).where(stats.unlocks).length,
              total: speciesInGroup(g).length,
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: .66,
              children: [
                for (final s in speciesInGroup(g))
                  _CollectionTile(
                    id: s.id,
                    name: speciesName(t, s.id),
                    origin: originName(t, s.origin),
                    rule: unlockText(t, s.unlock),
                    open: stats.unlocks(s),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The name of a collection section.
String groupName(AppLocalizations t, SpeciesGroup g) => switch (g) {
  SpeciesGroup.start => t.gardenGroupStart,
  SpeciesGroup.memory => t.gardenGroupMemory,
  SpeciesGroup.diligence => t.gardenGroupDiligence,
  SpeciesGroup.focus => t.gardenGroupFocus,
  SpeciesGroup.season => t.gardenGroupSeason,
  SpeciesGroup.legend => t.gardenGroupLegend,
};

/// Where a species is at home; the legendary one has no country.
String originName(AppLocalizations t, Origin? o) => switch (o) {
  Origin.vietnam => t.originVietnam,
  Origin.japan => t.originJapan,
  Origin.korea => t.originKorea,
  Origin.china => t.originChina,
  Origin.india => t.originIndia,
  Origin.germany => t.originGermany,
  Origin.england => t.originEngland,
  Origin.netherlands => t.originNetherlands,
  Origin.france => t.originFrance,
  Origin.spain => t.originSpain,
  Origin.greece => t.originGreece,
  Origin.norway => t.originNorway,
  Origin.finland => t.originFinland,
  Origin.russia => t.originRussia,
  Origin.kazakhstan => t.originKazakhstan,
  Origin.canada => t.originCanada,
  Origin.usa => t.originUsa,
  Origin.mexico => t.originMexico,
  Origin.madagascar => t.originMadagascar,
  null => t.originLegend,
};

class _GroupHeader extends StatelessWidget {
  final String name;
  final int open, total;
  const _GroupHeader({
    required this.name,
    required this.open,
    required this.total,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(name, style: D.text(16, weight: FontWeight.w700)),
      const SizedBox(width: 8),
      Text(
        '$open/$total',
        style: D.text(12, weight: FontWeight.w600, color: D.muted),
      ),
    ],
  );
}

/// What a learner must do to unlock a species.
String unlockText(AppLocalizations t, Unlock u) => switch (u.kind) {
  UnlockKind.always => t.unlockAlways,
  UnlockKind.studyTrees => t.unlockStudyTrees(u.value),
  UnlockKind.wordsKnown => t.unlockWordsKnown(u.value),
  UnlockKind.streak => t.unlockStreak(u.value),
  UnlockKind.focusHours => t.unlockFocusHours(u.value),
  UnlockKind.focusSessions => t.unlockFocusSessions(u.value),
  UnlockKind.longSession => t.unlockLongSession(u.value),
  UnlockKind.reviews => t.unlockReviews(u.value),
  UnlockKind.studyDays => t.unlockStudyDays(u.value),
  UnlockKind.blooms => t.unlockBlooms(u.value),
  UnlockKind.eveningDays => t.unlockEvenings(u.value),
  UnlockKind.comeback => t.unlockComeback(u.value),
  UnlockKind.weeksInRow => t.unlockWeeks(u.value),
  UnlockKind.month => t.unlockMonth(u.value),
};

class _PeriodTabs extends StatelessWidget {
  final GardenPeriod selected;
  final List<String> labels;
  final ValueChanged<GardenPeriod> onPick;
  const _PeriodTabs({
    required this.selected,
    required this.labels,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: D.line,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      children: [
        for (final p in GardenPeriod.values)
          Expanded(
            child: PressFade(
              key: ValueKey('garden-period-${p.name}'),
              onTap: () => onPick(p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: p == selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[p.index],
                  style: D.text(
                    12.5,
                    weight: FontWeight.w700,
                    color: p == selected ? D.ink : D.secondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Arrow extends StatelessWidget {
  final String id;
  final IconData icon;
  final VoidCallback? onTap;
  const _Arrow(this.id, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey(id),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Icon(icon, size: 16, color: onTap == null ? D.line : D.secondary),
    ),
  );
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: D.text(17, weight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: D.text(11, weight: FontWeight.w600, color: D.secondary),
        ),
      ],
    ),
  );
}

class _CollectionTile extends StatelessWidget {
  final String id, name, origin, rule;
  final bool open;
  const _CollectionTile({
    required this.id,
    required this.name,
    required this.origin,
    required this.rule,
    required this.open,
  });

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('garden-species-$id'),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: D.line),
    ),
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: Opacity(
              opacity: open ? 1 : .35,
              child: TreeArt(
                species: id,
                size: 92,
                island: false,
                animate: false,
              ),
            ),
          ),
        ),
        Row(
          children: [
            if (!open) ...[
              const Icon(CupertinoIcons.lock_fill, size: 11, color: D.muted),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: D.text(13, weight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          origin,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: D.text(10.5, weight: FontWeight.w600, color: D.secondary),
        ),
        if (!open) ...[
          const SizedBox(height: 2),
          Text(
            rule,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: D.text(
              10.5,
              weight: FontWeight.w600,
              color: Palette.menuFocus,
              height: 1.3,
            ),
          ),
        ],
      ],
    ),
  );
}

/// One tag's share of the period's focus time: a dot, the name, a bar and
/// the time with its percentage.
class _TagShare extends StatelessWidget {
  final String name, time;
  final Color color;
  final double share;
  const _TagShare({
    required this.name,
    required this.color,
    required this.time,
    required this.share,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: D.text(12.5, weight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 8,
              color: color,
              backgroundColor: D.line,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$time · ${(share * 100).round()}%',
          style: D.text(11.5, weight: FontWeight.w600, color: D.secondary),
        ),
      ],
    ),
  );
}
