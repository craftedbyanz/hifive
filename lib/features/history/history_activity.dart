part of 'history_screen.dart';

/// One card of an activity section: its key, what it shows, what search
/// matches, and what a tap does.
class _Activity {
  final String id, headline, detail, title, date, search;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;
  const _Activity({
    required this.id,
    required this.headline,
    required this.detail,
    required this.title,
    required this.date,
    required this.search,
    required this.icon,
    required this.tint,
    this.onTap,
  });
}

/// The sections after the lessons: vocabulary, listening, games and focus,
/// newest first, each limited to its latest [_ActivitySections.shown]
/// cards and filtered by [query].
class _ActivitySections {
  static const shown = 20;
  final List<(String, List<_Activity>)> sections;
  const _ActivitySections(this.sections);

  bool get isEmpty => sections.every((s) => s.$2.isEmpty);

  factory _ActivitySections.of(BuildContext context, String query) {
    final t = context.t;
    final state = AppScope.read(context);
    final locale = t.localeName;
    String when(DateTime at) =>
        '${DateFormat.MMMd(locale).format(at)} · ${DateFormat.Hm(locale).format(at)}';
    final q = query.trim().toLowerCase();
    List<_Activity> pick(Iterable<_Activity> all) => [
      for (final a in all)
        if (q.isEmpty || a.search.toLowerCase().contains(q)) a,
    ].take(shown).toList();

    String sourceName(String source) => switch (source) {
      'today' || 'practice' => t.todayTitle,
      'focusBreak' => t.activityFocusBreak,
      'flowLetter' => t.activityGames,
      _ => t.menuFlashcards,
    };

    final words = [
      for (final (i, s) in state.wordSessionLog.indexed)
        _Activity(
          id: 'words-$i',
          headline: t.activityWordsCount(s.words.length),
          detail: t.activityKnown(s.known, s.words.length),
          title: sourceName(s.source),
          date: when(s.start),
          search: '${sourceName(s.source)} ${s.words.join(' ')}',
          icon: CupertinoIcons.rectangle_stack_fill,
          tint: Palette.menuFlashcard,
          onTap: () {
            final cards = state.cardsFor(s.words);
            if (cards.isEmpty) return;
            go<void>(
              context,
              ReviewScreen(
                deck: Deck(
                  id: 'history',
                  title: sourceName(s.source),
                  description: '',
                  words: cards,
                ),
                words: cards,
                source: 'history',
              ),
            );
          },
        ),
    ];

    final listening = [
      for (final s in state.listenSessionLog)
        _Activity(
          id: 'listen-${s.day.id}',
          headline: t.activityMinutes((s.day.heard / 60).ceil()),
          detail: s.day.done ? t.activityListenDone : (s.source?.title ?? ''),
          title: s.title.isEmpty ? t.activityListening : s.title,
          date: when(s.day.at),
          search: '${s.title} ${s.source?.title ?? ''}',
          icon: CupertinoIcons.headphones,
          tint: Palette.menuListen,
          onTap: s.source == null
              ? null
              : () => go<void>(
                  context,
                  ListenScreen(source: s.source!, index: s.index),
                ),
        ),
    ];

    final games = [
      for (final (i, g) in state.gameResults.reversed.indexed)
        _Activity(
          id: 'game-$i',
          headline: t.activityScore(g.score),
          detail: g.score >= state.bestScore && g.score > 0
              ? t.activityBest
              : '',
          title: t.activityGames,
          date: when(g.at),
          search: t.activityGames,
          icon: CupertinoIcons.game_controller_solid,
          tint: Palette.menuGame,
        ),
    ];

    final focus = [
      for (final f in [
        ...state.focusSessions,
      ]..sort((a, b) => b.start.compareTo(a.start)))
        _Activity(
          id: 'focus-${f.id}',
          headline: t.activityMinutes(
            (f.end.difference(f.start).inSeconds / 60).round(),
          ),
          detail: f.outcome == FocusOutcome.done
              ? t.activityFocusDone
              : t.activityFocusWithered,
          title: f.title.isNotEmpty
              ? f.title
              : tagName(t, state.tagById(f.tag)),
          date: when(f.start),
          search: '${f.title} ${tagName(t, state.tagById(f.tag))}',
          icon: CupertinoIcons.tree,
          tint: f.outcome == FocusOutcome.done ? D.green : D.muted,
        ),
    ];

    return _ActivitySections([
      (t.activityWords, pick(words)),
      (t.activityListening, pick(listening)),
      (t.activityGames, pick(games)),
      (t.activityFocus, pick(focus)),
    ]);
  }
}

/// A section of activity cards under its title and a hairline, scrolling
/// sideways like the lesson sections.
class _ActivitySection extends StatelessWidget {
  final String title;
  final List<_Activity> items;
  final bool searching;
  const _ActivitySection({
    required this.title,
    required this.items,
    required this.searching,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 15),
          child: Row(
            children: [
              Text(title, style: D.text(17, weight: FontWeight.w700)),
              if (searching) ...[
                const SizedBox(width: 8),
                Text(
                  '${items.length}',
                  style: D.text(13, weight: FontWeight.w700, color: D.muted),
                ),
              ],
              const SizedBox(width: 16),
              const Expanded(
                child: Divider(height: 1, thickness: 1, color: D.line),
              ),
            ],
          ),
        ),
        SizedBox(
          height: context.grow(186),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 23),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) =>
                SizedBox(width: 162, child: _ActivityTile(items[i])),
          ),
        ),
      ],
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  final _Activity a;
  const _ActivityTile(this.a);

  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey('activity-${a.id}'),
    onTap: a.onTap,
    child: Column(
      children: [
        Container(
          height: context.grow(148),
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: D.ink.withValues(alpha: .05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: a.tint.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(a.icon, size: 18, color: a.tint),
              ),
              const Spacer(),
              Text(
                a.headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: D.text(19, weight: FontWeight.w800),
              ),
              if (a.detail.isNotEmpty)
                Text(
                  a.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: D.text(12.5, color: D.secondary),
                ),
              const SizedBox(height: 6),
              Text(a.date, style: D.text(11, color: D.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          a.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: D.text(14, weight: FontWeight.w700),
        ),
      ],
    ),
  );
}
