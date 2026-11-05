part of 'review_screen.dart';

/// A 3D turn. Past the edge the faces cross-fade, so the far side shows mirrored
/// for a moment, as on the reference.
class _FlipCard extends StatelessWidget {
  final double turn;
  final Widget front, back;
  const _FlipCard({
    required this.turn,
    required this.front,
    required this.back,
  });
  @override
  Widget build(BuildContext context) {
    final frontOpacity = (1 - (turn - .35) / .3).clamp(0.0, 1.0);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, .0012)
        ..rotateY(turn * pi),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (frontOpacity < 1)
            Opacity(
              opacity: 1 - frontOpacity,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(pi),
                child: back,
              ),
            ),
          if (frontOpacity > 0) Opacity(opacity: frontOpacity, child: front),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Color color;
  final Widget child;
  const _CardShell({required this.color, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: ShapeDecoration(
      color: color,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(36),
        side: BorderSide(color: D.ink.withValues(alpha: .1), width: .5),
      ),
      shadows: [
        BoxShadow(
          color: D.ink.withValues(alpha: .08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _CardFront extends StatelessWidget {
  final FlashWord word;
  final Color color;
  const _CardFront({required this.word, required this.color});
  @override
  Widget build(BuildContext context) => _CardShell(
    color: color,
    child: Column(
      children: [
        const Spacer(flex: 154),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.75),
          decoration: BoxDecoration(
            color: Palette.settingsPanel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            word.partOfSpeech,
            style: D.text(
              10.5,
              weight: FontWeight.w700,
              color: Palette.settingsMuted,
              spacing: 1.2,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word.word,
              maxLines: 1,
              style: D.text(29.5, weight: FontWeight.w800, height: 38 / 29.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          word.phonetic,
          style: D.text(
            13.5,
            color: Palette.settingsHint,
            spacing: .3,
            height: 18 / 13.5,
          ),
        ),
        const Spacer(flex: 109),
        Text(
          'CHẠM ĐỂ LẬT',
          style: D.text(
            10.5,
            weight: FontWeight.w700,
            color: Palette.settingsHint,
            spacing: 1.2,
            height: 13 / 10.5,
          ),
        ),
        const SizedBox(height: 31),
      ],
    ),
  );
}

class _CardBack extends StatelessWidget {
  final FlashWord word;
  final Color color;
  const _CardBack({required this.word, required this.color});
  @override
  Widget build(BuildContext context) => _CardShell(
    color: color,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 23, 22, 23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 21,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Palette.newPill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  word.partOfSpeech,
                  style: D.text(
                    10.5,
                    weight: FontWeight.w700,
                    color: Palette.newPillInk,
                    height: 1,
                  ),
                ),
              ),
              Semantics(
                label: 'Phát âm',
                child: Tooltip(
                  message: 'Phát âm',
                  triggerMode: TooltipTriggerMode.manual,
                  child: PressFade(
                    onTap: () => playWord(context, word.word),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Palette.settingsPage,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.speaker_2_fill,
                        size: 19,
                        color: D.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Palette.settingsEdge),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.meaning,
                    style: D.text(
                      20.5,
                      weight: FontWeight.w800,
                      height: 26.5 / 20.5,
                    ),
                  ),
                  if (word.definition.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      word.definition,
                      style: D.text(
                        13.2,
                        color: Palette.settingsMuted,
                        height: 19.7 / 13.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxWidth: 222),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: ShapeDecoration(
              color: Palette.settingsPage,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ví dụ',
                  style: D.text(
                    11,
                    weight: FontWeight.w600,
                    color: Palette.settingsMuted,
                    height: 15 / 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${word.example}"',
                  style: D
                      .text(12.5, height: 16 / 12.5)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
