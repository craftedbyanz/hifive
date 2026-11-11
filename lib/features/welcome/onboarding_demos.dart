part of 'onboarding_screen.dart';

/// How long a demo "thinks" before it answers, so the wait reads as work.
const _thinking = Duration(milliseconds: 900);

BoxDecoration _panel({Color? border, double width = 1}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: border ?? D.line, width: width),
  boxShadow: D.shadow,
);

/// Try writing: a sentence to translate, the learner's attempt, and a tap
/// that grades it.
class _WritingDemo extends StatefulWidget {
  final bool active;
  const _WritingDemo({required this.active});
  @override
  State<_WritingDemo> createState() => _WritingDemoState();
}

enum _Grade { idle, grading, done }

class _WritingDemoState extends State<_WritingDemo> {
  var grade = _Grade.idle;
  Timer? _wait;

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  void _grade() {
    AppScope.read(context).feedback.tap();
    setState(() => grade = _Grade.grading);
    _wait = Timer(_thinking, () {
      if (mounted) setState(() => grade = _Grade.done);
    });
  }

  @override
  Widget build(BuildContext context) {
    final blue = StudyMode.writing.color;
    final content = D.text(17, weight: FontWeight.w600, height: 24 / 17);
    return _StepPage(
      active: widget.active,
      mode: StudyMode.writing,
      title: 'Viết, rồi nhận\ngóp ý ngay',
      body: 'Hifive chấm từng câu bạn viết và chỉ cách nói tự nhiên hơn. Thử chấm câu dưới đây.',
      children: [
        _After(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: _panel(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CapsLabel('DỊCH SANG TIẾNG ANH'),
                const SizedBox(height: 8),
                Text('Tôi đã sống ở Đà Nẵng ba năm.', style: content),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: blue.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'I live in Da Nang for three years.',
                    style: content,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: _SmallButton(
                    grade == _Grade.idle ? 'Chấm điểm' : 'Đã chấm',
                    key: const ValueKey('onboarding-grade'),
                    icon: CupertinoIcons.sparkles,
                    color: blue,
                    onTap: grade == _Grade.idle ? _grade : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeOut,
          child: switch (grade) {
            _Grade.idle => const SizedBox.shrink(),
            _Grade.grading => const _Skeleton(key: ValueKey('grading')),
            _Grade.done => const _WritingResult(key: ValueKey('graded')),
          },
        ),
      ],
    );
  }
}

/// Grey lines that pulse while a demo thinks.
class _Skeleton extends StatefulWidget {
  const _Skeleton({super.key});
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (welcomeAutoplay(context)) pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đang chấm',
    child: FadeTransition(
      opacity: Tween(begin: 1.0, end: .45).animate(pulse),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CupertinoActivityIndicator(radius: 8),
                const SizedBox(width: 10),
                Text(
                  'Đang chấm...',
                  style: D.text(
                    15,
                    weight: FontWeight.w600,
                    color: D.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final w in [1.0, .8, .55]) ...[
              FractionallySizedBox(
                widthFactor: w,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: D.line,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ),
  );
}

class _WritingResult extends StatelessWidget {
  const _WritingResult({super.key});
  @override
  Widget build(BuildContext context) {
    final base = D.text(16, weight: FontWeight.w600, height: 24 / 16);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panel(border: D.orange.withValues(alpha: .5), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                size: 20,
                color: D.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gần đúng',
                  style: D.text(16, weight: FontWeight.w800),
                ),
              ),
              Text('72', style: D.text(22, weight: FontWeight.w800, height: 1)),
              Text(
                '/100',
                style: D.text(13, weight: FontWeight.w600, color: D.secondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const CapsLabel('CÂU ĐÚNG', small: true),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: base,
              children: [
                const TextSpan(text: 'I '),
                TextSpan(
                  text: 'live',
                  style: base.copyWith(
                    color: Palette.wrong,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Palette.wrong,
                  ),
                ),
                TextSpan(
                  text: ' have lived',
                  style: base.copyWith(color: D.green),
                ),
                const TextSpan(text: ' in Da Nang for three years.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const CapsLabel('GIẢI THÍCH', small: true),
          const SizedBox(height: 6),
          Text(
            'Việc bắt đầu trong quá khứ và vẫn còn tiếp diễn nên dùng thì hiện tại hoàn thành.',
            style: D.text(14, color: D.secondary, height: 20 / 14),
          ),
        ],
      ),
    );
  }
}

/// Try grammar: one gap, three choices, and why the right one is right.
class _GrammarDemo extends StatefulWidget {
  final bool active;
  const _GrammarDemo({required this.active});
  @override
  State<_GrammarDemo> createState() => _GrammarDemoState();
}

class _GrammarDemoState extends State<_GrammarDemo> {
  static const _options = ['go', 'goes', 'going'];
  static const _answer = 1;
  int? picked;

  void _pick(int i) {
    final s = AppScope.read(context);
    i == _answer ? s.feedback.success() : s.feedback.tap();
    setState(() => picked = i);
  }

  @override
  Widget build(BuildContext context) {
    final violet = StudyMode.grammar.color;
    final solved = picked == _answer;
    final blank = solved ? _options[_answer] : '____';
    return _StepPage(
      active: widget.active,
      mode: StudyMode.grammar,
      title: 'Sửa lỗi\ntrong từng câu',
      body: 'Câu ngắn, giải thích rõ, để lỗi quen không lặp lại. Chọn từ đúng cho chỗ trống.',
      children: [
        _After(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: _panel(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CapsLabel('ĐIỀN VÀO CHỖ TRỐNG'),
                const SizedBox(height: 10),
                Text(
                  'She $blank to work by bus every day.',
                  style: D.text(19, weight: FontWeight.w700, height: 27 / 19),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (final (i, option) in _options.indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _Choice(
                          option,
                          key: ValueKey('onboarding-option-$option'),
                          color: violet,
                          state: picked != i
                              ? _ChoiceState.idle
                              : i == _answer
                              ? _ChoiceState.right
                              : _ChoiceState.wrong,
                          onTap: solved ? null : () => _pick(i),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: picked == null
              ? const SizedBox.shrink()
              : _Note(
                  key: ValueKey(picked),
                  icon: solved
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.xmark_circle_fill,
                  color: solved ? D.green : Palette.wrong,
                  title: solved ? 'Chính xác!' : 'Chưa đúng, thử lại nhé',
                  body: solved
                      ? 'Chủ ngữ số ít (she) ở thì hiện tại đơn thì động từ thêm -s hoặc -es.'
                      : 'Gợi ý: "every day" là thói quen, và chủ ngữ là "she".',
                ),
        ),
      ],
    );
  }
}

enum _ChoiceState { idle, right, wrong }

class _Choice extends StatelessWidget {
  final String text;
  final Color color;
  final _ChoiceState state;
  final VoidCallback? onTap;
  const _Choice(
    this.text, {
    super.key,
    required this.color,
    required this.state,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final edge = switch (state) {
      _ChoiceState.idle => D.line,
      _ChoiceState.right => D.green,
      _ChoiceState.wrong => Palette.wrong,
    };
    return Semantics(
      button: true,
      selected: state != _ChoiceState.idle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: state == _ChoiceState.idle
                ? color.withValues(alpha: .06)
                : edge.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: edge,
              width: state == _ChoiceState.idle ? 1 : 1.7,
            ),
          ),
          child: Text(text, style: D.text(16, weight: FontWeight.w700)),
        ),
      ),
    );
  }
}

/// A feedback card: a status icon and title, and a line of explanation.
class _Note extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body;
  const _Note({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: D.text(15, weight: FontWeight.w800, height: 20 / 15),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: D.text(14, color: D.secondary, height: 20 / 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Try a conversation: the partner asks, the learner picks a reply, and the
/// partner answers, with a tip when the reply could be more polite.
class _ChatDemo extends StatefulWidget {
  final bool active;
  const _ChatDemo({required this.active});
  @override
  State<_ChatDemo> createState() => _ChatDemoState();
}

class _ChatDemoState extends State<_ChatDemo> {
  static const _replies = [
    ('A latte, please.', 'Great choice! Hot or iced?', null),
    (
      'I want coffee.',
      'Sure! What kind of coffee?',
      'Lịch sự hơn: "Could I have a coffee, please?"',
    ),
  ];
  int? reply;
  bool answered = false;
  Timer? _wait;

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  void _send(int i) {
    AppScope.read(context).feedback.tap();
    setState(() => reply = i);
    _wait = Timer(_thinking, () {
      if (mounted) setState(() => answered = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cyan = StudyMode.conversation.color;
    final base = D.text(15, weight: FontWeight.w600, height: 21 / 15);
    final picked = reply == null ? null : _replies[reply!];
    return _StepPage(
      active: widget.active,
      mode: StudyMode.conversation,
      title: 'Trò chuyện\nnhư ngoài đời',
      body: 'Luyện nói theo tình huống thật. Chọn một câu để trả lời.',
      children: [
        _After(
          child: _ChatLine(
            partner: true,
            color: cyan,
            child: Text('Hi! What would you like to order?', style: base),
          ),
        ),
        const SizedBox(height: 12),
        if (picked == null)
          _After(
            delay: const Duration(milliseconds: 80),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (i, r) in _replies.indexed)
                  _SmallButton(
                    r.$1,
                    key: ValueKey('onboarding-reply-$i'),
                    color: cyan,
                    outlined: true,
                    onTap: () => _send(i),
                  ),
              ],
            ),
          )
        else ...[
          Reveal(
            child: _ChatLine(
              partner: false,
              color: cyan,
              child: Text(picked.$1, style: base),
            ),
          ),
          const SizedBox(height: 12),
          if (!answered)
            _ChatLine(
              partner: true,
              color: cyan,
              child: const SizedBox(
                width: 36,
                child: CupertinoActivityIndicator(radius: 8),
              ),
            )
          else ...[
            if (picked.$3 case final String tip) ...[
              Reveal(
                child: _Note(
                  icon: CupertinoIcons.lightbulb_fill,
                  color: D.purple,
                  title: 'Gợi ý',
                  body: tip,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Reveal(
              delay: const Duration(milliseconds: 120),
              child: _ChatLine(
                partner: true,
                color: cyan,
                child: Text(picked.$2, style: base),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ChatLine extends StatelessWidget {
  final bool partner;
  final Color color;
  final Widget child;
  const _ChatLine({
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: partner
              ? _panel()
              : BoxDecoration(
                  color: color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(24),
                ),
          child: child,
        ),
      ),
    ],
  );
}

/// A compact capsule button inside a demo card; 44 pt tall to tap.
class _SmallButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final bool outlined;
  final VoidCallback? onTap;
  const _SmallButton(
    this.text, {
    super.key,
    required this.color,
    required this.onTap,
    this.icon,
    this.outlined = false,
  });
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fill = outlined
        ? Colors.white
        : enabled
        ? D.ink
        : Palette.ctaDisabled;
    final ink = outlined ? D.ink : Colors.white;
    return Semantics(
      button: true,
      enabled: enabled,
      child: PressFade(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(22),
            border: outlined ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: ink),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: D.text(14, weight: FontWeight.w700, color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
