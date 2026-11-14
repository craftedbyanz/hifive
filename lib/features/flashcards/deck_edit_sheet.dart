import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

/// The icons a deck can have, by the number it stores. Only append: decks
/// keep their number. 0 and 1 are the icons decks had first.
const deckIcons = <IconData>[
  CupertinoIcons.briefcase_fill,
  Icons.restaurant_rounded,
  CupertinoIcons.airplane,
  CupertinoIcons.house_fill,
  CupertinoIcons.heart_fill,
  CupertinoIcons.book_fill,
  CupertinoIcons.bookmark_fill,
  CupertinoIcons.chat_bubble_2_fill,
  CupertinoIcons.music_note_2,
  CupertinoIcons.sportscourt_fill,
  CupertinoIcons.cart_fill,
  CupertinoIcons.desktopcomputer,
  CupertinoIcons.tree,
  Icons.pets_rounded,
  CupertinoIcons.person_2_fill,
  CupertinoIcons.lightbulb_fill,
  CupertinoIcons.star_fill,
  CupertinoIcons.globe,
  CupertinoIcons.film_fill,
  Icons.local_hospital_rounded,
  CupertinoIcons.money_dollar_circle_fill,
  CupertinoIcons.car_fill,
  CupertinoIcons.sun_max_fill,
  CupertinoIcons.gamecontroller_fill,
];

/// A deck's icon. Saved words show a bookmark until given another.
IconData deckIcon(Deck deck) => deck.id == 'saved' && deck.icon == 0
    ? CupertinoIcons.bookmark_fill
    : deckIcons[deck.icon.clamp(0, deckIcons.length - 1)];

/// Every deck icon to choose from, the [selected] one marked.
class DeckIconGrid extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onPick;
  const DeckIconGrid({super.key, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final (i, icon) in deckIcons.indexed)
        PressFade(
          key: ValueKey('deck-icon-$i'),
          onTap: () => onPick(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: i == selected ? D.ink : Palette.settingsPage,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 21,
              color: i == selected ? Colors.white : D.ink,
            ),
          ),
        ),
    ],
  );
}

/// Changes a deck's name, description and icon.
class EditDeckSheet extends StatefulWidget {
  final Deck deck;
  const EditDeckSheet({super.key, required this.deck});

  @override
  State<EditDeckSheet> createState() => _EditDeckSheetState();
}

class _EditDeckSheetState extends State<EditDeckSheet> {
  late final _title = TextEditingController(text: widget.deck.title);
  late final _description = TextEditingController(
    text: widget.deck.description,
  );
  late int _icon = deckIcons.indexOf(deckIcon(widget.deck));

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;
    AppScope.read(context).editDeck(
      widget.deck,
      title: _title.text,
      description: _description.text,
      icon: _icon,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.editDeck, style: D.text(20, weight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: ShapeDecoration(
                  color: Palette.previewDefault,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Icon(deckIcons[_icon], size: 30, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const ValueKey('deck-edit-title'),
                  controller: _title,
                  maxLength: 60,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _save(),
                  style: D.text(16, weight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: t.deckName,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('deck-edit-description'),
            controller: _description,
            maxLength: 120,
            maxLines: 2,
            minLines: 1,
            style: D.text(14.5),
            decoration: InputDecoration(
              hintText: t.deckDescription,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            t.deckIcon,
            style: D.text(13, weight: FontWeight.w700, color: D.secondary),
          ),
          const SizedBox(height: 10),
          DeckIconGrid(
            selected: _icon,
            onPick: (i) => setState(() => _icon = i),
          ),
          const SizedBox(height: 20),
          ActionButton(
            t.save,
            key: const ValueKey('deck-edit-save'),
            onTap: _title.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }
}

/// Adds the learner's own words to [deck], one after another: the word, its
/// meaning and, if they like, an example. The sheet stays open for the next.
class AddWordSheet extends StatefulWidget {
  final Deck deck;
  const AddWordSheet({super.key, required this.deck});

  @override
  State<AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends State<AddWordSheet> {
  final _word = TextEditingController(),
      _meaning = TextEditingController(),
      _example = TextEditingController();
  final _wordFocus = FocusNode();
  var _added = 0;
  String? _problem;

  @override
  void dispose() {
    _word.dispose();
    _meaning.dispose();
    _example.dispose();
    _wordFocus.dispose();
    super.dispose();
  }

  bool get _ready =>
      _word.text.trim().isNotEmpty && _meaning.text.trim().isNotEmpty;

  void _add() {
    if (!_ready) return;
    final state = AppScope.read(context);
    final word = _word.text.trim();
    if (widget.deck.words.any(
      (w) => w.word.toLowerCase() == word.toLowerCase(),
    )) {
      setState(() => _problem = context.t.addWordExists);
      return;
    }
    state.addWords(widget.deck, [
      FlashWord(
        id: state.newId(),
        word: word,
        meaning: _meaning.text.trim(),
        example: _example.text.trim(),
      ),
    ]);
    state.feedback.tap();
    _word.clear();
    _meaning.clear();
    _example.clear();
    setState(() {
      _added++;
      _problem = null;
    });
    _wordFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    InputDecoration field(String hint) => InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.addWordTitle,
                  style: D.text(20, weight: FontWeight.w800),
                ),
              ),
              if (_added > 0)
                Text(
                  t.addWordAdded(_added),
                  key: const ValueKey('add-word-count'),
                  style: D.text(13, weight: FontWeight.w700, color: D.green),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('add-word-word'),
            controller: _word,
            focusNode: _wordFocus,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _problem = null),
            decoration: field(t.addWordWord),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('add-word-meaning'),
            controller: _meaning,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: field(t.addWordMeaning),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('add-word-example'),
            controller: _example,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            decoration: field(t.addWordExample),
          ),
          if (_problem case final p?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(p, style: D.text(13, color: Palette.wrong)),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  t.addWordDone,
                  key: const ValueKey('add-word-done'),
                  outlined: true,
                  color: D.ink,
                  foreground: D.ink,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionButton(
                  t.addWordSave,
                  key: const ValueKey('add-word-save'),
                  icon: CupertinoIcons.plus,
                  onTap: _ready ? _add : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
