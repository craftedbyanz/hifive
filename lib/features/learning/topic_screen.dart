import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../state/state.dart';
import '../../widgets/async_view.dart';
import '../../widgets/blur_header.dart';
import '../../widgets/common.dart';
import '../../widgets/press.dart';
import '../information/information.dart';
import 'collection_screen.dart';
import 'conversation_guide.dart';
import 'generator_screen.dart';

class TopicScreen extends StatefulWidget {
  final StudyMode mode;
  const TopicScreen({super.key, required this.mode});
  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  late Future<List<String>> categories = _loadCategories();
  String? category;
  int refresh = 0;
  Future<List<Topic>>? topics;

  bool popoverOpen = false;

  Future<List<String>> _loadCategories() async {
    final list = await AppScope.read(context).lessons.categories(widget.mode);
    if (mounted && list.isNotEmpty && category == null) {
      setState(() {
        category = list.first;
        topics = _loadTopics();
      });
    }
    return list;
  }

  /// A failure is shown by the grid's [FutureBuilder], which may subscribe a
  /// frame later, so the error is marked handled here.
  Future<List<Topic>> _loadTopics() =>
      AppScope.read(context).lessons
          .topics(widget.mode, category!, refresh: refresh)
        ..ignore();

  void _select(String c) => setState(() {
    category = c;
    refresh = 0;
    topics = _loadTopics();
  });

  void _refresh() => setState(() {
    refresh++;
    topics = _loadTopics();
  });

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Content scrolls under the floating back and AI buttons and fades out
    // beneath the status bar, as measured on the physical iPhone.
    return Scaffold(
      backgroundColor: D.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<List<String>>(
              future: categories,
              builder: (context, snapshot) {
                Widget below(Widget child) => Padding(
                  padding: EdgeInsets.only(top: top + 60),
                  child: child,
                );
                if (snapshot.hasError) {
                  return below(
                    ErrorView(
                      onRetry: () => setState(() {
                        categories = _loadCategories();
                      }),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data!.isEmpty) {
                  return below(const EmptyView(title: 'Chưa có danh mục'));
                }
                if (snapshot.connectionState != ConnectionState.done ||
                    topics == null) {
                  return below(const LoadingView());
                }
                return _content(snapshot.data!, top);
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + 3,
            child: const IgnorePointer(child: _StatusFade()),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: top,
            child: Row(
              children: [
                HeaderRoundButton(
                  icon: CupertinoIcons.back,
                  iconSize: 31,
                  label: 'Quay lại',
                  onTap: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                _AiButton(
                  onTap: () => go<void>(context, GeneratorScreen(mode: mode)),
                ),
              ],
            ),
          ),
          if (mode == StudyMode.conversation) ...[
            if (popoverOpen)
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('chat-settings-scrim'),
                  onTap: () => setState(() => popoverOpen = false),
                  child: ColoredBox(color: D.ink.withValues(alpha: .25)),
                ),
              ),
            if (popoverOpen)
              Positioned(
                left: 16,
                right: 16,
                bottom: bottom + 16,
                child: _ChatSettingsPopover(
                  onClose: () => setState(() => popoverOpen = false),
                ),
              )
            else ...[
              // Measured on the physical iPhone: a 50 pt circle whose centre
              // sits 24.7 pt from the right and 20.3 pt above the inset.
              Positioned(
                right: 24.7,
                bottom: bottom + 20.3,
                child: _SettingsButton(
                  onTap: () => setState(() {
                    popoverOpen = true;
                    AppScope.read(context).dismissChatTip();
                  }),
                ),
              ),
              if (!AppScope.of(context).chatTipSeen)
                Positioned(
                  left: 10,
                  bottom: bottom - .3,
                  child: _ChatSettingsTip(
                    onClose: () => AppScope.read(context).dismissChatTip(),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _content(List<String> categoryList, double top) {
    final mode = widget.mode;
    final suggested = category == categoryList.first;
    final title = D.text(
      38,
      weight: FontWeight.w800,
      height: 1.04,
      spacing: -2,
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, top + 69.3, 24, 0),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8.7),
                  Text('CHẾ ĐỘ TẠO', style: CapsLabel.style),
                ],
              ),
              const SizedBox(height: 11.2),
              Text(mode.headline, style: title),
              Text(
                mode.accentTitle,
                style: title.copyWith(
                  color: mode == StudyMode.grammar
                      ? Palette.grammarAccent
                      : mode == StudyMode.writing
                      ? Palette.categoryInactive
                      : D.blue,
                ),
              ),
              const SizedBox(height: 27),
              const CapsLabel('DANH MỤC'),
              const SizedBox(height: 19.1),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 41,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 22.7),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: categoryList.length,
              separatorBuilder: (_, _) => const SizedBox(width: 11.6),
              itemBuilder: (_, i) => _CategoryChip(
                label: categoryList[i],
                selected: categoryList[i] == category,
                onTap: () => _select(categoryList[i]),
              ),
            ),
          ),
        ),
        FutureBuilder<List<Topic>>(
          future: topics,
          builder: (context, snapshot) {
            final loaded = snapshot.connectionState == ConnectionState.done;
            final list = snapshot.data ?? const <Topic>[];
            final endless = mode == StudyMode.grammar && suggested;
            final count = list.length + (endless ? 1 : 0);
            return SliverMainAxisGroup(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 35.3, 24, 16.2),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: suggested ? 20.5 : 24.3,
                      child: Row(
                        children: [
                          Expanded(
                            child: CapsLabel(
                              suggested ? 'CHỦ ĐỀ CỦA BẠN' : 'CHỦ ĐỀ LIÊN QUAN',
                            ),
                          ),
                          if (!suggested)
                            _RefreshPill(onTap: loaded ? _refresh : null)
                          else if (loaded && !snapshot.hasError)
                            _CountPill('$count chủ đề'),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!loaded)
                  const SliverToBoxAdapter(child: LoadingView())
                else if (snapshot.hasError)
                  SliverToBoxAdapter(
                    child: ErrorView(
                      onRetry: () => setState(() {
                        topics = _loadTopics();
                      }),
                    ),
                  )
                else if (count == 0)
                  const SliverToBoxAdapter(
                    child: EmptyView(
                      title: 'Chưa có chủ đề',
                      subtitle:
                          'Hãy thử danh mục khác hoặc tạo chủ đề bằng AI.',
                      icon: Icons.auto_awesome_rounded,
                    ),
                  )
                else
                  SliverPadding(
                    // The last row stops 154 pt above the screen's bottom edge.
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 154),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 11,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 160,
                          ),
                      itemCount: count,
                      itemBuilder: (_, index) {
                        if (endless && index == 0) return const _EndlessTile();
                        final t = list[index - (endless ? 1 : 0)];
                        return TopicTile(
                          topic: t,
                          onTap: () =>
                              go<void>(context, CollectionScreen(topic: t)),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

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
