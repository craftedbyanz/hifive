import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/grading.dart';
import '../../domain/models/models.dart';
import '../../widgets/common.dart';
import 'dictionary.dart';

class FeedbackPanel extends StatefulWidget {
  final Question question;
  final String answer;
  final Grade grade;
  final StudyMode mode;

  /// Shows explanation and tips. Wrong answers open expanded; a correct one
  /// expands after "Xem phân tích AI".
  final bool expanded;
  final VoidCallback? onAnalyze;
  const FeedbackPanel({
    super.key,
    required this.question,
    required this.answer,
    required this.grade,
    required this.mode,
    this.expanded = false,
    this.onAnalyze,
  });
  @override
  State<FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<FeedbackPanel>
    with SingleTickerProviderStateMixin {
  /// A correct paragraph sentence opens with confetti over the sheet
  /// (survey 186); the grammar sheet has none (survey 141).
  late final burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.grade.kind == GradeKind.correct &&
        widget.mode == StudyMode.writing &&
        !widget.expanded) {
      burst.forward();
    }
  }

  @override
  void dispose() {
    burst.dispose();
    super.dispose();
  }

  late bool expanded = widget.expanded;
  int? rating;
  @override
  Widget build(BuildContext context) {
    final g = widget.grade, correct = g.kind == GradeKind.correct;
    // Before the analysis a correct answer shows as one sentence; with it,
    // as word chips under "SỬA LỖI" (survey 141/144).
    final plain = correct && !expanded;
    // "SỬA LỖI" is purple on a paragraph (survey 184), green on a sentence.
    final label = !plain && widget.mode == StudyMode.writing
        ? D.purple
        : D.green;
    final color = correct
        ? D.green
        : g.kind == GradeKind.near
        ? D.orange
        : Palette.wrong;
    final screen = MediaQuery.sizeOf(context);
    final sheet = Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(44),
        clipBehavior: Clip.antiAlias,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          // Tall enough that "Xem phân tích AI" is never under the buttons.
          height: screen.height * (expanded ? .68 : .40),
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 58,
                  height: 4,
                  decoration: BoxDecoration(
                    color: D.muted.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    correct
                        ? Icons.check_circle_rounded
                        : g.kind == GradeKind.near
                        ? Icons.thumb_up_rounded
                        : Icons.cancel_rounded,
                    color: color,
                    size: 34,
                  ),
                  const SizedBox(width: 13),
                  Text(
                    // The analysis titled the same correct answer "Xuất sắc"
                    // where the first grade said "Chính xác" (survey 144).
                    correct && expanded ? 'Xuất sắc' : g.title,
                    style: D.text(22, weight: FontWeight.w800, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Surface(
                        color: Palette.correctionBackground,
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  plain
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.sparkles,
                                  size: 13,
                                  color: label,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  plain ? 'CÂU TRẢ LỜI CỦA BẠN' : 'SỬA LỖI',
                                  style: D.text(
                                    10,
                                    weight: FontWeight.w700,
                                    color: label,
                                    spacing: 1,
                                  ),
                                ),
                                if (!plain) ...[
                                  const Spacer(),
                                  Text(
                                    'Chạm từ để tra cứu',
                                    style: D.text(9, color: D.muted),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            // A correct answer reads as one plain sentence
                            // (survey 141); corrections are word chips.
                            if (plain)
                              Text(widget.answer, style: _sf(17, height: 1.19))
                            else
                              Wrap(
                                spacing: 3,
                                runSpacing: 5,
                                children: [
                                  for (final token in diffWords(
                                    correct
                                        ? widget.question.answer
                                        : widget.answer,
                                    widget.question.answer,
                                  ))
                                    GestureDetector(
                                      onTap: () => showWord(
                                        context,
                                        token.text.replaceAll(
                                          RegExp(r'[^a-zA-ZÀ-ỹ]'),
                                          '',
                                        ),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              token.change == TokenChange.added
                                              ? D.green.withValues(alpha: .1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          token.text,
                                          // SF Pro, 15 pt (survey 134).
                                          style:
                                              _sf(
                                                15,
                                                weight: FontWeight.w500,
                                                color:
                                                    token.change ==
                                                        TokenChange.added
                                                    ? D.green
                                                    : token.change ==
                                                          TokenChange.removed
                                                    ? Palette.removedWord
                                                    : D.ink,
                                              ).copyWith(
                                                decoration:
                                                    token.change ==
                                                        TokenChange.removed
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 18),
                        const Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 6),
                          child: CapsLabel('GIẢI THÍCH', small: true),
                        ),
                        Text(
                          g.explanation,
                          style: _sf(
                            14,
                            weight: FontWeight.w500,
                            color: Palette.feedbackText,
                            height: 1.59,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 6),
                          child: CapsLabel(
                            widget.mode == StudyMode.writing
                                ? 'KEY IMPROVEMENTS'
                                : 'MẸO',
                            small: true,
                          ),
                        ),
                        for (final tip in [
                          'Giữ đúng ý và thời gian của câu gốc.',
                          'Đối chiếu chủ ngữ và động từ.',
                          'Chạm từ trong câu tham khảo để tra nghĩa.',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    // Purple under KEY IMPROVEMENTS
                                    // (survey 184), lime under MẸO.
                                    decoration: BoxDecoration(
                                      color: widget.mode == StudyMode.writing
                                          ? D.purple
                                          : Palette.grammarAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: _sf(
                                      14,
                                      weight: FontWeight.w500,
                                      color: Palette.feedbackTip,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Xem phân tích chi tiết từ AI cho câu trả lời của bạn.',
                            textAlign: TextAlign.center,
                            style: D.text(11, color: D.muted),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: GestureDetector(
                            key: const ValueKey('feedback-analyze'),
                            behavior: HitTestBehavior.opaque,
                            onTap:
                                widget.onAnalyze ??
                                () => setState(() => expanded = true),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.sparkles,
                                    size: 14,
                                    color: D.purple,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Xem phân tích AI',
                                    style: D.text(
                                      12,
                                      weight: FontWeight.w700,
                                      color: D.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (expanded) ...[
                    Expanded(
                      child: _SheetButton(
                        label: widget.mode == StudyMode.writing
                            ? 'Edit'
                            : 'Sửa',
                        leading: CupertinoIcons.pencil,
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _SheetButton(
                      key: const ValueKey('feedback-next'),
                      // Survey 186: a correct paragraph answer also reads
                      // "Câu tiếp theo"; Edit/Next appear with the analysis.
                      label: correct && !expanded
                          ? 'Câu tiếp theo'
                          : widget.mode == StudyMode.writing
                          ? 'Next'
                          : 'Tiếp theo',
                      trailing: correct && !expanded
                          ? CupertinoIcons.arrow_right
                          : CupertinoIcons.chevron_right,
                      dark: true,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
              // Thích / Không thích: 22 pt glyphs under the buttons
              // (survey 134), 11 pt above the sheet's edge.
              if (expanded) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Rate(
                      label: 'Hữu ích',
                      icon: rating == 1
                          ? CupertinoIcons.hand_thumbsup_fill
                          : CupertinoIcons.hand_thumbsup,
                      onTap: () => setState(() => rating = 1),
                    ),
                    const SizedBox(width: 18),
                    _Rate(
                      label: 'Chưa hữu ích',
                      icon: rating == -1
                          ? CupertinoIcons.hand_thumbsdown_fill
                          : CupertinoIcons.hand_thumbsdown,
                      onTap: () => setState(() => rating = -1),
                    ),
                  ],
                ),
              ] else
                const SizedBox(height: 33),
            ],
          ),
        ),
      ),
    );
    return Stack(
      children: [
        sheet,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: burst,
              builder: (_, _) => burst.value == 0 || burst.value == 1
                  ? const SizedBox.shrink()
                  : CustomPaint(painter: ConfettiPainter(burst.value)),
            ),
          ),
        ),
      ],
    );
  }
}

/// SF Pro text, as the reference sets the feedback body.
TextStyle _sf(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = D.ink,
  double? height,
}) => TextStyle(
  fontFamily: size >= 20 ? 'CupertinoSystemDisplay' : 'CupertinoSystemText',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  // SF Pro Text's optical tracking, which Flutter does not apply itself.
  letterSpacing: size >= 15 ? -.23 : -.15,
);

class _Rate extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _Rate({required this.label, required this.icon, required this.onTap});
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
        child: SizedBox(
          width: 22,
          height: 23,
          child: Icon(icon, size: 22, color: D.muted),
        ),
      ),
    ),
  );
}

/// The sheet's pill buttons: white with a small leading pencil for Sửa, ink
/// with a trailing chevron or arrow for going on (survey 134/141/144).
class _SheetButton extends StatelessWidget {
  final String label;
  final IconData? leading, trailing;
  final bool dark;
  final VoidCallback onTap;
  const _SheetButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.trailing,
    this.dark = false,
  });
  @override
  Widget build(BuildContext context) {
    final ink = dark ? Colors.white : D.ink;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 49,
          decoration: BoxDecoration(
            color: dark ? D.ink : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: dark ? null : Border.all(color: D.line),
            boxShadow: [
              BoxShadow(
                color: D.ink.withValues(alpha: dark ? .18 : .06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 17, color: ink),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: D.text(16, weight: FontWeight.w700, color: ink),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, size: 17, color: ink),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
