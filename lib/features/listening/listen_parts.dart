part of 'listen_screen.dart';

/// `m:ss`, or `h:mm:ss` from an hour.
String _clock(double seconds) {
  final s = seconds.isFinite ? seconds.floor() : 0;
  final h = s ~/ 3600, m = s % 3600 ~/ 60, r = s % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(r)}' : '$m:${two(r)}';
}

/// The episode playing: its number, title, a bar to seek, and the controls.
class _NowPlaying extends StatelessWidget {
  final ListeningSource source;
  final Episode? episode;
  final int number;
  final ListenPlayer player;
  final VoidCallback onBack, onForward, onToggle, onRate, onSaveWord;
  const _NowPlaying({
    required this.source,
    required this.episode,
    required this.number,
    required this.player,
    required this.onBack,
    required this.onForward,
    required this.onToggle,
    required this.onRate,
    required this.onSaveWord,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final e = episode;
    final rate = player.rate == player.rate.roundToDouble()
        ? '${player.rate.round()}×'
        : '${player.rate}×';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [
            if (e != null) t.listenEpisode(number).toUpperCase(),
            source.channel,
            source.level,
          ].join(' · '),
          style: D.text(
            11.5,
            weight: FontWeight.w800,
            color: Palette.menuListen,
            spacing: .6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          e?.title ?? source.title,
          key: const ValueKey('listen-now-title'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: D.text(20, weight: FontWeight.w800, spacing: -.3),
        ),
        if (e != null) ...[
          const SizedBox(height: 4),
          _Scrubber(player: player, fallback: e.seconds.toDouble()),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Pill(
                key: const ValueKey('listen-rate'),
                tooltip: t.listenSpeed,
                label: rate,
                highlighted: player.rate != 1,
                onTap: onRate,
              ),
              _RoundButton(
                key: const ValueKey('listen-back'),
                tooltip: t.listenBack,
                icon: CupertinoIcons.gobackward,
                badge: '5',
                onTap: onBack,
              ),
              PressFade(
                key: const ValueKey('listen-toggle'),
                onTap: onToggle,
                child: Tooltip(
                  message: player.playing ? t.listenPause : t.listenPlay,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Palette.menuListen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Palette.menuListen.withValues(alpha: .35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      player.playing
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              _RoundButton(
                key: const ValueKey('listen-forward'),
                tooltip: t.listenForward,
                icon: CupertinoIcons.goforward,
                badge: '5',
                onTap: onForward,
              ),
              _RoundButton(
                key: const ValueKey('listen-save-word'),
                tooltip: t.listenSaveWord,
                icon: CupertinoIcons.bookmark_fill,
                onTap: onSaveWord,
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 14),
          PressFade(
            key: const ValueKey('listen-save-word'),
            onTap: onSaveWord,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.menuListen,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Text(
                t.listenSaveWord,
                style: D.text(
                  15.5,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A thin bar of the time played; dragging it seeks.
class _Scrubber extends StatefulWidget {
  final ListenPlayer player;

  /// The episode's length from the catalog, until the video tells its own.
  final double fallback;
  const _Scrubber({required this.player, required this.fallback});

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final length = p.duration > 0 ? p.duration : widget.fallback;
    final at = (_drag ?? p.position).clamp(0, math.max(length, 1)).toDouble();
    final label = D.text(11.5, weight: FontWeight.w700, color: D.secondary);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            activeTrackColor: Palette.menuListen,
            inactiveTrackColor: D.line,
            thumbColor: Palette.menuListen,
            overlayColor: Palette.menuListen.withValues(alpha: .12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: SizedBox(
            height: 28,
            child: Slider(
              key: const ValueKey('listen-seek'),
              value: at,
              max: math.max(length, 1),
              onChanged: (v) => setState(() => _drag = v),
              onChangeEnd: (v) {
                p.seekTo(v);
                setState(() => _drag = null);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_clock(at), style: label),
              Text('-${_clock(math.max(0, length - at))}', style: label),
            ],
          ),
        ),
      ],
    );
  }
}

/// A white round control with an icon and, inside it, a small number.
class _RoundButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;
  const _RoundButton({
    super.key,
    required this.tooltip,
    required this.icon,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => PressFade(
    onTap: onTap,
    child: Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: D.line),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: badge == null ? 20 : 30, color: D.ink),
            if (badge case final b?)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  b,
                  textScaler: TextScaler.noScaling,
                  style: D.text(9.5, weight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The speed control: its value in a pill, tinted when not 1×.
class _Pill extends StatelessWidget {
  final String tooltip, label;
  final bool highlighted;
  final VoidCallback onTap;
  const _Pill({
    super.key,
    required this.tooltip,
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => PressFade(
    onTap: onTap,
    child: Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 54,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted ? Palette.listenSoft : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: highlighted ? Palette.menuListen : D.line),
        ),
        child: Text(
          label,
          textScaler: TextScaler.noScaling,
          style: D.text(
            13.5,
            weight: FontWeight.w800,
            color: highlighted ? Palette.listenInk : D.ink,
          ),
        ),
      ),
    ),
  );
}

/// One episode in the list: its thumbnail with length and progress, its
/// number or a playing sign, its title and a tick once heard.
class _EpisodeRow extends StatelessWidget {
  /// The row's height at normal text size.
  static const height = 84.0;

  final Episode episode;
  final int number;
  final bool current, playing;
  final ListenProgress? progress;
  final VoidCallback onTap;
  const _EpisodeRow({
    required this.episode,
    required this.number,
    required this.current,
    required this.playing,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final done = progress?.done ?? false;
    final part = !done && progress != null && episode.seconds > 0
        ? (progress!.position / episode.seconds).clamp(0.0, 1.0)
        : 0.0;
    return PressFade(
      key: ValueKey('listen-episode-$number'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: current ? Palette.listenSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 112,
                height: 63,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      episode.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Palette.listenSoft),
                    ),
                    Positioned(
                      right: 5,
                      bottom: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _clock(episode.seconds.toDouble()),
                          textScaler: TextScaler.noScaling,
                          style: D.text(
                            10.5,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (part > 0)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: FractionallySizedBox(
                          widthFactor: part,
                          child: Container(
                            height: 3,
                            color: Palette.menuListen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (current) ...[
                        _SoundBars(playing: playing),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        current
                            ? t.listenNowPlaying.toUpperCase()
                            : t.listenEpisode(number).toUpperCase(),
                        style: D.text(
                          10.5,
                          weight: FontWeight.w800,
                          color: current ? Palette.listenInk : D.muted,
                          spacing: .5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    episode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: D.text(
                      14.5,
                      weight: FontWeight.w700,
                      height: 1.3,
                      color: done && !current ? D.secondary : D.ink,
                    ),
                  ),
                ],
              ),
            ),
            if (done)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  key: ValueKey('listen-done'),
                  size: 20,
                  color: D.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Three small bars in the logo's colors that bounce while [playing], like
/// a voice; they rest at the logo's heights otherwise or without
/// [AmbientMotion].
class _SoundBars extends StatefulWidget {
  final bool playing;
  const _SoundBars({required this.playing});

  @override
  State<_SoundBars> createState() => _SoundBarsState();
}

class _SoundBarsState extends State<_SoundBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_SoundBars old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.playing && AmbientMotion.of(context)) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _loop,
    builder: (context, _) => SizedBox(
      width: 13,
      height: 11,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final (i, rest) in const [.55, 1.0, .7].indexed)
            Container(
              width: 3,
              height:
                  11 *
                  (_loop.isAnimating
                      ? .3 +
                            .7 *
                                math
                                    .sin((_loop.value + i * .33) * math.pi)
                                    .abs()
                      : rest),
              decoration: BoxDecoration(
                color: Palette.logoBars[i + 1],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    ),
  );
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
                color: Palette.menuListen,
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
