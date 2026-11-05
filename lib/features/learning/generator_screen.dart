import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'chat_screen.dart';
import 'practice_screen.dart';

/// The AI chooser and its custom-topic editor, measured on the physical
/// iPhone (3 November 2026). The topics form a flat snapping wheel: the row
/// in the middle is selected, drawn 1.48 times larger in black, and its line
/// shows under "MÔ TẢ CHỦ ĐỀ". Generation is served by
/// [LessonRepository.createPractice].
class GeneratorScreen extends StatefulWidget {
  final StudyMode mode;
  final String initialTopic;
  const GeneratorScreen({
    super.key,
    this.mode = StudyMode.grammar,
    this.initialTopic = '',
  });
  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

/// The custom row is first; presets follow.
const _custom = 'TÙY CHỈNH';

class _GeneratorScreenState extends State<GeneratorScreen> {
  /// A typed topic; presets come from the wheel.
  late String typed = widget.initialTopic;
  int selected = 0;
  bool generating = false;
  final wheel = FixedExtentScrollController();

  /// The last catalog loaded, whose sample prompts the editor offers.
  GeneratorCatalog? catalog;

  Future<GeneratorCatalog> load() async {
    final state = AppScope.read(context);
    return catalog = await state.lessons.generator(state.language, widget.mode);
  }

  @override
  void dispose() {
    wheel.dispose();
    super.dispose();
  }

  Future<void> start(String title) async {
    if (title.trim().isEmpty) return editTopic();
    setState(() => generating = true);
    try {
      final state = AppScope.read(context);
      final lesson = await state.lessons.createPractice(
        state.language,
        title.trim(),
        widget.mode,
      );
      if (!mounted) return;
      setState(() => generating = false);
      await go<void>(
        context,
        widget.mode == StudyMode.conversation
            ? ChatScreen(lesson: lesson)
            : PracticeScreen(lesson: lesson),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => generating = false);
      toast(context, 'Không tạo được bài luyện tập. Vui lòng thử lại.');
    }
  }

  Future<void> editTopic() async {
    // A floating sheet inset 9 pt from the screen edges, resting on the
    // keyboard, as on the reference.
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Palette.sheetBarrier,
      elevation: 0,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          9,
          0,
          9,
          MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(38),
          ),
          child: _TopicEditor(
            initial: typed,
            mode: widget.mode,
            examples: catalog?.examples ?? const [],
          ),
        ),
      ),
    );
    if (text == null || !mounted) return;
    setState(() => typed = text);
    await start(text);
  }

  /// What the arrow starts: the typed topic on the custom row, else the
  /// selected preset.
  String chosen(List<GeneratorPreset> presets) =>
      selected == 0 ? typed : presets[selected - 1].title;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    resizeToAvoidBottomInset: false,
    body: SafeArea(
      bottom: false,
      child: AsyncView<GeneratorCatalog>(
        load: load,
        isEmpty: (c) => c.presets.isEmpty,
        empty: const EmptyView(
          title: 'Chưa có gợi ý',
          subtitle: 'Hãy tự mô tả chủ đề bạn muốn luyện tập.',
        ),
        builder: (context, catalog) => _body(catalog.presets),
      ),
    ),
  );

  Widget _body(List<GeneratorPreset> presets) {
    final topic = chosen(presets);
    final line = selected == 0
        ? (typed.isEmpty ? 'Tạo chủ đề độc đáo của riêng bạn.' : typed)
        : presets[selected - 1].description;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'TẠO BẰNG AI',
                        style: D.text(
                          10,
                          weight: FontWeight.w700,
                          color: D.muted,
                          spacing: 2,
                          height: 1.45,
                        ),
                      ),
                      Text(
                        'CHỌN CHỦ ĐỀ',
                        style: D.text(
                          10,
                          weight: FontWeight.w800,
                          spacing: 2,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Đóng',
                  child: PressFade(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: D.line),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 21,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Palette.chooserRule),
        Expanded(
          // The middle row sits at y 420 on the 852 pt screen.
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListWheelScrollView.useDelegate(
              controller: wheel,
              itemExtent: 64,
              // Flat: the reference's rows neither curve nor shrink.
              diameterRatio: 1000,
              perspective: .000001,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) => setState(() => selected = i),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: presets.length + 1,
                builder: (context, i) => _Row(
                  text: i == 0 ? _custom : presets[i - 1].title,
                  custom: i == 0,
                  selected: i == selected,
                  onTap: () {
                    if (i == selected && i == 0) {
                      editTopic();
                      return;
                    }
                    wheel.animateToItem(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Palette.chooserFoot),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 23.3, 24, bottom + 24),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: const ValueKey('generator-describe'),
                  behavior: HitTestBehavior.opaque,
                  onTap: editTopic,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MÔ TẢ CHỦ ĐỀ',
                        style: D.text(
                          10,
                          color: D.muted,
                          weight: FontWeight.w700,
                          spacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: D.text(13, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: 'Bắt đầu luyện tập',
                child: PressFade(
                  key: const ValueKey('generator-go'),
                  onTap: generating ? null : () => start(topic),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .2),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: generating
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A wheel row: 21 pt grey, or 1.48 times larger and black in the middle.
class _Row extends StatelessWidget {
  final String text;
  final bool custom, selected;
  final VoidCallback onTap;
  const _Row({
    required this.text,
    required this.custom,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black : Palette.chooserFaded;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: selected ? 32 : 28, right: 24),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedScale(
            scale: selected ? 1.48 : 1,
            alignment: Alignment.centerLeft,
            duration: const Duration(milliseconds: 200),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: D.text(21, weight: FontWeight.w700, color: color),
                ),
                if (custom) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 22,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The custom-topic editor (iPhone, 3 November 2026): a grabber, a centred
/// title with a round close button, a tinted text area, a row of example
/// chips and a full-width button. It owns its controller because the sheet
/// keeps building while it animates closed.
class _TopicEditor extends StatefulWidget {
  final String initial;
  final StudyMode mode;
  final List<String> examples;
  const _TopicEditor({
    required this.initial,
    required this.mode,
    required this.examples,
  });
  @override
  State<_TopicEditor> createState() => _TopicEditorState();
}

class _TopicEditorState extends State<_TopicEditor> {
  late final controller = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = controller.text.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 25.3),
          Center(
            child: Container(
              width: 54,
              height: 5.7,
              decoration: BoxDecoration(
                color: D.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  widget.mode == StudyMode.conversation
                      ? 'Tạo tình huống'
                      : 'Tạo Câu Luyện Tập',
                  style: D.text(15.3, weight: FontWeight.w700),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    button: true,
                    label: 'Đóng',
                    child: PressFade(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Palette.topicIconFill,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: D.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 115,
            padding: const EdgeInsets.fromLTRB(19, 20, 30, 10),
            decoration: BoxDecoration(
              color: D.background,
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              key: const ValueKey('generator-topic'),
              controller: controller,
              autofocus: true,
              maxLines: null,
              expands: true,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              style: D.text(14.6),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: "VD: 'Phrasal Verbs với Get', 'Câu hỏi phỏng vấn'...",
                hintStyle: D.text(14.6, color: D.muted),
              ),
            ),
          ),
          const SizedBox(height: 19),
          SizedBox(
            height: 33,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: widget.examples.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) => PressFade(
                onTap: () => setState(() {
                  controller.text = widget.examples[i];
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.5),
                    border: Border.all(color: D.line),
                  ),
                  child: Text(
                    widget.examples[i],
                    style: D.text(11, weight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 23),
          PressFade(
            key: const ValueKey('generator-start'),
            onTap: text.isEmpty ? null : () => Navigator.pop(context, text),
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: text.isEmpty ? D.line : D.ink,
                borderRadius: BorderRadius.circular(27),
              ),
              child: Text(
                'Bắt Đầu Luyện Tập',
                style: D.text(16, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
