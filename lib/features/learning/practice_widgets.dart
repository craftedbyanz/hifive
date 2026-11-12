part of 'practice_screen.dart';

/// Thích and Không thích side by side at the bottom of the lesson menu.
class _OpinionRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChoose;
  const _OpinionRow({required this.selected, required this.onChoose});
  @override
  Widget build(BuildContext context) {
    Widget choice(String value, IconData icon, String label) => Expanded(
      child: GestureDetector(
        key: ValueKey('lesson-$value'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onChoose(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: selected == value ? D.blue : D.ink),
              const SizedBox(height: 6),
              Text(
                label,
                style: D.text(
                  12,
                  weight: FontWeight.w600,
                  color: selected == value ? D.blue : D.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        choice('like', CupertinoIcons.hand_thumbsup, context.t.like),
        choice('dislike', CupertinoIcons.hand_thumbsdown, context.t.dislike),
      ],
    );
  }
}

/// A white key of the lesson bar, 35 pt tall with a soft edge.
class _BarKey extends StatelessWidget {
  final String label;
  final double? width;
  final double padding;
  final VoidCallback? onTap;
  final Widget child;
  const _BarKey({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.width,
    this.padding = 0,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.manual,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: width,
            height: 35,
            padding: EdgeInsets.symmetric(horizontal: padding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: D.ink.withValues(alpha: .05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ExcludeSemantics(child: child),
          ),
        ),
      ),
    ),
  );
}

/// A hidden hint: a field of grey specks about as wide as the word, as the
/// reference draws it, so the word's length shows but not its letters.
class _Speckle extends StatelessWidget {
  final String word;
  const _Speckle({required this.word});
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(math.max(14, word.length * 5.6), 17),
    painter: _SpecklePainter(word.hashCode),
  );
}

class _SpecklePainter extends CustomPainter {
  final int seed;
  const _SpecklePainter(this.seed);
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final count = (size.width * size.height / 4.5).round();
    for (var i = 0; i < count; i++) {
      final shade = 110 + random.nextInt(90);
      final side = .9 + random.nextDouble() * .7;
      canvas.drawRect(
        Rect.fromLTWH(
          random.nextDouble() * (size.width - side),
          random.nextDouble() * (size.height - side),
          side,
          side,
        ),
        Paint()..color = Color.fromARGB(255, shade, shade, shade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpecklePainter old) => old.seed != seed;
}

/// The 35 pt next button: grey when there is nothing to send, ink otherwise.
class _NextButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;
  const _NextButton({super.key, required this.busy, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: context.t.next,
    child: Tooltip(
      message: context.t.next,
      triggerMode: TooltipTriggerMode.manual,
      child: GestureDetector(
        onTap: onTap,
        // While grading it grows to 43 pt and spins (survey 140/143).
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: busy ? 43 : 35,
          height: busy ? 43 : 35,
          decoration: BoxDecoration(
            color: onTap == null && !busy ? Palette.nextIdle : D.ink,
            shape: BoxShape.circle,
          ),
          child: busy
              ? const CupertinoActivityIndicator(color: Colors.white, radius: 8)
              : const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: Colors.white,
                ),
        ),
      ),
    ),
  );
}

class _DictionaryCard extends StatelessWidget {
  final LessonWord entry;
  const _DictionaryCard({required this.entry});
  @override
  Widget build(BuildContext context) {
    Widget round(
      IconData icon,
      Color color,
      String label,
      VoidCallback onTap,
    ) => Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Palette.correctionBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
    final where = context.t.sentencesList(entry.sentences.join(', '));
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(9, 16, 9, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: D.ink.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.word,
                  style: D.text(16, weight: FontWeight.w700),
                ),
              ),
              round(
                CupertinoIcons.speaker_2_fill,
                D.muted,
                context.t.pronounceWord(entry.word),
                () => playWord(context, entry.word),
              ),
              const SizedBox(width: 8),
              round(
                CupertinoIcons.add,
                D.green,
                context.t.saveItem(entry.word),
                () {
                  AppScope.read(context).saveWord(entry.word, entry.meaning);
                  toast(context, context.t.savedWord(entry.word));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(entry.meaning, style: D.text(15, height: 1.3)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                if (entry.ipa != null) ...[
                  TextSpan(
                    text: entry.ipa,
                    style: const TextStyle(fontFamily: 'Courier'),
                  ),
                  const TextSpan(text: '  ·  '),
                ],
                TextSpan(text: where),
              ],
            ),
            style: D.text(12, color: D.muted),
          ),
        ],
      ),
    );
  }
}
