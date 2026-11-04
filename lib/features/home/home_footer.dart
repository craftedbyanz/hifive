import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../history/history.dart';
import '../insights/insights.dart';
import '../profile/profile.dart';
import 'home_painters.dart';

/// Colors solved from the reference frames of the writing and grammar cards.
/// The conversation card follows the same formula but was not observed at rest.
Color footerTint(Color modeColor) =>
    Color.lerp(modeColor, Palette.footerBase, .67)!;
Color glassTint(Color modeColor) => modeColor == D.blue
    ? Palette.glassWriting
    : modeColor == D.modeColor(StudyMode.grammar)
    ? Palette.glassGrammar
    : Palette.glassConversation;

/// The dark hairline around the footer buttons, measured for each card.
Color glassEdge(Color modeColor) => modeColor == D.blue
    ? Palette.edgeWriting
    : modeColor == D.modeColor(StudyMode.grammar)
    ? Palette.edgeGrammar
    : Palette.edgeConversation;

class HomeFooterGlow extends StatelessWidget {
  final Color color;
  final bool scrolledAway;
  const HomeFooterGlow({
    super.key,
    required this.color,
    required this.scrolledAway,
  });
  @override
  Widget build(BuildContext context) {
    final tint = scrolledAway
        ? Palette.footerNeutral.withValues(alpha: .52)
        : footerTint(color).withValues(alpha: .745);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final (start, sigma) in _blurSteps)
            FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: 1 - start,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: tint),
            duration: const Duration(milliseconds: 400),
            builder: (context, value, _) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [value!.withValues(alpha: 0), value],
                  stops: const [.31, .63],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Backdrop blur inside a shader mask has nothing to sample, so the blur
  /// builds up through overlapping steps instead.
  static const _blurSteps = [(.55, 3.0), (.58, 7.0), (.61, 12.0)];
}

class StreakPill extends StatelessWidget {
  final int streak;
  const StreakPill({super.key, required this.streak});
  @override
  Widget build(BuildContext context) => Center(
    child: Glass(
      opacity: .88,
      onTap: () => go<void>(context, const StreakScreen()),
      child: SizedBox(
        height: 32,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 34,
                height: 12,
                child: CustomPaint(painter: StreakBarsPainter()),
              ),
              const SizedBox(width: 9),
              Text(
                'Chuỗi:',
                style: D.text(
                  12,
                  weight: FontWeight.w600,
                  spacing: -.4,
                  height: 1.2,
                  color: D.secondary,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '$streak ngày',
                style: D.text(
                  12,
                  weight: FontWeight.w700,
                  spacing: -.6,
                  height: 1.2,
                  color: D.orange,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(CupertinoIcons.flame_fill, size: 12, color: D.orange),
            ],
          ),
        ),
      ),
    ),
  );
}

class HomeBottomBar extends StatelessWidget {
  final VoidCallback onMenu;
  final Color glass, edge;
  const HomeBottomBar({
    super.key,
    required this.onMenu,
    required this.glass,
    required this.edge,
  });
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(end: glass),
    duration: const Duration(milliseconds: 400),
    builder: (context, color, _) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _FooterGlass(
          color: color!,
          edge: edge,
          key: const ValueKey('home-history'),
          onTap: () => go<void>(context, const HistoryScreen()),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: CustomPaint(
                size: Size.square(24),
                painter: RotateGlyphPainter(),
              ),
            ),
          ),
        ),
        _FooterGlass(
          color: color,
          edge: edge,
          onTap: onMenu,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 12),
            child: Row(
              children: [
                const CustomPaint(
                  size: Size(23, 24),
                  painter: StarGlyphPainter(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Menu',
                  style: D.text(
                    15,
                    weight: FontWeight.w700,
                    spacing: .2,
                    height: 20 / 15,
                    color: Palette.footerIcon,
                  ),
                ),
              ],
            ),
          ),
        ),
        _FooterGlass(
          color: color,
          edge: edge,
          key: const ValueKey('home-settings'),
          onTap: () => go<void>(context, const ProfileScreen()),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: CustomPaint(
                size: Size.square(24),
                painter: GearGlyphPainter(),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Footer button: tinted glass with a dark hairline and a bright top rim.
class _FooterGlass extends StatelessWidget {
  final Color color, edge;
  final VoidCallback onTap;
  final Widget child;
  const _FooterGlass({
    super.key,
    required this.color,
    required this.edge,
    required this.onTap,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(50),
      boxShadow: [
        BoxShadow(
          color: D.ink.withValues(alpha: .09),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Glass(
      color: color,
      border: BorderSide(color: edge, width: .7),
      pressColor: Colors.white.withValues(alpha: .5),
      onTap: onTap,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, .09],
            colors: [
              Colors.white.withValues(alpha: .75),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
        child: child,
      ),
    ),
  );
}
