import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../learning/learning.dart';
import 'preparing_view.dart';
import 'welcome_motion.dart';

part 'onboarding_demos.dart';
part 'onboarding_intro.dart';
part 'onboarding_steps.dart';

/// After the first sign-in: a welcome, four ways to practise to try
/// (flashcards first), then the learner's name, level and goals, then a
/// short wait while the answers are saved. The answers sync, so another
/// device signing in to the account skips this.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

const _nameStep = 5, _levelStep = 6, _goalStep = 7, _stepCount = 8;

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
                context.t.preparingSavingProfile(_name),
                context.t.preparingChoosingLessons(level ?? ''),
                context.t.preparingSorting,
              ],
              detail: context.t.preparingDetail,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 44,
                  child: step == 0
                      ? null
                      : _BackButton(onTap: () => _goTo(step - 1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Progress(step: step, count: _stepCount),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              key: const ValueKey('onboarding-pages'),
              controller: pages,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _WelcomeStep(active: step == 0),
                _FlashcardDemo(active: step == 1),
                _WritingDemo(active: step == 2),
                _GrammarDemo(active: step == 3),
                _ChatDemo(active: step == 4),
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
            child: SizedBox(
              height: 56,
              child: ActionButton(
                step == _stepCount - 1
                    ? context.t.finish
                    : context.t.continueStep,
                key: const ValueKey('onboarding-next'),
                trailing: step == _stepCount - 1
                    ? null
                    : CupertinoIcons.arrow_right,
                onTap: _canContinue ? _next : null,
              ),
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
    label: context.t.back,
    child: PressFade(
      key: const ValueKey('onboarding-back'),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: D.line.withValues(alpha: .6),
          shape: BoxShape.circle,
        ),
        child: const Icon(CupertinoIcons.chevron_back, size: 20, color: D.ink),
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
    label: context.t.stepOf(step + 1, count),
    child: Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 5,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: D.line,
                borderRadius: BorderRadius.circular(2.5),
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
                    borderRadius: BorderRadius.circular(2.5),
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

/// Step heading styles: a two-line title, ink then an accent color, and a
/// line of SF Pro under it.
final _titleStyle = D.text(
  26,
  weight: FontWeight.w800,
  spacing: -.6,
  height: 32 / 26,
);
final _bodyStyle = D.system(15, color: D.secondary, height: 21 / 15);

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

/// A step: its heading ([title] in ink, [accent] under it in
/// [accentColor], then [body]) writes itself when the step becomes
/// [active], then [children] come in through [_After]. With [fill] the
/// children share the height left instead of scrolling. Without autoplay
/// everything shows at once.
class _StepPage extends StatefulWidget {
  final bool active, fill;
  final String title, accent, body;
  final Color accentColor;
  final double gap;
  final List<Widget> children;
  const _StepPage({
    required this.active,
    required this.title,
    required this.accent,
    required this.accentColor,
    required this.body,
    required this.children,
    this.gap = 24,
    this.fill = false,
  });
  @override
  State<_StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<_StepPage>
    with SingleTickerProviderStateMixin {
  late final String _heading = '${widget.title}\n${widget.accent}';
  late final int _headingLength = _heading.characters.length;
  late final int _bodyLength = widget.body.characters.length;
  late final writing = AnimationController(
    vsync: this,
    duration:
        _titleChar * _headingLength + _titlePause + _bodyChar * _bodyLength,
  )..addListener(_tick);
  bool done = false;
  int _shown = 0;

  double _share(Duration d) =>
      d.inMicroseconds / writing.duration!.inMicroseconds;
  double get _titleEnd => _share(_titleChar * _headingLength);
  double get _bodyStart => _share(_titleChar * _headingLength + _titlePause);

  int get _titleChars => (_headingLength * (writing.value / _titleEnd))
      .floor()
      .clamp(0, _headingLength);
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
        : _heading.characters.elementAt(title - 1);
    _shown = shown;
    if (letter.trim().isNotEmpty) AppScope.read(context).feedback.tap();
  }

  @override
  void dispose() {
    writing.dispose();
    super.dispose();
  }

  /// The title and accent lines, written up to [count] characters.
  Widget _title(int count) {
    final titleLength = widget.title.characters.length;
    final accent = TextStyle(color: widget.accentColor);
    final full = Text.rich(
      TextSpan(
        style: _titleStyle,
        children: [
          TextSpan(text: '${widget.title}\n'),
          TextSpan(text: widget.accent, style: accent),
        ],
      ),
    );
    if (count >= _headingLength) return full;
    final shown = _heading.characters.take(count);
    return Semantics(
      label: '${widget.title} ${widget.accent}',
      excludeSemantics: true,
      child: Stack(
        children: [
          Opacity(opacity: 0, child: full),
          Text.rich(
            TextSpan(
              style: _titleStyle,
              children: [
                TextSpan(text: shown.take(titleLength + 1).toString()),
                TextSpan(
                  text: shown.skip(titleLength + 1).toString(),
                  style: accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
  Widget build(BuildContext context) {
    final heading = AnimatedBuilder(
      animation: writing,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: _title(_titleChars)),
          const SizedBox(height: 12),
          // The line under the title can change after writing, as the goal
          // count does, so a finished heading shows it whole.
          done
              ? Text(widget.body, style: _bodyStyle)
              : _written(widget.body, _bodyChars, _bodyStyle),
        ],
      ),
    );
    const padding = EdgeInsets.fromLTRB(24, 30, 24, 16);
    return _HeadingDone(
      done: done,
      child: widget.fill
          ? Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  SizedBox(height: widget.gap),
                  ...widget.children,
                ],
              ),
            )
          : SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  SizedBox(height: widget.gap),
                  ...widget.children,
                ],
              ),
            ),
    );
  }
}
