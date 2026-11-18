import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/design/design.dart';

class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final bool shadow;
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
    this.radius = 28,
    this.onTap,
    this.shadow = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: D.line.withValues(alpha: .7)),
      boxShadow: shadow ? D.shadow : null,
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class Glass extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Color? color;
  final BorderSide? border;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final Color? pressColor;
  const Glass({
    super.key,
    this.opacity = .53,
    this.color,
    this.border,
    required this.child,
    this.onTap,
    this.radius = const BorderRadius.all(Radius.circular(50)),
    this.pressColor,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: radius,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Material(
        color: color ?? Colors.white.withValues(alpha: opacity),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: border ?? BorderSide(color: Colors.white.withValues(alpha: .7)),
        ),
        child: InkWell(
          onTap: onTap,
          highlightColor: pressColor,
          splashFactory: pressColor == null ? null : NoSplash.splashFactory,
          child: child,
        ),
      ),
    ),
  );
}

/// A tinted note in a page's flow that something needs the learner's
/// attention, such as data not saving, with an optional action under it.
class Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final String? action;
  final VoidCallback? onAction;
  const Notice({
    super.key,
    required this.icon,
    required this.text,
    this.color = Palette.wrong,
    this.action,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: D.text(13, color: D.ink, height: 1.4)),
                if (action != null && onAction != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onAction,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        action!,
                        style: D.text(
                          13,
                          weight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
