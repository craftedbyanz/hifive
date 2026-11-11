import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../learning/learning.dart';
import 'preparing_view.dart';
import 'welcome_motion.dart';

part 'onboarding_demos.dart';
part 'onboarding_steps.dart';

/// After the first sign-in: three modes to try, then the learner's name,
/// level and goals, then a short wait while the answers are saved. The
/// answers sync, so another device signing in to the account skips this.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

const _nameStep = 3, _levelStep = 4, _goalStep = 5, _stepCount = 6;

/// The longest name, as on Profile.
const _maxName = 12;

/// How many goals a learner can pick.
const _maxGoals = 3;

/// How long the closing wait lasts; it saves instantly, so this is only long
/// enough to read its lines.
const _preparing = Duration(milliseconds: 2800);

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  bool preparing = false;
  final pages = PageController();
  late final name = TextEditingController(text: _suggestedName());
  final nameFocus = FocusNode();
  String? level;
  final goals = <String>[];

  /// The account's first name when it has one that fits.
  String _suggestedName() {
    final full = AppScope.read(context).user?.displayName?.trim() ?? '';
    if (full.characters.length <= _maxName) return full;
    // Vietnamese names end with the given name.
    final last = full.split(RegExp(r'\s+')).last;
    return last.characters.length <= _maxName ? last : '';
  }

  @override
  void dispose() {
    pages.dispose();
    name.dispose();
    nameFocus.dispose();
    super.dispose();
  }

  String get _name => name.text.trim();

  bool get _canContinue => switch (step) {
    _nameStep => _name.isNotEmpty && _name.characters.length <= _maxName,
    _levelStep => level != null,
    _goalStep => goals.isNotEmpty,
    _ => true,
  };

  void _goTo(int target) {
    FocusScope.of(context).unfocus();
    setState(() => step = target);
    if (MediaQuery.disableAnimationsOf(context)) {
      pages.jumpToPage(target);
    } else {
      pages.animateToPage(
        target,
        duration: welcomeTurn,
        curve: Curves.easeOutCubic,
      );
    }
    if (target == _nameStep && name.text.isEmpty) nameFocus.requestFocus();
  }

  void _next() {
    if (!_canContinue) return;
    if (step < _stepCount - 1) {
      _goTo(step + 1);
    } else {
      FocusScope.of(context).unfocus();
      setState(() => preparing = true);
    }
  }

  void _finish() =>
      AppScope.read(context)
          .completeOnboarding(name: _name, level: level!, goals: goals);

  void _toggleGoal(String id) => setState(() {
    if (!goals.remove(id) && goals.length < _maxGoals) goals.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: still ? Duration.zero : welcomeTurn,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      child: preparing
          ? PreparingView(
              key: const ValueKey('onboarding-preparing'),
              steps: [
                'Đang lưu hồ sơ của $_name',
                'Chọn bài học trình độ $level',
                'Sắp xếp theo mục tiêu của bạn',
              ],
              detail: 'Chỉ một chút nữa thôi.',
              duration: _preparing,
              onDone: _finish,
            )
          : _steps(context),
    );
  }

  Widget _steps(BuildContext context) => Scaffold(
    key: const ValueKey('onboarding-steps'),
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 6),
                SizedBox(
                  width: 44,
                  child: step == 0
                      ? null
                      : _BackButton(onTap: () => _goTo(step - 1)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _Progress(step: step, count: _stepCount),
                ),
                const SizedBox(width: 56),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              key: const ValueKey('onboarding-pages'),
              controller: pages,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _WritingDemo(active: step == 0),
                _GrammarDemo(active: step == 1),
                _ChatDemo(active: step == 2),
                _NameStep(
                  active: step == _nameStep,
                  controller: name,
                  focus: nameFocus,
                  onChanged: () => setState(() {}),
                  onSubmitted: _next,
                ),
                _LevelStep(
                  active: step == _levelStep,
                  selected: level,
                  onSelect: (v) => setState(() => level = v),
                ),
                _GoalStep(
                  active: step == _goalStep,
                  selected: goals,
                  onToggle: _toggleGoal,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
            child: ActionButton(
              step == _stepCount - 1 ? 'Hoàn tất' : 'Tiếp tục',
              key: const ValueKey('onboarding-next'),
              onTap: _canContinue ? _next : null,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Quay lại',
    child: PressFade(
      key: const ValueKey('onboarding-back'),
      onTap: onTap,
      child: const SizedBox.square(
        dimension: 44,
        child: Icon(CupertinoIcons.chevron_back, size: 22, color: D.ink),
      ),
    ),
  );
}

/// One bar per step; bars up to the current one fill in.
class _Progress extends StatelessWidget {
  final int step, count;
  const _Progress({required this.step, required this.count});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Bước ${step + 1} trên $count',
    child: Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 4,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: D.line,
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedFractionallySizedBox(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : welcomeEnter,
                curve: Curves.easeOutCubic,
                widthFactor: i <= step ? 1 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: D.ink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// How fast a step's heading writes itself: the title a character at a
/// time with a haptic tick each, then the line under it, faster.
const _titleChar = Duration(milliseconds: 45);
const _bodyChar = Duration(milliseconds: 12);
const _titlePause = Duration(milliseconds: 160);

/// Whether the heading of the enclosing [_StepPage] has finished writing.
class _HeadingDone extends InheritedWidget {
  final bool done;
  const _HeadingDone({required this.done, required super.child});
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HeadingDone>()?.done ?? true;
  @override
  bool updateShouldNotify(_HeadingDone old) => done != old.done;
}

/// Fades a step's content in once its heading has written itself, after
/// [delay].
class _After extends StatelessWidget {
  final Duration delay;
  final Widget child;
  const _After({required this.child, this.delay = Duration.zero});
  @override
  Widget build(BuildContext context) =>
      Reveal(active: _HeadingDone.of(context), delay: delay, child: child);
}

/// A step: its heading (an optional mode tag, the title and a line under
/// it) writes itself when the step becomes [active], then [children] come
/// in through [_After]. Without autoplay everything shows at once.
class _StepPage extends StatefulWidget {
  final bool active;
  final StudyMode? mode;
  final String title, body;
  final double gap;
  final List<Widget> children;
  const _StepPage({
    required this.active,
    required this.title,
    required this.body,
    required this.children,
    this.mode,
    this.gap = 24,
  });
  @override
  State<_StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<_StepPage>
    with SingleTickerProviderStateMixin {
  static const _modeNames = {
    StudyMode.writing: 'LUYỆN VIẾT',
    StudyMode.grammar: 'NGỮ PHÁP',
    StudyMode.conversation: 'HỘI THOẠI',
  };

  late final int _titleLength = widget.title.characters.length;
  late final int _bodyLength = widget.body.characters.length;
  late final writing = AnimationController(
    vsync: this,
    duration: _titleChar * _titleLength + _titlePause + _bodyChar * _bodyLength,
  )..addListener(_tick);
  bool done = false;
  int _shown = 0;

  /// The share of the timeline when the title is written.
  double get _titleEnd =>
      (_titleChar * _titleLength).inMicroseconds /
      writing.duration!.inMicroseconds;
  double get _bodyStart =>
      (_titleChar * _titleLength + _titlePause).inMicroseconds /
      writing.duration!.inMicroseconds;

  int get _titleChars => (_titleLength * (writing.value / _titleEnd))
      .floor()
      .clamp(0, _titleLength);
  int get _bodyChars =>
      (_bodyLength * ((writing.value - _bodyStart) / (1 - _bodyStart)))
          .floor()
          .clamp(0, _bodyLength);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _start();
  }

  @override
  void didUpdateWidget(_StepPage old) {
    super.didUpdateWidget(old);
    _start();
  }

  void _start() {
    if (!widget.active || done || writing.isAnimating) return;
    if (!welcomeAutoplay(context)) {
      writing.value = 1;
      done = true;
      return;
    }
    writing.forward().whenComplete(() {
      if (mounted) setState(() => done = true);
    });
  }

  /// A tick for each new letter of the title and every third of the line
  /// under it, so the writing can be felt.
  void _tick() {
    final title = _titleChars, body = _bodyChars;
    final shown = title + body;
    if (shown == _shown) return;
    final letter = body > 0
        ? (body % 3 == 0 ? widget.body.characters.elementAt(body - 1) : ' ')
        : widget.title.characters.elementAt(title - 1);
    _shown = shown;
    if (letter.trim().isNotEmpty) AppScope.read(context).feedback.tap();
  }

  @override
  void dispose() {
    writing.dispose();
    super.dispose();
  }

  /// [text] written up to [count] characters over its full, hidden copy, so
  /// the layout never moves while it writes; once written, just the text.
  Widget _written(String text, int count, TextStyle style) =>
      count >= text.characters.length
      ? Text(text, style: style)
      : Semantics(
          label: text,
          excludeSemantics: true,
          child: Stack(
            children: [
              Opacity(opacity: 0, child: Text(text, style: style)),
              Text(text.characters.take(count).toString(), style: style),
            ],
          ),
        );

  @override
  Widget build(BuildContext context) => _HeadingDone(
    done: done,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.mode case final StudyMode m) ...[
            Reveal(
              active: widget.active,
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: m.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(m.icon, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  CapsLabel(_modeNames[m]!, color: m.color),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          AnimatedBuilder(
            animation: writing,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: _written(
                    widget.title,
                    _titleChars,
                    D.text(
                      28,
                      weight: FontWeight.w800,
                      spacing: -.5,
                      height: 34 / 28,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // The line under the title can change after writing, as the
                // goal count does, so a finished heading shows it whole.
                done
                    ? Text(
                        widget.body,
                        style: D.text(15, color: D.secondary, height: 21 / 15),
                      )
                    : _written(
                        widget.body,
                        _bodyChars,
                        D.text(15, color: D.secondary, height: 21 / 15),
                      ),
              ],
            ),
          ),
          SizedBox(height: widget.gap),
          ...widget.children,
        ],
      ),
    ),
  );
}
