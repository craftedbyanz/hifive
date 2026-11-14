import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/community/community.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'import_deck_sheet.dart';
import 'share_errors.dart';

/// Public decks in the study language (Community, step 2): search, most
/// added or newest first, twenty at a time. Opening one previews it, adds it
/// to the learner's decks, reports it or blocks its owner.
class ExploreScreen extends StatelessWidget {
  /// Opens a deck the learner just added; the flashcards area owns the
  /// deck screen.
  final void Function(BuildContext context, Deck deck)? onAdded;
  const ExploreScreen({super.key, this.onAdded});

  @override
  Widget build(BuildContext context) => AppPage(
    title: context.t.exploreTitle,
    child: ExploreView(onAdded: onAdded),
  );
}

/// Explore's list, on its own page or as a tab of [CommunityScreen].
class ExploreView extends StatefulWidget {
  final void Function(BuildContext context, Deck deck)? onAdded;
  const ExploreView({super.key, this.onAdded});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  late final AppState _state = AppScope.read(context);
  final _search = TextEditingController();
  Timer? _typing;
  var _sort = ExploreSort.popular;
  final _decks = <PublicDeck>[];
  int? _next;
  bool _loading = true;
  Object? _error;

  /// Answers to stale requests are dropped.
  var _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _typing?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final id = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _decks.clear();
        _next = null;
      }
    });
    try {
      final page = await _state.explore(
        sort: _sort,
        query: _search.text.trim(),
        offset: more ? _next ?? 0 : 0,
      );
      if (!mounted || id != _request) return;
      setState(() {
        _decks.addAll(page.decks);
        _next = page.next;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted || id != _request) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _searchChanged(String _) {
    _typing?.cancel();
    _typing = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _open(PublicDeck deck) async {
    final added = await sheet<Deck>(context, ImportDeckSheet.listed(deck));
    if (!mounted) return;
    if (added != null) {
      toast(context, context.t.importAdded(added.title));
      widget.onAdded?.call(context, added);
    } else {
      // A report or block takes decks off the list.
      unawaited(_load());
    }
  }

  Future<void> _unblock() async {
    final t = context.t;
    try {
      await _state.unblockAll();
      if (!mounted) return;
      toast(context, t.exploreUnblocked);
      unawaited(_load());
    } on Object catch (e) {
      if (mounted) toast(context, shareErrorText(t, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      key: const ValueKey('explore-list'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        TextField(
          key: const ValueKey('explore-search'),
          controller: _search,
          onChanged: _searchChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _load(),
          decoration: InputDecoration(
            hintText: t.exploreSearch,
            prefixIcon: const Icon(
              CupertinoIcons.search,
              size: 18,
              color: D.secondary,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (sort, label) in [
              (ExploreSort.popular, t.explorePopular),
              (ExploreSort.newest, t.exploreNewest),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PressFade(
                  key: ValueKey('explore-sort-${sort.name}'),
                  onTap: () {
                    if (_sort == sort) return;
                    _state.feedback.tap();
                    _sort = sort;
                    _load();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _sort == sort ? D.ink : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: _sort == sort ? D.ink : D.line),
                    ),
                    child: Text(
                      label,
                      style: D.text(
                        13.5,
                        weight: FontWeight.w700,
                        color: _sort == sort ? Colors.white : D.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        for (final d in _decks) _DeckTile(deck: d, onTap: () => _open(d)),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: CupertinoActivityIndicator(),
          )
        else if (_error case final e?)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Text(
                  shareErrorText(t, e),
                  key: const ValueKey('explore-error'),
                  textAlign: TextAlign.center,
                  style: D.text(14, color: D.secondary, height: 1.45),
                ),
                TextButton(
                  key: const ValueKey('explore-retry'),
                  onPressed: _load,
                  child: Text(
                    t.retry,
                    style: D.text(14.5, weight: FontWeight.w700, color: D.blue),
                  ),
                ),
              ],
            ),
          )
        else if (_decks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
            child: Text(
              _search.text.trim().isEmpty ? t.exploreEmpty : t.exploreNoResults,
              key: const ValueKey('explore-empty'),
              textAlign: TextAlign.center,
              style: D.text(14, color: D.secondary, height: 1.5),
            ),
          )
        else if (_next != null)
          Center(
            child: TextButton(
              key: const ValueKey('explore-more'),
              onPressed: () => _load(more: true),
              child: Text(
                t.exploreMore,
                style: D.text(14.5, weight: FontWeight.w700, color: D.blue),
              ),
            ),
          ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            key: const ValueKey('explore-unblock'),
            onPressed: _unblock,
            child: Text(
              t.exploreUnblock,
              style: D.text(12.5, weight: FontWeight.w600, color: D.muted),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeckTile extends StatelessWidget {
  final PublicDeck deck;
  final VoidCallback onTap;
  const _DeckTile({required this.deck, required this.onTap});

  static const _tints = [
    Palette.menuFocus,
    Palette.menuGame,
    Palette.menuListen,
    Palette.menuPlus,
    Palette.menuInsight,
    Palette.menuFlashcard,
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tint =
        _tints[deck.code.codeUnits.fold(0, (a, b) => a + b) % _tints.length];
    final initial = deck.title.trim().isEmpty
        ? '?'
        : deck.title.trim().characters.first.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressFade(
        key: ValueKey('explore-deck-${deck.code}'),
        onTap: onTap,
        child: Surface(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  initial,
                  style: D.text(20, weight: FontWeight.w800, color: tint),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: D.text(15.5, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.exploreMeta(
                        deck.wordCount,
                        deck.author.isEmpty
                            ? t.exploreAuthorUnknown
                            : deck.author,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: D.text(12.5, color: D.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    CupertinoIcons.arrow_down_circle,
                    size: 16,
                    color: D.muted,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.exploreAdds(deck.adds),
                    style: D.text(11, weight: FontWeight.w600, color: D.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
