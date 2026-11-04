import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../widgets/blur_header.dart';
import '../../widgets/common.dart';
import '../../widgets/glass_menu.dart';
import '../learning/learning.dart';
import 'result_screen.dart';

/// Saved results, laid out from survey 75/82/124/125 (iPhone): sections of
/// sideways cards under a title, a hairline and "Xem thêm ›", and a frosted
/// search bar floating at the bottom. With [mode] it is that section's
/// "Xem thêm" page: a two-column grid under "N sessions".
class HistoryScreen extends StatefulWidget {
  final StudyMode? mode;
  const HistoryScreen({super.key, this.mode});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

/// Section names on the reference: grammar results are "Câu".
String _section(StudyMode mode) => switch (mode) {
  StudyMode.writing => 'Đoạn văn',
  StudyMode.grammar => 'Câu',
  StudyMode.conversation => 'Hội thoại',
};

/// The ring and badge colour of each kind of result.
Color _tint(StudyMode mode) => switch (mode) {
  StudyMode.writing => D.purple,
  StudyMode.grammar => Palette.historyYellow,
  StudyMode.conversation => D.blue,
};

class _HistoryScreenState extends State<HistoryScreen> {
  final search = TextEditingController();
  final focus = FocusNode();
  String query = '';

  @override
  void initState() {
    super.initState();
    focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    search.dispose();
    focus.dispose();
    super.dispose();
  }

  Future<void> menu(BuildContext anchor) async {
    final state = AppScope.read(context);
    final choice = await showGlassMenu<String>(anchor, const [
      GlassMenuItem(
        'clear',
        'Xóa tất cả',
        icon: CupertinoIcons.trash,
        danger: true,
      ),
    ]);
    if (choice != 'clear' || !mounted) return;
    if (await confirm(
      context,
      'Xóa lịch sử cục bộ?',
      'Chỉ xóa kết quả trên bản ứng dụng này. Hành động không thể hoàn tác.',
      action: 'Xóa tất cả',
      cancel: 'Huỷ',
      destructive: true,
    )) {
      state.clearHistory();
    }
  }

  void newLesson() => sheet<void>(
    context,
    Column(
      children: [
        const SheetTitle('Luyện tập mới'),
        for (final mode in StudyMode.values)
          ListTile(
            key: ValueKey('history-new-${mode.name}'),
            leading: Icon(D.modeIcon(mode)),
            title: Text(mode.title),
            subtitle: Text(mode.category),
            onTap: () {
              Navigator.pop(context);
              go<void>(context, TopicScreen(mode: mode));
            },
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mode = widget.mode;
    final sessions = state.history
        .where(
          (s) =>
              (mode == null || s.lesson.mode == mode) &&
              '${s.lesson.title} ${s.lesson.description}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final searching = focus.hasFocus || query.isNotEmpty;
    final count = sessions.length;

    final Widget body;
    if (sessions.isEmpty) {
      body = Padding(
        padding: EdgeInsets.only(top: top + 54),
        child: EmptyView(
          title: query.isEmpty
              ? 'Chưa có bài ôn tập'
              : 'Không tìm thấy kết quả',
          subtitle: query.isEmpty
              ? 'Hoàn thành một bài học để lưu lại tiến bộ của bạn.'
              : 'Thử một từ khóa khác.',
          icon: Icons.search_rounded,
        ),
      );
    } else if (mode != null) {
      body = GridView.builder(
        padding: EdgeInsets.fromLTRB(23, top + 80, 23, bottom + 110),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 20,
          mainAxisExtent: context.grow(186),
        ),
        itemCount: count,
        itemBuilder: (_, i) => SessionTile(session: sessions[i]),
      );
    } else {
      body = ListView(
        padding: EdgeInsets.only(
          top: top + (searching ? 16 : 70),
          bottom: bottom + 110 + keyboard,
        ),
        children: [
          for (final m in StudyMode.values)
            if (sessions.any((s) => s.lesson.mode == m))
              _Section(
                mode: m,
                count: query.isEmpty
                    ? null
                    : sessions.where((s) => s.lesson.mode == m).length,
                sessions: [
                  for (final s in sessions)
                    if (s.lesson.mode == m) s,
                ],
                onMore: () => go<void>(context, HistoryScreen(mode: m)),
              ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: D.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          // The navigation row hides while searching (survey 124). It stays
          // in the tree so the search field is not rebuilt and keeps focus.
          Positioned(
            left: 16,
            right: 16,
            top: top,
            child: Offstage(
              offstage: searching && mode == null,
              child: SizedBox(
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mode == null ? 'Ôn tập' : _section(mode),
                          style: D.text(
                            mode == null ? 20 : 18,
                            weight: FontWeight.w600,
                          ),
                        ),
                        if (mode != null)
                          Text(
                            '$count sessions',
                            style: D.text(11, color: D.secondary),
                          ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: HeaderRoundButton(
                        icon: CupertinoIcons.back,
                        iconSize: 31,
                        label: 'Quay lại',
                        onTap: () => Navigator.maybePop(context),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Builder(
                        builder: (anchor) => HeaderRoundButton(
                          icon: CupertinoIcons.ellipsis,
                          iconSize: 20,
                          label: 'Tùy chọn lịch sử',
                          onTap: () => menu(anchor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Over the keyboard the bar widens to 8 pt from the edges.
          Positioned(
            left: keyboard > 0 ? 8 : 24,
            right: keyboard > 0 ? 8 : 24,
            bottom: keyboard > 0 ? keyboard + 8 : bottom - 6,
            child: Row(
              children: [
                Expanded(
                  child: _GlassCapsule(
                    height: 48,
                    child: Row(
                      children: [
                        const SizedBox(width: 18),
                        const Icon(
                          CupertinoIcons.search,
                          size: 21,
                          color: D.ink,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            key: const ValueKey('history-search'),
                            controller: search,
                            focusNode: focus,
                            textInputAction: TextInputAction.search,
                            textCapitalization: TextCapitalization.sentences,
                            style: D.text(17),
                            onChanged: (v) => setState(() => query = v),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Tìm kiếm tiêu đề, mô tả...',
                              hintStyle: D.text(17, color: D.muted),
                            ),
                          ),
                        ),
                        if (query.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() {
                              search.clear();
                              query = '';
                            }),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                size: 20,
                                color: D.ink,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Survey 75 shows "+" beside the search field; it was never
                // pressed there, and here it starts a new lesson. While
                // searching it becomes ✕, which ends the search (survey 124).
                Semantics(
                  button: true,
                  label: searching ? 'Đóng tìm kiếm' : 'Tạo bài luyện tập mới',
                  child: GestureDetector(
                    key: ValueKey(searching ? 'history-close' : 'history-new'),
                    onTap: searching
                        ? () => setState(() {
                            search.clear();
                            query = '';
                            focus.unfocus();
                          })
                        : newLesson,
                    child: _GlassCapsule(
                      height: 48,
                      width: 48,
                      child: Icon(
                        searching ? CupertinoIcons.xmark : CupertinoIcons.add,
                        size: 24,
                        color: D.ink,
                      ),
                    ),
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

class _GlassCapsule extends StatelessWidget {
  final double height;
  final double? width;
  final Widget child;
  const _GlassCapsule({required this.height, required this.child, this.width});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(height / 2),
      boxShadow: [
        BoxShadow(
          color: D.ink.withValues(alpha: .08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: height,
          width: width,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  final StudyMode mode;
  final int? count;
  final List<StudySession> sessions;
  final VoidCallback onMore;
  const _Section({
    required this.mode,
    required this.count,
    required this.sessions,
    required this.onMore,
  });
  @override
  Widget build(BuildContext context) => Padding(
    // Sections repeat every 252 pt (survey 75).
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 15),
          child: Row(
            children: [
              Text(_section(mode), style: D.text(17, weight: FontWeight.w700)),
              // While searching, a badge counts the matches (survey 125).
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tint(mode).withValues(alpha: .18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: D.text(
                      11,
                      weight: FontWeight.w700,
                      color: _tint(mode),
                    ),
                  ),
                ),
                const Spacer(),
              ] else ...[
                const SizedBox(width: 16),
                const Expanded(
                  child: Divider(height: 1, thickness: 1, color: D.line),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: onMore,
                  child: Row(
                    children: [
                      Text(
                        'Xem thêm',
                        style: D.text(
                          11,
                          weight: FontWeight.w700,
                          color: D.muted,
                          spacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 9,
                        color: D.muted,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: context.grow(186),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 23),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) =>
                SizedBox(width: 162, child: SessionTile(session: sessions[i])),
          ),
        ),
      ],
    ),
  );
}

/// A saved result: a white card with the language flag and a progress ring,
/// a preview of the content, and the title under the card.
class SessionTile extends StatelessWidget {
  final StudySession session;
  const SessionTile({super.key, required this.session});
  @override
  Widget build(BuildContext context) {
    final lesson = session.lesson;
    final questions = lesson.questions;
    final Widget preview = switch (lesson.mode) {
      StudyMode.writing => Text(
        questions.map((q) => q.prompt).join(' '),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: D.text(13, color: D.secondary, height: 1.25),
      ),
      StudyMode.grammar => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < math.min(2, questions.length); i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 5, right: 7),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Palette.historyYellow,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: D.text(
                        10,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      questions[i].prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: D.text(12.5, color: D.secondary, height: 1.15),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      StudyMode.conversation => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < math.min(2, questions.length); i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: i.isEven ? D.blue : D.line.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${i.isEven ? 'A' : 'B'}: ${questions[i].prompt}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: D.text(
                  10.5,
                  color: i.isEven ? Colors.white : D.secondary,
                  height: 1.2,
                ),
              ),
            ),
        ],
      ),
    };
    return GestureDetector(
      // Saved results open in an iOS sheet over the history (survey 76).
      onTap: () => showCupertinoSheet<void>(
        context: context,
        useNestedNavigation: true,
        scrollableBuilder: (_, _) => ResultScreen(session: session),
      ),
      child: Column(
        children: [
          Container(
            height: context.grow(148),
            padding: const EdgeInsets.fromLTRB(15, 17, 15, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: D.ink.withValues(alpha: .05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: HistoryFlag(),
                    ),
                    const Spacer(),
                    _Ring(
                      value: session.accuracy / 100,
                      color: _tint(lesson.mode),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Clips a preview taller than the card without an error.
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: preview,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            lesson.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: D.text(14, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A small US flag: stripes and a blue canton.
class HistoryFlag extends StatelessWidget {
  const HistoryFlag({super.key});
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(18, 12), painter: _FlagPainter());
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final stripe = size.height / 7;
    for (var i = 0; i < 7; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripe, size.width, stripe),
        Paint()..color = i.isEven ? Palette.flagRed : Colors.white,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * .45, stripe * 4),
      Paint()..color = Palette.flagBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The progress ring at the card's top right.
class _Ring extends StatelessWidget {
  final double value;
  final Color color;
  const _Ring({required this.value, required this.color});
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(22, 22),
    painter: _RingPainter(value, color),
  );
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  const _RingPainter(this.value, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = D.line,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * math.max(.08, value),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}
