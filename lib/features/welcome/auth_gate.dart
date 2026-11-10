import 'package:flutter/material.dart';

import '../../state/state.dart';
import 'onboarding_screen.dart';
import 'preparing_view.dart';
import 'welcome_screen.dart';

/// Hifive needs an account: signed out, the learner sees [WelcomeScreen];
/// signed in without onboarding, [OnboardingScreen], after waiting for the
/// first sync in case another device already did it; then [child] (Home).
/// Signing out also closes every page opened on top of Home, so the welcome
/// screen isn't hidden behind them.
class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _uid;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final user = s.user;
    if (_uid != null && user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
    _uid = user?.uid;
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
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
      child: switch (user) {
        null => const WelcomeScreen(key: ValueKey('welcome')),
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
      },
    );
  }
}
