part of 'focus_screen.dart';

/// The tag and the session title at the top left, and the close button.
class FocusTopBar extends StatelessWidget {
  final String tag, title, titleHint;
  final Color color;

  /// Null while a session runs, when neither can change.
  final VoidCallback? onTag, onTitle;

  /// Null hides the close button, as while a session runs.
  final String? closeKey;
  final VoidCallback onClose;
  const FocusTopBar({
    super.key,
    required this.tag,
    required this.color,
    required this.title,
    required this.titleHint,
    required this.onTag,
    required this.onTitle,
    required this.closeKey,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 14, 18, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PressFade(
                key: const ValueKey('focus-tag'),
                onTap: onTag,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: D.text(
                          15,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (onTag != null)
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 13,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              PressFade(
                key: const ValueKey('focus-title'),
                onTap: onTitle,
                child: Text(
                  title.isEmpty ? titleHint : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: D.text(
                    16,
                    weight: title.isEmpty ? FontWeight.w500 : FontWeight.w700,
                    color: Colors.white.withValues(
                      alpha: title.isEmpty ? .7 : 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (closeKey case final key?)
          PressFade(
            key: ValueKey(key),
            onTap: onClose,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
      ],
    ),
  );
}

/// A ring around the tree: 60 ticks showing the chosen length, or a progress
/// arc while the session runs.
class FocusRing extends StatelessWidget {
  final double value;
  final bool ticks;
  const FocusRing({super.key, required this.value, this.ticks = false});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(236, 236),
    painter: _RingPainter(value, ticks),
  );
}

class _RingPainter extends CustomPainter {
  final double value;
  final bool ticks;
  _RingPainter(this.value, this.ticks);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.width / 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (ticks) {
      final on = (value * 60).round();
      for (var i = 0; i < 60; i++) {
        final a = -math.pi / 2 + i * math.pi * 2 / 60, lit = i < on;
        final r0 = lit ? r - 9 : r - 6, r1 = lit ? r : r - 3;
        paint
          ..color = Colors.white.withValues(alpha: lit ? .95 : .28)
          ..strokeWidth = lit ? 2 : 1.4;
        canvas.drawLine(
          c + Offset(math.cos(a), math.sin(a)) * r0,
          c + Offset(math.cos(a), math.sin(a)) * r1,
          paint,
        );
      }
      return;
    }
    final rect = Rect.fromCircle(center: c, radius: r - 4);
    paint
      ..strokeWidth = 4
      ..color = Colors.white.withValues(alpha: .2);
    canvas.drawCircle(c, r - 4, paint);
    paint.color = Colors.white;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.max(.001, value) * math.pi * 2,
      false,
      paint,
    );
    final a = -math.pi / 2 + value * math.pi * 2;
    canvas.drawCircle(
      c + Offset(math.cos(a), math.sin(a)) * (r - 4),
      6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.ticks != ticks;
}

class FocusTimer extends StatelessWidget {
  final Duration left;
  const FocusTimer(this.left, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = left.inSeconds.clamp(0, 24 * 3600);
    final text =
        '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    return Text(
      text,
      key: const ValueKey('focus-timer'),
      style: D
          .text(
            56,
            weight: FontWeight.w800,
            color: Colors.white,
            height: 1,
            spacing: -1,
          )
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}

class FocusTitle extends StatelessWidget {
  final String text;
  const FocusTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: D.text(
        22,
        weight: FontWeight.w800,
        color: Colors.white,
        spacing: -.3,
      ),
    ),
  );
}

class FocusNote extends StatelessWidget {
  final String text;
  const FocusNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: D.text(
        14,
        weight: FontWeight.w500,
        color: Colors.white.withValues(alpha: .92),
        height: 1.45,
      ),
    ),
  );
}

class FocusButton extends StatelessWidget {
  final String id, label;
  final VoidCallback onTap;
  const FocusButton(this.id, this.label, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey(id),
    onTap: onTap,
    child: Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: D.text(16, weight: FontWeight.w700, color: Palette.focusInk),
      ),
    ),
  );
}

class FocusLink extends StatelessWidget {
  final String id, label;
  final VoidCallback onTap;
  const FocusLink(this.id, this.label, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey(id),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        label,
        style: D.text(15, weight: FontWeight.w600, color: Colors.white),
      ),
    ),
  );
}
