import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../information/information.dart';
import 'auth_text.dart';
import 'welcome_motion.dart';

part 'welcome_scenes.dart';

/// The first screen when signed out: short demos of what Hifive does play
/// one after another above the sign-in buttons, which never move.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

/// How long each demo stays before the next one; its own timeline is
/// [_sceneLength], then it holds its last frame.
const _sceneHold = Duration(milliseconds: 4800);

class _WelcomeScreenState extends State<WelcomeScreen> {
  int scene = 0;
  bool busy = false;
  Timer? _next;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  /// Moves on to the next demo after [_sceneHold] while demos autoplay.
  void _schedule() {
    _next?.cancel();
    if (!welcomeAutoplay(context)) return;
    _next = Timer(_sceneHold, () {
      if (mounted) _show((scene + 1) % _sceneCount);
    });
  }

  void _show(int index) {
    setState(() => scene = index);
    _schedule();
  }

  Future<void> _signIn(Future<void> Function() call) async {
    setState(() => busy = true);
    await runAuth(context, call);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final current = _scenesOf(context.t)[scene];
    final still = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: current.color.withValues(alpha: .16)),
        duration: still ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, tint, child) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .62],
              colors: [tint!, Colors.white],
            ),
          ),
          child: child,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  key: const ValueKey('welcome-stage'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v.abs() < 200) return;
                    final step = v < 0 ? 1 : -1;
                    _show((scene + step) % _sceneCount);
                  },
                  child: _Stage(scene: scene),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Column(
                  children: [
                    _Dots(count: _sceneCount, current: scene, onTap: _show),
                    const SizedBox(height: 18),
                    if (s.auth.supportsApple) ...[
                      ActionButton(
                        context.t.continueWithApple,
                        key: const ValueKey('sign-in-apple'),
                        icon: Icons.apple,
                        onTap: busy ? null : () => _signIn(s.signInWithApple),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Google's light button: white, outlined, with its
                    // four-colour mark.
                    ActionButton(
                      context.t.continueWithGoogle,
                      key: const ValueKey('sign-in-google'),
                      leading: const GoogleLogo(),
                      color: Colors.white,
                      foreground: D.ink,
                      outlined: true,
                      onTap: busy ? null : () => _signIn(s.signInWithGoogle),
                    ),
                    const SizedBox(height: 14),
                    const _Terms(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The current demo with its title, centred in the space above the dots.
class _Stage extends StatelessWidget {
  final int scene;
  const _Stage({required this.scene});
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final current = _scenesOf(context.t)[scene];
    return LayoutBuilder(
      builder: (context, box) {
        // The art gives up height first on short screens and large text.
        final art = (box.maxHeight - context.grow(150)).clamp(0.0, 290.0);
        return Column(
          children: [
            const SizedBox(height: 8),
            const _Brand(),
            const Spacer(),
            SizedBox(
              height: art,
              child: art < 120
                  ? null
                  : AnimatedSwitcher(
                      duration: still ? Duration.zero : welcomeTurn,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(begin: .96, end: 1.0).animate(animation),
                          child: child,
                        ),
                      ),
                      child: FittedBox(
                        key: ValueKey('scene-$scene'),
                        child: SizedBox(
                          width: 345,
                          height: 290,
                          child: _SceneArt(index: scene),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              child: Padding(
                key: ValueKey('title-$scene'),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      current.title,
                      textAlign: TextAlign.center,
                      style: D.text(
                        26,
                        weight: FontWeight.w800,
                        height: 32 / 26,
                        spacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current.body,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: D.text(15, color: D.secondary, height: 21 / 15),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}

/// The logo and the lowercase wordmark.
class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Hifive',
    excludeSemantics: true,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppLogo(size: 30),
        const SizedBox(width: 8),
        Text(
          'hifive',
          style: D.text(21, weight: FontWeight.w800, spacing: -.6, height: 1),
        ),
      ],
    ),
  );
}

class _Dots extends StatelessWidget {
  final int count, current;
  final ValueChanged<int> onTap;
  const _Dots({
    required this.count,
    required this.current,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        Semantics(
          button: true,
          selected: i == current,
          label: context.t.introPage(i + 1, count),
          child: GestureDetector(
            key: ValueKey('welcome-dot-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            // A 44 pt tall hit box around the 8 pt dot.
            child: SizedBox(
              width: 34,
              height: 44,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: i == current ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == current ? D.ink : D.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// The agreement line under the buttons, with both documents a tap away.
class _Terms extends StatelessWidget {
  const _Terms();
  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context), t = context.t;
    final base = D.text(12, color: D.secondary, height: 17 / 12);
    final link = D.text(
      12,
      weight: FontWeight.w700,
      color: D.ink,
      height: 17 / 12,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(t.agreePrefix, style: base),
        _TermsLink(
          t.agreeTerms,
          key: const ValueKey('welcome-terms'),
          style: link,
          onTap: () async {
            if (!await s.system.openTerms() && context.mounted) {
              toast(context, t.cannotOpenTerms);
            }
          },
        ),
        Text(t.agreeAnd, style: base),
        _TermsLink(
          t.profilePrivacy,
          key: const ValueKey('welcome-privacy'),
          style: link,
          onTap: () => go<void>(context, const PrivacyScreen()),
        ),
        if (t.agreeSuffix.isNotEmpty) Text(t.agreeSuffix, style: base),
      ],
    );
  }
}

class _TermsLink extends StatelessWidget {
  final String text;
  final TextStyle style;
  final VoidCallback onTap;
  const _TermsLink(
    this.text, {
    super.key,
    required this.style,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    link: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        // Taller hit area without moving the line.
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text, style: style),
      ),
    ),
  );
}
