import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/dictionary/dictionary.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'deck_edit_sheet.dart';
import 'dictionary_entry_screen.dart';

part 'dictionary_rows.dart';

/// The deck words go to when the learner hasn't picked one; made on the
/// first add. Its title is stored data, like the deck itself.
const savedDeckTitle = 'Từ đã lưu';

/// Looks words up and adds them to [deck] in one tap, or to the deck the
/// learner picks (saved words by default), starting with [query] when given.
/// docs/dictionary-plan.md.
class DictionaryScreen extends StatefulWidget {
  final Deck? deck;
  final String query;
  const DictionaryScreen({super.key, this.deck, this.query = ''});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  var _seq = 0;
  DictResult? _result;
  var _searching = false;

  /// The chosen deck; null means saved words, made on the first add.
  late Deck? _target = widget.deck;

  /// Cards added here, by entry id, so a second tap takes them back out.
  final _added = <String, (Deck, FlashWord)>{};

  /// Words to learn at the learner's level, asked for once the page is in.
  Future<List<DictEntry>>? _toLearn;
  var _settled = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onChanged);
    if (widget.query.isNotEmpty) _search.text = widget.query;
  }

  /// The keyboard and the suggestions wait for the push transition to end:
  /// opening the keyboard while the page slides in made it stutter. The
  /// route's animation is read after the first frame, once it is attached to
  /// the transition (before that it reads as already complete).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settled) return;
    _settled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animation = ModalRoute.of(context)?.animation;
      if (animation == null || animation.isCompleted) return _arrived();
      void done(AnimationStatus status) {
        if (status != AnimationStatus.completed) return;
        animation.removeStatusListener(done);
        _arrived();
      }

      animation.addStatusListener(done);
    });
  }

  void _arrived() {
    if (!mounted) return;
    _focus.requestFocus();
    final toLearn = AppScope.read(context).wordsToLearn();
    setState(() {
      _toLearn = toLearn;
    });
  }

  /// Back: the keyboard goes first, so the page doesn't resize under it
  /// while it slides away.
  void _close() {
    _focus.unfocus();
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim();

  void _onChanged() {
    // Telex and VNI send letters that are still being composed.
    final v = _search.value;
    if (v.composing.isValid && !v.composing.isCollapsed) return;
    _debounce?.cancel();
    if (_query.isEmpty) {
      _seq++;
      setState(() {
        _result = null;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), _run);
  }

  Future<void> _run() async {
    final seq = ++_seq;
    final query = _query;
    // Only a slow lookup shows the spinner; the old rows stay meanwhile.
    final slow = Timer(const Duration(milliseconds: 300), () {
      if (mounted && seq == _seq) setState(() => _searching = true);
    });
    final result = await AppScope.read(context).lookupWord(query);
    slow.cancel();
    if (!mounted || seq != _seq) return;
    setState(() {
      _result = result;
      _searching = false;
    });
  }

  void _lookUp(String text) {
    _search.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _focus.requestFocus();
  }

  String _deckName(Deck? deck) => deck?.title ?? savedDeckTitle;

  Deck? _currentTarget(AppState state) =>
      _target ?? state.decks.where((d) => d.id == 'saved').firstOrNull;

  Future<void> _pickDeck(BuildContext anchor) async {
    final state = AppScope.read(context);
    final decks = [...state.ownDecks];
    if (widget.deck case final d? when !decks.contains(d)) decks.insert(0, d);
    final hasSaved = decks.any((d) => d.id == 'saved');
    final current = _currentTarget(state);
    final picked = await showGlassMenu<String>(anchor, [
      if (!hasSaved)
        GlassMenuItem(
          'saved',
          savedDeckTitle,
          icon: CupertinoIcons.bookmark_fill,
          checked: current == null,
        ),
      for (final d in decks)
        GlassMenuItem(
          d.id,
          d.title,
          icon: deckIcon(d),
          checked: identical(d, current),
        ),
    ]);
    if (picked == null || !mounted) return;
    setState(() {
      _target = picked == 'saved' && !hasSaved
          ? null
          : decks.firstWhere((d) => d.id == picked);
    });
  }

  /// Adds [entry]; one that needs a meaning opens the manual form first.
  Future<void> _add(DictEntry entry, {List<int> picked = const [0]}) async {
    final state = AppScope.read(context);
    if (entry.needsMeaning) {
      final deck = _target ?? state.savedDeck();
      final card = await sheet<FlashWord>(
        context,
        AddWordSheet(deck: deck, entry: entry),
      );
      if (card != null && mounted) _remember(entry, deck, card);
      return;
    }
    final card = state.addFromDictionary(entry, deck: _target, picked: picked);
    state.feedback.tap();
    _remember(entry, _currentTarget(state)!, card);
  }

  void _remember(DictEntry entry, Deck deck, FlashWord card) {
    AppScope.read(context).rememberLookup(entry.word);
    setState(() => _added[entry.id] = (deck, card));
    // The next word replaces this one as soon as the learner types.
    _search.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _search.text.length,
    );
    _focus.requestFocus();
  }

  void _undo(DictEntry entry) {
    final added = _added.remove(entry.id);
    if (added == null) return;
    AppScope.read(context).removeWord(added.$1, added.$2);
    setState(() {});
  }

  Future<void> _open(DictEntry entry) async {
    final state = AppScope.read(context);
    final card = await go<FlashWord>(
      context,
      DictionaryEntryScreen(entry: entry, deck: _target),
    );
    if (card != null && mounted) {
      _remember(entry, _currentTarget(state)!, card);
    }
  }

  Future<void> _manual() async {
    final state = AppScope.read(context);
    final deck = _target ?? state.savedDeck();
    final card = await sheet<FlashWord>(
      context,
      AddWordSheet(deck: deck, word: _query),
    );
    if (card != null && mounted) {
      state.rememberLookup(card.word);
      setState(() => _added['manual:${card.id}'] = (deck, card));
    }
  }

  /// How a row's add button looks for [entry].
  _AddState _addState(AppState state, DictEntry entry) {
    if (_added.containsKey(entry.id)) return _AddState.added;
    final target = _currentTarget(state);
    final holder = state.deckWith(entry.word, deck: target);
    if (holder != null && identical(holder, target)) return _AddState.inDeck;
    return _AddState.add;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = AppScope.of(context);
    final target = _currentTarget(state);
    final count = _added.length;
    return AppPage(
      title: t.dictTitle,
      background: Palette.settingsPage,
      // The lists add room for the keyboard themselves (`_KeyboardSpace`):
      // resizing the whole page with it made going back lag.
      resizeToAvoidBottomInset: false,
      onBack: _close,
      trailing: count == 0
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                t.dictAddedCount(count),
                key: const ValueKey('dict-added-count'),
                style: D.text(13, weight: FontWeight.w700, color: D.green),
              ),
            ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (anchor) => PressFade(
                      key: const ValueKey('dict-target-deck'),
                      onTap: () => _pickDeck(anchor),
                      child: SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                t.dictAddTo(_deckName(target)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: D.text(
                                  14,
                                  weight: FontWeight.w600,
                                  color: D.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              size: 14,
                              color: D.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SearchField(
              controller: _search,
              focus: _focus,
              onSubmitted: () {
                final first = _result?.hits.firstOrNull;
                if (first != null) _open(first.entry);
              },
            ),
          ),
          if (state.dictionaryDownloading || !state.dictionaryReady)
            _Notice(downloading: state.dictionaryDownloading),
          Expanded(child: _body(context, state)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AppState state) {
    final t = context.t;
    final result = _result;
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    if (_query.isEmpty || result == null) {
      if (_query.isNotEmpty) {
        return const Center(child: CupertinoActivityIndicator());
      }
      return _Start(
        recent: state.recentLookups,
        toLearn: _toLearn,
        level: state.level,
        onLookUp: _lookUp,
        onClear: state.clearRecentLookups,
        onManual: _manual,
        rowFor: (e) => _row(state, DictHit(e, DictMatch.exact)),
      );
    }
    final rows = <Widget>[];
    switch (result.outcome) {
      case DictOutcome.empty:
        break;
      case DictOutcome.tooLong:
        rows.add(_Message(title: t.dictTooLong));
      case DictOutcome.found:
        for (final (i, h) in result.hits.take(12).indexed) {
          rows.add(_row(state, h, featured: i == 0));
        }
      case DictOutcome.meaning:
        rows.add(_SectionLabel(t.dictFromVietnamese));
        for (final h in result.hits) {
          rows.add(_row(state, h));
        }
      case DictOutcome.suggestions:
        final fixes = result.hits.where((h) => h.match == DictMatch.suggestion);
        final prefix = result.hits.where((h) => h.match == DictMatch.prefix);
        if (fixes.isNotEmpty) {
          rows.add(_SectionLabel(t.dictDidYouMean));
          for (final h in fixes) {
            rows.add(_row(state, h));
          }
        }
        if (prefix.isNotEmpty) {
          rows.add(_SectionLabel(t.dictMoreWords));
          for (final h in prefix) {
            rows.add(_row(state, h));
          }
        }
      case DictOutcome.none:
        rows.add(
          _Message(
            title: t.dictNotFound(result.query),
            body: t.dictNotFoundBody,
          ),
        );
    }
    return Stack(
      children: [
        ListView(
          key: const ValueKey('dict-results'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
          children: [
            ...rows,
            const SizedBox(height: 8),
            _ManualRow(
              label: _query.isEmpty ? t.dictManualPlain : t.dictManual(_query),
              onTap: _manual,
            ),
            const _KeyboardSpace(),
          ],
        ),
        if (_searching)
          const Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(child: CupertinoActivityIndicator()),
          ),
      ],
    );
  }

  Widget _row(AppState state, DictHit hit, {bool featured = false}) {
    final target = _currentTarget(state);
    final holder = state.deckWith(hit.entry.word, deck: target);
    return _ResultRow(
      key: ValueKey('dict-result-${hit.entry.id}'),
      hit: hit,
      featured: featured,
      american: state.americanVoice,
      deckName: _deckName(target),
      addState: _addState(state, hit.entry),
      learningIn: holder != null && !identical(holder, target)
          ? holder.title
          : null,
      onTap: () => _open(hit.entry),
      onAdd: () => _add(hit.entry),
      onUndo: () => _undo(hit.entry),
      onSpeak: () => state.speak(hit.entry.word),
    );
  }
}
