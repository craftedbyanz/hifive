import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/listening/listening.dart';
import '../../domain/vocab/vocab.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'listen_player.dart';

part 'listen_parts.dart';

/// Makes the player for a [ListenScreen]; tests pass a stand-in.
typedef PlayerFactory = ListenPlayer Function();

/// One listening source: the episode playing on top, with controls made for
/// learners (back five seconds, a slower speed, saving a word heard), and
/// every episode below. It remembers where each episode stopped, plays the
/// next one when an episode ends, and counts the minutes heard.
///
/// A source without a list of episodes plays its playlist in YouTube's own
/// player instead.
class ListenScreen extends StatefulWidget {
  final ListeningSource source;

  /// The episode to open; null opens the one after the last heard.
  final int? index;

  /// Where to start it, in seconds; null resumes where it stopped.
  final int? start;
  final PlayerFactory player;
  const ListenScreen({
    super.key,
    required this.source,
    this.index,
    this.start,
    this.player = YouTubeListenPlayer.new,
  });

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  static const _rates = [1.0, .75, .5, 1.25];

  late final AppState _state = AppScope.read(context);
  late final ListenPlayer _player = widget.player();
  final _list = ScrollController();
  late int _index;

  /// Where the last report stood, and seconds heard but not yet saved.
  double _last = 0, _pending = 0;
  bool _wasPlaying = false;

  List<Episode> get _episodes => widget.source.episodes;
  Episode? get _episode => _episodes.isEmpty ? null : _episodes[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.index ?? _firstUnheard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_list.hasClients) return;
      _list.jumpTo(
        math.min(
          _list.position.maxScrollExtent,
          math.max(0, _index - 1) * context.grow(_EpisodeRow.height),
        ),
      );
    });
    _player
      ..onEnded = _ended
      ..addListener(_onPlayer);
    final e = _episode;
    if (e == null) {
      _player.loadPlaylist(widget.source.playlistId);
    } else {
      _open(e, widget.start ?? _resumeAt(e), autoplay: false);
    }
  }

  @override
  void dispose() {
    // Saving notifies the app's listeners, which must wait for the frame
    // that closes this screen to finish.
    _save(later: true);
    _player
      ..removeListener(_onPlayer)
      ..dispose();
    _list.dispose();
    super.dispose();
  }

  /// The first episode not heard to the end, after the last one heard.
  int _firstUnheard() {
    final progress = _state.listenLog.progress;
    var last = -1;
    for (final (i, e) in _episodes.indexed) {
      if (progress[e.id] != null) last = i;
    }
    if (last < 0) return 0;
    final p = progress[_episodes[last].id]!;
    return p.done && last + 1 < _episodes.length ? last + 1 : last;
  }

  /// Where [e] stopped, unless it was heard to the end or nearly so.
  int _resumeAt(Episode e) {
    final p = _state.listenLog.progress[e.id];
    if (p == null || p.done || p.position > e.seconds - 15) return 0;
    return p.position;
  }

  void _open(Episode e, int start, {required bool autoplay}) {
    _last = start.toDouble();
    _player.load(e.id, start: start, autoplay: autoplay);
  }

  /// Counts the seconds heard; seeking adds none. Saves every 15 seconds
  /// heard and whenever playback stops.
  void _onPlayer() {
    final p = _player.position;
    final step = p - _last;
    if (_player.playing && step > 0 && step <= 3) _pending += step;
    _last = p;
    if (_pending >= 15 || (_wasPlaying && !_player.playing)) _save();
    _wasPlaying = _player.playing;
  }

  void _save({bool done = false, bool later = false}) {
    final e = _episode;
    if (e == null) return;
    final heard = _pending.floor();
    if (heard == 0 && !done && _player.position < 1) return;
    _pending -= heard;
    final position = _player.position.round();
    void save() =>
        _state.listened(e.id, position: position, heard: heard, done: done);
    later ? scheduleMicrotask(save) : save();
  }

  void _ended() {
    _save(done: true);
    _state.feedback.success();
    final t = context.t;
    if (_index + 1 >= _episodes.length) {
      toast(context, t.listenAllDone);
      setState(() {});
      return;
    }
    final next = _episodes[_index + 1];
    toast(context, t.listenEpisodeDone(_index + 1, next.title));
    _play(_index + 1);
  }

  void _play(int i) {
    if (i == _index) {
      _player.toggle();
      return;
    }
    _save();
    _state.feedback.tap();
    setState(() => _index = i);
    _open(_episodes[i], _resumeAt(_episodes[i]), autoplay: true);
  }

  void _seekBy(double seconds) {
    _state.feedback.tap();
    final end = _player.duration > 0 ? _player.duration : double.infinity;
    _player.seekTo((_player.position + seconds).clamp(0, end).toDouble());
  }

  void _nextRate() {
    _state.feedback.tap();
    final i = _rates.indexOf(_player.rate);
    _player.setRate(_rates[(i + 1) % _rates.length]);
  }

  Future<void> _saveWord() async {
    _player.pause();
    final saved = await sheet<String>(context, const _SaveWordSheet());
    if (saved != null && mounted) toast(context, context.t.listenSaved(saved));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final e = _episode;
    final progress = AppScope.of(context).listenLog.progress;
    final heard = _episodes.where((x) => progress[x.id]?.done ?? false).length;
    return AppPage(
      title: t.listenTitle,
      child: Column(
        key: const ValueKey('listen-detail'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _player.view(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: ListenableBuilder(
              listenable: _player,
              builder: (context, _) => _NowPlaying(
                source: widget.source,
                episode: e,
                number: _index + 1,
                player: _player,
                onBack: () => _seekBy(-5),
                onForward: () => _seekBy(5),
                onToggle: () {
                  _state.feedback.tap();
                  _player.toggle();
                },
                onRate: _nextRate,
                onSaveWord: _saveWord,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (e != null)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.listenEpisodes,
                              style: D.text(16, weight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            t.listenHeardCount(heard, _episodes.length),
                            key: const ValueKey('listen-heard'),
                            style: D.text(
                              12.5,
                              weight: FontWeight.w700,
                              color: D.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: _player,
                        builder: (context, _) => ListView.builder(
                          key: const ValueKey('listen-episodes'),
                          controller: _list,
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
                          itemExtent: context.grow(_EpisodeRow.height),
                          itemCount: _episodes.length,
                          itemBuilder: (context, i) => _EpisodeRow(
                            episode: _episodes[i],
                            number: i + 1,
                            current: i == _index,
                            playing: i == _index && _player.playing,
                            progress: progress[_episodes[i].id],
                            onTap: () => _play(i),
                          ),
                        ),
                      ),
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
