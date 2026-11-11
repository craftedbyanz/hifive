import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../state/state.dart';
import '../../widgets/common.dart';
import 'onboarding_screen.dart';
import 'preparing_view.dart';
import 'welcome_motion.dart';
import 'welcome_screen.dart';

/// Hifive needs an account: signed out, the learner sees [WelcomeScreen];
/// signed in without onboarding, [OnboardingScreen], after waiting for the
/// first sync in case another device already did it; then [child] (Home).
/// Signing in raises a frosted veil over sign-in before the next screen
/// fades in. Signing out also closes every page opened on top of Home, so
/// the welcome screen isn't hidden behind them.
class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

/// The veil rises, then holds a moment on the logo before the swap.
const _veilRise = Duration(milliseconds: 900);
const _veilHold = Duration(milliseconds: 300);

class _AuthGateState extends State<AuthGate>
    with SingleTickerProviderStateMixin {
  String? _uid;

  late final veil = AnimationController(
    vsync: this,
    duration: _veilRise + _veilHold,
  );

  /// True from a sign-in on the welcome screen until the veil has covered
  /// it; the welcome screen stays underneath until then.
  bool veiling = false;

  @override
  void dispose() {
    veil.dispose();
    super.dispose();
  }

  /// Points along the rise, as shares of the whole veil timeline, where a
  /// light knock is felt: further apart at first, closer as the veil
  /// speeds up, then one heavy knock as it covers the screen.
  static const _knocks = [.04, .16, .26, .35, .43, .5, .56, .61, .65, .69];
  static const _landing = .75;
  int _knocked = 0;

  void _raiseVeil() {
    veiling = true;
    _knocked = 0;
    veil.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => veiling = false);
    });
  }

  /// Plays the knocks the veil has passed since the last frame.
  void _feel() {
    final feedback = AppScope.read(context).feedback;
    while (_knocked < _knocks.length && veil.value >= _knocks[_knocked]) {
      _knocked++;
      feedback.impact();
    }
    if (_knocked == _knocks.length && veil.value >= _landing) {
      _knocked++;
      feedback.impact(heavy: true);
    }
  }

  @override
  void initState() {
    super.initState();
    veil.addListener(_feel);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final user = s.user;
    if (_uid != null && user == null) {
      veil.reset();
      veiling = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
    if (_uid == null && user != null && welcomeAutoplay(context)) {
      _raiseVeil();
    }
    _uid = user?.uid;
    final still = MediaQuery.disableAnimationsOf(context);
    // The same tree with or without the veil, so the demos keep playing
    // underneath it.
    final welcome = KeyedSubtree(
      key: const ValueKey('welcome'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const WelcomeScreen(),
          if (veiling) _Veil(progress: veil),
        ],
      ),
    );
    final Widget page = switch (user) {
      null => welcome,
      _ when veiling => welcome,
      _ when s.onboarded => KeyedSubtree(
        key: const ValueKey('home'),
        child: widget.child,
      ),
      _ when s.awaitingAccount => const PreparingView(
        key: ValueKey('restoring'),
        steps: ['Đang tải dữ liệu của bạn'],
        detail: 'Lấy tiến độ từ tài khoản về thiết bị này.',
      ),
      _ => const OnboardingScreen(key: ValueKey('onboarding')),
    };
    return ColoredBox(
      // The pages fade through white rather than black.
      color: Colors.white,
      child: AnimatedSwitcher(
        // A panel's timing from the design system's motion table.
        duration: still ? Duration.zero : const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: .98, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: page,
      ),
    );
  }
}

/// A frosted white sheet with an arched top edge that rises from the
/// bottom over the sign-in screen, with the logo breathing in its middle.
class _Veil extends StatelessWidget {
  final Animation<double> progress;
  const _Veil({required this.progress});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đang đăng nhập',
    liveRegion: true,
    child: AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final rise = _veilRise.inMicroseconds / veilLength.inMicroseconds;
        final p = phase(progress.value, 0, rise, Curves.easeInOutCubic);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Taps go nowhere while the veil is up.
            const ModalBarrier(dismissible: false, color: Colors.transparent),
            ClipPath(
              clipper: _ArchClipper(p),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22 * p, sigmaY: 22 * p),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .55 + .3 * p),
                        Colors.white.withValues(alpha: .92),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Opacity(
                opacity: phase(progress.value, rise * .55, rise),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      // One slow breath while the veil holds.
                      scale: 1 + .06 * sin(pi * progress.value),
                      child: const AppLogo(size: 64),
                    ),
                    const SizedBox(height: 20),
                    const CupertinoActivityIndicator(radius: 9),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  static Duration get veilLength => _veilRise + _veilHold;
}

/// The part of the screen under a rising arch: at [p] 0 nothing, at 1 all
/// of it. The arch flattens as it reaches the top.
class _ArchClipper extends CustomClipper<Path> {
  final double p;
  _ArchClipper(this.p);
  @override
  Path getClip(Size size) {
    final bulge = 90 * (1 - p);
    final edge = size.height * (1 - p) + bulge;
    return Path()
      ..moveTo(0, edge)
      ..quadraticBezierTo(size.width / 2, edge - 2 * bulge, size.width, edge)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_ArchClipper old) => old.p != p;
}
