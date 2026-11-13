import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/vocab/vocab.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'listen_screen.dart';

/// The listening sources hifive recommends, from the catalog: one card each
/// with the cover, level and channel. With none cached yet, opening it
/// fetches the catalog at once instead of waiting for the daily check.
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
    if (state.listening.isEmpty) state.refreshCatalog(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final sources = AppScope.of(context).listening;
    return AppPage(
      title: t.listenTitle,
      child: ListView(
        key: const ValueKey('listen-list'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text(
            t.listenIntro,
            style: D.text(
              14,
              weight: FontWeight.w500,
              color: D.secondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (sources.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                t.listenEmpty,
                key: const ValueKey('listen-empty'),
                textAlign: TextAlign.center,
                style: D.text(14, color: D.secondary, height: 1.5),
              ),
            )
          else
            for (final s in sources) _SourceCard(source: s),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final ListeningSource source;
  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) => Padding(
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
                        const ColoredBox(color: Palette.focusSkyMiddle),
                  ),
                  const Center(
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        CupertinoIcons.play_fill,
                        size: 24,
                        color: Palette.focusInk,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        source.level,
                        style: D.text(
                          12,
                          weight: FontWeight.w800,
                          color: Palette.focusInk,
                        ),
                      ),
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
                    context.t.listenPlaylist(source.channel),
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
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
