import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/vocab/vocab.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'listen_screen.dart';

/// Minutes of listening a day that hifive suggests.
const listenGoalMinutes = 15;

/// Listening: today's minutes against a small goal, the episode to keep
/// listening to, and the sources hifive recommends, from the catalog. With
/// none cached yet, opening it fetches the catalog at once instead of
/// waiting for the daily check.
class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    if (state.listening.isEmpty || state.listening.first.episodes.isEmpty) {
      state.refreshCatalog(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = AppScope.of(context);
    final sources = state.listening;
    final next = state.listenNext;
    return AppPage(
      title: t.listenTitle,
      child: ListView(
        key: const ValueKey('listen-list'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _TodayCard(minutes: state.listenedToday ~/ 60),
          if (next != null) ...[
            _Heading(t.listenResume),
            _ResumeCard(
              source: next.source,
              index: next.index,
              position: next.position,
            ),
          ],
          _Heading(t.listenSources),
          if (sources.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                t.listenEmpty,
                key: const ValueKey('listen-empty'),
                textAlign: TextAlign.center,
                style: D.text(14, color: D.secondary, height: 1.5),
              ),
            )
          else
            for (final s in sources) _SourceCard(source: s),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  CupertinoIcons.lightbulb_fill,
                  size: 16,
                  color: Palette.menuPlus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.listenTip,
                  style: D.text(
                    13,
                    weight: FontWeight.w500,
                    color: D.secondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
    child: Text(text, style: D.text(18, weight: FontWeight.w800)),
  );
}

/// Today's minutes in a ring that fills towards [listenGoalMinutes].
class _TodayCard extends StatelessWidget {
  final int minutes;
  const _TodayCard({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final reached = minutes >= listenGoalMinutes;
    return Container(
      key: const ValueKey('listen-today'),
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.listenSoft, Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.listenSoft),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 72,
            child: CustomPaint(
              painter: _RingPainter(
                math.min(1, minutes / listenGoalMinutes).toDouble(),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minutes',
                      key: const ValueKey('listen-today-minutes'),
                      textScaler: TextScaler.noScaling,
                      style: D.text(22, weight: FontWeight.w800, height: 1.1),
                    ),
                    Text(
                      t.listenMinuteUnit,
                      textScaler: TextScaler.noScaling,
                      style: D.text(
                        10.5,
                        weight: FontWeight.w700,
                        color: D.secondary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.listenToday.toUpperCase(),
                  style: D.text(
                    11.5,
                    weight: FontWeight.w800,
                    color: Palette.menuListen,
                    spacing: .6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reached
                      ? t.listenGoalDone
                      : t.listenTodayBody(minutes, listenGoalMinutes),
                  style: D.text(16, weight: FontWeight.w800, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  t.listenTodayHint,
                  style: D.text(
                    12.5,
                    weight: FontWeight.w500,
                    color: D.secondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double share;
  const _RingPainter(this.share);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(4);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = Colors.white);
    if (share <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * share,
      false,
      stroke..color = Palette.menuListen,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.share != share;
}

/// The episode to keep listening to, with how much is left.
class _ResumeCard extends StatelessWidget {
  final ListeningSource source;
  final int index, position;
  const _ResumeCard({
    required this.source,
    required this.index,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final e = source.episodes[index];
    final left = math.max(1, ((e.seconds - position) / 60).ceil());
    final share = e.seconds == 0 ? 0.0 : position / e.seconds;
    return PressFade(
      key: const ValueKey('listen-resume'),
      onTap: () => go<void>(
        context,
        ListenScreen(source: source, index: index, start: position),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: D.shadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 120,
                height: 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      e.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Palette.listenSoft),
                    ),
                    const Center(
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.white,
                        child: Icon(
                          CupertinoIcons.play_fill,
                          size: 15,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: D.text(15.5, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.listenEpisode(index + 1)} · '
                    '${position > 0 ? t.listenMinutesLeft(left) : t.listenMinutes(left)}',
                    style: D.text(
                      12.5,
                      weight: FontWeight.w600,
                      color: D.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: share.clamp(0.0, 1.0),
                      minHeight: 5,
                      color: Palette.menuListen,
                      backgroundColor: Palette.listenSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final ListeningSource source;
  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final progress = AppScope.of(context).listenLog.progress;
    final total = source.episodes.length;
    final heard = source.episodes
        .where((e) => progress[e.id]?.done ?? false)
        .length;
    final hours = (source.seconds / 3600).round();
    Widget chip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: D.text(12, weight: FontWeight.w800, color: Palette.listenInk),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PressFade(
        key: ValueKey('listen-source-${source.id}'),
        onTap: () => go<void>(context, ListenScreen(source: source)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: D.shadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      source.cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Palette.listenSoft),
                    ),
                    const Center(
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(
                          CupertinoIcons.play_fill,
                          size: 24,
                          color: Palette.menuListen,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Row(
                        children: [
                          chip(source.level),
                          if (total > 0) ...[
                            const SizedBox(width: 6),
                            chip(t.listenEpisodeCount(total)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title,
                      style: D.text(17, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      total > 0 && hours > 0
                          ? '${source.channel} · ${t.listenAboutHours(hours)}'
                          : t.listenPlaylist(source.channel),
                      style: D.text(
                        12.5,
                        weight: FontWeight.w600,
                        color: D.muted,
                      ),
                    ),
                    if (source.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        source.description,
                        style: D.text(
                          13.5,
                          weight: FontWeight.w500,
                          color: D.secondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (total > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: heard / total,
                                minHeight: 6,
                                color: Palette.menuListen,
                                backgroundColor: Palette.listenSoft,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            t.listenHeardCount(heard, total),
                            key: ValueKey('listen-source-heard-${source.id}'),
                            style: D.text(
                              12,
                              weight: FontWeight.w700,
                              color: D.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
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
