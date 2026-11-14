import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/community/community.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'share_errors.dart';

/// Adds a deck someone shared: the learner types or pastes its code or link,
/// sees its title and first words, and copies it into their own decks. The
/// sheet returns the new deck.
class ImportDeckSheet extends StatefulWidget {
  /// A code or link to open at once, as from a shared link.
  final String initial;

  /// The public deck this was opened for from Explore: adding it counts for
  /// its owner, and it can be reported or its owner blocked.
  final PublicDeck? listed;
  const ImportDeckSheet({super.key, this.initial = '', this.listed});

  /// Opens [deck] from Explore.
  factory ImportDeckSheet.listed(PublicDeck deck, {Key? key}) =>
      ImportDeckSheet(key: key, initial: deck.code, listed: deck);

  @override
  State<ImportDeckSheet> createState() => _ImportDeckSheetState();
}

class _ImportDeckSheetState extends State<ImportDeckSheet> {
  late final AppState _state = AppScope.read(context);
  late final _input = TextEditingController(text: widget.initial);
  Future<SharedDeck>? _deck;
  String? _problem;

  @override
  void initState() {
    super.initState();
    // Opened with a code, as from Explore: load it at once. A bad code
    // falls through to the input, where it can be fixed.
    if (shareCodeIn(widget.initial) case final code?) {
      _deck = _state.openSharedDeck(code)..ignore();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _open() {
    final code = shareCodeIn(_input.text);
    FocusScope.of(context).unfocus();
    setState(() {
      _problem = code == null ? context.t.importBadCode : null;
      // Marked handled at once; the preview below still shows the error.
      _deck = code == null ? null : (_state.openSharedDeck(code)..ignore());
    });
  }

  void _add(SharedDeck shared) {
    final deck = widget.listed == null
        ? _state.addSharedDeck(shared)
        : _state.addPublicDeck(shared);
    _state.feedback.success();
    Navigator.of(context).pop(deck);
  }

  Future<void> _report() async {
    final t = context.t;
    final reason = await sheet<ReportReason>(context, const _ReportReasons());
    if (reason == null || !mounted) return;
    try {
      await _state.reportDeck(widget.listed!.code, reason);
      if (!mounted) return;
      Navigator.of(context).pop();
      toast(context, t.reportDone);
    } on Object catch (e) {
      if (mounted) toast(context, shareErrorText(t, e));
    }
  }

  Future<void> _block() async {
    final t = context.t;
    final listed = widget.listed!;
    final yes = await confirm(
      context,
      t.blockTitle(
        listed.author.isEmpty ? t.exploreAuthorUnknown : listed.author,
      ),
      t.blockBody,
      action: t.blockOwner,
      cancel: t.cancel,
      destructive: true,
    );
    if (!yes || !mounted) return;
    try {
      await _state.blockOwnerOf(listed.code);
      if (!mounted) return;
      Navigator.of(context).pop();
      toast(context, t.blockDone);
    } on Object catch (e) {
      if (mounted) toast(context, shareErrorText(t, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final listed = widget.listed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (listed != null)
            Text(t.exploreTitle, style: D.text(20, weight: FontWeight.w800))
          else ...[
            Text(t.importTitle, style: D.text(20, weight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('import-code'),
                    controller: _input,
                    autofocus: widget.initial.isEmpty,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _open(),
                    style: D.text(16, weight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: t.importHint,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PressFade(
                  key: const ValueKey('import-open'),
                  onTap: _open,
                  child: Tooltip(
                    message: t.importOpen,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: D.ink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_right,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_problem case final p?)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  p,
                  key: const ValueKey('import-problem'),
                  style: D.text(13, color: Palette.wrong),
                ),
              ),
          ],
          if (_deck case final future?)
            FutureBuilder<SharedDeck>(
              future: future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      shareErrorText(t, snap.error!),
                      key: const ValueKey('import-problem'),
                      style: D.text(13.5, color: D.secondary, height: 1.45),
                    ),
                  );
                }
                final deck = snap.data;
                if (deck == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: CupertinoActivityIndicator(),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Preview(deck: deck, onAdd: () => _add(deck)),
                    if (listed != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            key: const ValueKey('explore-report'),
                            onPressed: _report,
                            icon: const Icon(
                              CupertinoIcons.flag,
                              size: 15,
                              color: D.secondary,
                            ),
                            label: Text(
                              t.reportDeck,
                              style: D.text(
                                13.5,
                                weight: FontWeight.w700,
                                color: D.secondary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            key: const ValueKey('explore-block'),
                            onPressed: _block,
                            icon: const Icon(
                              CupertinoIcons.nosign,
                              size: 15,
                              color: D.secondary,
                            ),
                            label: Text(
                              t.blockOwner,
                              style: D.text(
                                13.5,
                                weight: FontWeight.w700,
                                color: D.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final SharedDeck deck;
  final VoidCallback onAdd;
  const _Preview({required this.deck, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final shown = deck.words.take(5).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const ValueKey('import-preview'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: D.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: D.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.importWordCount(deck.words.length).toUpperCase(),
                  style: D.text(
                    11.5,
                    weight: FontWeight.w800,
                    color: D.secondary,
                    spacing: .5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(deck.title, style: D.text(18, weight: FontWeight.w800)),
                if (deck.description.isNotEmpty)
                  Text(
                    deck.description,
                    style: D.text(13, color: D.secondary, height: 1.4),
                  ),
                const SizedBox(height: 8),
                for (final w in shown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            w.word,
                            style: D.text(14.5, weight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            w.meaning,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: D.text(13.5, color: D.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (deck.words.length > shown.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      t.importMore(deck.words.length - shown.length),
                      style: D.text(12.5, color: D.muted),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ActionButton(
            t.importAdd,
            key: const ValueKey('import-add'),
            icon: CupertinoIcons.plus,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

/// The reasons to report a public deck; returns the one chosen.
class _ReportReasons extends StatelessWidget {
  const _ReportReasons();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.reportTitle, style: D.text(20, weight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final (reason, label) in [
            (ReportReason.offensive, t.reportOffensive),
            (ReportReason.spam, t.reportSpam),
            (ReportReason.wrong, t.reportWrong),
            (ReportReason.copyright, t.reportCopyright),
            (ReportReason.other, t.reportOther),
          ])
            PressFade(
              key: ValueKey('report-${reason.name}'),
              onTap: () => Navigator.of(context).pop(reason),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: D.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: D.text(15, weight: FontWeight.w600),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 15,
                      color: D.muted,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
