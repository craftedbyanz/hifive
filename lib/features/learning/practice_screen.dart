import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/glass_menu.dart';
import '../insights/insights.dart';
import 'dictionary.dart';
import 'grading_sheet.dart';

class PracticeScreen extends StatefulWidget {
  final Lesson lesson;
  const PracticeScreen({super.key, required this.lesson});
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final text = TextEditingController();
  final focus = FocusNode();
  final clock = Stopwatch()..start();
  late List<AnswerRecord?> records = List.filled(
    widget.lesson.questions.length,
    null,
  );
  int index = 0;
  bool busy = false, grading = false, allowExit = false;
  String? opinion;
  final Set<String> revealed = {};
  Grade? lastGrade;
  Question get question => widget.lesson.questions[index];
  Animation<double>? _entryAnimation;
  bool _initialFocusScheduled = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialFocusScheduled) return;
    _initialFocusScheduled = true;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focus.requestFocus();
      });
    } else {
      _entryAnimation = animation;
      animation.addStatusListener(_onEntryStatus);
    }
  }

  void _onEntryStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _entryAnimation?.removeStatusListener(_onEntryStatus);
    _entryAnimation = null;
    if (mounted) focus.requestFocus();
  }

  @override
  void dispose() {
    _entryAnimation?.removeStatusListener(_onEntryStatus);
    text.dispose();
    focus.dispose();
    clock.stop();
    super.dispose();
  }

  Future<void> exit() async {
    if (await confirm(
      context,
      'Thoát bài tập?',
      'Bạn chưa hoàn thành bài tập. Tiến độ sẽ không được lưu nếu bạn thoát bây giờ.',
      destructive: true,
    )) {
      if (!mounted) return;
      setState(() => allowExit = true);
      await Future<void>.delayed(Duration.zero);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> submit() async {
    if (text.text.trim().isEmpty || busy) return;
    if (lastGrade?.kind == GradeKind.correct &&
        records[index]?.text == text.text.trim()) {
      next();
      return;
    }
    final answer = text.text.trim();
    final state = AppScope.read(context), current = question;
    void record(Grade grade) {
      final first = records[index]?.firstScore ?? grade.score;
      records[index] = AnswerRecord(answer, first, grade.kind);
      lastGrade = grade;
      state.feedback.tap();
    }

    // Survey 140/143: while grading, the next button spins and the keyboard
    // stays as it was; the feedback sheet opens with the result.
    setState(() => busy = grading = true);
    Grade? graded;
    try {
      graded = await state.grading.grade(current, answer);
    } catch (_) {
      // The sheet opens on its error state and offers a retry.
    }
    if (!mounted) return;
    setState(() => grading = false);
    if (graded != null) record(graded);
    FocusScope.of(context).unfocus();
    final advance = await GradingSheet.show(
      context,
      question: current,
      answer: answer,
      mode: widget.lesson.mode,
      initial: graded,
      grade: () => state.grading.grade(current, answer),
      onGraded: record,
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (advance == true) {
      next();
    } else {
      focus.requestFocus();
    }
  }

  /// ✨ in the hint row: help for the current draft from the grading service.
  void assist() {
    final state = AppScope.read(context), current = question;
    final draft = text.text;
    sheet<void>(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle('Gợi ý AI'),
          SizedBox(
            height: 220,
            child: AsyncView<List<String>>(
              load: () => state.grading.assist(current, draft),
              loadingLabel: 'Đang phân tích bản nháp...',
              builder: (context, tips) => ListView(
                children: [
                  for (final tip in tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2, right: 10),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: D.purple,
                            ),
                          ),
                          Expanded(
                            child: Text(tip, style: D.text(14, height: 1.55)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Màu nền": a frosted submenu over the lesson menu (iPhone, 3 November
  /// 2026), each colour with a swatch and the current one ticked. Its title
  /// row goes back to the lesson menu.
  Future<void> colors(BuildContext anchor) async {
    final state = AppScope.read(context);
    final choice = await showGlassMenu<String>(
      anchor,
      [
        for (final c in D.inputColors)
          GlassMenuItem(
            c,
            c,
            checked: state.inputColor == c,
            dot: D.input(StudyMode.grammar, c),
          ),
      ],
      title: 'Màu nền',
      titleIcon: Icons.palette_outlined,
      titleValue: '..',
      behind: const GlassMenuItem('..', ''),
    );
    if (!mounted || !anchor.mounted || choice == null) return;
    if (choice == '..') {
      await menu(anchor);
    } else {
      state.setInputColor(choice);
    }
  }

  void next() {
    if (index == widget.lesson.questions.length - 1) {
      final state = AppScope.read(context);
      final session = StudySession(
        id: 'session-${widget.lesson.id}-${state.now().microsecondsSinceEpoch}',
        lesson: widget.lesson,
        date: state.now(),
        answers: records
            .map((r) => r ?? const AnswerRecord('', 0, GradeKind.incorrect))
            .toList(),
        seconds: clock.elapsed.inSeconds,
      );
      state.complete(session);
      state.feedback.success();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CompletionScreen(session: session),
        ),
      );
    } else {
      setState(() {
        index++;
        text.text = records[index]?.text ?? '';
        lastGrade = null;
      });
      focus.requestFocus();
    }
  }

  void previous() {
    if (index > 0) {
      setState(() {
        index--;
        text.text = records[index]?.text ?? '';
        lastGrade = null;
      });
    }
  }

  /// "Từ điển bài" (survey 146): a floating sheet at half height with a
  /// centred title, "Xong", and one card per word, most used first.
  void dictionary() {
    final words = lessonWords([
      for (final q in widget.lesson.questions) q.answer,
    ]);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Palette.sheetBarrier,
      elevation: 0,
      showDragHandle: false,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: .54,
        minChildSize: .3,
        maxChildSize: .93,
        expand: false,
        builder: (ctx, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: ColoredBox(
              color: D.background,
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: D.line,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Từ điển bài',
                          style: D.text(17, weight: FontWeight.w700),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: D.line),
                              ),
                              child: Text(
                                'Xong',
                                style: D.text(17, weight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final w in words) _DictionaryCard(entry: w),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> menu(BuildContext anchor) async {
    final state = AppScope.read(context);
    final choice = await showGlassMenu<String>(
      anchor,
      [
        const GlassMenuItem(
          'color',
          'Màu nền',
          icon: Icons.palette_outlined,
          trailing: CupertinoIcons.chevron_right,
        ),
        GlassMenuItem(
          'hints',
          state.showHints ? 'Ẩn gợi ý' : 'Hiển thị gợi ý',
          icon: CupertinoIcons.lightbulb,
        ),
        const GlassMenuItem(
          'dictionary',
          'Từ điển bài',
          icon: Icons.book_rounded,
        ),
      ],
      footer: (context, choose) =>
          _OpinionRow(selected: opinion, onChoose: choose),
    );
    if (!mounted || !anchor.mounted || choice == null) return;
    switch (choice) {
      case 'color':
        await colors(anchor);
      case 'hints':
        state.setShowHints(!state.showHints);
      case 'dictionary':
        dictionary();
      case 'like' || 'dislike':
        setState(() => opinion = choice);
        toast(context, 'Đã ghi nhận đánh giá trong phiên học này');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), mode = widget.lesson.mode;
    final color = D.input(mode, state.inputColor);
    return PopScope(
      canPop: allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) exit();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // Measured on the iPhone (survey 132/143): a 44 pt row whose
              // controls centre at y 81, 2.7 pt above the prompt card.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 2.7),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Thoát bài tập',
                        constraints: const BoxConstraints.tightFor(
                          width: 44,
                          height: 44,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: exit,
                        icon: const Icon(
                          CupertinoIcons.xmark,
                          color: D.muted,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < records.length; i++)
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: i <= index
                                        ? Palette.progressDone
                                        : D.line,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // The frosted system menu (survey 145).
                      Builder(
                        builder: (anchor) => IconButton(
                          tooltip: 'Tùy chọn bài học',
                          constraints: const BoxConstraints.tightFor(
                            width: 44,
                            height: 44,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: D.muted,
                            size: 26,
                          ),
                          onPressed: () => menu(anchor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The set's title in 8 pt capitals (survey 183).
              if (mode != StudyMode.grammar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 2.5, 24, 11.3),
                  child: Text(
                    widget.lesson.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: D.text(
                      8,
                      color: D.muted,
                      weight: FontWeight.w800,
                      spacing: 1.6,
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final prompt = mode == StudyMode.writing
                          ? SingleChildScrollView(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < widget.lesson.questions.length;
                                      i++
                                    )
                                      TextSpan(
                                        text:
                                            '${widget.lesson.questions[i].prompt} ',
                                        // SF Pro 17 pt, 26 pt lines; later
                                        // sentences in the line colour.
                                        style:
                                            TextStyle(
                                              fontFamily: 'CupertinoSystemText',
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500,
                                              height: 1.53,
                                              letterSpacing: -.43,
                                              color: i == index
                                                  ? D.ink
                                                  : i < index
                                                  ? D.muted
                                                  : D.line,
                                            ).copyWith(
                                              backgroundColor: i == index
                                                  ? Palette.highlight
                                                  : null,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: SingleChildScrollView(
                                child: Text(
                                  question.prompt,
                                  textAlign: TextAlign.center,
                                  // SF Pro Bold, 17 pt caps, lines 34.6 pt
                                  // apart, whether or not the keyboard shows.
                                  style: const TextStyle(
                                    fontFamily: 'CupertinoSystemDisplay',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    height: 1.44,
                                    color: D.ink,
                                  ),
                                ),
                              ),
                            );
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Surface(
                                  radius: 33,
                                  padding: mode == StudyMode.writing
                                      ? const EdgeInsets.fromLTRB(
                                          21,
                                          16,
                                          21,
                                          16,
                                        )
                                      : const EdgeInsets.symmetric(
                                          horizontal: 29,
                                          vertical: 22,
                                        ),
                                  child: prompt,
                                ),
                              ),
                              const SizedBox(height: 11),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(33),
                                  ),
                                  alignment: Alignment.center,
                                  child: TextField(
                                    key: const ValueKey('answer-input'),
                                    controller: text,
                                    focusNode: focus,
                                    maxLines: null,
                                    minLines: 1,
                                    textAlign: TextAlign.center,
                                    // iOS shows a ✓ "done" key; it closes
                                    // the keyboard and keeps the answer.
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => focus.unfocus(),
                                    style: const TextStyle(
                                      fontFamily: 'CupertinoSystemDisplay',
                                      fontSize: 21,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      // Lines 26 pt apart (survey 143).
                                      height: 1.24,
                                      // An explicit value replaces SF Display's own tracking (about
                                      // 0.5 here); 0.75 matches survey 132.
                                      letterSpacing: .75,
                                    ),
                                    onChanged: (_) =>
                                        setState(() => lastGrade = null),
                                    decoration: InputDecoration(
                                      hintText: mode == StudyMode.writing
                                          ? 'Nhập bản dịch của bạn...'
                                          : 'Nhập câu trả lời...',
                                      hintStyle: TextStyle(
                                        fontFamily: 'CupertinoSystemDisplay',
                                        fontSize: 21,
                                        color: Colors.white.withValues(
                                          alpha: .45,
                                        ),
                                      ),
                                      fillColor: Colors.transparent,
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(22),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: constraints.maxHeight / 2 - 17,
                            left: constraints.maxWidth / 2 - 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                border: Border.all(
                                  color: D.background,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.swap_vert_rounded,
                                color: Colors.white,
                                size: 27,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // 47 pt under a sentence, 22 pt under a paragraph.
              SizedBox(height: mode == StudyMode.writing ? 22 : 47),
              // The bar (survey 139/143/159): a 44 x 35 undo key, ✨ once
              // there is text, speckled hint chips, and a 35 pt next button.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12.5),
                child: SizedBox(
                  height: 37,
                  child: Row(
                    children: [
                      _BarKey(
                        label: 'Câu trước',
                        width: 44,
                        onTap: index == 0 ? null : previous,
                        child: Icon(
                          CupertinoIcons.arrow_uturn_left,
                          size: 18,
                          color: index == 0 ? D.line : D.secondary,
                        ),
                      ),
                      if (text.text.trim().isNotEmpty) ...[
                        const SizedBox(width: 12),
                        _BarKey(
                          key: const ValueKey('ai-assist'),
                          label: 'Gợi ý AI',
                          width: 43,
                          onTap: assist,
                          child: const Icon(
                            CupertinoIcons.sparkles,
                            size: 22,
                            color: Palette.grammarAccent,
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: question.hints.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (_, i) {
                            final key = '$index-$i',
                                show =
                                    state.showHints || revealed.contains(key);
                            final word = question.hints[i];
                            return _BarKey(
                              label: show ? word : 'Gợi ý ẩn',
                              onTap: () => setState(() => revealed.add(key)),
                              padding: 15,
                              child: show
                                  // Revealed words are amber-brown (survey 150).
                                  ? Text(
                                      word,
                                      style: D.text(
                                        14,
                                        weight: FontWeight.w600,
                                        color: Palette.hintWord,
                                      ),
                                    )
                                  : _Speckle(word: word),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      _NextButton(
                        key: const ValueKey('submit-answer'),
                        busy: grading,
                        onTap: text.text.trim().isEmpty || busy ? null : submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        choice('like', CupertinoIcons.hand_thumbsup, 'Thích'),
        choice('dislike', CupertinoIcons.hand_thumbsdown, 'Không thích'),
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
    label: 'Chuyển tiếp',
    child: Tooltip(
      message: 'Chuyển tiếp',
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
    final where = 'Câu ${entry.sentences.join(', ')}';
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
                'Phát âm ${entry.word}',
                () => playWord(context, entry.word),
              ),
              const SizedBox(width: 8),
              round(CupertinoIcons.add, D.green, 'Lưu ${entry.word}', () {
                AppScope.read(context).saveWord(entry.word, entry.meaning);
                toast(context, 'Đã lưu ${entry.word}');
              }),
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
