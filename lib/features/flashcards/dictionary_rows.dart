part of 'dictionary_screen.dart';

enum _AddState { add, added, inDeck }

/// The note under a result that is a link rather than the word itself.
String? dictNote(AppLocalizations t, DictHit hit) => switch (hit.match) {
  DictMatch.form => switch (hit.formLabel) {
    'past' => t.dictFormPast(hit.entry.word),
    'pastParticiple' => t.dictFormPastParticiple(hit.entry.word),
    'ing' => t.dictFormIng(hit.entry.word),
    'plural' => t.dictFormPlural(hit.entry.word),
    'comparative' => t.dictFormComparative(hit.entry.word),
    'superlative' => t.dictFormSuperlative(hit.entry.word),
    'thirdPerson' => t.dictFormThird(hit.entry.word),
    _ => t.dictFormOther(hit.entry.word),
  },
  DictMatch.variant => t.dictSpellingOf,
  DictMatch.contraction => t.dictContraction(hit.entry.word, hit.expansion),
  _ => null,
};

/// A sense label's name (`slang` → "tiếng lóng").
String dictLabel(AppLocalizations t, String code) => switch (code) {
  'slang' => t.dictLabelSlang,
  'informal' => t.dictLabelInformal,
  'figurative' => t.dictLabelFigurative,
  'us' => t.dictLabelUs,
  'uk' => t.dictLabelUk,
  'literary' => t.dictLabelLiterary,
  'humorous' => t.dictLabelHumorous,
  'formal' => t.dictLabelFormal,
  _ => code,
};

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSubmitted;
  const _SearchField({
    required this.controller,
    required this.focus,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: D.line),
    ),
    child: Row(
      children: [
        const SizedBox(width: 18),
        const Icon(CupertinoIcons.search, size: 21, color: D.ink),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            key: const ValueKey('dict-search-field'),
            controller: controller,
            focusNode: focus,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSubmitted(),
            style: D.text(17),
            decoration: InputDecoration(
              isCollapsed: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: context.t.dictSearchHint,
              hintStyle: D.text(17, color: D.muted),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? const SizedBox(width: 16)
              : Semantics(
                  button: true,
                  label: context.t.dictClear,
                  child: PressFade(
                    key: const ValueKey('dict-clear'),
                    onTap: () {
                      controller.clear();
                      focus.requestFocus();
                    },
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 20,
                        color: D.ink,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  final bool downloading;
  const _Notice({required this.downloading});

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('dict-notice'),
    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
    child: Row(
      children: [
        if (downloading)
          const CupertinoActivityIndicator(radius: 7)
        else
          const Icon(CupertinoIcons.wifi_slash, size: 15, color: D.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            downloading ? context.t.dictDownloading : context.t.dictOffline,
            style: D.text(12.5, color: D.secondary),
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
    child: CapsLabel(text.toUpperCase()),
  );
}

class _Message extends StatelessWidget {
  final String title, body;
  const _Message({required this.title, this.body = ''});
  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('dict-message'),
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
    child: Column(
      children: [
        const Icon(CupertinoIcons.search, size: 40, color: D.muted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: D.text(17, weight: FontWeight.w700),
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: D.text(14, color: D.secondary),
          ),
        ],
      ],
    ),
  );
}

/// The empty search: recent lookups, then words at the learner's level.
class _Start extends StatelessWidget {
  final List<String> recent;
  final Future<List<DictEntry>>? toLearn;
  final String level;
  final ValueChanged<String> onLookUp;
  final VoidCallback onClear, onManual;
  final Widget Function(DictEntry) rowFor;
  const _Start({
    required this.recent,
    required this.toLearn,
    required this.level,
    required this.onLookUp,
    required this.onClear,
    required this.onManual,
    required this.rowFor,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: _SectionLabel(t.dictRecent)),
              Semantics(
                button: true,
                label: t.dictClearRecent,
                child: PressFade(
                  key: const ValueKey('dict-clear-recent'),
                  onTap: onClear,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 15,
                      color: D.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in recent)
                PressFade(
                  key: ValueKey('dict-recent-$w'),
                  onTap: () => onLookUp(w),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: D.line),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        w,
                        style: D.text(15, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        FutureBuilder<List<DictEntry>>(
          future: toLearn,
          builder: (context, snap) {
            final words = snap.data ?? const [];
            if (words.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(t.dictForYou(level)),
                for (final e in words) rowFor(e),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        _ManualRow(label: t.dictManualPlain, onTap: onManual),
        const _KeyboardSpace(),
      ],
    );
  }
}

/// One result: word, IPA, part of speech, level, meanings or a link note,
/// and the speak and add buttons. Tapping it opens the entry.
class _ResultRow extends StatelessWidget {
  final DictHit hit;
  final bool featured, american;
  final String deckName;
  final String? learningIn;
  final _AddState addState;
  final VoidCallback onTap, onAdd, onUndo, onSpeak;
  const _ResultRow({
    super.key,
    required this.hit,
    required this.featured,
    required this.american,
    required this.deckName,
    required this.addState,
    required this.learningIn,
    required this.onTap,
    required this.onAdd,
    required this.onUndo,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final e = hit.entry;
    final note = dictNote(t, hit);
    final ipa = e.ipa(american: american);
    final meanings = e.needsMeaning
        ? [t.dictNeedsMeaning]
        : [for (final s in e.senses.take(featured ? 3 : 1)) s.meaning];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Surface(
        radius: 22,
        shadow: featured,
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        e.word,
                        style: D.text(
                          featured ? 21 : 17,
                          weight: FontWeight.w800,
                        ),
                      ),
                      if (ipa.isNotEmpty)
                        Text(ipa, style: D.text(13.5, color: D.secondary)),
                      Text(
                        e.partOfSpeech,
                        style: D.text(
                          10.5,
                          weight: FontWeight.w700,
                          color: D.muted,
                          spacing: .4,
                        ),
                      ),
                      if (e.level case final level?) _LevelChip(level),
                    ],
                  ),
                  if (note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        note,
                        style: D.text(
                          13,
                          weight: FontWeight.w600,
                          color: D.blue,
                        ),
                      ),
                    ),
                  const SizedBox(height: 3),
                  for (final m in meanings)
                    Text(
                      m,
                      maxLines: featured ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: D.text(
                        15,
                        color: e.needsMeaning ? D.muted : D.ink,
                      ),
                    ),
                  if (e.needsMeaning && e.definition.isNotEmpty)
                    Text(
                      e.definition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: D.text(13, color: D.secondary),
                    ),
                  if (learningIn case final deck?)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        t.dictLearningIn(deck),
                        style: D.text(12.5, color: D.green),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconButton(
                  icon: CupertinoIcons.speaker_2_fill,
                  label: t.dictSpeak,
                  keyName: 'dict-speak-${e.id}',
                  onTap: onSpeak,
                ),
                _AddButton(
                  entry: e,
                  state: addState,
                  deckName: deckName,
                  onAdd: onAdd,
                  onUndo: onUndo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String level;
  const _LevelChip(this.level);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
    decoration: BoxDecoration(
      color: Palette.newPill,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      level,
      style: D.text(11, weight: FontWeight.w700, color: Palette.newPillInk),
    ),
  );
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String label, keyName;
  final VoidCallback onTap;
  const _IconButton({
    required this.icon,
    required this.label,
    required this.keyName,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.manual,
      child: PressFade(
        key: ValueKey(keyName),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 19, color: D.secondary),
        ),
      ),
    ),
  );
}

class _AddButton extends StatelessWidget {
  final DictEntry entry;
  final _AddState state;
  final String deckName;
  final VoidCallback onAdd, onUndo;
  const _AddButton({
    required this.entry,
    required this.state,
    required this.deckName,
    required this.onAdd,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (icon, color, fill, label, tap) = switch (state) {
      _AddState.add => (
        entry.needsMeaning ? CupertinoIcons.pencil : CupertinoIcons.plus,
        Colors.white,
        D.ink,
        entry.needsMeaning
            ? t.dictAddMeaning
            : t.dictAddWord(entry.word, deckName),
        onAdd,
      ),
      _AddState.added => (
        CupertinoIcons.checkmark,
        Colors.white,
        D.green,
        t.dictUndoWord(entry.word, deckName),
        onUndo,
      ),
      _AddState.inDeck => (
        CupertinoIcons.checkmark,
        D.muted,
        Palette.settingsPage,
        t.dictInDeck,
        null,
      ),
    };
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        triggerMode: TooltipTriggerMode.manual,
        child: PressFade(
          key: ValueKey('dict-add-${entry.id}'),
          onTap: tap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                child: Icon(icon, size: 17, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ManualRow({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => PressFade(
    key: const ValueKey('dict-manual'),
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: D.line),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.pencil, size: 18, color: D.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: D.text(15, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Room at the end of a list for the keyboard, so the last rows can scroll
/// above it. Only this rebuilds as the keyboard moves.
class _KeyboardSpace extends StatelessWidget {
  const _KeyboardSpace();
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: MediaQuery.viewInsetsOf(context).bottom);
}
