import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../community/community.dart';
import '../game/game.dart';
import 'deck_edit_sheet.dart';
import 'deck_list_screen.dart';
import 'review_screen.dart';
import 'word_screen.dart';

class DeckScreen extends StatefulWidget {
  final Deck deck;
  const DeckScreen({super.key, required this.deck});
  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  String filter = 'All', sort = 'Newest', query = '';
  bool searching = false;
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<FlashWord> get words {
    final list = widget.deck.words
        .where(
          (w) =>
              (filter == 'All' ||
                  w.status ==
                      {
                        'Not studied': 'new',
                        'Learning': 'learning',
                        'Mastered': 'review',
                      }[filter]) &&
              (w.word.toLowerCase().contains(query.toLowerCase()) ||
                  w.meaning.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
    if (sort == 'A-Z') list.sort((a, b) => a.word.compareTo(b.word));
    if (sort == 'Oldest') return list.reversed.toList();
    return list;
  }

  /// Cards still being learned come first, as on the reference.
  static List<FlashWord> _queue(List<FlashWord> list) => [
    ...list.where((w) => w.status == 'learning'),
    ...list.where((w) => w.status != 'learning'),
  ];

  Future<void> _openOptions(BuildContext anchor) async {
    final choice = await showGlassMenu<String>(anchor, [
      GlassMenuItem(
        'words',
        context.t.addWords,
        icon: CupertinoIcons.text_badge_plus,
      ),
      GlassMenuItem('add', context.t.addCards, icon: CupertinoIcons.sparkles),
      GlassMenuItem('edit', context.t.editDeck, icon: CupertinoIcons.pencil),
      GlassMenuItem(
        'reset',
        context.t.restartDeck,
        icon: CupertinoIcons.arrow_counterclockwise,
      ),
      if (AppScope.read(context).shares != null && widget.deck.words.isNotEmpty)
        GlassMenuItem('share', context.t.shareDeck, icon: CupertinoIcons.share),
    ]);
    if (!mounted || choice == null) return;
    if (choice == 'words') {
      await sheet<void>(context, AddWordSheet(deck: widget.deck));
      if (mounted) setState(() {});
    } else if (choice == 'edit') {
      await sheet<void>(context, EditDeckSheet(deck: widget.deck));
      if (mounted) setState(() {});
    } else if (choice == 'share') {
      await sheet<void>(context, ShareDeckSheet(deck: widget.deck));
    } else if (choice == 'add') {
      await deckForm(context, deck: widget.deck);
    } else if (await confirm(
      context,
      context.t.restartDeckTitle,
      context.t.restartDeckBody,
      action: context.t.resetAction,
      cancel: context.t.cancel,
      destructive: true,
    )) {
      if (mounted) AppScope.read(context).resetSchedule(widget.deck);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final deck = widget.deck, list = words;
    final due = list.where((w) => w.isDue(state.now())).toList();
    // With nothing due, an unfiltered deck offers to review everything.
    final reviewAll = due.isEmpty && list.isNotEmpty && filter == 'All';
    final review = reviewAll ? list : due;
    return Stack(
      children: [
        Positioned.fill(
          child: _ScrollBody(
            title: deck.title,
            trailing: Builder(
              builder: (anchor) => HeaderRoundButton(
                icon: CupertinoIcons.ellipsis,
                iconSize: 24,
                width: 48,
                label: context.t.deckOptions,
                onTap: () => _openOptions(anchor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: searching
                      ? _SearchBar(
                          controller: search,
                          onChanged: (v) => setState(() => query = v),
                          onCancel: () => setState(() {
                            searching = false;
                            query = '';
                            search.clear();
                            FocusScope.of(context).unfocus();
                          }),
                        )
                      : _Summary(
                          deck: deck,
                          onEdit: () async {
                            await sheet<void>(
                              context,
                              EditDeckSheet(deck: deck),
                            );
                            if (mounted) setState(() {});
                          },
                          reviewLabel: reviewAll
                              ? context.t.reviewAll
                              : context.t.reviewDue(due.length),
                          onReview: review.isEmpty
                              ? null
                              : () => go<void>(
                                  context,
                                  ReviewScreen(
                                    deck: deck,
                                    words: _queue(review),
                                  ),
                                ),
                          onGame: list.isEmpty
                              ? null
                              : () => go<void>(
                                  context,
                                  GameScreen(
                                    words: List.of(list),
                                    title: deck.title,
                                  ),
                                ),
                          sort: sort,
                          filter: filter,
                          onSort: (v) => setState(() => sort = v),
                          onFilter: (v) => setState(() => filter = v),
                        ),
                ),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 62),
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.checkmark_circle,
                          size: 36,
                          color: Palette.settingsEdge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.t.doneForToday,
                          style: D.text(
                            14,
                            color: Palette.settingsHint,
                            height: 17 / 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final w in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11.5),
                    child: PressFade(
                      key: ValueKey('deck-word-${w.id}'),
                      onTap: () => go<void>(context, WordScreen(word: w)),
                      child: _WordRow(word: w, due: w.isDue(state.now())),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 27,
          bottom: 28,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            offset: searching ? const Offset(0, 2) : Offset.zero,
            child: Semantics(
              label: context.t.searchCards,
              child: Tooltip(
                message: context.t.searchCards,
                triggerMode: TooltipTriggerMode.manual,
                child: PressFade(
                  key: const ValueKey('deck-search-open'),
                  onTap: () => setState(() => searching = true),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Palette.insightBackEdge,
                        width: .5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: D.ink.withValues(alpha: .1),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.search,
                      size: 25,
                      color: D.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrollBody extends StatelessWidget {
  final String title;
  final Widget trailing, child;
  const _ScrollBody({
    required this.title,
    required this.trailing,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => HeaderScrollPage(
    title: title,
    titleSize: 16.5,
    padding: const EdgeInsets.fromLTRB(24, 137, 24, 110),
    trailing: trailing,
    child: child,
  );
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onCancel,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 25),
    child: Transform.translate(
      offset: const Offset(-8, -10),
      child: SizedBox(
        height: 44,
        // Fixed at 361 pt, the iPhone measurement; minWidth too, so a wider
        // screen (411 pt on the Android emulator) cannot invert the bounds.
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 361,
          maxWidth: 361,
          child: SizedBox(
            width: 361,
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('deck-search'),
                    controller: controller,
                    autofocus: true,
                    onChanged: onChanged,
                    style: D.text(14.5, height: 20 / 14.5),
                    decoration: InputDecoration(
                      hintText: context.t.searchWordsHint,
                      hintStyle: D.text(
                        14.5,
                        color: Palette.settingsHint,
                        height: 20 / 14.5,
                      ),
                      filled: true,
                      fillColor: Palette.settingsPanel,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      prefixIconConstraints: const BoxConstraints(minWidth: 39),
                      prefixIcon: const Icon(
                        CupertinoIcons.search,
                        size: 19,
                        color: Palette.settingsHint,
                      ),
                      enabledBorder: _border,
                      focusedBorder: _border,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                PressFade(
                  key: const ValueKey('deck-search-cancel'),
                  onTap: onCancel,
                  child: Text(
                    context.t.cancelEn,
                    style: D.text(14.5, height: 19 / 14.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide.none,
  );
}

class _Summary extends StatelessWidget {
  final Deck deck;
  final String reviewLabel, sort, filter;
  final VoidCallback? onReview, onGame;

  /// Opens the editor for the name, description and icon.
  final VoidCallback onEdit;
  final ValueChanged<String> onSort, onFilter;
  const _Summary({
    required this.deck,
    required this.reviewLabel,
    required this.onReview,
    required this.onGame,
    required this.onEdit,
    required this.sort,
    required this.filter,
    required this.onSort,
    required this.onFilter,
  });

  int _count(String status) =>
      deck.words.where((w) => w.status == status).length;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: PressFade(
          key: const ValueKey('deck-header-icon'),
          onTap: onEdit,
          child: Container(
            width: 64,
            height: 64,
            decoration: ShapeDecoration(
              color: Palette.previewDefault,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadows: [
                BoxShadow(
                  color: Palette.previewDefault.withValues(alpha: .35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(deckIcon(deck), size: 36, color: Colors.white),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        deck.title,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: D.text(
          27.5,
          weight: FontWeight.w800,
          spacing: -.3,
          height: 35 / 27.5,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        deck.description,
        textAlign: TextAlign.center,
        style: D.text(13, color: Palette.settingsMuted, height: 17 / 13),
      ),
      const SizedBox(height: 32),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Stat(CupertinoIcons.sparkles, '${_count('new')}', context.t.statNew),
          const SizedBox(width: 34),
          _Stat(
            CupertinoIcons.book_fill,
            '${_count('learning')}',
            context.t.statLearning,
          ),
          const SizedBox(width: 34),
          _Stat(
            Icons.history_rounded,
            '${_count('review')}',
            context.t.statReview,
          ),
        ],
      ),
      const SizedBox(height: 32),
      Row(
        children: [
          Expanded(
            child: _Action(
              reviewLabel,
              key: const ValueKey('start-review'),
              filled: true,
              onTap: onReview,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(child: _Action('Flow Letter', onTap: onGame)),
        ],
      ),
      const SizedBox(height: 31),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.t.deckProgress,
            style: D.text(
              13.5,
              weight: FontWeight.w500,
              color: Palette.settingsMuted,
              height: 18 / 13.5,
            ),
          ),
          Text(
            context.t.cardsCount(deck.words.length),
            style: D.text(13.5, weight: FontWeight.w700, height: 18 / 13.5),
          ),
        ],
      ),
      const SizedBox(height: 11),
      _ProgressBar(
        fresh: _count('new'),
        learning: _count('learning'),
        review: _count('review'),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          _Legend(context.t.statNew, Palette.previewDefault),
          const SizedBox(width: 15),
          _Legend(context.t.statLearning, Palette.progressLearning),
          const SizedBox(width: 15),
          _Legend(context.t.statReview, Palette.progressReview),
        ],
      ),
      const SizedBox(height: 11),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (anchor) => _Chip(
              key: const ValueKey('deck-sort'),
              icon: CupertinoIcons.arrow_up_arrow_down,
              label: _sortName(context.t, sort),
              active: false,
              onTap: () async {
                final v = await showGlassMenu<String>(anchor, [
                  for (final s in const ['Newest', 'Oldest', 'A-Z'])
                    GlassMenuItem(
                      s,
                      _sortName(context.t, s),
                      checked: s == sort,
                    ),
                ]);
                if (v != null) onSort(v);
              },
            ),
          ),
          Builder(
            builder: (anchor) => _Chip(
              key: const ValueKey('deck-filter'),
              icon: CupertinoIcons.line_horizontal_3_decrease_circle,
              label: filter == 'All'
                  ? context.t.filters
                  : _filterName(context.t, filter),
              active: filter != 'All',
              onTap: () async {
                final v = await showGlassMenu<String>(anchor, [
                  for (final f in const [
                    'All',
                    'Not studied',
                    'Learning',
                    'Mastered',
                  ])
                    GlassMenuItem(
                      f,
                      _filterName(context.t, f),
                      checked: f == filter,
                    ),
                ]);
                if (v != null) onFilter(v);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ],
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _Stat(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 56,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Palette.settingsHint),
            const SizedBox(width: 4),
            Text(
              value,
              style: D.text(22, weight: FontWeight.w800, height: 29 / 22),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          softWrap: false,
          style: D.text(12, color: Palette.settingsMuted, height: 14 / 12),
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onTap;
  const _Action(this.label, {super.key, this.filled = false, this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    enabled: onTap != null,
    child: PressFade(
      onTap: onTap,
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? (onTap == null ? Palette.settingsPage : Palette.settingsPanel)
              : Colors.white,
          borderRadius: BorderRadius.circular(22.5),
          border: filled ? null : Border.all(color: Palette.settingsEdge),
        ),
        child: Text(
          label,
          style: D.text(
            14,
            weight: FontWeight.w700,
            color: onTap == null ? Palette.ctaDisabled : D.ink,
            height: 1,
          ),
        ),
      ),
    ),
  );
}

class _ProgressBar extends StatelessWidget {
  final int fresh, learning, review;
  const _ProgressBar({
    required this.fresh,
    required this.learning,
    required this.review,
  });
  @override
  Widget build(BuildContext context) {
    final parts = [
      (fresh, Palette.previewDefault),
      (learning, Palette.progressLearning),
      (review, Palette.progressReview),
    ].where((p) => p.$1 > 0).toList();
    return SizedBox(
      height: 10,
      child: Row(
        children: [
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              flex: part.$1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: part.$2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String text;
  final Color color;
  const _Legend(this.text, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        text,
        style: D.text(12, color: Palette.settingsMuted, height: 15 / 12),
      ),
    ],
  );
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => PressFade(
    onTap: onTap,
    child: Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.settingsPanel, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: active ? D.ink : Palette.settingsMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: D.text(
              12,
              weight: FontWeight.w500,
              color: active ? D.ink : Palette.settingsMuted,
              height: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

class _WordRow extends StatelessWidget {
  final FlashWord word;
  final bool due;
  const _WordRow({required this.word, required this.due});
  @override
  Widget build(BuildContext context) {
    final (label, fill, ink) = switch (word.status) {
      'new' => (context.t.pillNew, Palette.newPill, Palette.newPillInk),
      'learning' => (
        context.t.pillLearning,
        Palette.learningPill,
        Palette.learningPillInk,
      ),
      _ => (context.t.pillReview, Palette.reviewPill, Palette.reviewPillInk),
    };
    return Container(
      // The reference has no phonetic for some words, and those rows are shorter.
      height: context.grow(word.phonetic.isEmpty ? 88 : 102),
      padding: const EdgeInsets.fromLTRB(15, 19, 15, 0),
      decoration: ShapeDecoration(
        color: Palette.deckRowFill,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Palette.settingsEdge, width: 1.2),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      word.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: D.text(
                        15.5,
                        weight: FontWeight.w700,
                        height: 22 / 15.5,
                      ),
                    ),
                  ),
                  Semantics(
                    label: context.t.pronounceWord(word.word),
                    child: Tooltip(
                      message: context.t.pronounceWord(word.word),
                      triggerMode: TooltipTriggerMode.manual,
                      child: PressFade(
                        onTap: () => playWord(context, word.word),
                        child: const SizedBox(
                          width: 36,
                          height: 22,
                          child: Icon(
                            CupertinoIcons.speaker_2_fill,
                            size: 17,
                            color: Palette.settingsHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: D.text(
                        10,
                        weight: FontWeight.w700,
                        color: ink,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Padding(
                padding: EdgeInsets.only(right: due ? 22 : 0),
                child: Text(
                  word.meaning,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: D.text(13.2, color: D.ink, height: 18 / 13.2),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                word.phonetic,
                style: D.text(
                  9.5,
                  color: Palette.settingsHint,
                  height: 12 / 9.5,
                ),
              ),
            ],
          ),
          if (due)
            Positioned(
              right: 0,
              bottom: 15,
              child: Container(
                key: ValueKey('due-${word.id}'),
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Palette.dueDot,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A sort id's name; the ids stay the English words.
String _sortName(AppLocalizations t, String sort) => switch (sort) {
  'Oldest' => t.sortOldest,
  'A-Z' => t.sortAZ,
  _ => t.sortNewest,
};

/// A filter id's name; the ids stay the English words.
String _filterName(AppLocalizations t, String filter) => switch (filter) {
  'Not studied' => t.filterNotStudied,
  'Learning' => t.filterLearning,
  'Mastered' => t.filterMastered,
  _ => t.filterAll,
};
