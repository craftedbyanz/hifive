part of 'welcome_screen.dart';

/// One demo on the sign-in screen: its tint, words and art.
class _Scene {
  final Color color;
  final String title, body;
  const _Scene(this.color, this.title, this.body);
}

const _sceneCount = 3;

List<_Scene> _scenesOf(AppLocalizations t) => [
  _Scene(StudyMode.writing.color, t.sceneWritingTitle, t.sceneWritingBody),
  _Scene(StudyMode.conversation.color, t.sceneChatTitle, t.sceneChatBody),
  _Scene(D.purple, t.sceneWordsTitle, t.sceneWordsBody),
];

/// One demo's timeline; the screen then holds the last frame until
/// [_sceneHold] moves on.
const _sceneLength = Duration(milliseconds: 4000);

/// Plays one demo once. Without autoplay it shows the finished frame.
class _SceneArt extends StatefulWidget {
  final int index;
  const _SceneArt({required this.index});
  @override
  State<_SceneArt> createState() => _SceneArtState();
}

class _SceneArtState extends State<_SceneArt>
    with SingleTickerProviderStateMixin {
  late final timeline = AnimationController(
    vsync: this,
    duration: _sceneLength,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (welcomeAutoplay(context)) {
      if (!timeline.isAnimating && timeline.value == 0) timeline.forward();
    } else {
      timeline.value = 1;
    }
  }

  @override
  void dispose() {
    timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: timeline,
      builder: (context, _) => switch (widget.index) {
        0 => _WritingScene(timeline.value),
        1 => _ChatScene(timeline.value),
        _ => _CardsScene(timeline.value),
      },
    ),
  );
}

/// White card with the standard outline and card shadow.
BoxDecoration _card({double radius = 22}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: D.line),
  boxShadow: D.shadow,
);

/// The part of [text] typed by [progress] (0 to 1), with a caret while
/// typing.
String _typed(String text, double progress, {bool caret = true}) {
  final n = (text.length * progress).round();
  final typing = progress > 0 && progress < 1;
  return text.substring(0, n) + (caret && typing ? '|' : '');
}

/// A Vietnamese sentence, the learner's English typed below it, then a
/// score badge.
class _WritingScene extends StatelessWidget {
  final double t;
  const _WritingScene(this.t);
  static const _answer = "Let's go to the beach this weekend!";
  static final _answerStyle = D.text(
    17,
    weight: FontWeight.w600,
    height: 23 / 17,
  );

  @override
  Widget build(BuildContext context) {
    final blue = StudyMode.writing.color;
    final badge = phase(t, .66, .78, Curves.easeOutBack);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 28,
          top: 6,
          child: appear(
            phase(t, 0, .1),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: _card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CapsLabel(context.t.demoSourceLanguage),
                  const SizedBox(height: 8),
                  Text(
                    context.t.demoSourceSentence,
                    style: D.text(17, weight: FontWeight.w600, height: 23 / 17),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 150,
          top: 104,
          child: Opacity(
            opacity: phase(t, .1, .18),
            child: Icon(CupertinoIcons.arrow_down, size: 20, color: blue),
          ),
        ),
        Positioned(
          left: 28,
          right: 0,
          top: 136,
          child: appear(
            phase(t, .14, .24),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: _card().copyWith(
                border: Border.all(
                  color: blue.withValues(alpha: .45),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CapsLabel(context.t.demoYouWrote, color: blue),
                  const SizedBox(height: 8),
                  // The whole sentence with its caret, hidden, sizes the
                  // card while the line types over it, so neither the card
                  // nor the wrap moves.
                  Stack(
                    children: [
                      Opacity(
                        opacity: 0,
                        child: Text('$_answer|', style: _answerStyle),
                      ),
                      Text(
                        _typed(_answer, phase(t, .24, .62, Curves.linear)),
                        style: _answerStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 252,
          child: Transform.scale(
            scale: badge,
            child: Opacity(
              opacity: badge.clamp(0.0, 1.0),
              child: _Pill(
                icon: CupertinoIcons.checkmark_alt,
                text: context.t.demoNatural,
                color: D.green,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A partner question, the learner's answer with one mistake, the fix, and
/// the partner carrying on.
class _ChatScene extends StatelessWidget {
  final double t;
  const _ChatScene(this.t);

  @override
  Widget build(BuildContext context) {
    final cyan = StudyMode.conversation.color;
    final fix = phase(t, .5, .62);
    final base = D.text(15, weight: FontWeight.w600, height: 20 / 15);
    final answer = Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'I '),
          TextSpan(
            text: 'go',
            style: fix > 0
                ? base.copyWith(
                    color: Color.lerp(D.ink, Palette.wrong, fix),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Palette.wrong,
                  )
                : null,
          ),
          if (fix > 0)
            TextSpan(
              text: ' went',
              style: base.copyWith(color: D.green.withValues(alpha: fix)),
            ),
          const TextSpan(text: ' to the beach.'),
        ],
      ),
    );
    final typing = phase(t, .16, .4, Curves.linear);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        appear(
          phase(t, 0, .1),
          _Bubble(
            partner: true,
            color: cyan,
            child: Text('What did you do last weekend?', style: base),
          ),
        ),
        const SizedBox(height: 12),
        appear(
          phase(t, .12, .2),
          _Bubble(
            partner: false,
            color: cyan,
            child: typing < 1
                ? Text(_typed('I go to the beach.', typing), style: base)
                : answer,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: appear(
            phase(t, .6, .7),
            _Pill(
              icon: CupertinoIcons.lightbulb,
              text: context.t.demoPastTense,
              color: D.purple,
            ),
          ),
        ),
        const SizedBox(height: 12),
        appear(
          phase(t, .74, .84),
          _Bubble(
            partner: true,
            color: cyan,
            child: Text('Nice! Was the water warm?', style: base),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool partner;
  final Color color;
  final Widget child;
  const _Bubble({
    required this.partner,
    required this.color,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: partner
        ? MainAxisAlignment.start
        : MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (partner) ...[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(
            StudyMode.conversation.icon,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
      ],
      Flexible(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 270),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: partner
              ? _card(radius: 20)
              : BoxDecoration(
                  color: color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(20),
                ),
          child: child,
        ),
      ),
    ],
  );
}

/// A word card flips to its meaning, the learner rates it, and the next
/// review is set further out.
class _CardsScene extends StatelessWidget {
  final double t;
  const _CardsScene(this.t);

  @override
  Widget build(BuildContext context) {
    final flip = phase(t, .2, .38, Curves.easeInOutCubic);
    final back = flip > .5;
    final pick = phase(t, .62, .7);
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // The deck behind the card.
        for (final (i, angle) in [(0, -.09), (1, .07)])
          Positioned(
            top: 14.0 + i * 4,
            child: Transform.rotate(
              angle: angle * phase(t, 0, .12),
              child: Container(
                width: 230,
                height: 150,
                decoration: _card(radius: 24),
              ),
            ),
          ),
        Positioned(
          top: 14,
          child: appear(
            phase(t, 0, .1),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0012)
                ..rotateY(pi * flip),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(back ? pi : 0),
                child: Container(
                  width: 230,
                  height: 150,
                  decoration: _card(radius: 24),
                  alignment: Alignment.center,
                  child: back
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.t.demoRememberMeaning,
                              style: D.text(
                                26,
                                weight: FontWeight.w800,
                                height: 32 / 26,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Remember to call me.',
                              style: D.text(
                                14,
                                color: D.secondary,
                                height: 18 / 14,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'remember',
                              style: D.text(
                                26,
                                weight: FontWeight.w800,
                                height: 32 / 26,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '/rɪˈmembər/',
                              style: D.text(
                                14,
                                color: D.secondary,
                                height: 18 / 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 190,
          child: Row(
            children: [
              for (final (i, label) in [
                context.t.rateHard,
                context.t.rateOkay,
                context.t.rateEasy,
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                appear(
                  phase(t, .42 + i * .04, .52 + i * .04),
                  Transform.scale(
                    scale: i == 2 ? 1 + .08 * sin(pi * pick) : 1,
                    child: Container(
                      width: 76,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 2 && pick > 0
                            ? Color.lerp(Colors.white, D.green, pick)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: D.line),
                      ),
                      child: Text(
                        label,
                        style: D.text(
                          14,
                          weight: FontWeight.w700,
                          color: i == 2 && pick > .5 ? Colors.white : D.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: 246,
          child: appear(
            phase(t, .74, .84),
            _Pill(
              icon: CupertinoIcons.calendar,
              text: context.t.reviewInDays(4),
              color: D.purple,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 20,
          child: Transform.scale(
            scale: phase(t, .84, .94, Curves.easeOutBack),
            child: _Pill(
              leading: const StreakFlame(size: 18),
              text: context.t.streakDays(7),
              color: D.orange,
            ),
          ),
        ),
      ],
    );
  }
}

/// A short status pill: a white fill with the color's icon, or [leading]
/// in its place, and dark words.
class _Pill extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String text;
  final Color color;
  const _Pill({
    this.icon,
    this.leading,
    required this.text,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: .35)),
        boxShadow: D.shadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading ?? Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: D.text(
              13,
              weight: FontWeight.w700,
              color: D.ink,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
