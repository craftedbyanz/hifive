import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'completion_screen.dart';

/// Live conversation practice.
///
/// Laid out in the style of the other lesson screens and driven by
/// [ConversationRepository].
///
/// Even-index lines of the lesson are spoken by the partner; the learner
/// answers the others in English. In script mode the Vietnamese line to say is
/// shown; in free mode it stays hidden behind "Gợi ý".
class ChatScreen extends StatefulWidget {
  final Lesson lesson;
  const ChatScreen({super.key, required this.lesson});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _Message {
  final Question line;
  final String? answer;
  final Grade? grade;
  const _Message.partner(this.line) : answer = null, grade = null;
  const _Message.learner(this.line, this.answer, this.grade);
  bool get partner => answer == null;
}

class _ChatScreenState extends State<ChatScreen> {
  final text = TextEditingController();
  final focus = FocusNode();
  final scroll = ScrollController();
  final clock = Stopwatch()..start();
  final messages = <_Message>[];
  late final records = List<AnswerRecord?>.filled(
    widget.lesson.questions.length,
    null,
  );
  late final settings = AppScope.read(context).chatSettings;

  /// The line the learner must answer next, or the end of the lesson.
  int index = 0;
  bool waiting = false, hintShown = false, allowExit = false;
  String? failedAnswer;

  List<Question> get lines => widget.lesson.questions;

  @override
  void initState() {
    super.initState();
    _showPartnerLines(0);
  }

  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    scroll.dispose();
    clock.stop();
    super.dispose();
  }

  /// Shows partner lines from [from] up to the next learner line.
  void _showPartnerLines(int from) {
    var i = from;
    while (i < lines.length && lines[i].partner) {
      messages.add(_Message.partner(lines[i]));
      records[i] = AnswerRecord(lines[i].answer, 1, GradeKind.correct);
      i++;
    }
    index = i;
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> send([String? retry]) async {
    final answer = (retry ?? text.text).trim();
    if (answer.isEmpty || waiting || index >= lines.length) return;
    final state = AppScope.read(context);
    setState(() {
      waiting = true;
      failedAnswer = null;
      text.clear();
    });
    _scrollToEnd();
    try {
      final turn = await state.conversation.respond(
        language: state.language,
        lesson: widget.lesson,
        index: index,
        answer: answer,
        settings: settings,
      );
      if (!mounted) return;
      state.feedback.tap();
      setState(() {
        waiting = false;
        hintShown = false;
        messages.add(_Message.learner(lines[index], answer, turn.grade));
        records[index] = AnswerRecord(
          answer,
          turn.grade.score,
          turn.grade.kind,
        );
        _showPartnerLines(index + 1);
      });
      _scrollToEnd();
      if (index >= lines.length) _finish();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        waiting = false;
        failedAnswer = answer;
      });
    }
  }

  void _finish() {
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
  }

  Future<void> exit() async {
    if (await confirm(
      context,
      'Thoát hội thoại?',
      'Bạn chưa hoàn thành hội thoại. Tiến độ của phiên này sẽ không được lưu nếu bạn thoát bây giờ.',
    )) {
      if (!mounted) return;
      setState(() => allowExit = true);
      await Future<void>.delayed(Duration.zero);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final learnerLines = lines.where((l) => !l.partner).length;
    final done = records
        .asMap()
        .entries
        .where((e) => !lines[e.key].partner && e.value != null)
        .length;
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Thoát hội thoại',
                      onPressed: exit,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: D.muted,
                        size: 29,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.lesson.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: D.text(16, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${settings.freeChat ? 'Trò chuyện Tự do' : 'Chế độ Kịch bản'} · Giọng: ${settings.tone}',
                            style: D.text(11, color: D.muted),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$done/$learnerLines',
                        key: const ValueKey('chat-progress'),
                        textAlign: TextAlign.center,
                        style: D.text(13, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    for (final m in messages)
                      m.partner
                          ? _PartnerBubble(line: m.line)
                          : _LearnerBubble(message: m),
                    if (waiting) const _TypingBubble(),
                  ],
                ),
              ),
              if (failedAnswer != null)
                _FailureBar(onRetry: () => send(failedAnswer)),
              if (index < lines.length) _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    final line = lines[index];
    final showPrompt = !settings.freeChat || hintShown;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: D.ink.withValues(alpha: .06), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  showPrompt
                      ? 'Hãy nói: ${line.prompt}'
                      : 'Trả lời tự do bằng tiếng Anh',
                  key: const ValueKey('chat-prompt'),
                  style: D.text(
                    13,
                    color: showPrompt ? D.ink : D.muted,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              if (!showPrompt)
                TextButton(
                  key: const ValueKey('chat-hint'),
                  onPressed: () => setState(() => hintShown = true),
                  child: const Text('Gợi ý'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('chat-input'),
                  controller: text,
                  focusNode: focus,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => send(),
                  decoration: InputDecoration(
                    hintText: 'Nhập câu trả lời...',
                    filled: true,
                    fillColor: D.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              RoundButton(
                key: const ValueKey('chat-send'),
                icon: Icons.arrow_upward_rounded,
                label: 'Gửi',
                size: 46,
                color: text.text.trim().isEmpty || waiting ? D.line : D.ink,
                onTap: text.text.trim().isEmpty || waiting ? null : send,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartnerBubble extends StatefulWidget {
  final Question line;
  const _PartnerBubble({required this.line});
  @override
  State<_PartnerBubble> createState() => _PartnerBubbleState();
}

class _PartnerBubbleState extends State<_PartnerBubble> {
  bool translated = false;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 290),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: D.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.line.answer, style: D.text(16, weight: FontWeight.w600)),
          if (translated) ...[
            const SizedBox(height: 4),
            Text(widget.line.prompt, style: D.text(13, color: D.secondary)),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Nghe câu này',
                visualDensity: VisualDensity.compact,
                onPressed: () => playWord(context, widget.line.answer),
                icon: const Icon(Icons.volume_up_rounded, size: 18),
              ),
              IconButton(
                tooltip: translated ? 'Ẩn bản dịch' : 'Xem bản dịch',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => translated = !translated),
                icon: const Icon(Icons.translate_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _LearnerBubble extends StatefulWidget {
  final _Message message;
  const _LearnerBubble({required this.message});
  @override
  State<_LearnerBubble> createState() => _LearnerBubbleState();
}

class _LearnerBubbleState extends State<_LearnerBubble> {
  bool open = false;
  @override
  Widget build(BuildContext context) {
    final grade = widget.message.grade!;
    final color = switch (grade.kind) {
      GradeKind.correct => D.green,
      GradeKind.near => D.orange,
      GradeKind.incorrect => Palette.wrong,
    };
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => setState(() => open = !open),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 290),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: D.blue,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.message.answer!,
                style: D.text(16, weight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  grade.title,
                  style: D.text(11, weight: FontWeight.w700, color: color),
                ),
              ),
              if (open && grade.kind != GradeKind.correct) ...[
                const SizedBox(height: 8),
                Text(
                  'Gợi ý: ${widget.message.line.answer}',
                  style: D.text(13, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      key: const ValueKey('chat-typing'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: D.shadow,
      ),
      child: const CupertinoActivityIndicator(radius: 8),
    ),
  );
}

class _FailureBar extends StatelessWidget {
  final VoidCallback onRetry;
  const _FailureBar({required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    color: Palette.wrong.withValues(alpha: .08),
    padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Palette.wrong, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Không gửi được câu trả lời.',
            style: D.text(13, color: Palette.wrong),
          ),
        ),
        TextButton(
          key: const ValueKey('chat-retry'),
          onPressed: onRetry,
          child: const Text('Thử lại'),
        ),
      ],
    ),
  );
}
