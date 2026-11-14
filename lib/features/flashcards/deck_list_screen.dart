import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../community/community.dart';
import 'deck_edit_sheet.dart';
import 'deck_screen.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  /// Adds a deck someone shared, then opens it.
  static Future<void> _import(BuildContext context) async {
    final deck = await sheet<Deck>(context, const ImportDeckSheet());
    if (deck == null || !context.mounted) return;
    toast(context, context.t.importAdded(deck.title));
    await go<void>(context, DeckScreen(deck: deck));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: HeaderScrollPage(
            title: context.t.menuFlashcards,
            titleSize: 16.5,
            trailing: state.shares == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeaderRoundButton(
                        key: const ValueKey('deck-explore'),
                        icon: CupertinoIcons.globe,
                        iconSize: 22,
                        label: context.t.communityTitle,
                        onTap: () => go<void>(
                          context,
                          CommunityScreen(
                            onOpenDeck: (c, deck) =>
                                go<void>(c, DeckScreen(deck: deck)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      HeaderRoundButton(
                        key: const ValueKey('deck-import'),
                        icon: CupertinoIcons.tray_arrow_down,
                        iconSize: 22,
                        label: context.t.importDeck,
                        onTap: () => _import(context),
                      ),
                    ],
                  ),
            background: Palette.settingsPage,
            padding: const EdgeInsets.fromLTRB(24, 137, 24, 120),
            child: state.decks.isEmpty
                ? SizedBox(
                    height: 500,
                    child: EmptyView(
                      title: context.t.noDecks,
                      subtitle: context.t.noDecksBody,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, c) => Wrap(
                      spacing: 15,
                      runSpacing: 20,
                      children: [
                        for (final deck in state.decks)
                          SizedBox(
                            width: (c.maxWidth - 15) / 2,
                            child: _DeckCard(deck: deck),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 66,
          child: Semantics(
            label: context.t.addDeck,
            child: Tooltip(
              message: context.t.addDeck,
              triggerMode: TooltipTriggerMode.manual,
              child: PressFade(
                onTap: () async {
                  final deck = await deckForm(context);
                  if (deck != null && context.mounted) {
                    await go<void>(context, DeckScreen(deck: deck));
                  }
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Palette.deckFab,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: D.ink.withValues(alpha: .18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 34,
                    color: Colors.white,
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

class _DeckCard extends StatelessWidget {
  final Deck deck;
  const _DeckCard({required this.deck});
  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey('deck-${deck.id}'),
    onTap: () => go<void>(context, DeckScreen(deck: deck)),
    child: Container(
      height: 128,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        shadows: [
          BoxShadow(
            color: D.ink.withValues(alpha: .025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Palette.settingsPage,
                  shape: BoxShape.circle,
                ),
                child: Icon(deckIcon(deck), size: 22, color: D.ink),
              ),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Palette.settingsPanel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '${deck.words.length}',
                      style: D.text(
                        12,
                        weight: FontWeight.w500,
                        color: Palette.settingsMuted,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      CupertinoIcons.rectangle_stack_fill,
                      size: 14,
                      color: Palette.settingsHint,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          Text(
            deck.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: D.text(13.3, weight: FontWeight.w700, height: 20 / 13.3),
          ),
          const SizedBox(height: 2),
          Text(
            deck.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: D.text(10.2, color: Palette.settingsHint, height: 16 / 10.2),
          ),
        ],
      ),
    ),
  );
}

/// New Deck, or Add Cards when [deck] is given. Returns a deck made empty
/// for the learner to fill.
Future<Deck?> deckForm(BuildContext context, {Deck? deck}) =>
    showModalBottomSheet<Deck>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Palette.sheetBarrier,
      elevation: 0,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          9,
          0,
          9,
          9 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: _DeckForm(
          deck: deck,
          onAdded: (count) => toast(context, context.t.addedSampleWords(count)),
        ),
      ),
    );

class _DeckForm extends StatefulWidget {
  final Deck? deck;
  final ValueChanged<int> onAdded;
  const _DeckForm({required this.deck, required this.onAdded});
  @override
  State<_DeckForm> createState() => _DeckFormState();
}

class _DeckFormState extends State<_DeckForm> {
  static const maxCards = 100;
  // Owned by this state because the sheet still builds while it animates closed.
  late final title = TextEditingController(text: widget.deck?.title ?? '');
  int count = 10;
  bool generating = false;

  /// The new deck's icon, by its number in [deckIcons].
  int icon = 0;

  int get remaining => maxCards - (widget.deck?.words.length ?? 0);

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  /// Makes an empty deck with the name and icon chosen, to fill by hand.
  void _create() {
    final name = title.text.trim();
    if (name.isEmpty) return;
    final state = AppScope.read(context);
    final deck = Deck(
      id: state.newId(),
      title: name,
      description: context.t.deckMine,
      icon: icon,
      words: [],
    );
    state.addDeck(deck);
    Navigator.pop(context, deck);
  }

  Future<void> _pickIcon() async {
    final picked = await sheet<int>(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Builder(
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(ctx.t.deckIcon, style: D.text(20, weight: FontWeight.w800)),
              const SizedBox(height: 14),
              DeckIconGrid(
                selected: icon,
                onPick: (i) => Navigator.of(ctx).pop(i),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => icon = picked);
  }

  /// Asks [DeckGenerator] for words, then saves them. A failure keeps the
  /// sheet open so the learner can try again.
  Future<void> generate() async {
    setState(() => generating = true);
    final state = AppScope.read(context);
    final deck = widget.deck;
    try {
      final words = await state.deckGenerator.generate(
        language: state.language,
        topic: title.text.trim(),
        count: count,
        exclude: deck?.words ?? const [],
      );
      if (!mounted) return;
      if (deck == null) {
        state.addDeck(
          Deck(
            id: state.newId(),
            title: title.text.trim(),
            description: context.t.sampleDeckDescription,
            icon: icon,
            words: words,
          ),
        );
      } else {
        state.addWords(deck, words);
      }
      Navigator.pop(context);
      widget.onAdded(words.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => generating = false);
      toast(context, context.t.cardsFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.deck != null;
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(38),
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(23, 10, 23, 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Palette.ctaDisabled,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              SizedBox(
                height: 30,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      locked ? context.t.addCards : context.t.newDeck,
                      style: D.text(
                        15,
                        weight: FontWeight.w700,
                        height: 20 / 15,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        label: context.t.close,
                        child: PressFade(
                          key: const ValueKey('deck-form-close'),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Palette.settingsPanel,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 19,
                              color: Palette.settingsMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                context.t.topicNameCaps,
                style: D.text(
                  10.5,
                  weight: FontWeight.w600,
                  color: Palette.settingsHint,
                  spacing: .6,
                  height: 13 / 10.5,
                ),
              ),
              const SizedBox(height: 7),
              TextField(
                key: const ValueKey('deck-topic'),
                controller: title,
                readOnly: locked,
                onChanged: (_) => setState(() {}),
                style: D.text(
                  14.7,
                  weight: locked ? FontWeight.w600 : FontWeight.w400,
                  height: 20 / 14.7,
                ),
                decoration: InputDecoration(
                  hintText: context.t.topicNameHint,
                  hintStyle: D.text(
                    15,
                    color: Palette.settingsHint,
                    height: 20 / 15,
                  ),
                  filled: true,
                  fillColor: locked
                      ? Palette.settingsPanel
                      : Palette.settingsPage,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 16,
                  ),
                  // A new deck's icon, tapped to choose another.
                  prefixIcon: locked
                      ? null
                      : PressFade(
                          key: const ValueKey('deck-form-icon'),
                          onTap: _pickIcon,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 4),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                deckIcons[icon],
                                size: 18,
                                color: D.ink,
                              ),
                            ),
                          ),
                        ),
                  prefixIconConstraints: const BoxConstraints(),
                  suffixIcon: locked
                      ? const Icon(
                          CupertinoIcons.lock_fill,
                          size: 15,
                          color: Palette.settingsHint,
                        )
                      : null,
                  enabledBorder: _border(locked),
                  focusedBorder: _border(locked),
                ),
              ),
              if (!locked) ...[
                const SizedBox(height: 14),
                ActionButton(
                  context.t.deckCreate,
                  key: const ValueKey('deck-create'),
                  onTap: title.text.trim().isEmpty ? null : _create,
                ),
                const SizedBox(height: 22),
                Text(
                  context.t.deckOrAi,
                  textAlign: TextAlign.center,
                  style: D.text(
                    12.5,
                    weight: FontWeight.w600,
                    color: Palette.settingsHint,
                  ),
                ),
                const SizedBox(height: 4),
              ] else
                const SizedBox(height: 21),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$count',
                    key: const ValueKey('deck-word-count'),
                    style: D.text(
                      45,
                      weight: FontWeight.w800,
                      spacing: -1,
                      height: 60 / 45,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.t.wordsUnit,
                    style: D.text(
                      17,
                      weight: FontWeight.w500,
                      color: Palette.settingsHint,
                      height: 22 / 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 62,
                child: OverflowBox(
                  maxWidth: MediaQuery.sizeOf(context).width - 18,
                  child: _Ruler(
                    value: count,
                    max: remaining.clamp(5, maxCards),
                    onChanged: (v) => setState(() => count = v),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Center(
                child: Text(
                  context.t.wordsToGenerateCaps,
                  style: D.text(
                    10.5,
                    weight: FontWeight.w600,
                    color: Palette.settingsHint,
                    spacing: .9,
                    height: 13 / 10.5,
                  ),
                ),
              ),
              if (locked) ...[
                const SizedBox(height: 9),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6.5,
                    ),
                    decoration: BoxDecoration(
                      color: Palette.slotFill,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      context.t.slotsLeft(remaining),
                      style: D.text(
                        12,
                        weight: FontWeight.w600,
                        color: Palette.slotInk,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 32),
              // Words come from samples, not AI yet, so generating is shown as
              // coming soon.
              Semantics(
                key: const ValueKey('deck-generate'),
                label: '${context.t.generateDeck}, ${context.t.comingSoon}',
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Palette.generateOff,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.t.generateDeck,
                        style: D.text(
                          14.5,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const SoonBadge(light: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(bool locked) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: locked
        ? BorderSide.none
        : const BorderSide(color: Palette.settingsPanel),
  );
}

/// The horizontal word-count ruler, measured at 7.7 pt per word with the marker
/// fixed in the middle. Values run from 5, and the track scrolls under the marker.
class _Ruler extends StatefulWidget {
  static const step = 7.7, min = 5;
  final int value, max;
  final ValueChanged<int> onChanged;
  const _Ruler({
    required this.value,
    required this.max,
    required this.onChanged,
  });
  @override
  State<_Ruler> createState() => _RulerState();
}

class _RulerState extends State<_Ruler> {
  late final _scroll = ScrollController(
    initialScrollOffset: (widget.value - _Ruler.min) * _Ruler.step,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    final v = (n.metrics.pixels / _Ruler.step).round() + _Ruler.min;
    final clamped = v.clamp(_Ruler.min, widget.max);
    if (clamped != widget.value) widget.onChanged(clamped);
    return false;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 62,
    child: LayoutBuilder(
      builder: (context, c) {
        final half = c.maxWidth / 2;
        final span = (widget.max - _Ruler.min) * _Ruler.step;
        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: SingleChildScrollView(
                key: const ValueKey('deck-ruler'),
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const HomeScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: half),
                child: CustomPaint(
                  size: Size(span, 62),
                  painter: _RulerPainter(widget.max),
                ),
              ),
            ),
            Positioned(
              left: half - 1.25,
              top: 0,
              child: IgnorePointer(
                child: Container(
                  width: 2.5,
                  height: 38,
                  decoration: BoxDecoration(
                    color: D.ink,
                    borderRadius: BorderRadius.circular(1.25),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _RulerPainter extends CustomPainter {
  final int max;
  const _RulerPainter(this.max);
  @override
  void paint(Canvas canvas, Size size) {
    final major = Paint()
      ..color = Palette.settingsHint
      ..strokeWidth = 1;
    final minor = Paint()
      ..color = Palette.ctaDisabled
      ..strokeWidth = 1;
    for (var v = _Ruler.min; v <= max; v++) {
      final x = (v - _Ruler.min) * _Ruler.step;
      final big = v % 5 == 0;
      canvas.drawLine(
        Offset(x, big ? 19 : 29),
        Offset(x, 38),
        big ? major : minor,
      );
      if (!big) continue;
      final text = TextPainter(
        text: TextSpan(
          text: '$v',
          style: D.text(
            12,
            color: Palette.settingsHint,
            weight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(x - text.width / 2, 43));
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(_RulerPainter oldDelegate) => max != oldDelegate.max;
}
