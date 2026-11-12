import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'completion_screen.dart';
import 'dictionary.dart';
import 'grading_sheet.dart';

part 'practice_widgets.dart';

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
      context.t.leaveExerciseTitle,
      context.t.leaveExerciseBody,
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
      graded = await state.grading.grade(state.language, current, answer);
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
      grade: () => state.grading.grade(state.language, current, answer),
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
          SheetTitle(context.t.aiHint),
          SizedBox(
            height: 220,
            child: AsyncView<List<String>>(
              load: () => state.grading.assist(state.language, current, draft),
              loadingLabel: context.t.analysingDraft,
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
            dot: StudyMode.grammar.inputColor(c),
          ),
      ],
      title: context.t.backgroundColor,
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
        id: state.newId(),
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
                          context.t.lessonDictionary,
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
                                context.t.doneVi,
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
        GlassMenuItem(
          'color',
          context.t.backgroundColor,
          icon: Icons.palette_outlined,
          trailing: CupertinoIcons.chevron_right,
        ),
        GlassMenuItem(
          'hints',
          state.showHints ? context.t.hideHints : context.t.showHints,
          icon: CupertinoIcons.lightbulb,
        ),
        GlassMenuItem(
          'dictionary',
          context.t.lessonDictionary,
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
        toast(context, context.t.feedbackNoted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), mode = widget.lesson.mode;
    final color = mode.inputColor(state.inputColor);
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
                        tooltip: context.t.leaveExercise,
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
                          tooltip: context.t.lessonOptions,
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
                                          ? context.t.typeTranslation
                                          : context.t.typeAnswer,
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
                        label: context.t.previousSentence,
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
                          label: context.t.aiHint,
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
                              label: show ? word : context.t.hiddenHint,
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
