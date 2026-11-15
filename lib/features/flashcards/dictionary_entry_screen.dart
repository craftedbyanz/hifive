import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/dictionary/dictionary.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'dictionary_screen.dart';

/// One dictionary entry: every meaning to choose from (up to three go on
/// the card), the learner's own wording, the example and its sources.
/// Adding pops with the card; [deck] null means saved words.
class DictionaryEntryScreen extends StatefulWidget {
  final DictEntry entry;
  final Deck? deck;
  const DictionaryEntryScreen({super.key, required this.entry, this.deck});

  @override
  State<DictionaryEntryScreen> createState() => _DictionaryEntryScreenState();
}

class _DictionaryEntryScreenState extends State<DictionaryEntryScreen> {
  static const maxMeanings = 3;
  late final List<int> _picked = widget.entry.senses.isEmpty ? [] : [0];
  late final _meaning = TextEditingController(text: _joined);
  late bool _editing = widget.entry.needsMeaning;

  /// Whether the learner changed the wording, which then wins over ticks.
  var _edited = false;

  String get _joined => widget.entry.meaningOf(_picked..sort());

  @override
  void dispose() {
    _meaning.dispose();
    super.dispose();
  }

  void _toggle(int i) {
    setState(() {
      if (_picked.contains(i)) {
        if (_picked.length > 1) _picked.remove(i);
      } else if (_picked.length < maxMeanings) {
        _picked.add(i);
      }
      if (!_edited) _meaning.text = _joined;
    });
  }

  void _add() {
    final state = AppScope.read(context);
    final meaning = _meaning.text.trim();
    if (meaning.isEmpty) return;
    final card = state.addFromDictionary(
      widget.entry,
      deck: widget.deck,
      picked: _picked,
      meaning: _edited || widget.entry.needsMeaning ? meaning : null,
    );
    state.feedback.tap();
    Navigator.of(context).pop(card);
  }

  String _source(AppLocalizations t, DictEntry e) {
    final from = e.exampleSource;
    if (from.startsWith('tatoeba:')) {
      final authors = from
          .split(':')
          .skip(3)
          .where((a) => a.isNotEmpty)
          .toSet()
          .join(', ');
      return t.dictTatoebaBy(authors.isEmpty ? 'Tatoeba' : authors);
    }
    return from == 'hifive' ? 'hifive' : 'Wiktionary';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = AppScope.of(context);
    final e = widget.entry;
    final target =
        widget.deck ?? state.decks.where((d) => d.id == 'saved').firstOrNull;
    final holder = state.deckWith(e.word, deck: target);
    final inDeck = holder != null && identical(holder, target);
    final ipa = e.ipa(american: state.americanVoice);
    return AppPage(
      title: e.word,
      background: Palette.settingsPage,
      trailing: RoundButton(
        key: const ValueKey('dict-entry-speak'),
        icon: CupertinoIcons.speaker_2_fill,
        label: t.dictSpeak,
        onTap: () => state.speak(e.word),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(e.word, style: D.text(28, weight: FontWeight.w800)),
              if (ipa.isNotEmpty)
                Text(ipa, style: D.text(16, color: D.secondary)),
              Text(
                e.partOfSpeech,
                style: D.text(12, weight: FontWeight.w700, color: D.muted),
              ),
              if (e.level case final level?)
                Text(
                  level,
                  style: D.text(
                    12,
                    weight: FontWeight.w700,
                    color: Palette.newPillInk,
                  ),
                ),
            ],
          ),
          if (holder != null && !inDeck)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                t.dictLearningIn(holder.title),
                style: D.text(13, color: D.green),
              ),
            ),
          const SizedBox(height: 18),
          if (e.senses.isNotEmpty) ...[
            CapsLabel(t.dictPickMeanings.toUpperCase()),
            const SizedBox(height: 8),
            Surface(
              radius: 22,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final (i, s) in e.senses.indexed)
                    _SenseRow(
                      key: ValueKey('dict-sense-$i'),
                      sense: s,
                      picked: _picked.contains(i),
                      onTap: () => _toggle(i),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (e.definition.isNotEmpty) ...[
            CapsLabel(t.dictDefinition.toUpperCase()),
            const SizedBox(height: 6),
            Text(e.definition, style: D.text(15, color: D.secondary)),
            const SizedBox(height: 14),
          ],
          if (_editing)
            TextField(
              key: const ValueKey('dict-meaning-field'),
              controller: _meaning,
              autofocus: e.needsMeaning,
              maxLines: 3,
              minLines: 1,
              onChanged: (_) => setState(() => _edited = true),
              decoration: InputDecoration(
                hintText: t.dictMeaningHint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: PressFade(
                key: const ValueKey('dict-edit-meaning'),
                onTap: () => setState(() => _editing = true),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.pencil,
                        size: 16,
                        color: D.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.dictEditMeaning,
                        style: D.text(
                          14,
                          weight: FontWeight.w600,
                          color: D.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (e.example.isNotEmpty) ...[
            const SizedBox(height: 16),
            CapsLabel(t.dictExample.toUpperCase()),
            const SizedBox(height: 8),
            Surface(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.example,
                          style: D.system(16, weight: FontWeight.w600),
                        ),
                        if (e.exampleMeaning.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              e.exampleMeaning,
                              style: D.system(15, color: D.secondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: t.dictSpeak,
                    child: PressFade(
                      key: const ValueKey('dict-example-speak'),
                      onTap: () => state.speak(e.example),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          CupertinoIcons.speaker_2_fill,
                          size: 18,
                          color: D.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            t.dictSource(
              {
                if (e.curated) 'hifive' else 'Wiktionary',
                if (e.example.isNotEmpty) _source(t, e),
              }.join(' · '),
            ),
            key: const ValueKey('dict-source'),
            style: D.text(12, color: D.muted),
          ),
          const SizedBox(height: 22),
          ListenableBuilder(
            listenable: _meaning,
            builder: (context, _) => ActionButton(
              inDeck
                  ? t.dictInDeck
                  : t.dictAddToDeck(target?.title ?? savedDeckTitle),
              key: const ValueKey('dict-entry-add'),
              icon: inDeck ? CupertinoIcons.checkmark : CupertinoIcons.plus,
              onTap: inDeck || _meaning.text.trim().isEmpty ? null : _add,
            ),
          ),
        ],
      ),
    );
  }
}

class _SenseRow extends StatelessWidget {
  final DictSense sense;
  final bool picked;
  final VoidCallback onTap;
  const _SenseRow({
    super.key,
    required this.sense,
    required this.picked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Semantics(
      checked: picked,
      child: PressFade(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(
                picked
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 22,
                color: picked ? D.ink : D.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sense.meaning, style: D.text(15.5)),
                    if (sense.labels.isNotEmpty)
                      Text(
                        sense.labels.map((l) => dictLabel(t, l)).join(' · '),
                        style: D.text(12, color: D.secondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
