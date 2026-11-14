import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'share_errors.dart';

/// Shares a deck by link or code (Community, step 1). Opening it publishes
/// the deck's current words, so the shared copy is always up to date; it
/// then shows the code and link to copy or send, and a way to stop sharing.
class ShareDeckSheet extends StatefulWidget {
  final Deck deck;
  const ShareDeckSheet({super.key, required this.deck});

  @override
  State<ShareDeckSheet> createState() => _ShareDeckSheetState();
}

class _ShareDeckSheetState extends State<ShareDeckSheet> {
  late final AppState _state = AppScope.read(context);
  late Future<String> _code = _state.shareDeck(widget.deck)..ignore();

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _state.feedback.tap();
    if (mounted) toast(context, context.t.shareCopied);
  }

  /// Lists the deck in Explore or takes it off; the first time, the learner
  /// agrees to the community rules.
  Future<void> _setPublic(bool on) async {
    final t = context.t;
    if (on && !_state.communityRules) {
      final yes = await confirm(
        context,
        t.rulesTitle,
        t.rulesBody,
        action: t.rulesAccept,
        cancel: t.cancel,
      );
      if (!yes || !mounted) return;
      _state.acceptCommunityRules();
    }
    setState(() {
      _code = _state.shareDeck(widget.deck, public: on)..ignore();
    });
  }

  Future<void> _stop() async {
    final t = context.t;
    final yes = await confirm(
      context,
      t.shareStopTitle,
      t.shareStopBody,
      action: t.shareStop,
      cancel: t.cancel,
      destructive: true,
    );
    if (!yes || !mounted) return;
    try {
      await _state.unshareDeck(widget.deck);
      if (!mounted) return;
      Navigator.of(context).pop();
      toast(context, t.shareStopped);
    } on Object catch (e) {
      if (mounted) toast(context, shareErrorText(t, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: FutureBuilder<String>(
        future: _code,
        builder: (context, snap) {
          final code = snap.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.shareDeck, style: D.text(20, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                widget.deck.title,
                style: D.text(14, weight: FontWeight.w600, color: D.secondary),
              ),
              const SizedBox(height: 18),
              if (snap.hasError)
                _Failed(
                  text: shareErrorText(t, snap.error!),
                  onRetry: () => setState(() {
                    _code = _state.shareDeck(widget.deck)..ignore();
                  }),
                )
              else if (code == null)
                SizedBox(
                  height: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CupertinoActivityIndicator(),
                      const SizedBox(height: 10),
                      Text(
                        t.shareDeckSending,
                        style: D.text(13.5, color: D.secondary),
                      ),
                    ],
                  ),
                )
              else
                ..._ready(t, code),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _ready(AppLocalizations t, String code) {
    final link = _state.shares!.linkFor(code).toString();
    return [
      PressFade(
        key: const ValueKey('share-code'),
        onTap: () => _copy(code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Palette.storyTop,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Palette.storyBottom),
          ),
          child: Column(
            children: [
              Text(
                code,
                key: const ValueKey('share-code-text'),
                style: D.text(
                  36,
                  weight: FontWeight.w800,
                  color: Palette.focusInk,
                  spacing: 7,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.doc_on_doc,
                    size: 13,
                    color: D.secondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    t.shareCopy,
                    style: D.text(
                      12.5,
                      weight: FontWeight.w700,
                      color: D.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      PressFade(
        key: const ValueKey('share-link'),
        onTap: () => _copy(link),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: D.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: D.line),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.link, size: 16, color: D.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  link,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: D.text(13, weight: FontWeight.w600),
                ),
              ),
              const Icon(
                CupertinoIcons.doc_on_doc,
                size: 15,
                color: D.secondary,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _PublicSwitch(
        on: _state.publicDecks.contains(widget.deck.id),
        name: _state.name.trim(),
        onChanged: _setPublic,
      ),
      const SizedBox(height: 12),
      Text(
        '${t.shareDeckBody} ${t.shareDeckUpdated}',
        style: D.text(12.5, color: D.secondary, height: 1.45),
      ),
      const SizedBox(height: 18),
      ActionButton(
        t.shareSend,
        key: const ValueKey('share-send'),
        icon: CupertinoIcons.share,
        onTap: () => _state.system.shareText(
          t.shareMessage(widget.deck.title, link, code),
        ),
      ),
      const SizedBox(height: 4),
      Center(
        child: TextButton(
          key: const ValueKey('share-stop'),
          onPressed: _stop,
          child: Text(
            t.shareStop,
            style: D.text(14, weight: FontWeight.w700, color: Palette.wrong),
          ),
        ),
      ),
    ];
  }
}

/// Whether Explore lists the deck, with who it shows as.
class _PublicSwitch extends StatelessWidget {
  final bool on;
  final String name;
  final ValueChanged<bool> onChanged;
  const _PublicSwitch({
    required this.on,
    required this.name,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: D.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: D.line),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.globe, size: 18, color: D.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.sharePublic, style: D.text(14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  on
                      ? t.sharePublicOn(
                          name.isEmpty ? t.exploreAuthorUnknown : name,
                        )
                      : t.sharePublicOff,
                  style: D.text(12, color: D.secondary, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            key: const ValueKey('share-public'),
            value: on,
            activeTrackColor: D.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;
  const _Failed({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('share-error'),
    children: [
      Text(
        text,
        textAlign: TextAlign.center,
        style: D.text(14, color: D.secondary, height: 1.45),
      ),
      const SizedBox(height: 12),
      TextButton(
        key: const ValueKey('share-retry'),
        onPressed: onRetry,
        child: Text(
          context.t.retry,
          style: D.text(14.5, weight: FontWeight.w700, color: D.blue),
        ),
      ),
    ],
  );
}
