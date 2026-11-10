part of 'onboarding_screen.dart';

class _NameStep extends StatelessWidget {
  final bool active;
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onChanged, onSubmitted;
  const _NameStep({
    required this.active,
    required this.controller,
    required this.focus,
    required this.onChanged,
    required this.onSubmitted,
  });
  @override
  Widget build(BuildContext context) {
    final name = controller.text.trim();
    final valid = name.isNotEmpty && name.characters.length <= _maxName;
    return _StepPage(
      children: [
        _Heading(
          active: active,
          title: 'Bạn tên là gì?',
          body: 'Hifive sẽ gọi bạn bằng tên này. Bạn có thể đổi trong Hồ sơ.',
        ),
        const SizedBox(height: 28),
        Reveal(
          active: active,
          delay: const Duration(milliseconds: 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('onboarding-name'),
                controller: controller,
                focusNode: focus,
                maxLength: _maxName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onSubmitted(),
                style: D.text(22, weight: FontWeight.w700, height: 28 / 22),
                decoration: InputDecoration(
                  hintText: 'Tên của bạn',
                  hintStyle: D.text(
                    22,
                    weight: FontWeight.w700,
                    color: D.muted,
                    height: 28 / 22,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: Palette.settingsPage,
                  contentPadding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
                  suffixIcon: AnimatedOpacity(
                    opacity: valid ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: D.green,
                      size: 22,
                    ),
                  ),
                  enabledBorder: _border(Palette.settingsPanel),
                  focusedBorder: _border(Palette.ctaDisabled),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${name.characters.length}/$_maxName',
                textAlign: TextAlign.right,
                style: D.text(12, weight: FontWeight.w600, color: D.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color),
  );
}

class _LevelStep extends StatelessWidget {
  final bool active;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _LevelStep({
    required this.active,
    required this.selected,
    required this.onSelect,
  });

  /// One line each, short enough to compare at a glance; the full
  /// descriptions are on the level information sheet.
  static const _lines = [
    'Biết vài từ và câu chào hỏi.',
    'Viết được câu đơn giản về bản thân.',
    'Viết được đoạn ngắn về chủ đề quen thuộc.',
    'Nêu quan điểm khá tự nhiên, có lập luận.',
    'Viết mạch lạc cho học tập và công việc.',
    'Gần như người bản ngữ.',
  ];

  @override
  Widget build(BuildContext context) => _StepPage(
    children: [
      _Heading(
        active: active,
        title: 'Trình độ hiện tại\ncủa bạn?',
        body:
            'Bài học bắt đầu từ mức này. Chưa chắc thì chọn thấp hơn một bậc.',
      ),
      const SizedBox(height: 20),
      for (final (i, title) in levels.indexed) ...[
        Reveal(
          active: active,
          delay: Duration(milliseconds: 160 + 40 * i),
          child: _OptionCard(
            key: ValueKey('onboarding-level-${title.substring(0, 2)}'),
            selected: selected == title.substring(0, 2),
            color: levelColors[i],
            onTap: () => onSelect(title.substring(0, 2)),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: levelColors[i],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: D.text(
                          15,
                          weight: FontWeight.w800,
                          height: 20 / 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lines[i],
                        style: D.text(13, color: D.secondary, height: 18 / 13),
                      ),
                    ],
                  ),
                ),
                // Room for the tick.
                const SizedBox(width: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _GoalStep extends StatelessWidget {
  final bool active;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  const _GoalStep({
    required this.active,
    required this.selected,
    required this.onToggle,
  });

  static const _goals = {
    'daily': (
      CupertinoIcons.chat_bubble_2_fill,
      'Giao tiếp',
      'Trò chuyện hằng ngày',
    ),
    'travel': (CupertinoIcons.airplane, 'Du lịch', 'Hỏi đường, gọi món'),
    'work': (
      CupertinoIcons.briefcase_fill,
      'Công việc',
      'Email, họp, thuyết trình',
    ),
    'exam': (
      CupertinoIcons.doc_text_fill,
      'Thi chứng chỉ',
      'IELTS, TOEIC, TOEFL',
    ),
    'study': (CupertinoIcons.book_fill, 'Du học', 'Bài giảng, bài luận'),
    'writing': (CupertinoIcons.pencil, 'Viết tốt hơn', 'Câu rõ ý, ít lỗi'),
    'media': (
      CupertinoIcons.film_fill,
      'Phim và nhạc',
      'Hiểu không cần phụ đề',
    ),
    'family': (
      CupertinoIcons.heart_fill,
      'Cùng gia đình',
      'Học cùng con, người thân',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final full = selected.length >= _maxGoals;
    return _StepPage(
      children: [
        _Heading(
          active: active,
          title: 'Bạn học để làm gì?',
          body: selected.isEmpty
              ? 'Chọn tối đa $_maxGoals mục tiêu.'
              : 'Đã chọn ${selected.length}/$_maxGoals mục tiêu.',
        ),
        const SizedBox(height: 20),
        Reveal(
          active: active,
          delay: const Duration(milliseconds: 180),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: 1.45,
            children: [
              for (final id in learningGoals)
                if (_goals[id] case (final icon, final title, final line))
                  _OptionCard(
                    key: ValueKey('onboarding-goal-$id'),
                    selected: selected.contains(id),
                    color: D.blue,
                    dimmed: full && !selected.contains(id),
                    onTap: () => onToggle(id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(icon, size: 22, color: D.ink),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: D.text(
                                14,
                                weight: FontWeight.w800,
                                height: 19 / 14,
                              ),
                            ),
                            Text(
                              line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: D.text(
                                12,
                                color: D.secondary,
                                height: 16 / 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A choice card: selected shows its color on a 1.7 pt border and a tick
/// (design system "Selected").
class _OptionCard extends StatelessWidget {
  final bool selected, dimmed;
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  const _OptionCard({
    super.key,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.child,
    this.dimmed = false,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppScope.read(context).feedback.tap();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: .07)
              : dimmed
              ? D.background
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : D.line,
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Stack(
          children: [
            child,
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  size: 20,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
