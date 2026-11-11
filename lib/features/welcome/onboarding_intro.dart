part of 'onboarding_screen.dart';

/// Card stacks on the welcome and flashcard steps: the front card at most
/// this size, with the cards behind peeking out below it.
const _stackCard = Size(300, 380);
const _stackPeek = 20.0;

/// Where a card sits at depth [d]: 0 in front, 1 and 2 behind it, a
/// fraction while the stack moves. Behind cards drop, shrink and pale.
Widget _atDepth(double d, Widget card) {
  final behind = d.clamp(0.0, 3.0);
  return Transform.translate(
    offset: Offset(0, _stackPeek * behind),
    child: Transform.scale(
      scale: 1 - .06 * behind,
      alignment: Alignment.bottomCenter,
      child: Opacity(
        // The third card fades in from nothing as it joins.
        opacity: (3 - behind).clamp(0.0, 1.0),
        child: Stack(
          children: [
            card,
            if (behind > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: min(.55, .3 * behind),
                      ),
                      borderRadius: BorderRadius.circular(34),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The largest card that fits [box] with room for the peeking cards.
Size _cardSize(BoxConstraints box) {
  final height = min(_stackCard.height, box.maxHeight - 2 * _stackPeek);
  final width = min(_stackCard.width, box.maxWidth);
  return Size(width, max(0, height));
}

/// Runs [controller] to [target], or jumps there under Reduce Motion.
TickerFuture _drive(
  BuildContext context,
  AnimationController controller,
  double target,
) {
  if (MediaQuery.disableAnimationsOf(context)) {
    controller.value = target;
    return TickerFuture.complete();
  }
  return controller.animateTo(target);
}

class _WelcomeStep extends StatelessWidget {
  final bool active;
  const _WelcomeStep({required this.active});
  @override
  Widget build(BuildContext context) => _StepPage(
    active: active,
    fill: true,
    title: 'Chào mừng',
    accent: 'đến với Hifive',
    accentColor: D.blue,
    body: 'Học ngoại ngữ bằng cách viết, nói và ôn từ mỗi ngày. Bốn cách luyện tập giúp bạn tiến bộ tự nhiên, từng chút một.',
    gap: 22,
    children: [
      Expanded(
        child: _After(child: _PracticeStack(active: active)),
      ),
    ],
  );
}

/// One way to practise on the welcome stack.
class _Practice {
  final Color color;
  final IconData icon;
  final String title, line;
  final _Preview preview;
  const _Practice(this.color, this.icon, this.title, this.line, this.preview);
}

enum _Preview { writing, grammar, chat, cards }

final _practices = [
  _Practice(
    StudyMode.writing.color,
    StudyMode.writing.icon,
    'Viết đoạn văn',
    'Dịch và viết lại từng câu theo chủ đề bạn thích.',
    _Preview.writing,
  ),
  _Practice(
    StudyMode.grammar.color,
    StudyMode.grammar.icon,
    'Sửa câu',
    'Câu ngắn, sửa nhanh, hiểu vì sao sai.',
    _Preview.grammar,
  ),
  _Practice(
    Palette.chatBlue,
    StudyMode.conversation.icon,
    'Hội thoại',
    'Đóng vai trong những tình huống thật.',
    _Preview.chat,
  ),
  const _Practice(
    D.purple,
    CupertinoIcons.square_stack_3d_up_fill,
    'Thẻ từ vựng',
    'Lưu từ mới, ôn đúng lúc sắp quên.',
    _Preview.cards,
  ),
];

/// The four ways to practise as a stack that deals the front card away
/// every few seconds, or on a tap.
class _PracticeStack extends StatefulWidget {
  final bool active;
  const _PracticeStack({required this.active});
  @override
  State<_PracticeStack> createState() => _PracticeStackState();
}

/// How long each practice card stays in front while the stack autoplays.
const _dealEvery = Duration(milliseconds: 2800);

class _PracticeStackState extends State<_PracticeStack>
    with SingleTickerProviderStateMixin {
  int front = 0;
  late final deal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(_PracticeStack old) {
    super.didUpdateWidget(old);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!widget.active || !welcomeAutoplay(context)) return;
    _timer = Timer.periodic(_dealEvery, (_) => _deal());
  }

  Future<void> _deal() async {
    if (deal.isAnimating) return;
    await _drive(context, deal, 1);
    if (!mounted) return;
    setState(() => front = (front + 1) % _practices.length);
    deal.value = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    deal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = _cardSize(box);
      return Semantics(
        button: true,
        label: _practices[front].title,
        hint: 'Chạm để xem cách học tiếp theo',
        child: GestureDetector(
          key: const ValueKey('onboarding-practice-stack'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppScope.read(context).feedback.tap();
            _schedule();
            _deal();
          },
          child: AnimatedBuilder(
            animation: deal,
            builder: (context, _) {
              final t = Curves.easeInOutCubic.transform(deal.value);
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  for (var k = 3; k >= 0; k--)
                    if (k == 0)
                      // The front card is dealt away up and to the left.
                      Transform.translate(
                        offset: Offset(-90 * t, -40 * t),
                        child: Transform.rotate(
                          angle: -.2 * t,
                          child: Opacity(
                            opacity: 1 - t,
                            child: _PracticeCard(
                              _practices[front],
                              size: size,
                              number: front + 1,
                            ),
                          ),
                        ),
                      )
                    else
                      _atDepth(
                        k - t,
                        _PracticeCard(
                          _practices[(front + k) % _practices.length],
                          size: size,
                          number: (front + k) % _practices.length + 1,
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

class _PracticeCard extends StatelessWidget {
  final _Practice practice;
  final Size size;
  final int number;
  const _PracticeCard(
    this.practice, {
    required this.size,
    required this.number,
  });
  @override
  Widget build(BuildContext context) {
    final c = practice.color;
    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, Color.lerp(c, D.ink, .28)!],
        ),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: .28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  shape: BoxShape.circle,
                ),
                child: Icon(practice.icon, size: 22, color: Colors.white),
              ),
              const Spacer(),
              Text(
                '$number/${_practices.length}',
                style: D.text(
                  13,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: .75),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            practice.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: D.text(
              28,
              weight: FontWeight.w800,
              color: Colors.white,
              spacing: -.6,
              height: 34 / 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            practice.line,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: D.system(
              15,
              weight: FontWeight.w500,
              color: Colors.white.withValues(alpha: .9),
              height: 20 / 15,
            ),
          ),
          if (size.height > 300) ...[
            const SizedBox(height: 18),
            _PracticePreview(practice.preview, color: c),
          ],
        ],
      ),
    );
  }
}

/// A tiny white sketch of the practice, drawn with shapes.
class _PracticePreview extends StatelessWidget {
  final _Preview kind;
  final Color color;
  const _PracticePreview(this.kind, {required this.color});

  static Widget _bar(double width, {double alpha = .7, double height = 9}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
    height: 92,
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .22)),
    ),
    child: switch (kind) {
      _Preview.writing => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _bar(170),
          Row(
            children: [_bar(110), const SizedBox(width: 8), _bar(54, alpha: 1)],
          ),
          _bar(80, alpha: .45),
        ],
      ),
      _Preview.grammar => Row(
        children: [
          for (final (i, word) in ['go', 'goes', 'going'].indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: i == 1 ? 1 : .2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  word,
                  style: D.system(
                    15,
                    weight: FontWeight.w600,
                    color: i == 1 ? color : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      _Preview.chat => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _bar(150, alpha: .35, height: 26),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _bar(120, alpha: .95, height: 26),
          ),
        ],
      ),
      _Preview.cards => Row(
        children: [
          for (final (i, word) in ['Aa', 'Bb', 'Cc'].indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Transform.rotate(
              angle: (i - 1) * .08,
              child: Container(
                width: 52,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: i == 1 ? 1 : .3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  word,
                  style: D.text(
                    17,
                    weight: FontWeight.w800,
                    color: i == 1 ? color : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    },
  );
}

class _FlashcardDemo extends StatelessWidget {
  final bool active;
  const _FlashcardDemo({required this.active});
  @override
  Widget build(BuildContext context) => _StepPage(
    active: active,
    fill: true,
    title: 'Lưu từ mới mọi lúc,',
    accent: 'ôn đúng lúc sắp quên',
    accentColor: D.purple,
    body: 'Lưu từ ngay khi học và ôn lại bằng bộ thẻ. Chạm vào thẻ để lật, rồi cho Hifive biết bạn đã nhớ chưa.',
    gap: 22,
    children: [
      Expanded(
        child: _After(child: _WordStack(active: active)),
      ),
    ],
  );
}

/// A word to review on the flashcard step.
class _Word {
  final String word, phonetic, kind, meaning, example;
  final Color color;
  const _Word(
    this.word,
    this.phonetic,
    this.kind,
    this.meaning,
    this.example,
    this.color,
  );
}

final _words = [
  const _Word(
    'curious',
    '/ˈkjʊriəs/',
    'TÍNH TỪ',
    'tò mò',
    'Kids are curious about everything.',
    D.purple,
  ),
  const _Word(
    'journey',
    '/ˈdʒɜːrni/',
    'DANH TỪ',
    'chuyến đi',
    'The journey took two days.',
    D.blue,
  ),
  const _Word(
    'improve',
    '/ɪmˈpruːv/',
    'ĐỘNG TỪ',
    'cải thiện',
    'A little practice every day helps you improve.',
    D.green,
  ),
  const _Word(
    'brave',
    '/breɪv/',
    'TÍNH TỪ',
    'dũng cảm',
    'It was brave of her to speak first.',
    D.orange,
  ),
];

/// Word cards to flip and rate: "Đã nhớ" sends a card off to the right and
/// shows when it comes back, "Chưa nhớ" to the left, sooner. The deck
/// loops.
class _WordStack extends StatefulWidget {
  final bool active;
  const _WordStack({required this.active});
  @override
  State<_WordStack> createState() => _WordStackState();
}

class _WordStackState extends State<_WordStack> with TickerProviderStateMixin {
  int front = 0;

  /// Card flip, as in flashcard review (design system: 0.33 s).
  late final flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 330),
  );
  late final fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  double direction = 1;
  String? note;
  Timer? _clearNote;

  @override
  void dispose() {
    _clearNote?.cancel();
    flip.dispose();
    fly.dispose();
    super.dispose();
  }

  void _flip() {
    if (fly.isAnimating) return;
    AppScope.read(context).feedback.tap();
    _drive(context, flip, flip.value < .5 ? 1 : 0);
  }

  Future<void> _rate({required bool remembered}) async {
    if (fly.isAnimating) return;
    final s = AppScope.read(context);
    remembered ? s.feedback.success() : s.feedback.tap();
    _clearNote?.cancel();
    setState(() {
      direction = remembered ? 1 : -1;
      note = remembered ? 'Ôn lại sau 4 ngày' : 'Ôn lại vào ngày mai';
    });
    _clearNote = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => note = null);
    });
    await _drive(context, fly, 1);
    if (!mounted) return;
    setState(() => front = (front + 1) % _words.length);
    flip.value = 0;
    fly.value = 0;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, box) {
            final size = _cardSize(box);
            return AnimatedBuilder(
              animation: Listenable.merge([flip, fly]),
              builder: (context, _) {
                final t = Curves.easeInCubic.transform(fly.value);
                final f = Curves.easeInOut.transform(flip.value);
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    for (var k = 3; k >= 1; k--)
                      _atDepth(
                        k - Curves.easeOutCubic.transform(fly.value),
                        _WordFace(
                          _words[(front + k) % _words.length],
                          size: size,
                        ),
                      ),
                    Transform.translate(
                      offset: Offset(direction * 420 * t, -30 * t),
                      child: Transform.rotate(
                        angle: direction * .22 * t,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, .0012)
                            ..rotateY(pi * f),
                          child: f < .5
                              ? GestureDetector(
                                  key: const ValueKey('onboarding-card'),
                                  onTap: _flip,
                                  child: Semantics(
                                    button: true,
                                    hint: 'Chạm để lật',
                                    child: _WordFace(_words[front], size: size),
                                  ),
                                )
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(pi),
                                  child: GestureDetector(
                                    key: const ValueKey('onboarding-card-back'),
                                    onTap: _flip,
                                    child: _WordBack(
                                      _words[front],
                                      size: size,
                                      onRate: (r) => _rate(remembered: r),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      SizedBox(
        height: 34,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: note == null
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(note),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: D.purple.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.calendar,
                          size: 15,
                          color: D.purple,
                        ),
                        const SizedBox(width: 6),
                        Text(note!, style: D.text(13, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    ],
  );
}

/// A word card's front: its kind, the word and how it sounds.
class _WordFace extends StatelessWidget {
  final _Word word;
  final Size size;
  const _WordFace(this.word, {required this.size});
  @override
  Widget build(BuildContext context) {
    final ink = Color.lerp(word.color, D.ink, .35)!;
    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, word.color, .1),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: word.color.withValues(alpha: .18)),
        boxShadow: D.shadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  word.kind,
                  style: CapsLabel.smallStyle.copyWith(color: ink),
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: 'Nghe "${word.word}"',
                child: PressFade(
                  key: ValueKey('onboarding-speak-${word.word}'),
                  onTap: () => AppScope.read(context).speak(word.word),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.speaker_2_fill,
                      size: 19,
                      color: ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            word.word,
            style: D.text(40, weight: FontWeight.w800, color: ink, spacing: -1),
          ),
          const SizedBox(height: 4),
          Text(word.phonetic, style: D.system(17, color: D.secondary)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.arrow_2_circlepath, size: 14, color: ink),
              const SizedBox(width: 6),
              Text(
                'CHẠM ĐỂ LẬT',
                style: CapsLabel.smallStyle.copyWith(color: ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A word card's back: the meaning, an example, and the two ratings.
class _WordBack extends StatelessWidget {
  final _Word word;
  final Size size;
  final ValueChanged<bool> onRate;
  const _WordBack(this.word, {required this.size, required this.onRate});
  @override
  Widget build(BuildContext context) => Container(
    width: size.width,
    height: size.height,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(34),
      border: Border.all(color: word.color.withValues(alpha: .35), width: 1.5),
      boxShadow: D.shadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CapsLabel(word.word.toUpperCase(), small: true),
        const SizedBox(height: 10),
        Text(
          word.meaning,
          style: D.text(30, weight: FontWeight.w800, spacing: -.6),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: word.color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '"${word.example}"',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: D.system(
              16,
              color: D.secondary,
              style: FontStyle.italic,
              height: 22 / 16,
            ),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                'Chưa nhớ',
                key: const ValueKey('onboarding-again'),
                outlined: true,
                color: D.ink,
                foreground: D.ink,
                onTap: () => onRate(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ActionButton(
                'Đã nhớ',
                key: const ValueKey('onboarding-remembered'),
                onTap: () => onRate(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
