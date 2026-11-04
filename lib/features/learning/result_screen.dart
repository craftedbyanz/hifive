import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../widgets/blur_header.dart';
import '../../widgets/common.dart';
import '../../widgets/glyphs.dart';
import '../../widgets/medal.dart';
import 'learning.dart';

class ResultScreen extends StatelessWidget {
  final StudySession session;
  final bool fresh;
  const ResultScreen({super.key, required this.session, this.fresh = false});
  @override
  Widget build(BuildContext context) =>
      fresh ? _FreshResult(session: session) : _saved(context);

  /// A saved result (survey 76/80), shown in an iOS sheet from history.
  Widget _saved(BuildContext context) {
    final lesson = session.lesson;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final tint = switch (lesson.mode) {
      StudyMode.writing => D.purple,
      StudyMode.grammar => Palette.historyYellow,
      StudyMode.conversation => D.blue,
    };
    Widget stat(String value, String label, {Color color = D.ink}) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: D.text(19, weight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 5),
          Text(label, style: D.text(12, color: D.secondary)),
        ],
      ),
    );
    final rule = Container(width: 1, height: 34, color: D.line);
    Widget glassButton(IconData icon, String label, VoidCallback onTap) =>
        HeaderRoundButton(
          icon: icon,
          iconSize: icon == CupertinoIcons.back ? 28 : 20,
          label: label,
          width: 40,
          onTap: onTap,
        );
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 130),
            children: [
              Row(
                children: [
                  glassButton(
                    CupertinoIcons.back,
                    'Quay lại',
                    () => Navigator.of(context, rootNavigator: true).maybePop(),
                  ),
                  const Spacer(),
                  glassButton(CupertinoIcons.ellipsis, 'Thêm', () {}),
                ],
              ),
              const SizedBox(height: 14),
              // SF Pro Bold, as on the reference (survey 76).
              Text(
                lesson.title,
                style: const TextStyle(
                  fontFamily: 'CupertinoSystemDisplay',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lesson.mode.title.toUpperCase(),
                      style: D.text(
                        10,
                        weight: FontWeight.w700,
                        color: tint,
                        spacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const MiniFlag(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lesson.description,
                style: D.text(14, color: D.secondary, height: 1.25),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: D.line),
                ),
                child: Row(
                  children: [
                    stat(
                      '${session.accuracy}%',
                      'Độ chính xác',
                      color: session.accuracy >= 65 ? D.green : Palette.wrong,
                    ),
                    rule,
                    stat(
                      session.seconds == 0
                          ? '--:--'
                          : timeLabel(session.seconds),
                      'Thời gian',
                    ),
                    rule,
                    stat(
                      '${session.correct}/${session.scored.length}',
                      'Câu đúng',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (lesson.mode == StudyMode.writing) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    color: D.background,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.text_alignleft,
                            size: 15,
                            color: D.muted,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'VĂN BẢN GỐC',
                            style: D.text(
                              11,
                              weight: FontWeight.w700,
                              color: D.muted,
                              spacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lesson.questions.map((q) => q.prompt).join(' '),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: D.text(15, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
              ],
              Text(
                'CÂU TRẢ LỜI CỦA BẠN',
                style: D.text(
                  10,
                  weight: FontWeight.w700,
                  color: D.muted,
                  spacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: D.line),
              const SizedBox(height: 16),
              for (var i = 0; i < session.answers.length; i++)
                if (!lesson.questions[i].partner)
                  _SavedAnswer(
                    number: i + 1,
                    question: lesson.questions[i],
                    record: session.answers[i],
                    plain: lesson.mode == StudyMode.conversation,
                  ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0), Colors.white],
                  stops: const [0, .35],
                ),
              ),
              // The reference's free account reads "Nâng cấp để làm lại
              // bài tập" here and leads to Plus; the clone redoes the lesson.
              child: SizedBox(
                height: 55,
                child: ActionButton(
                  'Làm lại bài tập',
                  icon: CupertinoIcons.star_fill,
                  color: Palette.grammarAccent,
                  foreground: D.ink,
                  onTap: () => go<void>(
                    context,
                    lesson.mode == StudyMode.conversation
                        ? ChatScreen(lesson: lesson)
                        : PracticeScreen(lesson: lesson),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One saved answer: the prompt, what was typed after an arrow, and the
/// expected answer in green italics joined by a corner line (survey 76).
/// Conversation lines show the prompt only (survey 80).
class _SavedAnswer extends StatelessWidget {
  final int number;
  final Question question;
  final AnswerRecord record;
  final bool plain;
  const _SavedAnswer({
    required this.number,
    required this.question,
    required this.record,
    required this.plain,
  });
  @override
  Widget build(BuildContext context) {
    final good = record.firstScore >= .65;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: D.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 31,
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: D.text(14, color: D.muted),
                ),
              ),
              Expanded(
                child: Text(
                  question.prompt,
                  style: D.text(16, weight: FontWeight.w500, height: 1.3),
                ),
              ),
              if (!plain) ...[
                const SizedBox(width: 30),
                Icon(
                  good
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.exclamationmark_circle_fill,
                  size: 17,
                  color: good ? D.green : Palette.wrong,
                ),
              ],
            ],
          ),
          if (!plain && record.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 33),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.arrow_right,
                    size: 14,
                    color: D.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(record.text, style: D.text(16, height: 1.25)),
                  ),
                ],
              ),
            ),
            if (!good) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 39),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 14,
                      height: 16,
                      margin: const EdgeInsets.only(right: 9),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: D.green.withValues(alpha: .5),
                            width: 1.5,
                          ),
                          bottom: BorderSide(
                            color: D.green.withValues(alpha: .5),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        question.answer,
                        style: D
                            .text(16, color: D.green, height: 1.25)
                            .copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The result right after a lesson (survey 175): the lesson's title, the
/// medal in still confetti, "Excellent!", a white stats card, the answers as
/// plain rows and a floating "Tiếp tục". Only the excellent result was seen;
/// lower scores keep the clone's own lines.
class _FreshResult extends StatelessWidget {
  final StudySession session;
  const _FreshResult({required this.session});
  @override
  Widget build(BuildContext context) {
    final great = session.accuracy > 80;
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget stat(String value, String label, {Color color = D.ink}) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: D.text(19, weight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: D.text(12, color: D.secondary)),
        ],
      ),
    );
    final rule = Container(width: 1, height: 34, color: D.line);
    return Scaffold(
      backgroundColor: Palette.resultPage,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Center(
                    child: Text(
                      session.lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: D.text(16, weight: FontWeight.w700),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 100),
                    children: [
                      const SizedBox(
                        height: 330,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: StillConfettiPainter(),
                              ),
                            ),
                            CustomPaint(
                              size: Size(115, 150),
                              painter: MedalPainter(),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        great ? 'Excellent!' : 'Tiếp tục cố gắng!',
                        textAlign: TextAlign.center,
                        style: D.text(20, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        great
                            ? 'You have mastered this lesson'
                            : 'Mỗi buổi học là một bước tiến.',
                        textAlign: TextAlign.center,
                        style: D.text(14, color: D.secondary),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            stat(
                              '${session.accuracy}%',
                              'Độ chính xác',
                              color: D.green,
                            ),
                            rule,
                            stat(
                              session.seconds == 0
                                  ? '--:--'
                                  : timeLabel(session.seconds),
                              'Time',
                            ),
                            rule,
                            stat(
                              '${session.correct}/${session.scored.length}',
                              'Correct',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'CÂU TRẢ LỜI CỦA BẠN',
                        style: D.text(
                          10,
                          weight: FontWeight.w700,
                          color: D.muted,
                          spacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: D.line),
                      for (var i = 0; i < session.answers.length; i++)
                        if (!session.lesson.questions[i].partner)
                          _AnswerRow(
                            number: i + 1,
                            prompt: session.lesson.questions[i].prompt,
                            answer: session.answers[i].text,
                            good: session.answers[i].firstScore >= .65,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // The button floats over the list, which fades out beneath it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Palette.resultPage.withValues(alpha: 0),
                    Palette.resultPage,
                  ],
                  stops: const [0, .35],
                ),
              ),
              child: SizedBox(
                height: 52,
                child: ActionButton(
                  'Tiếp tục',
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final int number;
  final String prompt, answer;
  final bool good;
  const _AnswerRow({
    required this.number,
    required this.prompt,
    required this.answer,
    required this.good,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                number.toString().padLeft(2, '0'),
                style: D.text(14, color: D.muted),
              ),
            ),
            Expanded(child: Text(prompt, style: D.text(17, height: 1.3))),
            const SizedBox(width: 62),
            Icon(
              good
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.exclamationmark_circle_fill,
              size: 18,
              color: good ? D.green : D.orange,
            ),
          ],
        ),
        if (answer.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    CupertinoIcons.arrow_right,
                    size: 15,
                    color: D.secondary,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    answer,
                    style: D.text(17, color: D.ink, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
