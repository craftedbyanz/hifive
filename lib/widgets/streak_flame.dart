import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';

import '../core/design/design.dart';
import 'ambient.dart';

/// The streak flame: a looping Lottie animation, grey while [active] is false.
///
/// It loops only under [AmbientMotion], so tests can still settle; otherwise it
/// holds its first frame. [size] is the side of the square it fits in.
class StreakFlame extends StatelessWidget {
  final double size;
  final bool active;
  const StreakFlame({super.key, required this.size, this.active = true});

  static const activeAsset = 'assets/lottie/streak_flame_active.json';
  static const inactiveAsset = 'assets/lottie/streak_flame_inactive.json';

  /// How far the drawing is raised, as a share of [size]. The flame's body
  /// spans y 97–679 of the 690-high canvas (the top is left for sparks), so it
  /// sits about 6% low; this centers its body in the box.
  static const lift = .065;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Transform.translate(
      offset: Offset(0, -size * lift),
      child: Lottie.asset(
        active ? activeAsset : inactiveAsset,
        key: ValueKey(active ? 'streak-flame-active' : 'streak-flame-inactive'),
        animate: AmbientMotion.of(context),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          CupertinoIcons.flame_fill,
          size: size,
          color: active ? D.orange : Palette.flameGrey,
        ),
      ),
    ),
  );
}
