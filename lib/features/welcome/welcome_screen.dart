import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'sign_in_panel.dart';

/// Three pages about Hifive, then sign-in. A device that has seen the pages
/// opens on sign-in; the pages stay a swipe away.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

const _signInPage = 3;

/// Element entering (design system motion table).
const _enter = Duration(milliseconds: 300);

/// Page change, as a panel moves.
const _turn = Duration(milliseconds: 350);

class _WelcomeScreenState extends State<WelcomeScreen> {
  late int page = AppScope.read(context).introSeen ? _signInPage : 0;
  late final pages = PageController(initialPage: page);

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  void _goTo(int target) {
    if (MediaQuery.disableAnimationsOf(context)) {
      pages.jumpToPage(target);
    } else {
      pages.animateToPage(target, duration: _turn, curve: Curves.easeOutCubic);
    }
  }

  void _changed(int p) {
    setState(() => page = p);
    if (p == _signInPage) AppScope.read(context).finishIntro();
  }

  @override
  Widget build(BuildContext context) {
    final intro = page < _signInPage;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Align(
                alignment: Alignment.centerRight,
                // Removed, not just hidden, on sign-in, so screen readers
                // don't announce a button nobody can see.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeOut,
                  child: intro
                      ? Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _TextButton(
                            'Bỏ qua',
                            key: const ValueKey('welcome-skip'),
                            onTap: () => _goTo(_signInPage),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                key: const ValueKey('welcome-pages'),
                controller: pages,
                onPageChanged: _changed,
                children: [
                  _IntroPage(
                    active: page == 0,
                    art: const _WelcomeArt(),
                    title: 'Học ngoại ngữ bằng cách viết và nói',
                    body: 'Hifive chấm từng câu bạn viết và gợi ý cách nói tự nhiên hơn.',
                  ),
                  _IntroPage(
                    active: page == 1,
                    art: _ModesArt(active: page == 1),
                    title: 'Ba cách luyện tập',
                    body: 'Viết đoạn văn, luyện ngữ pháp hay trò chuyện. Chọn cách hợp với mục tiêu hôm nay.',
                  ),
                  _IntroPage(
                    active: page == 2,
                    art: const _MemoryArt(),
                    title: 'Nhớ lâu hơn mỗi ngày',
                    body: 'Lưu từ mới vào bộ thẻ, ôn đúng lúc sắp quên và giữ chuỗi ngày học.',
                  ),
                  const SignInPanel(),
                ],
              ),
            ),
            AnimatedSize(
              duration: _enter,
              curve: Curves.easeOutCubic,
              child: intro
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: Column(
                        children: [
                          _Dots(count: _signInPage, current: page),
                          const SizedBox(height: 24),
                          ActionButton(
                            page == _signInPage - 1 ? 'Bắt đầu' : 'Tiếp tục',
                            key: const ValueKey('welcome-next'),
                            onTap: () => _goTo(page + 1),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades and lifts its child in when [active] turns on, after [delay].
class _Reveal extends StatefulWidget {
  final bool active;
  final Duration delay;
  final Widget child;
  const _Reveal({
    required this.active,
    required this.child,
    this.delay = Duration.zero,
  });
  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(_Reveal old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) _schedule();
  }

  void _schedule() {
    if (!widget.active) return;
    if (MediaQuery.disableAnimationsOf(context) ||
        widget.delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => shown = true);
      });
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted && widget.active) setState(() => shown = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final visible = shown || still;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: still ? Duration.zero : _enter,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, .08),
        duration: still ? Duration.zero : _enter,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final bool active;
  final Widget art;
  final String title, body;
  const _IntroPage({
    required this.active,
    required this.art,
    required this.title,
    required this.body,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // Centered in the space between the top bar and the dots; scrolls when
    // a large text size needs more room.
    builder: (context, box) => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Reveal(
              active: active,
              child: SizedBox(height: 260, child: art),
            ),
            const SizedBox(height: 36),
            _Reveal(
              active: active,
              delay: const Duration(milliseconds: 60),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: D.text(26, weight: FontWeight.w800, height: 32 / 26),
              ),
            ),
            const SizedBox(height: 12),
            _Reveal(
              active: active,
              delay: const Duration(milliseconds: 120),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: D.text(15, color: D.secondary, height: 22 / 15),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

/// The logo inside rings in the three mode colors.
class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt();
  @override
  Widget build(BuildContext context) => Center(
    child: Stack(
      alignment: Alignment.center,
      children: [
        for (final (i, mode) in StudyMode.values.indexed)
          Container(
            width: 240 - i * 48.0,
            height: 240 - i * 48.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: mode.color.withValues(alpha: .08 + i * .04),
            ),
          ),
        const AppLogo(size: 88),
      ],
    ),
  );
}

/// The three modes as rows that arrive one after another.
class _ModesArt extends StatelessWidget {
  final bool active;
  const _ModesArt({required this.active});
  static const _labels = {
    StudyMode.writing: ('Luyện viết', 'Viết đoạn văn theo gợi ý'),
    StudyMode.grammar: ('Ngữ pháp', 'Sửa lỗi trong từng câu'),
    StudyMode.conversation: ('Hội thoại', 'Phản xạ khi trò chuyện'),
  };
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (final (i, mode) in StudyMode.values.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _Reveal(
            active: active,
            delay: Duration(milliseconds: 80 * i),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: D.line),
                boxShadow: D.shadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: mode.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(mode.icon, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _labels[mode]!.$1,
                          style: D.text(
                            15,
                            weight: FontWeight.w700,
                            height: 20 / 15,
                          ),
                        ),
                        Text(
                          _labels[mode]!.$2,
                          style: D.text(
                            12.5,
                            color: D.secondary,
                            height: 17 / 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

/// A small stack of word cards with a streak badge.
class _MemoryArt extends StatelessWidget {
  const _MemoryArt();
  Widget _card(String word, String meaning, {required bool front}) => Container(
    width: 200,
    height: 132,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: D.line),
      boxShadow: D.shadow,
    ),
    alignment: Alignment.center,
    child: front
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                word,
                style: D.text(24, weight: FontWeight.w800, height: 30 / 24),
              ),
              const SizedBox(height: 4),
              Text(
                meaning,
                style: D.text(14, color: D.secondary, height: 18 / 14),
              ),
            ],
          )
        : null,
  );

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 260,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(angle: -.14, child: _card('', '', front: false)),
          Transform.rotate(angle: .08, child: _card('', '', front: false)),
          _card('remember', 'ghi nhớ', front: true),
          Positioned(
            right: 8,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: D.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '7 ngày',
                    style: D.text(
                      12.5,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Dots extends StatelessWidget {
  final int count, current;
  const _Dots({required this.count, required this.current});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Trang ${current + 1} trên $count',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? D.ink : D.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    ),
  );
}

class _TextButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _TextButton(this.text, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => PressFade(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          widthFactor: 1,
          child: Text(
            text,
            style: D.text(15, weight: FontWeight.w600, color: D.secondary),
          ),
        ),
      ),
    ),
  );
}
