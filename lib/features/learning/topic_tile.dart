part of 'topic_screen.dart';

class TopicTile extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;
  const TopicTile({super.key, required this.topic, required this.onTap});

  /// Plane, chat, briefcase and cup are the glyphs seen on the reference.
  static const glyphs = [
    CupertinoIcons.airplane,
    CupertinoIcons.chat_bubble_fill,
    CupertinoIcons.briefcase_fill,
    Icons.coffee_rounded,
    Icons.computer_rounded,
    Icons.public_rounded,
    CupertinoIcons.sparkles,
  ];
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: PressFade(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 18.8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Palette.topicTileEdge, width: .6),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Palette.topicTileTop,
              Palette.topicTileBand,
              Palette.topicTileBottom,
            ],
            stops: [0, .08, .3],
          ),
          boxShadow: [
            BoxShadow(
              color: D.ink.withValues(alpha: .08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: D.ink.withValues(alpha: .08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Palette.topicIconFill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                glyphs[topic.icon % glyphs.length],
                color: Palette.iconGrey,
                size: 21,
              ),
            ),
            const Spacer(),
            NoOrphanText(
              topic.title,
              // Two-line titles step 17.4 pt on the reference.
              style: D.text(
                13,
                weight: FontWeight.w800,
                height: 1.28,
                spacing: -.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 6,
                  decoration: BoxDecoration(
                    color: D.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8.4),
                Text(
                  '${topic.sets} ${topic.mode == StudyMode.grammar ? 'Qs' : 'Sets'}',
                  style: D.text(11, color: D.muted, weight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Two-line text that, like iOS, never leaves one word alone on the last
/// line: "Mở rộng vốn từ / tự nhiên", not "Mở rộng vốn từ tự / nhiên".
class NoOrphanText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const NoOrphanText(this.text, {super.key, required this.style});

  static String wrap(String text, TextStyle style, double width) {
    TextPainter measure(String t) => TextPainter(
      text: TextSpan(text: t, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: width);
    final painter = measure(text);
    final lines = painter.computeLineMetrics();
    final secondLine = lines.length == 2
        ? painter.getPositionForOffset(Offset(0, lines.first.height + 1))
        : null;
    painter.dispose();
    final words = text.split(' ');
    if (secondLine == null || words.length < 3) return text;
    if (text.substring(secondLine.offset).trim() != words.last) return text;
    return '${words.sublist(0, words.length - 2).join(' ')}\n'
        '${words.sublist(words.length - 2).join(' ')}';
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Text(
      wrap(text, style, constraints.maxWidth),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    ),
  );
}
