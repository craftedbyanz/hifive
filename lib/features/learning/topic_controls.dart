part of 'topic_screen.dart';

class _CountPill extends StatelessWidget {
  final String text;
  const _CountPill(this.text);
  @override
  Widget build(BuildContext context) => Container(
    height: 20.5,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 8.5),
    decoration: BoxDecoration(
      color: Palette.topicCountPill,
      borderRadius: BorderRadius.circular(10.25),
    ),
    child: Text(
      text,
      style: D.text(10, color: D.secondary, weight: FontWeight.w500),
    ),
  );
}

/// Content blurs and fades out beneath the status bar, as on the reference:
/// a blur that eases off downwards under a fading tint.
class _StatusFade extends StatelessWidget {
  const _StatusFade();
  @override
  Widget build(BuildContext context) => ShaderMask(
    // The mask makes the blurred layer strongest at the top.
    shaderCallback: (rect) => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.black, Colors.black, Colors.transparent],
      stops: [0, .55, 1],
    ).createShader(rect),
    blendMode: BlendMode.dstIn,
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                D.background.withValues(alpha: .3),
                D.background.withValues(alpha: .15),
                D.background.withValues(alpha: 0),
              ],
              stops: const [0, .6, 1],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The glass "AI" pill with its orbit glyph, 56 × 44.
class _AiButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AiButton({required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'AI',
    child: PressFade(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Palette.insightBackEdge, width: .5),
          boxShadow: [
            BoxShadow(
              color: D.ink.withValues(alpha: .06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustomPaint(size: Size(17, 16.3), painter: _OrbitGlyph()),
            const SizedBox(width: 5.7),
            ExcludeSemantics(
              child: Text(
                'AI',
                style: D.text(
                  13,
                  weight: FontWeight.w700,
                  height: 1,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Three ellipses at 60° steps, as on the reference's AI button.
class _OrbitGlyph extends CustomPainter {
  const _OrbitGlyph();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.black;
    canvas.translate(size.width / 2, size.height / 2);
    final major = size.height - paint.strokeWidth;
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate(math.pi / 2 + i * math.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: major, height: major * .47),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// SF-style glyphs approximated with Material and Cupertino icons; the
/// reference's are two-tone illustrations.
const _categoryGlyphs = {
  'Dành cho bạn': Icons.star_rounded,
  'Giao tiếp': CupertinoIcons.chat_bubble_2_fill,
  'Hằng ngày': Icons.home_rounded,
  'Công việc': CupertinoIcons.briefcase_fill,
  'Du lịch': Icons.flight_rounded,
  'Mua sắm': Icons.shopping_bag_rounded,
  'Ẩm thực': Icons.restaurant_rounded,
  'Sức khỏe': CupertinoIcons.heart_fill,
  'Phim ảnh': Icons.smart_display_rounded,
  'Âm nhạc': Icons.music_note_rounded,
  'Trò chơi': Icons.sports_esports_rounded,
  'Thể thao': Icons.directions_run_rounded,
  'Văn hóa': Icons.palette_rounded,
  'Truyện ngắn': Icons.menu_book_rounded,
  'Tiểu luận': Icons.description_rounded,
  'Email': Icons.email_rounded,
  'Học thuật': Icons.school_rounded,
  'IELTS': Icons.verified_rounded,
  'Công nghệ': Icons.memory_rounded,
  'Sân bay & Khách sạn': Icons.flight_rounded,
  'Văn hóa & Phim ảnh': Icons.palette_rounded,
  'Học tập & Nghiên cứu': Icons.school_rounded,
  // The reference shows a popcorn box.
  'Vui chơi & Giải trí': Icons.celebration_rounded,
};

/// The selected border takes the category's colour, a shade deeper than its
/// glyph: #F97216 for the star (glyph #F9852F) and #EB4899 for the plane
/// (glyph #F15EA7). Other categories' borders were not seen and use the same
/// shift.
Color _selectedEdge(String label) {
  final glyph = Palette.categoryIcons[label];
  if (glyph == null) return Palette.categorySelected;
  final hsl = HSLColor.fromColor(glyph);
  return hsl.withLightness((hsl.lightness - .06).clamp(0, 1)).toColor();
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: PressFade(
      onTap: onTap,
      child: Container(
        height: 41,
        padding: const EdgeInsets.only(left: 10, right: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? _selectedEdge(label) : Colors.transparent,
            width: 1.7,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: D.ink.withValues(alpha: .03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryGlyphs[label] ?? Icons.label_rounded,
              color: Palette.categoryIcons[label] ?? D.blue,
              size: 24,
            ),
            const SizedBox(width: 5.3),
            Text(
              label,
              style: D.text(
                12,
                weight: FontWeight.w700,
                color: Palette.categoryText,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: D.muted),
          ],
        ),
      ),
    ),
  );
}

/// "Làm mới" replaces the topic count on a category (survey 25).
class _RefreshPill extends StatelessWidget {
  final VoidCallback? onTap;
  const _RefreshPill({required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: PressFade(
      key: const ValueKey('topics-refresh'),
      onTap: onTap,
      child: Container(
        height: 24.3,
        padding: const EdgeInsets.symmetric(horizontal: 10.6),
        decoration: BoxDecoration(
          color: Palette.topicCountPill,
          borderRadius: BorderRadius.circular(12.15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.arrow_clockwise,
              size: 11,
              color: D.secondary,
            ),
            const SizedBox(width: 4.5),
            Text(
              'Làm mới',
              style: D.text(10, color: D.secondary, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A heavy lemniscate, as on the reference's endless tile.
class _InfinityGlyph extends CustomPainter {
  const _InfinityGlyph();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, s = 2.6;
    final path = Path()..moveTo(w / 2, h / 2);
    for (var i = 1; i <= 64; i++) {
      final t = i / 64 * 2 * math.pi;
      final d = 1 + math.pow(math.sin(t), 2);
      path.lineTo(
        w / 2 + (w / 2 - s / 2) * math.cos(t) / d,
        h / 2 + (h - s) * math.sin(t) * math.cos(t) / d,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.endlessPurple
        ..style = PaintingStyle.stroke
        ..strokeWidth = s
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The lavender "Chế độ Vô tận" tile that leads grammar suggestions.
class _EndlessTile extends StatelessWidget {
  const _EndlessTile();
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: PressFade(
      onTap: () => go<void>(context, const PlusScreen()),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20.6, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Palette.endlessEdge),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Palette.endlessFill],
            stops: [0, .3],
          ),
          boxShadow: [
            BoxShadow(
              color: D.ink.withValues(alpha: .05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Palette.endlessIconFill,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const CustomPaint(
                    size: Size(22, 11),
                    painter: _InfinityGlyph(),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 17,
                  padding: const EdgeInsets.symmetric(horizontal: 6.5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Palette.endlessPurple,
                    borderRadius: BorderRadius.circular(8.5),
                  ),
                  child: Text(
                    'PLUS',
                    style: D.text(
                      9,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Chế độ Vô tận',
              style: D.text(
                13,
                weight: FontWeight.w800,
                height: 1.35,
                spacing: -.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Học tập không ngừng',
              style: D.text(11, color: D.secondary, weight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The tip beside the settings button when conversation topics open
/// (survey 10/83).
/// System text, as the tip is an iOS TipKit popover drawn in SF Pro. Unlike
/// the rest of the app, TipKit follows the system text size: the test iPhone
/// is one step below the default and showed 15/13 pt where the default is
/// 17/15. [base] is the default size; whole points as iOS uses.
TextStyle _system(
  BuildContext context,
  double base,
  Color color,
  FontWeight weight,
) {
  final size = MediaQueryData.fromView(View.of(context)).textScaler
      .scale(base)
      .roundToDouble();
  return TextStyle(
    fontFamily: 'CupertinoSystemText',
    fontSize: size,
    color: color,
    fontWeight: weight,
    // SF Pro Text's optical tracking, which Flutter does not apply itself.
    letterSpacing: switch (size) {
      >= 17 => -.43,
      16 => -.31,
      15 => -.23,
      14 => -.15,
      13 => -.08,
      _ => 0,
    },
  );
}
