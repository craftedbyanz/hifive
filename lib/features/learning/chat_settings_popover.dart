part of 'topic_screen.dart';

/// The white circle with the sliders glyph, bottom right.
class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SettingsButton({required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Tùy chỉnh bài học',
    child: PressFade(
      key: const ValueKey('chat-settings'),
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: D.ink.withValues(alpha: .08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const CustomPaint(
          size: Size(20, 16.7),
          painter: _SlidersGlyph(Colors.black),
        ),
      ),
    ),
  );
}

/// Three rails with oval knobs (right, left, right), like SF "slider.horizontal.3".
class _SlidersGlyph extends CustomPainter {
  final Color color;
  const _SlidersGlyph(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 20;
    final stroke = 1.6 * unit;
    final rail = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final knob = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final clear = Paint()..color = Colors.white;
    final gap = (size.height - stroke * 3.2) / 2;
    for (final (i, x) in const [(0, 13.3), (1, 6.0), (2, 13.3)]) {
      final y = stroke * 1.6 + i * gap;
      canvas.drawLine(
        Offset(stroke / 2, y),
        Offset(size.width - stroke / 2, y),
        rail,
      );
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x * unit, y),
          width: 6 * unit,
          height: 4.4 * unit,
        ),
        Radius.circular(2.2 * unit),
      );
      canvas.drawRRect(r, clear);
      canvas.drawRRect(r, knob);
    }
  }

  @override
  bool shouldRepaint(covariant _SlidersGlyph old) => old.color != color;
}

/// The first-visit tip, pointing at the settings button. Geometry from
/// survey 10 (iPhone screenshot, 1 November 2026).
class _ChatSettingsTip extends StatelessWidget {
  final VoidCallback onClose;
  const _ChatSettingsTip({required this.onClose});
  @override
  Widget build(BuildContext context) {
    final body = _system(context, 15, Palette.tipBody, FontWeight.w400);
    return CustomPaint(
      painter: const _TipBubble(),
      child: SizedBox(
        width: 333,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 17.5, 42, 1.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5.2),
                    child: CustomPaint(
                      size: Size(37.7, 31.3),
                      painter: _SlidersGlyph(Palette.tipBlue),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tùy chỉnh Bài học',
                          style: _system(
                            context,
                            17,
                            Colors.black,
                            FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          'Chuyển đổi giữa Trò chuyện Tự do và Kịch bản. Điều chỉnh độ khó, giọng và số câu hỏi.',
                          // Flutter sets this body about 5% wider than iOS,
                          // which moved "do" to the next line; a little
                          // extra tracking keeps the reference's breaks.
                          style: body.copyWith(
                            height: 21 / body.fontSize!,
                            letterSpacing: body.letterSpacing! - .2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 279.7,
              top: 14.7,
              child: Semantics(
                button: true,
                label: 'Đóng gợi ý',
                child: GestureDetector(
                  key: const ValueKey('chat-tip-close'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Palette.tipClose,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: Palette.tipBody,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 320 pt wide rounded bubble with a 13 pt arrow on its right edge,
/// level with the settings button.
class _TipBubble extends CustomPainter {
  const _TipBubble();
  @override
  void paint(Canvas canvas, Size size) {
    // The arrow is placed from the bottom edge, level with the button.
    const w = 320.0, radius = 31.0;
    final h = size.height;
    final arrowTop = h - 61.3, arrowBottom = h - 30.3;
    final apex = Offset(333, h - 45.6);
    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(w - radius, 0)
      ..arcToPoint(
        const Offset(w, radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(w, arrowTop)
      ..quadraticBezierTo(w, arrowTop + 6, w + 5, arrowTop + 9)
      ..quadraticBezierTo(apex.dx, apex.dy - 3, apex.dx, apex.dy)
      ..quadraticBezierTo(apex.dx, apex.dy + 3, w + 5, arrowBottom - 9)
      ..quadraticBezierTo(w, arrowBottom - 6, w, arrowBottom)
      ..lineTo(w, h - radius)
      ..arcToPoint(Offset(w - radius, h), radius: const Radius.circular(radius))
      ..lineTo(radius, h)
      ..arcToPoint(Offset(0, h - radius), radius: const Radius.circular(radius))
      ..lineTo(0, radius)
      ..arcToPoint(
        const Offset(radius, 0),
        radius: const Radius.circular(radius),
      )
      ..close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: .25), 8, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.tipTop, Palette.tipBottom],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .5
        ..color = Palette.tipEdge,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mode, voice, guide and close pills (survey 86).
class _ChatSettingsPopover extends StatelessWidget {
  final VoidCallback onClose;
  const _ChatSettingsPopover({required this.onClose});
  static const tones = ['Thoải mái', 'Trang trọng', 'Thân thiện'];
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    Widget pill({
      required Key key,
      required VoidCallback onTap,
      required Widget child,
    }) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 1,
      shadowColor: D.ink.withValues(alpha: .15),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: SizedBox(height: 52, child: child),
      ),
    );
    Widget labelled(String label, IconData icon) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: D.text(15, weight: FontWeight.w600)),
          ),
          Icon(icon, color: D.ink),
        ],
      ),
    );
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            pill(
              key: const ValueKey('chat-mode'),
              onTap: () => state.setChatFree(!state.chatFree),
              child: labelled(
                state.chatFree ? 'Trò chuyện Tự do' : 'Chế độ Kịch bản',
                state.chatFree ? Icons.forum_outlined : Icons.article_outlined,
              ),
            ),
            const SizedBox(height: 8),
            pill(
              key: const ValueKey('chat-tone'),
              onTap: () => state.setChatTone(
                tones[(tones.indexOf(state.chatTone) + 1) % tones.length],
              ),
              child: labelled(
                'Giọng: ${state.chatTone}',
                Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: pill(
                    key: const ValueKey('chat-guide'),
                    onTap: () =>
                        sheet<void>(context, const ConversationGuide()),
                    child: const Icon(Icons.info_outline_rounded),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: pill(
                    key: const ValueKey('chat-settings-close'),
                    onTap: onClose,
                    child: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
