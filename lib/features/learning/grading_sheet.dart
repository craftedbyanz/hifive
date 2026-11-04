import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import 'feedback_panel.dart';

/// The feedback sheet. The answer is graded before it opens (the next
/// button spins meanwhile, survey 140/143) and arrives as [initial]; without
/// one, as after a failure, the sheet grades itself. "Xem phân tích AI" runs
/// [grade] again and shows "Đang chấm điểm..." with Huỷ meanwhile (survey 142);
/// Huỷ there returns to the feedback.
///
/// Pops `true` to advance, `false` to edit, and null when cancelled.
class GradingSheet extends StatefulWidget {
  final Question question;
  final String answer;
  final StudyMode mode;
  final Future<Grade> Function() grade;
  final ValueChanged<Grade> onGraded;
  final Grade? initial;
  const GradingSheet({
    this.initial,
    super.key,
    required this.question,
    required this.answer,
    required this.mode,
    required this.grade,
    required this.onGraded,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Question question,
    required String answer,
    required StudyMode mode,
    required Future<Grade> Function() grade,
    required ValueChanged<Grade> onGraded,
    Grade? initial,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Palette.sheetBarrier,
    showDragHandle: false,
    builder: (_) => GradingSheet(
      question: question,
      answer: answer,
      mode: mode,
      grade: grade,
      onGraded: onGraded,
      initial: initial,
    ),
  );

  @override
  State<GradingSheet> createState() => _GradingSheetState();
}

class _GradingSheetState extends State<GradingSheet> {
  late Grade? result = widget.initial;
  Object? error;
  late bool loading = result == null, reported = result != null;
  bool analysed = false;

  /// Bumped by Huỷ so a late answer from the cancelled run is ignored.
  int run = 0;

  void _cancel() {
    run++;
    if (result == null) {
      Navigator.pop(context);
    } else {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (result == null) _run();
  }

  Future<void> _run({bool analysis = false}) async {
    final mine = ++run;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final grade = await widget.grade();
      // A grade arriving after Huỷ must not count.
      if (!mounted || mine != run) return;
      if (!reported) {
        reported = true;
        widget.onGraded(grade);
      }
      setState(() {
        result = grade;
        loading = false;
        analysed = analysed || analysis;
      });
    } catch (e) {
      if (!mounted || mine != run) return;
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return _GradingPlaceholder(onCancel: _cancel);
    if (error != null) {
      return _SheetFrame(
        child: Column(
          children: [
            Expanded(
              child: EmptyView(
                title: 'Không chấm được câu trả lời',
                subtitle: 'Kết nối hoặc dịch vụ AI đang gặp sự cố.',
                icon: Icons.cloud_off_rounded,
                action: SizedBox(
                  width: 180,
                  child: ActionButton(
                    'Thử lại',
                    key: const ValueKey('grading-retry'),
                    icon: Icons.refresh_rounded,
                    onTap: () => _run(analysis: result != null),
                  ),
                ),
              ),
            ),
            ActionButton(
              'Huỷ',
              key: const ValueKey('grading-cancel'),
              outlined: true,
              onTap: _cancel,
            ),
          ],
        ),
      );
    }
    return FeedbackPanel(
      key: ValueKey(analysed),
      question: widget.question,
      answer: widget.answer,
      grade: result!,
      mode: widget.mode,
      expanded: analysed || result!.kind != GradeKind.correct,
      onAnalyze: () => _run(analysis: true),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  final Widget child;
  const _SheetFrame({required this.child});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(44),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: MediaQuery.sizeOf(context).height * .68,
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 22),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 4,
              decoration: BoxDecoration(
                color: D.muted.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class _GradingPlaceholder extends StatelessWidget {
  final VoidCallback onCancel;
  const _GradingPlaceholder({required this.onCancel});
  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor, {double height = 14}) =>
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: D.line.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        );
    return _SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CupertinoActivityIndicator(radius: 12),
              const SizedBox(width: 12),
              Text(
                'Đang chấm điểm...',
                style: D.text(22, weight: FontWeight.w800, color: D.muted),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Surface(
            color: Palette.correctionBackground,
            radius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✦  SỬA LỖI',
                  style: D.text(
                    10,
                    weight: FontWeight.w700,
                    color: D.muted,
                    spacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                bar(1, height: 18),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 6),
            child: CapsLabel('GIẢI THÍCH', small: true),
          ),
          bar(1),
          bar(.6),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 6),
            child: CapsLabel('MẸO', small: true),
          ),
          bar(.72),
          bar(.6),
          const Spacer(),
          ActionButton(
            'Huỷ',
            key: const ValueKey('grading-cancel'),
            outlined: true,
            onTap: onCancel,
          ),
        ],
      ),
    );
  }
}
