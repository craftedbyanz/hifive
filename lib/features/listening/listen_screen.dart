import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/design/design.dart';
import '../../domain/vocab/vocab.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

/// Builds the video player for a playlist. Tests pass a stand-in, since the
/// real player needs a web view.
typedef PlayerBuilder = Widget Function(ListeningSource source);

/// One listening source: the playlist in YouTube's own player, and a way to
/// save words heard into the learner's saved words.
class ListenScreen extends StatelessWidget {
  final ListeningSource source;
  final PlayerBuilder player;
  const ListenScreen({
    super.key,
    required this.source,
    this.player = youtubePlaylist,
  });

  static Widget youtubePlaylist(ListeningSource source) =>
      _PlaylistPlayer(source: source);

  Future<void> _saveWord(BuildContext context) async {
    final saved = await sheet<String>(context, const _SaveWordSheet());
    if (saved != null && context.mounted) {
      toast(context, context.t.listenSaved(saved));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppPage(
      title: t.listenTitle,
      child: ListView(
        key: const ValueKey('listen-detail'),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: player(source),
          ),
          const SizedBox(height: 16),
          Text(source.title, style: D.text(20, weight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(
            t.listenPlaylist(source.channel),
            style: D.text(13, weight: FontWeight.w600, color: D.muted),
          ),
          const SizedBox(height: 16),
          PressFade(
            key: const ValueKey('listen-save-word'),
            onTap: () => _saveWord(context),
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.menuFocus,
                borderRadius: BorderRadius.circular(27),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.bookmark_fill,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.listenSaveWord,
                    style: D.text(
                      15.5,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: D.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.lightbulb_fill,
                  size: 18,
                  color: Palette.menuPlus,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.listenTip,
                    style: D.text(13.5, weight: FontWeight.w500, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          if (source.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              source.description,
              style: D.text(
                14,
                weight: FontWeight.w500,
                color: D.secondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// YouTube's own player, loaded with the source's playlist.
class _PlaylistPlayer extends StatefulWidget {
  final ListeningSource source;
  const _PlaylistPlayer({required this.source});

  @override
  State<_PlaylistPlayer> createState() => _PlaylistPlayerState();
}

class _PlaylistPlayerState extends State<_PlaylistPlayer> {
  late final _controller = YoutubePlayerController(
    params: const YoutubePlayerParams(
      showFullscreenButton: true,
      strictRelatedVideos: true,
    ),
  )..cuePlaylist(list: [widget.source.playlistId], listType: ListType.playlist);

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      YoutubePlayer(controller: _controller, backgroundColor: Colors.black);
}

/// A word and its meaning, saved like a dictionary word.
class _SaveWordSheet extends StatefulWidget {
  const _SaveWordSheet();

  @override
  State<_SaveWordSheet> createState() => _SaveWordSheetState();
}

class _SaveWordSheetState extends State<_SaveWordSheet> {
  final _word = TextEditingController(), _meaning = TextEditingController();

  @override
  void dispose() {
    _word.dispose();
    _meaning.dispose();
    super.dispose();
  }

  void _save() {
    final word = _word.text.trim(), meaning = _meaning.text.trim();
    if (word.isEmpty || meaning.isEmpty) return;
    AppScope.read(context).saveWord(word, meaning);
    Navigator.of(context).pop(word);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    InputDecoration field(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: D.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: D.line),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.listenSaveWord, style: D.text(18, weight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('listen-word'),
            controller: _word,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: field(t.listenWord),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('listen-meaning'),
            controller: _meaning,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: field(t.listenMeaning),
          ),
          const SizedBox(height: 16),
          PressFade(
            key: const ValueKey('listen-save'),
            onTap: _save,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.menuFocus,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                t.listenSave,
                style: D.text(
                  15.5,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
